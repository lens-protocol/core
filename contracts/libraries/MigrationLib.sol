// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Events} from 'contracts/libraries/constants/Events.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';
import {LensHandles} from 'contracts/misc/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/misc/namespaces/TokenHandleRegistry.sol';

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
            _migrateProfilePublic(profileIds[i], lensHandles, tokenHandleRegistry);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Migrates a profile from V1 to V2.
     *
     * @dev We check if the profile exists by checking owner != address(0).
     * @dev We check if the profile has already been migrated by checking handleDeprecated != "".
     * @dev We check if the profile is the "lensprotocol" profile by checking profileId != 1. This is the only profile
     *      without a .lens suffix.
     * @dev We mint a new handle on the LensHandles contract and link it to the profile in the TokenHandleRegistry contract.
     * @dev The resulting handle NFT is sent to the profile owner.
     * @dev We emit the ProfileMigrated event.
     * @dev We do not revert in any case, as we want to allow the migration to continue even if one profile fails
     *      (and it usually fails if already migrated or profileNFT moved).
     *
     * @dev Estimated gas cost of one profile migration is around 150k gas.
     *
     * @param profileId The profile ID to migrate.
     */
    function _migrateProfilePublic(
        uint256 profileId,
        LensHandles lensHandles,
        TokenHandleRegistry tokenHandleRegistry
    ) internal {
        address profileOwner = StorageLib.getTokenData(profileId).owner;
        if (profileOwner != address(0)) {
            string memory handle = StorageLib.getProfile(profileId).handleDeprecated;
            if (bytes(handle).length == 0) {
                return; // Already migrated
            }
            bytes32 handleHash = keccak256(bytes(handle));
            // "lensprotocol" is the only edge case without the .lens suffix:
            if (profileId != LENS_PROTOCOL_PROFILE_ID) {
                assembly {
                    let handle_length := mload(handle)
                    mstore(handle, sub(handle_length, DOT_LENS_SUFFIX_LENGTH)) // Cut 5 chars (.lens) from the end
                }
            }
            uint256 handleId = lensHandles.mintHandle(profileOwner, handle);
            tokenHandleRegistry.migrationLinkHandleWithToken(handleId, profileId);
            emit ProfileMigrated(profileId, profileOwner, handle, handleId);
            delete StorageLib.getProfile(profileId).handleDeprecated;
            delete StorageLib.profileIdByHandleHash()[handleHash];
        }
    }

    // FollowNFT Migration:

    function batchMigrateFollows(
        uint256[] calldata followerProfileIds,
        uint256[] calldata idsOfProfileFollowed,
        address[] calldata followNFTAddresses,
        uint256[] calldata followTokenIds
    ) external {
        if (
            followerProfileIds.length != idsOfProfileFollowed.length ||
            followerProfileIds.length != followNFTAddresses.length ||
            followerProfileIds.length != followTokenIds.length
        ) {
            revert Errors.ArrayMismatch();
        }
        uint256 i;
        while (i < followerProfileIds.length) {
            _migrateFollow(followerProfileIds[i], idsOfProfileFollowed[i], followNFTAddresses[i], followTokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _migrateFollow(
        uint256 followerProfileId,
        uint256 idOfProfileFollowed,
        address followNFTAddress,
        uint256 followTokenId
    ) internal {
        uint48 mintTimestamp = IFollowNFT(followNFTAddress).migrate({
            followerProfileId: followerProfileId,
            followerProfileOwner: StorageLib.getTokenData(followerProfileId).owner,
            idOfProfileFollowed: idOfProfileFollowed,
            followTokenId: followTokenId
        });
        // `mintTimestamp` will be 0 if already migrated (or not holding both Profile & Follow NFT together)
        if (mintTimestamp != 0) {
            emit Events.Followed({
                followerProfileId: followerProfileId,
                idOfProfileFollowed: idOfProfileFollowed,
                followTokenIdAssigned: followTokenId,
                followModuleData: '',
                timestamp: mintTimestamp // The only case where this won't match block.timestamp is during the migration
            });
        }
    }
}
