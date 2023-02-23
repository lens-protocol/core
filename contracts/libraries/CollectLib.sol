// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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
    ) internal returns (uint256) {
        address collectModule;
        Types.PublicationType referrerPubType;
        uint256 tokenId;
        {
            Types.Publication storage _collectedPublication = StorageLib.getPublication(
                collectParams.publicationCollectedProfileId,
                collectParams.publicationCollectedId
            );
            collectModule = _collectedPublication.collectModule;
            if (collectModule == address(0)) {
                // Doesn't have collectModule, thus it cannot be a collected (a mirror or non-existent).
                revert Errors.CollectNotAllowed();
            }
            referrerPubType = ValidationLib.validateReferrerAndGetReferrerPubType(
                collectParams.referrerProfileId,
                collectParams.referrerPubId,
                collectParams.publicationCollectedProfileId,
                collectParams.publicationCollectedId
            );
            address collectNFT = _getOrDeployCollectNFT(
                _collectedPublication,
                collectParams.publicationCollectedProfileId,
                collectParams.publicationCollectedId,
                collectNFTImpl
            );
            tokenId = ICollectNFT(collectNFT).mint(collectorProfileOwner);
        }

        _processCollect({
            collectParams: collectParams,
            transactionExecutor: transactionExecutor,
            collectorProfileOwner: collectorProfileOwner,
            referrerPubType: referrerPubType,
            collectModule: collectModule
        });

        return tokenId;
    }

    function _getOrDeployCollectNFT(
        Types.Publication storage _collectedPublication,
        uint256 publicationCollectedProfileId,
        uint256 publicationCollectedId,
        address collectNFTImpl
    ) private returns (address) {
        address collectNFT = _collectedPublication.collectNFT;
        if (collectNFT == address(0)) {
            collectNFT = _deployCollectNFT(publicationCollectedProfileId, publicationCollectedId, collectNFTImpl);
            _collectedPublication.collectNFT = collectNFT;
        }
        return collectNFT;
    }

    function _processCollect(
        Types.CollectParams calldata collectParams,
        address transactionExecutor,
        address collectorProfileOwner,
        Types.PublicationType referrerPubType,
        address collectModule
    ) private {
        try
            ICollectModule(collectModule).processCollect({
                publicationCollectedProfileId: collectParams.publicationCollectedProfileId,
                publicationCollectedId: collectParams.publicationCollectedId,
                collectorProfileId: collectParams.collectorProfileId,
                collectorProfileOwner: collectorProfileOwner,
                executor: transactionExecutor,
                referrerProfileId: collectParams.referrerProfileId,
                referrerPubId: collectParams.referrerPubId,
                referrerPubType: referrerPubType,
                data: collectParams.collectModuleData
            })
        {} catch (bytes memory err) {
            assembly {
                /// Equivalent to reverting with the returned error selector if
                /// the length is not zero.
                let length := mload(err)
                if iszero(iszero(length)) {
                    revert(add(err, 32), length)
                }
            }
            if (collectorProfileOwner != transactionExecutor) revert Errors.ExecutorInvalid();
            IDeprecatedCollectModule(collectModule).processCollect(
                collectParams.publicationCollectedProfileId,
                collectorProfileOwner,
                collectParams.referrerProfileId,
                collectParams.referrerPubId,
                collectParams.collectModuleData
            );
        }

        emit Events.Collected({
            publicationCollectedProfileId: collectParams.publicationCollectedProfileId,
            publicationCollectedId: collectParams.publicationCollectedId,
            collectorProfileId: collectParams.collectorProfileId,
            referrerProfileId: collectParams.referrerProfileId,
            referrerPubId: collectParams.referrerPubId,
            collectModuleData: collectParams.collectModuleData,
            timestamp: block.timestamp
        });
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
    function _deployCollectNFT(
        uint256 profileId,
        uint256 pubId,
        address collectNFTImpl
    ) private returns (address) {
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
