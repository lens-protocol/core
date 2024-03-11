// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ValidationLib} from './ValidationLib.sol';
import {Types} from './constants/Types.sol';
import {Errors} from './constants/Errors.sol';
import {Events} from './constants/Events.sol';
import {ICollectNFT} from '../interfaces/ICollectNFT.sol';
import {ILegacyCollectModule} from '../interfaces/ILegacyCollectModule.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {StorageLib} from './StorageLib.sol';
import {FollowLib} from './FollowLib.sol';

/**
 * @title LegacyCollectLib
 * @author Lens Protocol
 * @notice Library containing the logic for legacy collect operation.
 */
library LegacyCollectLib {
    using Strings for uint256;

    /**
     * @dev Emitted upon a successful legacy collect action.
     *
     * @param publicationCollectedProfileId The profile ID of the publication being collected.
     * @param publicationCollectedId The publication ID of the publication being collected.
     * @param collectorProfileId The profile ID of the profile that collected the publication.
     * @param transactionExecutor The address of the account that executed the collect transaction.
     * @param referrerProfileId The profile ID of the referrer, if any. Zero if no referrer.
     * @param referrerPubId The publication ID of the referrer, if any. Zero if no referrer.
     * @param collectModule The address of the collect module that was used to collect the publication.
     * @param collectModuleData The data passed to the collect module's collect action. This is ABI-encoded and depends
     * on the collect module chosen.
     * @param tokenId The token ID of the collect NFT that was minted as a collect of the publication.
     * @param timestamp The current block timestamp.
     */
    event CollectedLegacy(
        uint256 indexed publicationCollectedProfileId,
        uint256 indexed publicationCollectedId,
        uint256 indexed collectorProfileId,
        address transactionExecutor,
        uint256 referrerProfileId,
        uint256 referrerPubId,
        address collectModule,
        bytes collectModuleData,
        uint256 tokenId,
        uint256 timestamp
    );

    function collect(
        Types.LegacyCollectParams calldata collectParams,
        address transactionExecutor,
        address collectorProfileOwner,
        address collectNFTImpl
    ) external returns (uint256) {
        ValidationLib.validateNotBlocked({
            profile: collectParams.collectorProfileId,
            byProfile: collectParams.publicationCollectedProfileId
        });

        address collectModule;
        uint256 tokenId;
        address collectNFT;
        {
            Types.Publication storage _collectedPublication = StorageLib.getPublication(
                collectParams.publicationCollectedProfileId,
                collectParams.publicationCollectedId
            );
            // This is a legacy collect operation, so we get the collect module from the deprecated storage field.
            collectModule = _collectedPublication.__DEPRECATED__collectModule;
            if (collectModule == address(0)) {
                // It doesn't have collect module, thus it cannot be collected (a mirror or non-existent).
                revert Errors.CollectNotAllowed();
            }

            if (collectParams.referrerProfileId != 0 || collectParams.referrerPubId != 0) {
                ValidationLib.validateLegacyCollectReferrer(
                    collectParams.referrerProfileId,
                    collectParams.referrerPubId,
                    collectParams.publicationCollectedProfileId,
                    collectParams.publicationCollectedId
                );
            }

            collectNFT = _getOrDeployCollectNFT(
                _collectedPublication,
                collectParams.publicationCollectedProfileId,
                collectParams.publicationCollectedId,
                collectNFTImpl
            );
            tokenId = ICollectNFT(collectNFT).mint(collectorProfileOwner);
        }

        _prefillLegacyCollectFollowValidationHelper({
            profileId: collectParams.publicationCollectedProfileId,
            collectorProfileId: collectParams.collectorProfileId,
            collector: transactionExecutor
        });

        ILegacyCollectModule(collectModule).processCollect({
            // Legacy collect modules expect referrer profile ID to match the collected pub's author if no referrer set.
            referrerProfileId: collectParams.referrerProfileId == 0
                ? collectParams.publicationCollectedProfileId
                : collectParams.referrerProfileId,
            // Collect NFT is minted to the `collectorProfileOwner`. Some follow-based constraints are expected to be
            // broken in legacy collect modules if the `transactionExecutor` does not match the `collectorProfileOwner`.
            collector: transactionExecutor,
            profileId: collectParams.publicationCollectedProfileId,
            pubId: collectParams.publicationCollectedId,
            data: collectParams.collectModuleData
        });

        emit CollectedLegacy({
            publicationCollectedProfileId: collectParams.publicationCollectedProfileId,
            publicationCollectedId: collectParams.publicationCollectedId,
            collectorProfileId: collectParams.collectorProfileId,
            transactionExecutor: transactionExecutor,
            referrerProfileId: collectParams.referrerProfileId,
            referrerPubId: collectParams.referrerPubId,
            collectModule: collectModule,
            collectModuleData: collectParams.collectModuleData,
            tokenId: tokenId,
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

        ICollectNFT(collectNFT).initialize(profileId, pubId);
        emit Events.LegacyCollectNFTDeployed(profileId, pubId, collectNFT, block.timestamp);

        return collectNFT;
    }

    function _prefillLegacyCollectFollowValidationHelper(
        uint256 profileId,
        uint256 collectorProfileId,
        address collector
    ) private {
        // It's important to set it as zero if not following, as the storage could be dirty from a previous transaction.
        StorageLib.legacyCollectFollowValidationHelper()[collector] = FollowLib.isFollowing({
            followerProfileId: collectorProfileId,
            followedProfileId: profileId
        })
            ? profileId
            : 0;
    }
}
