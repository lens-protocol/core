// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IPublicationActionModule} from 'contracts/interfaces/IPublicationActionModule.sol';
import {ICollectModule} from 'contracts/interfaces/ICollectModule.sol';
import {ICollectNFT} from 'contracts/interfaces/ICollectNFT.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {HubRestricted} from 'contracts/base/HubRestricted.sol';
import {VersionedInitializable} from 'contracts/base/upgradeability/VersionedInitializable.sol';

contract CollectPublicationAction is HubRestricted, VersionedInitializable, IPublicationActionModule {
    using Strings for uint256;

    // Constant for upgradeability purposes, see VersionedInitializable. Do not confuse it with the EIP-712 version number.
    uint256 internal constant REVISION = 1;

    // TODO: Should we move this to some Types file when in the Modules repo
    struct CollectData {
        address collectModule;
        address collectNFT;
    }

    address immutable COLLECT_NFT_IMPL;

    string constant COLLECT_NFT_NAME_INFIX = '-Collect-';
    string constant COLLECT_NFT_SYMBOL_INFIX = '-Cl-';

    mapping(address collectModule => bool isWhitelisted) internal _collectModuleWhitelisted;
    mapping(uint256 profileId => mapping(uint256 pubId => CollectData collectData)) internal _collectDataByPub;

    constructor(address hub, address collectNFTImpl) HubRestricted(hub) {
        if (collectNFTImpl == address(0)) {
            revert Errors.InitParamsInvalid();
        }
        COLLECT_NFT_IMPL = collectNFTImpl;
    }

    // TODO: Add whitelist collect module function

    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (address collectModule, bytes memory collectModuleInitData) = abi.decode(data, (address, bytes));
        if (!_collectModuleWhitelisted[collectModule]) {
            revert Errors.CollectModuleNotWhitelisted();
        }
        _collectDataByPub[profileId][pubId].collectModule = collectModule;
        ICollectModule(collectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            collectModuleInitData
        );
        return data;
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
        uint256 tokenId = ICollectNFT(collectNFT).mint(processActionParams.actorProfileOwner);
        bytes memory collectActionResult = _processCollect(collectModule, processActionParams);

        emit Events.Collected({
            collectActionParams: processActionParams,
            collectModule: collectModule,
            collectNFT: collectNFT,
            tokenId: tokenId,
            collectActionResult: collectActionResult,
            timestamp: block.timestamp
        });

        return abi.encode(tokenId, collectActionResult);
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
        Types.ProcessActionParams calldata processActionParams
    ) private returns (bytes memory) {
        return
            ICollectModule(collectModule).processCollect(
                Types.ProcessCollectParams({
                    publicationCollectedProfileId: processActionParams.publicationActedProfileId,
                    publicationCollectedId: processActionParams.publicationActedProfileId,
                    collectorProfileId: processActionParams.actorProfileId,
                    collectorProfileOwner: processActionParams.actorProfileOwner,
                    transactionExecutor: processActionParams.transactionExecutor,
                    referrerProfileIds: processActionParams.referrerProfileIds,
                    referrerPubIds: processActionParams.referrerPubIds,
                    referrerPubTypes: processActionParams.referrerPubTypes,
                    data: processActionParams.actionModuleData
                })
            );
    }

    function _deployCollectNFT(uint256 profileId, uint256 pubId, address collectNFTImpl) private returns (address) {
        address collectNFT = Clones.clone(collectNFTImpl);

        string memory collectNFTName = string(
            abi.encodePacked(profileId.toString(), COLLECT_NFT_NAME_INFIX, pubId.toString())
        );
        string memory collectNFTSymbol = string(
            abi.encodePacked(profileId.toString(), COLLECT_NFT_SYMBOL_INFIX, pubId.toString())
        );

        ICollectNFT(collectNFT).initialize(profileId, pubId, collectNFTName, collectNFTSymbol);
        emit Events.CollectNFTDeployed(profileId, pubId, collectNFT, block.timestamp);

        return collectNFT;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
