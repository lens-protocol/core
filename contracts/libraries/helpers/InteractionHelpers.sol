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
        address unfollowerProfileOwner,
        uint256[] calldata idsOfProfilesToUnfollow
    ) internal {
        bool isExecutorApproved = GeneralHelpers.isExecutorApproved(
            unfollowerProfileOwner,
            executor
        );
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

            IFollowNFT(followNFT).unfollow(
                unfollowerProfileId,
                executor,
                isExecutorApproved,
                unfollowerProfileOwner
            );

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
        // i.e. the slot of `_blockStatusByBlockeeProfileIdByProfileId[byProfileId]`
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
                IFollowNFT(followNFT).block(idOfProfileToSetBlockStatus);
            }
            // Stores the block status.
            // i.e. `_blockStatusByBlockeeProfileIdByProfileId[byProfileId][idOfProfileToSetBlockStatus] = setToBlocked;`
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
        uint256 collectorProfileId,
        address collectorProfileOwner,
        address transactionExecutor, // TODO: (ex-delegatedExecutor) - revisit the naming later
        uint256 publisherProfileId,
        uint256 pubId,
        bytes calldata collectModuleData,
        address collectNFTImpl
    ) internal returns (uint256) {
        uint256 publisherProfileIdCached = publisherProfileId;
        uint256 pubIdCached = pubId;
        uint256 collectorProfileIdCached = collectorProfileId;
        address collectorProfileOwnerCached = collectorProfileOwner;
        address transactionExecutorCached = transactionExecutor;

        GeneralHelpers.validateAddressIsOwnerOrDelegatedExecutor({
            transactionExecutor: transactionExecutor,
            profileOwner: collectorProfileOwner
        });

        GeneralHelpers.validateNotBlocked(collectorProfileId, publisherProfileId);

        (uint256 rootProfileId, uint256 rootPubId, address rootCollectModule) = GeneralHelpers
            .getPointedIfMirrorWithCollectModule(publisherProfileIdCached, pubIdCached);

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

        uint256 tokenId = ICollectNFT(collectNFT).mint(collectorProfileOwnerCached);
        _processCollect(
            ProcessCollectVars({
                collectModule: rootCollectModule,
                publisherProfileId: publisherProfileIdCached,
                collectorProfileId: collectorProfileIdCached,
                collectorProfileOwner: collectorProfileOwnerCached,
                transactionExecutor: transactionExecutorCached,
                rootProfileId: rootProfileId,
                rootPubId: rootPubId,
                pubId: pubIdCached
            }),
            collectModuleData
        );

        return tokenId;
    }

    // TODO: Think about how to make this better... (it's needed for stack too deep)
    struct ProcessCollectVars {
        address collectModule;
        uint256 publisherProfileId;
        uint256 collectorProfileId;
        address collectorProfileOwner;
        address transactionExecutor;
        uint256 rootProfileId;
        uint256 rootPubId;
        uint256 pubId;
    }

    function _processCollect(ProcessCollectVars memory vars, bytes calldata collectModuleData)
        private
    {
        try
            ICollectModule(vars.collectModule).processCollect(
                vars.publisherProfileId,
                vars.collectorProfileId,
                vars.collectorProfileOwner,
                vars.transactionExecutor,
                vars.rootProfileId,
                vars.rootPubId,
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
            if (vars.collectorProfileOwner != vars.transactionExecutor)
                revert Errors.ExecutorInvalid();
            IDeprecatedCollectModule(vars.collectModule).processCollect(
                vars.publisherProfileId,
                vars.collectorProfileOwner,
                vars.rootProfileId,
                vars.rootPubId,
                collectModuleData
            );
        }

        _emitCollectedEvent(
            vars.collectorProfileId,
            vars.publisherProfileId,
            vars.pubId,
            vars.rootProfileId,
            vars.rootPubId,
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
     * @param collectorProfileId The owner address of the profile collecting the publication.
     * @param publisherProfileId The token ID of the profile that the collect was initiated towards, useful to differentiate mirrors.
     * @param pubId The publication ID that the collect was initiated towards, useful to differentiate mirrors.
     * @param rootProfileId The profile token ID of the profile whose publication is being collected.
     * @param rootPubId The publication ID of the publication being collected.
     * @param data The data passed to the collect module.
     */
    function _emitCollectedEvent(
        uint256 collectorProfileId,
        uint256 publisherProfileId,
        uint256 pubId,
        uint256 rootProfileId,
        uint256 rootPubId,
        bytes calldata data
    ) private {
        emit Events.Collected(
            collectorProfileId,
            publisherProfileId,
            pubId,
            rootProfileId,
            rootPubId,
            data,
            block.timestamp
        );
    }

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
