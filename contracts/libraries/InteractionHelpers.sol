// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {FollowNFTProxy} from 'contracts/upgradeability/FollowNFTProxy.sol';
import {GeneralHelpers} from 'contracts/libraries/GeneralHelpers.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';
import {ICollectNFT} from 'contracts/interfaces/ICollectNFT.sol';
import {IFollowModule} from 'contracts/interfaces/IFollowModule.sol';
import {ICollectModule} from 'contracts/interfaces/ICollectModule.sol';
import {IReferenceModule} from 'contracts/interfaces/IReferenceModule.sol';
import {IDeprecatedFollowModule} from 'contracts/interfaces/IDeprecatedFollowModule.sol';
import {IDeprecatedCollectModule} from 'contracts/interfaces/IDeprecatedCollectModule.sol';
import {IDeprecatedReferenceModule} from 'contracts/interfaces/IDeprecatedReferenceModule.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

import 'contracts/libraries/Constants.sol';

/**
 * @title InteractionHelpers
 * @author Lens Protocol
 *
 * @notice This is the library used by the GeneralLib that contains the logic for follows & collects.
 *
 * @dev The functions are internal, so they are inlined into the GeneralLib.
 */
library InteractionHelpers {
    using Strings for uint256;

    function follow(
        uint256 followerProfileId,
        address executor,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata followModuleDatas
    ) internal returns (uint256[] memory) {
        if (
            idsOfProfilesToFollow.length != followTokenIds.length ||
            idsOfProfilesToFollow.length != followModuleDatas.length
        ) {
            revert Errors.ArrayMismatch();
        }
        uint256[] memory followTokenIdsAssigned = new uint256[](idsOfProfilesToFollow.length);
        uint256 i;
        while (i < idsOfProfilesToFollow.length) {
            _validateProfileExists({profileId: idsOfProfilesToFollow[i]});

            GeneralHelpers.validateNotBlocked({
                profile: followerProfileId,
                byProfile: idsOfProfilesToFollow[i]
            });

            if (followerProfileId == idsOfProfilesToFollow[i]) {
                revert Errors.SelfFollow();
            }

            followTokenIdsAssigned[i] = _follow({
                followerProfileId: followerProfileId,
                executor: executor,
                idOfProfileToFollow: idsOfProfilesToFollow[i],
                followTokenId: followTokenIds[i],
                followModuleData: followModuleDatas[i]
            });

            unchecked {
                ++i;
            }
        }
        return followTokenIdsAssigned;
    }

    function unfollow(
        uint256 unfollowerProfileId,
        address executor,
        uint256[] calldata idsOfProfilesToUnfollow
    ) internal {
        uint256 i;
        while (i < idsOfProfilesToUnfollow.length) {
            uint256 idOfProfileToUnfollow = idsOfProfilesToUnfollow[i];
            _validateProfileExists(idOfProfileToUnfollow);

            address followNFT;
            // Load the Follow NFT for the profile being unfollowed.
            assembly {
                mstore(0, idOfProfileToUnfollow)
                mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
                let followNFTSlot := add(keccak256(0, 64), PROFILE_FOLLOW_NFT_OFFSET)
                followNFT := sload(followNFTSlot)
            }

            if (followNFT == address(0)) {
                revert Errors.NotFollowing();
            }

            IFollowNFT(followNFT).unfollow({
                unfollowerProfileId: unfollowerProfileId,
                executor: executor
            });

            emit Events.Unfollowed(unfollowerProfileId, idOfProfileToUnfollow, block.timestamp);

            unchecked {
                ++i;
            }
        }
    }

    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) internal {
        if (idsOfProfilesToSetBlockStatus.length != blockStatus.length) {
            revert Errors.ArrayMismatch();
        }
        uint256 blockStatusByProfileSlot;
        // Calculates the slot of the block status internal mapping once accessed by `byProfileId`.
        // i.e. the slot of `_blockedStatus[byProfileId]`
        assembly {
            mstore(0, byProfileId)
            mstore(32, BLOCK_STATUS_MAPPING_SLOT)
            blockStatusByProfileSlot := keccak256(0, 64)
        }
        address followNFT;
        // Loads the Follow NFT address from storage.
        // i.e. `followNFT = _profileById[byProfileId].followNFT;`
        assembly {
            mstore(0, byProfileId)
            mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
            followNFT := sload(add(keccak256(0, 64), PROFILE_FOLLOW_NFT_OFFSET))
        }
        uint256 i;
        uint256 idOfProfileToSetBlockStatus;
        bool setToBlocked;
        while (i < idsOfProfilesToSetBlockStatus.length) {
            idOfProfileToSetBlockStatus = idsOfProfilesToSetBlockStatus[i];
            _validateProfileExists(idOfProfileToSetBlockStatus);
            if (byProfileId == idOfProfileToSetBlockStatus) {
                revert Errors.SelfBlock();
            }
            setToBlocked = blockStatus[i];
            if (followNFT != address(0) && setToBlocked) {
                IFollowNFT(followNFT).processBlock(idOfProfileToSetBlockStatus);
            }
            // Stores the block status.
            // i.e. `_blockedStatus[byProfileId][idOfProfileToSetBlockStatus] = setToBlocked;`
            assembly {
                mstore(0, idOfProfileToSetBlockStatus)
                mstore(32, blockStatusByProfileSlot)
                sstore(keccak256(0, 64), setToBlocked)
            }
            if (setToBlocked) {
                emit Events.Blocked(byProfileId, idOfProfileToSetBlockStatus, block.timestamp);
            } else {
                emit Events.Unblocked(byProfileId, idOfProfileToSetBlockStatus, block.timestamp);
            }
            unchecked {
                ++i;
            }
        }
    }

    function collect(
        Types.CollectParams calldata collectParams,
        address transactionExecutor,
        address collectNFTImpl
    ) internal returns (uint256) {
        address collectModule;
        Types.PublicationType referrerPubType;
        uint256 tokenId;
        address collectorProfileOwner = GeneralHelpers.ownerOf(collectParams.collectorProfileId);
        {
            Types.PublicationStruct storage _collectedPublication = GeneralHelpers
                .getPublicationStruct(
                    collectParams.publicationCollectedProfileId,
                    collectParams.publicationCollectedId
                );
            collectModule = _collectedPublication.collectModule;
            if (collectModule == address(0)) {
                // Doesn't have collectModule, thus it cannot be a collected (a mirror or non-existent).
                revert Errors.CollectNotAllowed();
            }
            referrerPubType = GeneralHelpers.validateReferrerAndGetReferrerPubType(
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
        Types.PublicationStruct storage _collectedPublication,
        uint256 publicationCollectedProfileId,
        uint256 publicationCollectedId,
        address collectNFTImpl
    ) private returns (address) {
        address collectNFT = _collectedPublication.collectNFT;
        if (collectNFT == address(0)) {
            collectNFT = _deployCollectNFT(
                publicationCollectedProfileId,
                publicationCollectedId,
                collectNFTImpl
            );
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

    // /**
    //  * @notice Emits the `Collected` event that signals that a successful collect action has occurred.
    //  *
    //  * @dev This is done through this function to prevent stack too deep compilation error.
    //  *
    //  * @param collectorProfileId The owner address of the profile collecting the publication.
    //  * @param publisherProfileId The token ID of the profile that the collect was initiated towards, useful to differentiate mirrors.
    //  * @param pubId The publication ID that the collect was initiated towards, useful to differentiate mirrors.
    //  * @param rootProfileId The profile token ID of the profile whose publication is being collected.
    //  * @param rootPubId The publication ID of the publication being collected.
    //  * @param data The data passed to the collect module.
    //  */
    // function _emitCollectedEvent(
    //     uint256 publicationCollectedProfileId,
    //     uint256 publicationCollectedId,
    //     uint256 collectorProfileId,
    //     uint256 referrerProfileId,
    //     uint256 referrerPubId,
    //     bytes calldata collectModuleData,
    //     uint256 timestamp
    // ) private {
    //     emit Events.Collected(
    //     publicationCollectedProfileId: publisherProfileId,
    //     publicationCollectedId: pubId,
    //     collectorProfileId: collectorProfileId,
    //     referrerProfileId: ,
    //     referrerPubId: ,
    //     collectModuleData: data,
    //     timestamp: block.timestamp,
    //     );
    // }

    function _follow(
        uint256 followerProfileId,
        address executor,
        uint256 idOfProfileToFollow,
        uint256 followTokenId,
        bytes calldata followModuleData
    ) internal returns (uint256) {
        uint256 followNFTSlot;
        address followModule;
        address followNFT;

        // Load the follow NFT and follow module for the given profile being followed, and cache
        // the follow NFT slot.
        assembly {
            mstore(0, idOfProfileToFollow)
            mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
            // The follow NFT offset is 2, the follow module offset is 1,
            // so we just need to subtract 1 instead of recalculating the slot.
            followNFTSlot := add(keccak256(0, 64), PROFILE_FOLLOW_NFT_OFFSET)
            followModule := sload(sub(followNFTSlot, 1))
            followNFT := sload(followNFTSlot)
        }

        if (followNFT == address(0)) {
            followNFT = _deployFollowNFT(idOfProfileToFollow);

            // Store the follow NFT in the cached slot.
            assembly {
                sstore(followNFTSlot, followNFT)
            }
        }

        uint256 followTokenIdAssigned = IFollowNFT(followNFT).follow({
            followerProfileId: followerProfileId,
            executor: executor,
            followTokenId: followTokenId
        });

        if (followModule != address(0)) {
            IFollowModule(followModule).processFollow(
                followerProfileId,
                followTokenId,
                executor,
                idOfProfileToFollow,
                followModuleData
            );
        }

        emit Events.Followed(
            followerProfileId,
            idOfProfileToFollow,
            followTokenIdAssigned,
            followModuleData,
            block.timestamp
        );

        return followTokenIdAssigned;
    }

    /**
     * @notice Deploys the given profile's Follow NFT contract.
     *
     * @param profileId The token ID of the profile which Follow NFT should be deployed.
     *
     * @return address The address of the deployed Follow NFT contract.
     */
    function _deployFollowNFT(uint256 profileId) private returns (address) {
        bytes memory functionData = abi.encodeWithSelector(
            IFollowNFT.initialize.selector,
            profileId
        );
        address followNFT = address(new FollowNFTProxy(functionData));
        emit Events.FollowNFTDeployed(profileId, followNFT, block.timestamp);

        return followNFT;
    }

    function _validateProfileExists(uint256 profileId) private view {
        if (GeneralHelpers.unsafeOwnerOf(profileId) == address(0))
            revert Errors.TokenDoesNotExist();
    }
}
