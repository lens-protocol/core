// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';

library StorageLib {
    uint256 constant NAME_SLOT = 0;
    uint256 constant TOKEN_DATA_MAPPING_SLOT = 2;
    uint256 constant TOKEN_APPROVAL_MAPPING_SLOT = 4;
    uint256 constant OPERATOR_APPROVAL_MAPPING_SLOT = 5;
    uint256 constant SIG_NONCES_MAPPING_SLOT = 10;
    uint256 constant PROTOCOL_STATE_SLOT = 12;
    uint256 constant PROFILE_CREATOR_WHITELIST_MAPPING_SLOT = 13;
    uint256 constant FOLLOW_MODULE_WHITELIST_MAPPING_SLOT = 14;
    uint256 constant ACTION_MODULE_WHITELIST_ID_MAPPING_SLOT = 15;
    uint256 constant REFERENCE_MODULE_WHITELIST_MAPPING_SLOT = 16;
    // Slot 17 is deprecated in Lens V2. In V1 it was used for the dispatcher address by profile ID.
    uint256 constant PROFILE_ID_BY_HANDLE_HASH_MAPPING_SLOT = 18;
    uint256 constant PROFILE_BY_ID_MAPPING_SLOT = 19;
    uint256 constant PUB_BY_ID_BY_PROFILE_MAPPING_SLOT = 20;
    uint256 constant DEFAULT_PROFILE_MAPPING_SLOT = 21; // Deprecated slot, but still needed for V2 migration.
    uint256 constant PROFILE_COUNTER_SLOT = 22;
    uint256 constant GOVERNANCE_SLOT = 23;
    uint256 constant EMERGENCY_ADMIN_SLOT = 24;
    // Introduced in Lens V2:
    uint256 constant DELEGATED_EXECUTOR_CONFIG_MAPPING_SLOT = 25;
    uint256 constant BLOCKED_STATUS_MAPPING_SLOT = 26;
    uint256 constant ACTION_MODULE_BY_ID_SLOT = 27;

    function getPublication(
        uint256 profileId,
        uint256 pubId
    ) internal pure returns (Types.Publication storage _publication) {
        assembly {
            mstore(0, profileId)
            mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            _publication.slot := keccak256(0, 64)
        }
    }

    function getProfile(uint256 profileId) internal pure returns (Types.Profile storage _profile) {
        assembly {
            mstore(0, profileId)
            mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
            _profile.slot := keccak256(0, 64)
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

    function followModuleWhitelisted()
        internal
        pure
        returns (mapping(address => bool) storage _followModuleWhitelisted)
    {
        assembly {
            _followModuleWhitelisted.slot := FOLLOW_MODULE_WHITELIST_MAPPING_SLOT
        }
    }

    function actionModuleWhitelistedId()
        internal
        pure
        returns (mapping(address => uint256) storage _actionModuleWhitelistedId)
    {
        assembly {
            _actionModuleWhitelistedId.slot := ACTION_MODULE_WHITELIST_ID_MAPPING_SLOT
        }
    }

    function actionModuleById() internal pure returns (mapping(uint256 => address) storage _actionModuleById) {
        assembly {
            _actionModuleById.slot := ACTION_MODULE_BY_ID_SLOT
        }
    }

    function referenceModuleWhitelisted()
        internal
        pure
        returns (mapping(address => bool) storage _referenceModuleWhitelisted)
    {
        assembly {
            _referenceModuleWhitelisted.slot := REFERENCE_MODULE_WHITELIST_MAPPING_SLOT
        }
    }

    // Used for all `ERC721Time` inherited contracts.
    function getName() internal pure returns (string storage _name) {
        assembly {
            _name.slot := NAME_SLOT
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
}
