// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {FollowNFTProxy} from '../../upgradeability/FollowNFTProxy.sol';
import {GeneralHelpers} from './GeneralHelpers.sol';
import {DataTypes} from '../DataTypes.sol';
import {Errors} from '../Errors.sol';
import {Events} from '../Events.sol';
import {IFollowNFT} from '../../interfaces/IFollowNFT.sol';
import {ICollectNFT} from '../../interfaces/ICollectNFT.sol';
import {IFollowModule} from '../../interfaces/IFollowModule.sol';
import {ICollectModule} from '../../interfaces/ICollectModule.sol';
import {IReferenceModule} from '../../interfaces/IReferenceModule.sol';
import {IDeprecatedFollowModule} from '../../interfaces/IDeprecatedFollowModule.sol';
import {IDeprecatedCollectModule} from '../../interfaces/IDeprecatedCollectModule.sol';
import {IDeprecatedReferenceModule} from '../../interfaces/IDeprecatedReferenceModule.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

import '../Constants.sol';

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
        uint256 follower,
        address executor,
        address followerOwner,
        uint256[] calldata profileIds,
        uint256[] calldata followIds,
        bytes[] calldata followModuleDatas
    ) internal returns (uint256[] memory) {
        if (
            profileIds.length != followIds.length || profileIds.length != followModuleDatas.length
        ) {
            revert Errors.ArrayMismatch();
        }

        uint256[] memory followIdsAssigned = new uint256[](profileIds.length);
        uint256 i;
        while (i < profileIds.length) {
            _validateProfileExists(profileIds[i]);

            _validateNotBlocked(follower, profileIds[i]);

            followIdsAssigned[i] = _follow(
                follower,
                executor,
                followerOwner,
                profileIds[i],
                followIds[i],
                followModuleDatas[i]
            );

            unchecked {
                ++i;
            }
        }
        return followIdsAssigned;
    }

    function unfollow(
        uint256 unfollower,
        address executor,
        address unfollowerOwner,
        uint256[] calldata profileIds
    ) internal {
        uint256 i;
        while (i < profileIds.length) {
            uint256 profileId = profileIds[i];
            _validateProfileExists(profileId);

            address followNFT;
            // Load the Follow NFT for the profile being unfollowed.
            assembly {
                mstore(0, profileId)
                mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
                let followNFTSlot := add(keccak256(0, 64), PROFILE_FOLLOW_NFT_OFFSET)
                followNFT := sload(followNFTSlot)
            }

            if (followNFT == address(0)) {
                revert Errors.NotFollowing();
            }

            IFollowNFT(followNFT).unfollow(unfollower, executor, unfollowerOwner);

            unchecked {
                ++i;
            }
        }
    }

    function setBlockStatus(
        uint256 byProfile,
        uint256[] calldata profileIds,
        bool[] calldata blocked
    ) external {
        if (profileIds.length != blocked.length) {
            revert Errors.ArrayMismatch();
        }
        uint256 blockStatusByProfileSlot;
        // Calculates the slot of the block status internal mapping once accessed by `byProfile`.
        // i.e. the slot of `_blockStatusByProfileByBlockee[byProfile]`
        assembly {
            mstore(0, byProfile)
            mstore(32, BLOCK_STATUS_MAPPING_SLOT)
            blockStatusByProfileSlot := keccak256(0, 64)
        }
        address followNFT;
        // Loads the Follow NFT address from storage.
        // i.e. `followNFT = _profileById[byProfile].followNFT;`
        assembly {
            mstore(0, byProfile)
            mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
            followNFT := sload(add(keccak256(0, 64), PROFILE_FOLLOW_NFT_OFFSET))
        }
        uint256 i;
        uint256 profileId;
        bool blockStatus;
        while (i < profileIds.length) {
            profileId = profileIds[i];
            _validateProfileExists(profileId);
            if (followNFT != address(0) && (blockStatus = blocked[i])) {
                IFollowNFT(followNFT).block(profileId);
            }
            // Stores the block status.
            // i.e. `_blockStatusByProfileByBlockee[byProfile][profileId] = blockStatus;`
            assembly {
                mstore(0, profileId)
                mstore(32, blockStatusByProfileSlot)
                sstore(keccak256(0, 64), blockStatus)
            }
            unchecked {
                ++i;
            }
        }
        emit Events.BlockStatusSet(byProfile, profileIds, blocked);
    }

    function collect(
        address collector,
        address delegatedExecutor,
        uint256 profileId,
        uint256 pubId,
        bytes calldata collectModuleData,
        address collectNFTImpl
    ) internal returns (uint256) {
        uint256 profileIdCached = profileId;
        uint256 pubIdCached = pubId;
        address collectorCached = collector;
        address delegatedExecutorCached = delegatedExecutor;

        (uint256 rootProfileId, uint256 rootPubId, address rootCollectModule) = GeneralHelpers
            .getPointedIfMirrorWithCollectModule(profileIdCached, pubIdCached);

        // Prevents stack too deep.
        address collectNFT;
        {
            uint256 collectNFTSlot;

            // Load the collect NFT and for the given publication being collected, and cache the
            // collect NFT slot.
            assembly {
                mstore(0, rootProfileId)
                mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
                mstore(32, keccak256(0, 64))
                mstore(0, rootPubId)
                collectNFTSlot := add(keccak256(0, 64), PUBLICATION_COLLECT_NFT_OFFSET)
                collectNFT := sload(collectNFTSlot)
            }

            if (collectNFT == address(0)) {
                collectNFT = _deployCollectNFT(rootProfileId, rootPubId, collectNFTImpl);

                // Store the collect NFT in the cached slot.
                assembly {
                    sstore(collectNFTSlot, collectNFT)
                }
            }
        }

        uint256 tokenId = ICollectNFT(collectNFT).mint(collectorCached);
        _processCollect(
            rootCollectModule,
            collectModuleData,
            profileIdCached,
            pubIdCached,
            collectorCached,
            delegatedExecutorCached,
            rootProfileId,
            rootPubId
        );

        return tokenId;
    }

    function _processCollect(
        address collectModule,
        bytes calldata collectModuleData,
        uint256 profileId,
        uint256 pubId,
        address collector,
        address executor,
        uint256 rootProfileId,
        uint256 rootPubId
    ) private {
        try
            ICollectModule(collectModule).processCollect(
                profileId,
                0,
                collector,
                executor,
                rootProfileId,
                rootPubId,
                collectModuleData
            )
        {} catch (bytes memory err) {
            assembly {
                /// Equivalent to reverting with the returned error selector if
                /// the length is not zero.
                let length := mload(err)
                if iszero(iszero(length)) {
                    revert(add(err, 32), length)
                }
            }
            if (collector != executor) revert Errors.ExecutorInvalid();
            IDeprecatedCollectModule(collectModule).processCollect(
                profileId,
                collector,
                rootProfileId,
                rootPubId,
                collectModuleData
            );
        }

        _emitCollectedEvent(
            collector,
            profileId,
            pubId,
            rootProfileId,
            rootPubId,
            collectModuleData
        );
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

    /**
     * @notice Emits the `Collected` event that signals that a successful collect action has occurred.
     *
     * @dev This is done through this function to prevent stack too deep compilation error.
     *
     * @param collector The address collecting the publication.
     * @param profileId The token ID of the profile that the collect was initiated towards, useful to differentiate mirrors.
     * @param pubId The publication ID that the collect was initiated towards, useful to differentiate mirrors.
     * @param rootProfileId The profile token ID of the profile whose publication is being collected.
     * @param rootPubId The publication ID of the publication being collected.
     * @param data The data passed to the collect module.
     */
    function _emitCollectedEvent(
        address collector,
        uint256 profileId,
        uint256 pubId,
        uint256 rootProfileId,
        uint256 rootPubId,
        bytes calldata data
    ) private {
        emit Events.Collected(
            collector,
            profileId,
            pubId,
            rootProfileId,
            rootPubId,
            data,
            block.timestamp
        );
    }

    function _follow(
        uint256 follower,
        address executor,
        address followerOwner,
        uint256 profileId,
        uint256 followId,
        bytes calldata followModuleData
    ) internal returns (uint256) {
        uint256 followNFTSlot;
        address followModule;
        address followNFT;

        // Load the follow NFT and follow module for the given profile being followed, and cache
        // the follow NFT slot.
        assembly {
            mstore(0, profileId)
            mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
            // The follow NFT offset is 2, the follow module offset is 1,
            // so we just need to subtract 1 instead of recalculating the slot.
            followNFTSlot := add(keccak256(0, 64), PROFILE_FOLLOW_NFT_OFFSET)
            followModule := sload(sub(followNFTSlot, 1))
            followNFT := sload(followNFTSlot)
        }

        if (followNFT == address(0)) {
            followNFT = _deployFollowNFT(profileId);

            // Store the follow NFT in the cached slot.
            assembly {
                sstore(followNFTSlot, followNFT)
            }
        }

        uint256 followIdAssigned = IFollowNFT(followNFT).follow(
            follower,
            executor,
            followerOwner,
            followId
        );

        if (followModule != address(0)) {
            IFollowModule(followModule).processFollow(
                follower,
                followId,
                executor,
                profileId,
                followModuleData
            );
        }

        emit Events.Followed(
            follower,
            profileId,
            followIdAssigned,
            followModuleData,
            block.timestamp
        );

        return followIdAssigned;
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

    function _validateNotBlocked(uint256 profile, uint256 byProfile) private view {
        bool isBlocked;
        assembly {
            mstore(0, byProfile)
            mstore(32, BLOCK_STATUS_MAPPING_SLOT)
            let blockStatusByProfileSlot := keccak256(0, 64)
            mstore(0, profile)
            mstore(32, blockStatusByProfileSlot)
            isBlocked := sload(keccak256(0, 64))
        }
        if (isBlocked) {
            revert Errors.Blocked();
        }
    }
}
