// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

string constant FOLLOW_NFT_NAME_SUFFIX = '-Follower';
string constant FOLLOW_NFT_SYMBOL_SUFFIX = '-Fl';
string constant COLLECT_NFT_NAME_INFIX = '-Collect-';
string constant COLLECT_NFT_SYMBOL_INFIX = '-Cl-';
uint8 constant MAX_HANDLE_LENGTH = 31;
uint16 constant MAX_PROFILE_IMAGE_URI_LENGTH = 6000;

// We store constants equal to the storage slots here to later access via inline
// assembly without needing to pass storage pointers. The NAME_SLOT_GT_31 slot
// is equivalent to keccak256(NAME_SLOT) and is where the name string is stored
// if the length is greater than 31 bytes.
uint256 constant NAME_SLOT = 0;
uint256 constant TOKEN_DATA_MAPPING_SLOT = 2;
uint256 constant TOKEN_APPROVAL_MAPPING_SLOT = 4;
uint256 constant OPERATOR_APPROVAL_MAPPING_SLOT = 5;
uint256 constant SIG_NONCES_MAPPING_SLOT = 10;
uint256 constant PROTOCOL_STATE_SLOT = 12;
uint256 constant PROFILE_CREATOR_WHITELIST_MAPPING_SLOT = 13;
uint256 constant FOLLOW_MODULE_WHITELIST_MAPPING_SLOT = 14;
uint256 constant COLLECT_MODULE_WHITELIST_MAPPING_SLOT = 15;
uint256 constant REFERENCE_MODULE_WHITELIST_MAPPING_SLOT = 16;
uint256 constant __DEPRECATED_SLOT__DISPATCHER_BY_PROFILE_MAPPING_SLOT = 17; // Deprecated slot.
uint256 constant PROFILE_ID_BY_HANDLE_HASH_MAPPING_SLOT = 18;
uint256 constant PROFILE_BY_ID_MAPPING_SLOT = 19;
uint256 constant PUB_BY_ID_BY_PROFILE_MAPPING_SLOT = 20;
uint256 constant DEFAULT_PROFILE_MAPPING_SLOT = 21; // Deprecated slot, but still needed for V2 migration.
uint256 constant PROFILE_COUNTER_SLOT = 22;
uint256 constant GOVERNANCE_SLOT = 23;
uint256 constant EMERGENCY_ADMIN_SLOT = 24;
uint256 constant DELEGATED_EXECUTOR_CONFIG_MAPPING_SLOT = 25;
uint256 constant PROFILE_METADATA_MAPPING_SLOT = 26;
uint256 constant BLOCK_STATUS_MAPPING_SLOT = 27;
uint256 constant NAME_SLOT_GT_31 = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;

// Profile struct offsets
// uint256 pubCount;       // offset 0
uint256 constant PROFILE_FOLLOW_MODULE_OFFSET = 1;
uint256 constant PROFILE_FOLLOW_NFT_OFFSET = 2;
uint256 constant PROFILE_HANDLE_OFFSET = 3;
uint256 constant PROFILE_IMAGE_URI_OFFSET = 4;
uint256 constant PROFILE_FOLLOW_NFT_URI_OFFSET = 5;

// Publication struct offsets
// uint256 pointedProfileId;    // offset 0
uint256 constant PUBLICATION_PUB_ID_POINTED_OFFSET = 1;
uint256 constant PUBLICATION_CONTENT_URI_OFFSET = 2; // offset 2
uint256 constant PUBLICATION_REFERENCE_MODULE_OFFSET = 3; // offset 3
uint256 constant PUBLICATION_COLLECT_MODULE_OFFSET = 4; // offset 4
uint256 constant PUBLICATION_COLLECT_NFT_OFFSET = 5; // offset 4

bytes4 constant EIP1271_MAGIC_VALUE = 0x1626ba7e;
