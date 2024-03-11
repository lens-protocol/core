// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from './constants/Types.sol';

library StorageLib {
    // uint256 constant NAME_SLOT = 0;
    // uint256 constant SYMBOL_SLOT = 1;
    uint256 constant TOKEN_DATA_MAPPING_SLOT = 2;
    // uint256 constant BALANCES_SLOT = 3;
    // uint256 constant TOKEN_APPROVAL_MAPPING_SLOT = 4;
    // uint256 constant OPERATOR_APPROVAL_MAPPING_SLOT = 5;
    // Slot 6 is deprecated in Lens V2. In V1 it was used for ERC-721 Enumerable's `ownedTokens`.
    // Slot 7 is deprecated in Lens V2. In V1 it was used for ERC-721 Enumerable's `ownedTokensIndex`.
    // uint256 constant TOTAL_SUPPLY_SLOT = 8;
    // Slot 9 is deprecated in Lens V2. In V1 it was used for ERC-721 Enumerable's `allTokensIndex`.
    uint256 constant SIG_NONCES_MAPPING_SLOT = 10;
    uint256 constant LAST_INITIALIZED_REVISION_SLOT = 11; // VersionedInitializable's `lastInitializedRevision` field.
    uint256 constant PROTOCOL_STATE_SLOT = 12;
    uint256 constant PROFILE_CREATOR_WHITELIST_MAPPING_SLOT = 13;
    // Slot 14 is deprecated in Lens V2. In V1 it was used for the follow module address whitelist.
    // Slot 15 is deprecated in Lens V2. In V1 it was used for the collect module address whitelist.
    // Slot 16 is deprecated in Lens V2. In V1 it was used for the reference module address whitelist.
    // Slot 17 is deprecated in Lens V2. In V1 it was used for the dispatcher address by profile ID.
    uint256 constant PROFILE_ID_BY_HANDLE_HASH_MAPPING_SLOT = 18; // Deprecated slot, but still needed for V2 migration.
    uint256 constant PROFILES_MAPPING_SLOT = 19;
    uint256 constant PUBLICATIONS_MAPPING_SLOT = 20;
    // Slot 21 is deprecated in Lens V2. In V1 it was used for the default profile ID by address.
    uint256 constant PROFILE_COUNTER_SLOT = 22;
    uint256 constant GOVERNANCE_SLOT = 23;
    uint256 constant EMERGENCY_ADMIN_SLOT = 24;
    //////////////////////////////////
    ///  Introduced in Lens V1.3:  ///
    //////////////////////////////////
    uint256 constant TOKEN_GUARDIAN_DISABLING_TIMESTAMP_MAPPING_SLOT = 25;
    //////////////////////////////////
    ///   Introduced in Lens V2:   ///
    //////////////////////////////////
    uint256 constant DELEGATED_EXECUTOR_CONFIG_MAPPING_SLOT = 26;
    uint256 constant BLOCKED_STATUS_MAPPING_SLOT = 27;
    uint256 constant PROFILE_ROYALTIES_BPS_SLOT = 28;
    uint256 constant MIGRATION_ADMINS_WHITELISTED_MAPPING_SLOT = 29;
    uint256 constant TREASURY_DATA_SLOT = 30;
    uint256 constant PROFILE_TOKEN_URI_CONTRACT_SLOT = 31;
    uint256 constant FOLLOW_TOKEN_URI_CONTRACT_SLOT = 32;
    uint256 constant LEGACY_COLLECT_FOLLOW_VALIDATION_HELPER_MAPPING_SLOT = 33;

    function getPublication(
        uint256 profileId,
        uint256 pubId
    ) internal pure returns (Types.Publication storage _publication) {
        assembly {
            mstore(0, profileId)
            mstore(32, PUBLICATIONS_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            _publication.slot := keccak256(0, 64)
        }
    }

    function getPublicationMemory(
        uint256 profileId,
        uint256 pubId
    ) internal pure returns (Types.PublicationMemory memory) {
        Types.PublicationMemory storage _publicationStorage;
        assembly {
            mstore(0, profileId)
            mstore(32, PUBLICATIONS_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            _publicationStorage.slot := keccak256(0, 64)
        }

        Types.PublicationMemory memory _publicationMemory;
        _publicationMemory = _publicationStorage;

        return _publicationMemory;
    }

    function getProfile(uint256 profileId) internal pure returns (Types.Profile storage _profiles) {
        assembly {
            mstore(0, profileId)
            mstore(32, PROFILES_MAPPING_SLOT)
            _profiles.slot := keccak256(0, 64)
        }
    }

    function getDelegatedExecutorsConfig(
        uint256 delegatorProfileId
    ) internal pure returns (Types.DelegatedExecutorsConfig storage _delegatedExecutorsConfig) {
        assembly {
            mstore(0, delegatorProfileId)
            mstore(32, DELEGATED_EXECUTOR_CONFIG_MAPPING_SLOT)
            _delegatedExecutorsConfig.slot := keccak256(0, 64)
        }
    }

    function tokenGuardianDisablingTimestamp()
        internal
        pure
        returns (mapping(address => uint256) storage _tokenGuardianDisablingTimestamp)
    {
        assembly {
            _tokenGuardianDisablingTimestamp.slot := TOKEN_GUARDIAN_DISABLING_TIMESTAMP_MAPPING_SLOT
        }
    }

    function getTokenData(uint256 tokenId) internal pure returns (Types.TokenData storage _tokenData) {
        assembly {
            mstore(0, tokenId)
            mstore(32, TOKEN_DATA_MAPPING_SLOT)
            _tokenData.slot := keccak256(0, 64)
        }
    }

    function blockedStatus(
        uint256 blockerProfileId
    ) internal pure returns (mapping(uint256 => bool) storage _blockedStatus) {
        assembly {
            mstore(0, blockerProfileId)
            mstore(32, BLOCKED_STATUS_MAPPING_SLOT)
            _blockedStatus.slot := keccak256(0, 64)
        }
    }

    function nonces() internal pure returns (mapping(address => uint256) storage _nonces) {
        assembly {
            _nonces.slot := SIG_NONCES_MAPPING_SLOT
        }
    }

    function profileIdByHandleHash()
        internal
        pure
        returns (mapping(bytes32 => uint256) storage _profileIdByHandleHash)
    {
        assembly {
            _profileIdByHandleHash.slot := PROFILE_ID_BY_HANDLE_HASH_MAPPING_SLOT
        }
    }

    function profileCreatorWhitelisted()
        internal
        pure
        returns (mapping(address => bool) storage _profileCreatorWhitelisted)
    {
        assembly {
            _profileCreatorWhitelisted.slot := PROFILE_CREATOR_WHITELIST_MAPPING_SLOT
        }
    }

    function migrationAdminWhitelisted()
        internal
        pure
        returns (mapping(address => bool) storage _migrationAdminWhitelisted)
    {
        assembly {
            _migrationAdminWhitelisted.slot := MIGRATION_ADMINS_WHITELISTED_MAPPING_SLOT
        }
    }

    function legacyCollectFollowValidationHelper()
        internal
        pure
        returns (mapping(address => uint256) storage _legacyCollectFollowValidationHelper)
    {
        assembly {
            _legacyCollectFollowValidationHelper.slot := LEGACY_COLLECT_FOLLOW_VALIDATION_HELPER_MAPPING_SLOT
        }
    }

    function getGovernance() internal view returns (address _governance) {
        assembly {
            _governance := sload(GOVERNANCE_SLOT)
        }
    }

    function setGovernance(address newGovernance) internal {
        assembly {
            sstore(GOVERNANCE_SLOT, newGovernance)
        }
    }

    function getEmergencyAdmin() internal view returns (address _emergencyAdmin) {
        assembly {
            _emergencyAdmin := sload(EMERGENCY_ADMIN_SLOT)
        }
    }

    function setEmergencyAdmin(address newEmergencyAdmin) internal {
        assembly {
            sstore(EMERGENCY_ADMIN_SLOT, newEmergencyAdmin)
        }
    }

    function getState() internal view returns (Types.ProtocolState _state) {
        assembly {
            _state := sload(PROTOCOL_STATE_SLOT)
        }
    }

    function setState(Types.ProtocolState newState) internal {
        assembly {
            sstore(PROTOCOL_STATE_SLOT, newState)
        }
    }

    function getLastInitializedRevision() internal view returns (uint256 _lastInitializedRevision) {
        assembly {
            _lastInitializedRevision := sload(LAST_INITIALIZED_REVISION_SLOT)
        }
    }

    function setLastInitializedRevision(uint256 newLastInitializedRevision) internal {
        assembly {
            sstore(LAST_INITIALIZED_REVISION_SLOT, newLastInitializedRevision)
        }
    }

    function getTreasuryData() internal pure returns (Types.TreasuryData storage _treasuryData) {
        assembly {
            _treasuryData.slot := TREASURY_DATA_SLOT
        }
    }

    function setProfileTokenURIContract(address profileTokenURIContract) internal {
        assembly {
            sstore(PROFILE_TOKEN_URI_CONTRACT_SLOT, profileTokenURIContract)
        }
    }

    function setFollowTokenURIContract(address followTokenURIContract) internal {
        assembly {
            sstore(FOLLOW_TOKEN_URI_CONTRACT_SLOT, followTokenURIContract)
        }
    }

    function getProfileTokenURIContract() internal view returns (address _profileTokenURIContract) {
        assembly {
            _profileTokenURIContract := sload(PROFILE_TOKEN_URI_CONTRACT_SLOT)
        }
    }

    function getFollowTokenURIContract() internal view returns (address _followTokenURIContract) {
        assembly {
            _followTokenURIContract := sload(FOLLOW_TOKEN_URI_CONTRACT_SLOT)
        }
    }
}
