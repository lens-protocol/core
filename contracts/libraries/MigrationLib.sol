// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Events} from 'contracts/libraries/constants/Events.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {LensHandles} from 'contracts/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/namespaces/TokenHandleRegistry.sol';
import {IFollowModule} from 'contracts/interfaces/IFollowModule.sol';

interface ILegacyFeeFollowModule {
    struct ProfileData {
        address currency;
        uint256 amount;
        address recipient;
    }

    function getProfileData(uint256 profileId) external view returns (ProfileData memory);
}

library MigrationLib {
    uint256 internal constant LENS_PROTOCOL_PROFILE_ID = 1;
    uint256 internal constant DOT_LENS_SUFFIX_LENGTH = 5;

    // Profiles Handles Migration:

    event ProfileMigrated(uint256 profileId);

    /**
     * @notice Migrates an array of profiles from V1 to V2. This function can be callable by anyone.
     * We would still perform the migration in batches by ourselves, but good to allow users to migrate on their own if they want to.
     *
     * @param profileIds The array of profile IDs to migrate.
     */
    function batchMigrateProfiles(
        uint256[] calldata profileIds,
        LensHandles lensHandles,
        TokenHandleRegistry tokenHandleRegistry
    ) external {
        uint256 i;
        while (i < profileIds.length) {
            _migrateProfile(profileIds[i], lensHandles, tokenHandleRegistry);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Migrates a profile from V1 to V2.
     *
     * @dev We do not revert in any case, as we want to allow the migration to continue even if one profile fails
     *      (and it usually fails if already migrated or profileNFT moved).
     * @dev Estimated gas cost of one profile migration is around 178k gas.
     *
     * @param profileId The profile ID to migrate.
     */
    function _migrateProfile(
        uint256 profileId,
        LensHandles lensHandles,
        TokenHandleRegistry tokenHandleRegistry
    ) private {
        address profileOwner = StorageLib.getTokenData(profileId).owner;
        // We check if the profile exists by checking owner != address(0).
        if (profileOwner != address(0)) {
            // We check if the profile has already been migrated by checking __DEPRECATED__handle != "".
            string memory handle = StorageLib.getProfile(profileId).__DEPRECATED__handle;
            if (bytes(handle).length == 0) {
                return; // Already migrated
            }
            bytes32 handleHash = keccak256(bytes(handle));
            // We check if the profile is the "lensprotocol" profile by checking profileId != 1.
            // "lensprotocol" is the only edge case without the .lens suffix:
            if (profileId != LENS_PROTOCOL_PROFILE_ID) {
                assembly {
                    let handle_length := mload(handle)
                    mstore(handle, sub(handle_length, DOT_LENS_SUFFIX_LENGTH)) // Cut 5 chars (.lens) from the end
                }
            }
            // We mint a new handle on the LensHandles contract. The resulting handle NFT is sent to the profile owner.
            uint256 handleId = lensHandles.migrateHandle(profileOwner, handle);
            // We link it to the profile in the TokenHandleRegistry contract.
            tokenHandleRegistry.migrationLink(handleId, profileId);
            emit ProfileMigrated(profileId);
            delete StorageLib.getProfile(profileId).__DEPRECATED__handle;
            delete StorageLib.getProfile(profileId).__DEPRECATED__followNFTURI;
            delete StorageLib.profileIdByHandleHash()[handleHash];

            if (StorageLib.getDelegatedExecutorsConfig(profileId).configNumber == 0) {
                // This event can be duplicated, and then redundant, if the profile has already configured the Delegated
                // Executors before being migrated. Given that this is an edge case, we exceptionally accept this
                // redundancy considering that the event is still consistent with the state.
                emit Events.DelegatedExecutorsConfigApplied(profileId, 0, block.timestamp);
            }
        }
    }

    // FollowNFT Migration:

    function batchMigrateFollows(
        uint256 followerProfileId,
        uint256[] calldata idsOfProfileFollowed,
        uint256[] calldata followTokenIds
    ) external {
        if (idsOfProfileFollowed.length != followTokenIds.length) {
            revert Errors.ArrayMismatch();
        }
        uint256 i;
        while (i < idsOfProfileFollowed.length) {
            _migrateFollow(
                StorageLib.getProfile(idsOfProfileFollowed[i]).followNFT,
                followerProfileId, // one follower for all the follows
                idsOfProfileFollowed[i],
                followTokenIds[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function batchMigrateFollowers(
        uint256[] calldata followerProfileIds,
        uint256 idOfProfileFollowed,
        uint256[] calldata followTokenIds
    ) external {
        if (followerProfileIds.length != followTokenIds.length) {
            revert Errors.ArrayMismatch();
        }
        address followNFT = StorageLib.getProfile(idOfProfileFollowed).followNFT;
        uint256 i;
        while (i < followTokenIds.length) {
            _migrateFollow(
                followNFT,
                followerProfileIds[i],
                idOfProfileFollowed, // one profile followed -> one FollowNFT
                followTokenIds[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    function _migrateFollow(
        address followNFT,
        uint256 followerProfileId,
        uint256 idOfProfileFollowed,
        uint256 followTokenId
    ) private {
        if (StorageLib.blockedStatus(idOfProfileFollowed)[followerProfileId]) {
            return; // Cannot follow if blocked
        }
        if (followerProfileId == idOfProfileFollowed) {
            return; // Cannot self-follow
        }

        uint48 mintTimestamp = FollowNFT(followNFT).tryMigrate({
            followerProfileId: followerProfileId,
            followerProfileOwner: StorageLib.getTokenData(followerProfileId).owner,
            followTokenId: followTokenId
        });
        // `mintTimestamp` will be 0 if:
        // - Follow NFT was already migrated
        // - Follow NFT does not exist or was burnt
        // - Follower profile Owner is different from Follow NFT Owner
        if (mintTimestamp != 0) {
            emit Events.Followed({
                followerProfileId: followerProfileId,
                idOfProfileFollowed: idOfProfileFollowed,
                followTokenIdAssigned: followTokenId,
                followModuleData: '',
                processFollowModuleReturnData: '',
                transactionExecutor: address(0), // For migrations, we use this special value as transaction executor.
                timestamp: mintTimestamp // The only case where this won't match block.timestamp is during the migration
            });
        }
    }

    function batchMigrateFollowModules(
        uint256[] calldata profileIds,
        address legacyFeeFollowModule,
        address legacyProfileFollowModule,
        address newFeeFollowModule
    ) external {
        uint256 i;
        while (i < profileIds.length) {
            address currentFollowModule = StorageLib.getProfile(profileIds[i]).followModule;
            if (currentFollowModule == legacyFeeFollowModule) {
                // If the profile had the legacy 'feeFollowModule' set, we need to read its parameters
                // and initialize the new feeFollowModule with them.
                StorageLib.getProfile(profileIds[i]).followModule = newFeeFollowModule;
                ILegacyFeeFollowModule.ProfileData memory feeFollowModuleData = ILegacyFeeFollowModule(
                    legacyFeeFollowModule
                ).getProfileData(profileIds[i]);
                bytes memory followModuleInitData = abi.encode(
                    feeFollowModuleData.currency,
                    feeFollowModuleData.amount,
                    feeFollowModuleData.recipient
                );
                bytes memory followModuleReturnData = IFollowModule(newFeeFollowModule).initializeFollowModule({
                    profileId: profileIds[i],
                    transactionExecutor: msg.sender, // TODO: Review
                    data: followModuleInitData
                });
                emit Events.FollowModuleSet(
                    profileIds[i],
                    newFeeFollowModule,
                    followModuleInitData,
                    followModuleReturnData,
                    address(0),
                    block.timestamp
                );
            } else if (currentFollowModule == legacyProfileFollowModule) {
                // If the profile had `ProfileFollowModule` set, we just remove the follow module, as in Lens V2
                // you can only follow with a Lens profile.
                delete StorageLib.getProfile(profileIds[i]).followModule;
                emit Events.FollowModuleSet(profileIds[i], address(0), '', '', address(0), block.timestamp);
            }
            unchecked {
                ++i;
            }
        }
    }
}
