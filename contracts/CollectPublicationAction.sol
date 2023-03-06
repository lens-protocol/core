// SPDX-License-Identifier: MIT

import {IPublicationActionModule} from 'contracts/interfaces/IPublicationActionModule.sol';
import {ICollectModule} from 'contracts/interfaces/ICollectModule.sol';
import {ICollectNFT} from 'contracts/interfaces/ICollectNFT.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {HubRestricted} from 'contracts/base/HubRestricted.sol';

contract CollectPublicationAction is HubRestricted, IPublicationActionModule {
    using Strings for uint256;

    struct CollectParams {
        uint256 publicationCollectedProfileId;
        uint256 publicationCollectedId;
        uint256 collectorProfileId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        bytes collectModuleData;
    }

    address immutable COLLECT_NFT_IMPL;

    string constant COLLECT_NFT_NAME_INFIX = '-Collect-';
    string constant COLLECT_NFT_SYMBOL_INFIX = '-Cl-';

    mapping(address collectModule => bool isWhitelisted) internal _collectModuleWhitelisted;
    mapping(uint256 profileId => mapping(uint256 pubId => address collectModule)) internal _collectModuleByPub;

    constructor(address hub, address collectNFTImpl) HubRestricted(hub) {
        if (collectNFTImpl == address(0)) {
            revert Errors.InitParamsInvalid();
        }
        COLLECT_NFT_IMPL = collectNFTImpl;
    }

    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address executor,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (address collectModule, bytes memory collectModuleInitData) = abi.decode(data, (address, bytes));
        if (!_collectModuleWhitelisted[collectModule]) {
            revert Errors.CollectModuleNotWhitelisted();
        }
        _collectModuleByPub[profileId][pubId] = collectModule;
        ICollectModule(collectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            executor,
            collectModuleInitData
        );
        return data;
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata processActionParams
    ) external override onlyHub returns (bytes memory) {
        CollectParams memory collectParams = abi.decode(processActionParams.actionModuleData, (CollectParams));
        address collectModule = _collectModuleByPub[processActionParams.publicationActedProfileId][
            processActionParams.publicationActedId
        ];
        if (collectModule == address(0)) {
            revert Errors.CollectNotAllowed();
        }
        address collectNFT = _getOrDeployCollectNFT({
            collectNFT: address(0), // TODO!
            publicationCollectedProfileId: processActionParams.publicationActedProfileId,
            publicationCollectedId: processActionParams.publicationActedId,
            collectNFTImpl: COLLECT_NFT_IMPL
        });
        uint256 tokenId = ICollectNFT(collectNFT).mint(processActionParams.actorProfileOwner);
        // _processCollect(
        //     collectParams,
        //     ProcessCollectParams({
        //         transactionExecutor: transactionExecutor,
        //         collectorProfileOwner: collectorProfileOwner,
        //         referrerPubTypes: referrerPubTypes,
        //         collectModule: collectModule
        //     })
        // );
        return abi.encode(tokenId);
    }

    function _getOrDeployCollectNFT(
        address collectNFT,
        uint256 publicationCollectedProfileId,
        uint256 publicationCollectedId,
        address collectNFTImpl
    ) private returns (address) {
        // address collectNFT = _collectedPublication.collectNFT;
        // if (collectNFT == address(0)) {
        //     collectNFT = _deployCollectNFT(publicationCollectedProfileId, publicationCollectedId, collectNFTImpl);
        //     _collectedPublication.collectNFT = collectNFT;
        // }
        // return collectNFT;
    }

    // // Stack too deep, so we need to use a struct.
    // struct ProcessCollectParams {
    //     address transactionExecutor;
    //     address collectorProfileOwner;
    //     Types.PublicationType[] referrerPubTypes;
    //     address collectModule;
    // }

    // function _processCollect(
    //     CollectParams calldata collectParams,
    //     ProcessCollectParams memory processCollectParams
    // ) private {
    //     ICollectModule(processCollectParams.collectModule).processCollect(
    //         Types.ProcessCollectParams({
    //             publicationCollectedProfileId: collectParams.publicationCollectedProfileId,
    //             publicationCollectedId: collectParams.publicationCollectedId,
    //             collectorProfileId: collectParams.collectorProfileId,
    //             collectorProfileOwner: processCollectParams.collectorProfileOwner,
    //             executor: processCollectParams.transactionExecutor,
    //             referrerProfileIds: collectParams.referrerProfileIds,
    //             referrerPubIds: collectParams.referrerPubIds,
    //             referrerPubTypes: processCollectParams.referrerPubTypes,
    //             data: collectParams.collectModuleData
    //         })
    //     );
    //     emit Events.Collected({
    //         publicationCollectedProfileId: collectParams.publicationCollectedProfileId,
    //         publicationCollectedId: collectParams.publicationCollectedId,
    //         collectorProfileId: collectParams.collectorProfileId,
    //         referrerProfileIds: collectParams.referrerProfileIds,
    //         referrerPubIds: collectParams.referrerPubIds,
    //         collectModuleData: collectParams.collectModuleData,
    //         timestamp: block.timestamp
    //     });
    // }

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
}
