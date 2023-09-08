// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IPublicationActionModule} from 'contracts/interfaces/IPublicationActionModule.sol';
import {ICollectModule} from 'contracts/interfaces/ICollectModule.sol';
import {ICollectNFT} from 'contracts/interfaces/ICollectNFT.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {HubRestricted} from 'contracts/base/HubRestricted.sol';
import {IModuleGlobals} from 'contracts/interfaces/IModuleGlobals.sol';

contract CollectPublicationAction is HubRestricted, IPublicationActionModule {
    struct CollectData {
        address collectModule;
        address collectNFT;
    }

    event CollectModuleRegistered(address collectModule, uint256 timestamp);

    /**
     * @dev Emitted when a collectNFT clone is deployed using a lazy deployment pattern.
     *
     * @param profileId The publisher's profile token ID.
     * @param pubId The publication associated with the newly deployed collectNFT clone's ID.
     * @param collectNFT The address of the newly deployed collectNFT clone.
     * @param timestamp The current block timestamp.
     */
    event CollectNFTDeployed(
        uint256 indexed profileId,
        uint256 indexed pubId,
        address indexed collectNFT,
        uint256 timestamp
    );

    /**
     * @dev Emitted upon a successful collect action.
     *
     * @param collectedProfileId The token ID of the profile that published the collected publication.
     * @param collectedPubId The ID of the collected publication.
     * @param collectorProfileId The token ID of the profile that collected the publication.
     * @param nftRecipient The address that received the collect NFT.
     * @param collectActionData The custom data passed to the collect module, if any.
     * @param collectActionResult The data returned from the collect module's collect action. This is ABI-encoded
     * and depends on the collect module chosen.
     * @param collectNFT The address of the NFT collection where the minted collect NFT belongs to.
     * @param tokenId The token ID of the collect NFT that was minted as a collect of the publication.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The current block timestamp.
     */
    event Collected(
        uint256 indexed collectedProfileId,
        uint256 indexed collectedPubId,
        uint256 indexed collectorProfileId,
        address nftRecipient,
        bytes collectActionData,
        bytes collectActionResult,
        address collectNFT,
        uint256 tokenId,
        address transactionExecutor,
        uint256 timestamp
    );

    address public immutable COLLECT_NFT_IMPL;
    address public immutable MODULE_GLOBALS;

    mapping(address collectModule => bool isWhitelisted) internal _collectModuleRegistered;
    mapping(uint256 profileId => mapping(uint256 pubId => CollectData collectData)) internal _collectDataByPub;

    constructor(address hub, address collectNFTImpl, address moduleGlobals) HubRestricted(hub) {
        COLLECT_NFT_IMPL = collectNFTImpl;
        MODULE_GLOBALS = moduleGlobals;
    }

    function registerCollectModule(address collectModule) external {
        _collectModuleRegistered[collectModule] = true;
        emit CollectModuleRegistered(collectModule, block.timestamp);
    }

    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (address collectModule, bytes memory collectModuleInitData) = abi.decode(data, (address, bytes));
        if (!_collectModuleRegistered[collectModule]) {
            revert Errors.NotRegistered();
        }
        _collectDataByPub[profileId][pubId].collectModule = collectModule;
        ICollectModule(collectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            collectModuleInitData
        );
        return '';
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata processActionParams
    ) external override onlyHub returns (bytes memory) {
        address collectModule = _collectDataByPub[processActionParams.publicationActedProfileId][
            processActionParams.publicationActedId
        ].collectModule;
        if (collectModule == address(0)) {
            revert Errors.CollectNotAllowed();
        }
        address collectNFT = _getOrDeployCollectNFT({
            publicationCollectedProfileId: processActionParams.publicationActedProfileId,
            publicationCollectedId: processActionParams.publicationActedId,
            collectNFTImpl: COLLECT_NFT_IMPL
        });
        (address collectNftRecipient, bytes memory collectData) = abi.decode(
            processActionParams.actionModuleData,
            (address, bytes)
        );
        uint256 tokenId = ICollectNFT(collectNFT).mint(collectNftRecipient);
        bytes memory collectActionResult = _processCollect(collectModule, collectData, processActionParams);
        _emitCollectedEvent(
            processActionParams,
            collectNftRecipient,
            collectData,
            collectActionResult,
            collectNFT,
            tokenId
        );
        return abi.encode(collectNFT, tokenId, collectModule, collectActionResult);
    }

    function _emitCollectedEvent(
        Types.ProcessActionParams calldata processActionParams,
        address collectNftRecipient,
        bytes memory collectData,
        bytes memory collectActionResult,
        address collectNFT,
        uint256 tokenId
    ) private {
        emit Collected({
            collectedProfileId: processActionParams.publicationActedProfileId,
            collectedPubId: processActionParams.publicationActedId,
            collectorProfileId: processActionParams.actorProfileId,
            nftRecipient: collectNftRecipient,
            collectActionData: collectData,
            collectActionResult: collectActionResult,
            collectNFT: collectNFT,
            tokenId: tokenId,
            transactionExecutor: processActionParams.transactionExecutor,
            timestamp: block.timestamp
        });
    }

    function getCollectData(uint256 profileId, uint256 pubId) external view returns (CollectData memory) {
        return _collectDataByPub[profileId][pubId];
    }

    function _getOrDeployCollectNFT(
        uint256 publicationCollectedProfileId,
        uint256 publicationCollectedId,
        address collectNFTImpl
    ) private returns (address) {
        address collectNFT = _collectDataByPub[publicationCollectedProfileId][publicationCollectedId].collectNFT;
        if (collectNFT == address(0)) {
            collectNFT = _deployCollectNFT(publicationCollectedProfileId, publicationCollectedId, collectNFTImpl);
            _collectDataByPub[publicationCollectedProfileId][publicationCollectedId].collectNFT = collectNFT;
        }
        return collectNFT;
    }

    function _processCollect(
        address collectModule,
        bytes memory collectData,
        Types.ProcessActionParams calldata processActionParams
    ) private returns (bytes memory) {
        return
            ICollectModule(collectModule).processCollect(
                Types.ProcessCollectParams({
                    publicationCollectedProfileId: processActionParams.publicationActedProfileId,
                    publicationCollectedId: processActionParams.publicationActedId,
                    collectorProfileId: processActionParams.actorProfileId,
                    collectorProfileOwner: processActionParams.actorProfileOwner,
                    transactionExecutor: processActionParams.transactionExecutor,
                    referrerProfileIds: processActionParams.referrerProfileIds,
                    referrerPubIds: processActionParams.referrerPubIds,
                    referrerPubTypes: processActionParams.referrerPubTypes,
                    data: collectData
                })
            );
    }

    function _deployCollectNFT(uint256 profileId, uint256 pubId, address collectNFTImpl) private returns (address) {
        address collectNFT = Clones.clone(collectNFTImpl);

        ICollectNFT(collectNFT).initialize(profileId, pubId);
        emit CollectNFTDeployed(profileId, pubId, collectNFT, block.timestamp);

        return collectNFT;
    }

    function isCollectModuleRegistered(address collectModule) external view returns (bool) {
        return _collectModuleRegistered[collectModule];
    }
}
