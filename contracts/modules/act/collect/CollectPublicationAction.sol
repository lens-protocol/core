// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IPublicationActionModule} from '../../../interfaces/IPublicationActionModule.sol';
import {ICollectModule} from '../../interfaces/ICollectModule.sol';
import {ICollectNFT} from '../../../interfaces/ICollectNFT.sol';
import {Types} from '../../../libraries/constants/Types.sol';
import {ModuleTypes} from '../../libraries/constants/ModuleTypes.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Errors} from '../../constants/Errors.sol';
import {HubRestricted} from '../../../base/HubRestricted.sol';
import {ILensModule} from '../../interfaces/ILensModule.sol';

import {LensModuleMetadataInitializable} from '../../LensModuleMetadataInitializable.sol';

/**
 * @title CollectPublicationAction
 * @author LensProtocol
 * @notice An Publication Action module that allows users to collect publications.
 * @custom:upgradeable Transparent upgradeable proxy without initializer.
 */
contract CollectPublicationAction is LensModuleMetadataInitializable, HubRestricted, IPublicationActionModule {
    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == type(IPublicationActionModule).interfaceId || super.supportsInterface(interfaceID);
    }

    struct CollectData {
        address collectModule;
        address collectNFT;
    }

    event CollectModuleRegistered(address collectModule, string metadata, uint256 timestamp);

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

    error NotCollectModule();

    address public immutable COLLECT_NFT_IMPL;

    mapping(address collectModule => bool isWhitelisted) internal _collectModuleRegistered;
    mapping(uint256 profileId => mapping(uint256 pubId => CollectData collectData)) internal _collectDataByPub;

    constructor(
        address hub,
        address collectNFTImpl,
        address moduleOwner
    ) HubRestricted(hub) LensModuleMetadataInitializable(moduleOwner) {
        COLLECT_NFT_IMPL = collectNFTImpl;
    }

    function verifyCollectModule(address collectModule) public returns (bool) {
        registerCollectModule(collectModule);
        return true;
    }

    function registerCollectModule(address collectModule) public returns (bool) {
        if (_collectModuleRegistered[collectModule]) {
            return false;
        } else {
            if (!ILensModule(collectModule).supportsInterface(type(ICollectModule).interfaceId)) {
                revert NotCollectModule();
            }

            string memory metadata = ILensModule(collectModule).getModuleMetadataURI();
            emit CollectModuleRegistered(collectModule, metadata, block.timestamp);
            _collectModuleRegistered[collectModule] = true;
            return true;
        }
    }

    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (address collectModule, bytes memory collectModuleInitData) = abi.decode(data, (address, bytes));
        if (_collectDataByPub[profileId][pubId].collectModule != address(0)) {
            revert Errors.AlreadyInitialized();
        }
        verifyCollectModule(collectModule);
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
                ModuleTypes.ProcessCollectParams({
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
