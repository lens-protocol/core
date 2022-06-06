// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

// library Constants {
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
uint256 constant SIG_NONCES_MAPPING_SLOT = 10;
uint256 constant PROTOCOL_STATE_SLOT = 12;
uint256 constant PROFILE_CREATOR_WHITELIST_MAPPING_SLOT = 13;
uint256 constant FOLLOW_MODULE_WHITELIST_MAPPING_SLOT = 14;
uint256 constant COLLECT_MODULE_WHITELIST_MAPPING_SLOT = 15;
uint256 constant REFERENCE_MODULE_WHITELIST_MAPPING_SLOT = 16;
uint256 constant DISPATCHER_BY_PROFILE_MAPPING_SLOT = 17;
uint256 constant PROFILE_BY_ID_MAPPING_SLOT  = 19;
uint256 constant DEFAULT_PROFILE_MAPPING_SLOT = 21;
uint256 constant GOVERNANCE_SLOT = 23;
uint256 constant EMERGENCY_ADMIN_SLOT = 24;
uint256 constant NAME_SLOT_GT_31 = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;

// Profile struct offsets
uint256 constant FOLLOW_MODULE_PROFILE_OFFSET = 1;
uint256 constant IMAGE_URI_PROFILE_OFFSET = 4;
        // uint256 pubCount;       // offset 0
        // address followModule;   // offset 1
        // address followNFT;      // offset 2
        // string handle;          // offset 3
        // string imageURI;        // offset 4
        // string followNFTURI;    // offset 5

// We also store typehashes here
bytes32 constant EIP712_REVISION_HASH = keccak256('1');
bytes32 constant PERMIT_TYPEHASH = keccak256(
    'Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)'
);
bytes32 constant PERMIT_FOR_ALL_TYPEHASH = keccak256(
    'PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)'
);
bytes32 constant BURN_WITH_SIG_TYPEHASH = keccak256(
    'BurnWithSig(uint256 tokenId,uint256 nonce,uint256 deadline)'
);
bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
);
bytes32 constant SET_DEFAULT_PROFILE_WITH_SIG_TYPEHASH = keccak256(
    'SetDefaultProfileWithSig(address wallet,uint256 profileId,uint256 nonce,uint256 deadline)'
);
bytes32 constant SET_FOLLOW_MODULE_WITH_SIG_TYPEHASH = keccak256(
    'SetFollowModuleWithSig(uint256 profileId,address followModule,bytes followModuleInitData,uint256 nonce,uint256 deadline)'
);
bytes32 constant SET_FOLLOW_NFT_URI_WITH_SIG_TYPEHASH = keccak256(
    'SetFollowNFTURIWithSig(uint256 profileId,string followNFTURI,uint256 nonce,uint256 deadline)'
);
bytes32 constant SET_DISPATCHER_WITH_SIG_TYPEHASH = keccak256(
    'SetDispatcherWithSig(uint256 profileId,address dispatcher,uint256 nonce,uint256 deadline)'
);
bytes32 constant SET_PROFILE_IMAGE_URI_WITH_SIG_TYPEHASH = keccak256(
    'SetProfileImageURIWithSig(uint256 profileId,string imageURI,uint256 nonce,uint256 deadline)'
);
bytes32 constant POST_WITH_SIG_TYPEHASH = keccak256(
    'PostWithSig(uint256 profileId,string contentURI,address collectModule,bytes collectModuleInitData,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)'
);
bytes32 constant COMMENT_WITH_SIG_TYPEHASH = keccak256(
    'CommentWithSig(uint256 profileId,string contentURI,uint256 profileIdPointed,uint256 pubIdPointed,bytes referenceModuleData,address collectModule,bytes collectModuleInitData,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)'
);
bytes32 constant MIRROR_WITH_SIG_TYPEHASH = keccak256(
    'MirrorWithSig(uint256 profileId,uint256 profileIdPointed,uint256 pubIdPointed,bytes referenceModuleData,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)'
);
bytes32 constant FOLLOW_WITH_SIG_TYPEHASH = keccak256(
    'FollowWithSig(uint256[] profileIds,bytes[] datas,uint256 nonce,uint256 deadline)'
);
bytes32 constant COLLECT_WITH_SIG_TYPEHASH = keccak256(
    'CollectWithSig(uint256 profileId,uint256 pubId,bytes data,uint256 nonce,uint256 deadline)'
);
