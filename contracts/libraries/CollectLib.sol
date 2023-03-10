// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {ICollectNFT} from 'contracts/interfaces/ICollectNFT.sol';
import {ICollectModule} from 'contracts/interfaces/ICollectModule.sol';
import {IDeprecatedCollectModule} from 'contracts/interfaces/IDeprecatedCollectModule.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';

/**
 * @title CollectLib
 * @author Lens Protocol
 */
library CollectLib {
    using Strings for uint256;

    string constant COLLECT_NFT_NAME_INFIX = '-Collect-';
    string constant COLLECT_NFT_SYMBOL_INFIX = '-Cl-';

    function collect(
        Types.CollectParams calldata collectParams,
        address transactionExecutor,
        address collectorProfileOwner,
        address collectNFTImpl
    ) external returns (uint256) {
        address collectModule;
        Types.PublicationType[] memory referrerPubTypes;
        uint256 tokenId;
        address collectNFT;
        {
            Types.Publication storage _collectedPublication = StorageLib.getPublication(
                collectParams.publicationCollectedProfileId,
                collectParams.publicationCollectedId
            );
            collectModule = _collectedPublication.__DEPRECATED__collectModule;
            if (collectModule == address(0)) {
                // Doesn't have collectModule, thus it cannot be a collected (a mirror or non-existent).
                revert Errors.CollectNotAllowed();
            }

            referrerPubTypes = ValidationLib.validateReferrersAndGetReferrersPubTypes(
                collectParams.referrerProfileIds,
                collectParams.referrerPubIds,
                collectParams.publicationCollectedProfileId,
                collectParams.publicationCollectedId
            );
            collectNFT = _getOrDeployCollectNFT(
                _collectedPublication,
                collectParams.publicationCollectedProfileId,
                collectParams.publicationCollectedId,
                collectNFTImpl
            );
            tokenId = ICollectNFT(collectNFT).mint(collectorProfileOwner);
        }

        _processCollect(
            collectParams,
            ProcessCollectParams({
                transactionExecutor: transactionExecutor,
                collectorProfileOwner: collectorProfileOwner,
                referrerPubTypes: referrerPubTypes,
                collectModule: collectModule
            })
        );

        emit Events.Collected({
            collectActionParams: Types.ProcessActionParams({
                publicationActedProfileId: collectParams.publicationCollectedProfileId,
                publicationActedId: collectParams.publicationCollectedId,
                actorProfileId: collectParams.collectorProfileId,
                actorProfileOwner: collectorProfileOwner,
                transactionExecutor: transactionExecutor,
                referrerProfileIds: collectParams.referrerProfileIds,
                referrerPubIds: collectParams.referrerPubIds,
                referrerPubTypes: referrerPubTypes,
                actionModuleData: collectParams.collectModuleData
            }),
            collectModule: collectModule,
            collectNFT: collectNFT,
            tokenId: tokenId,
            collectActionResult: '',
            timestamp: block.timestamp
        });

        return tokenId;
    }

    function _getOrDeployCollectNFT(
        Types.Publication storage _collectedPublication,
        uint256 publicationCollectedProfileId,
        uint256 publicationCollectedId,
        address collectNFTImpl
    ) private returns (address) {
        address collectNFT = _collectedPublication.__DEPRECATED__collectNFT;
        if (collectNFT == address(0)) {
            collectNFT = _deployCollectNFT(publicationCollectedProfileId, publicationCollectedId, collectNFTImpl);
            _collectedPublication.__DEPRECATED__collectNFT = collectNFT;
        }
        return collectNFT;
    }

    // Stack too deep, so we need to use a struct.
    struct ProcessCollectParams {
        address transactionExecutor;
        address collectorProfileOwner;
        Types.PublicationType[] referrerPubTypes;
        address collectModule;
    }

    function _processCollect(
        Types.CollectParams calldata collectParams,
        ProcessCollectParams memory processCollectParams
    ) private {
        try
            ICollectModule(processCollectParams.collectModule).processCollect(
                Types.ProcessCollectParams({
                    publicationCollectedProfileId: collectParams.publicationCollectedProfileId,
                    publicationCollectedId: collectParams.publicationCollectedId,
                    collectorProfileId: collectParams.collectorProfileId,
                    collectorProfileOwner: processCollectParams.collectorProfileOwner,
                    transactionExecutor: processCollectParams.transactionExecutor,
                    referrerProfileIds: collectParams.referrerProfileIds,
                    referrerPubIds: collectParams.referrerPubIds,
                    referrerPubTypes: processCollectParams.referrerPubTypes,
                    data: collectParams.collectModuleData
                })
            )
        {} catch (bytes memory err) {
            assembly {
                // Equivalent to reverting with the returned error selector if
                // the length is not zero.
                let length := mload(err)
                if iszero(iszero(length)) {
                    revert(add(err, 32), length)
                }
            }
            if (processCollectParams.collectorProfileOwner != processCollectParams.transactionExecutor) {
                revert Errors.ExecutorInvalid();
            }
            uint256 referrerProfileId;
            uint256 referrerPubId;
            if (collectParams.referrerProfileIds.length > 0) {
                if (collectParams.referrerProfileIds.length > 1) {
                    // Deprecated modules only support one referrer.
                    revert Errors.DeprecaredModulesOnlySupportOneReferrer();
                }
                // Only one referral was passed.
                referrerProfileId = collectParams.referrerProfileIds[0];
                referrerPubId = collectParams.referrerPubIds[0];
            }
            IDeprecatedCollectModule(processCollectParams.collectModule).processCollect(
                collectParams.publicationCollectedProfileId,
                processCollectParams.collectorProfileOwner,
                referrerProfileId,
                referrerPubId,
                collectParams.collectModuleData
            );
        }
    }

    /**
     * @notice Deploys the given profile's Collect NFT contract.
     *
     * @param profileId The token ID of the profile which Collect NFT should be deployed.
     * @param pubId The publication ID of the publication being collected, which Collect NFT should be deployed.
     * @param collectNFTImpl The address of the Collect NFT implementation that should be used for the deployment.
     *
     * @return address The address of the deployed Collect NFT contract.
     */
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
