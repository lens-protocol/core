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

    event ProfileMigrated(uint256 profileId, address profileDestination, string handle, uint256 handleId);

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
            emit ProfileMigrated(profileId, profileOwner, handle, handleId);
            delete StorageLib.getProfile(profileId).__DEPRECATED__handle;
            delete StorageLib.profileIdByHandleHash()[handleHash];
        }
    }

    // FollowNFT Migration:

    function batchMigrateFollows(
        uint256[] calldata followerProfileIds,
        uint256[] calldata idsOfProfileFollowed,
        uint256[] calldata followTokenIds
    ) external {
        if (
            followerProfileIds.length != idsOfProfileFollowed.length ||
            followerProfileIds.length != followTokenIds.length
        ) {
            revert Errors.ArrayMismatch();
        }
        uint256 i;
        while (i < followerProfileIds.length) {
            _migrateFollow(followerProfileIds[i], idsOfProfileFollowed[i], followTokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _migrateFollow(
        uint256 followerProfileId,
        uint256 idOfProfileFollowed,
        uint256 followTokenId
    ) private {
        uint48 mintTimestamp = FollowNFT(StorageLib.getProfile(idOfProfileFollowed).followNFT).tryMigrate({
            followerProfileId: followerProfileId,
            followerProfileOwner: StorageLib.getTokenData(followerProfileId).owner,
            idOfProfileFollowed: idOfProfileFollowed,
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
                IFollowModule(newFeeFollowModule).initializeFollowModule({
                    profileId: profileIds[i],
                    transactionExecutor: msg.sender,
                    data: abi.encode(
                        feeFollowModuleData.currency,
                        feeFollowModuleData.amount,
                        feeFollowModuleData.recipient
                    )
                });
            } else if (currentFollowModule == legacyProfileFollowModule) {
                // If the profile had `ProfileFollowModule` set, we just remove the follow module, as in Lens V2
                // you can only follow with a Lens profile.
                delete StorageLib.getProfile(profileIds[i]).followModule;
            }
            unchecked {
                ++i;
            }
        }
    }
}
