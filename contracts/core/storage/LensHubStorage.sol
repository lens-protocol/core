// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {DataTypes} from '../../libraries/DataTypes.sol';

contract LensHubStorage {
    bytes32 internal constant CREATE_PROFILE_WITH_SIG_TYPEHASH =
        keccak256(
            'CreateProfileWithSig(string handle,string uri,address followModule,bytes followModuleData,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_DEFAULT_PROFILE_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDefaultProfileWithSig(address wallet,uint256 profileId,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_FOLLOW_MODULE_WITH_SIG_TYPEHASH =
        keccak256(
            'SetFollowModuleWithSig(uint256 profileId,address followModule,bytes followModuleData,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_FOLLOW_NFT_URI_WITH_SIG_TYPEHASH =
        keccak256(
            'SetFollowNFTURIWithSig(uint256 profileId,string followNFTURI,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_DISPATCHER_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDispatcherWithSig(uint256 profileId,address dispatcher,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_PROFILE_IMAGE_URI_WITH_SIG_TYPEHASH =
        keccak256(
            'SetProfileImageURIWithSig(uint256 profileId,string imageURI,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant POST_WITH_SIG_TYPEHASH =
        keccak256(
            'PostWithSig(uint256 profileId,string contentURI,address collectModule,bytes collectModuleData,address referenceModule,bytes referenceModuleData,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant COMMENT_WITH_SIG_TYPEHASH =
        keccak256(
            'CommentWithSig(uint256 profileId,string contentURI,uint256 profileIdPointed,uint256 pubIdPointed,address collectModule,bytes collectModuleData,address referenceModule,bytes referenceModuleData,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant MIRROR_WITH_SIG_TYPEHASH =
        keccak256(
            'MirrorWithSig(uint256 profileId,uint256 profileIdPointed,uint256 pubIdPointed,address referenceModule,bytes referenceModuleData,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant FOLLOW_WITH_SIG_TYPEHASH =
        keccak256(
            'FollowWithSig(uint256[] profileIds,bytes[] datas,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant COLLECT_WITH_SIG_TYPEHASH =
        keccak256(
            'CollectWithSig(uint256 profileId,uint256 pubId,bytes data,uint256 nonce,uint256 deadline)'
        );

    mapping(address => bool) internal _profileCreatorWhitelisted;
    mapping(address => bool) internal _followModuleWhitelisted;
    mapping(address => bool) internal _collectModuleWhitelisted;
    mapping(address => bool) internal _referenceModuleWhitelisted;

    mapping(uint256 => address) internal _dispatcherByProfile;
    mapping(bytes32 => uint256) internal _profileIdByHandleHash;
    mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) internal _pubByIdByProfile;

    mapping(address => uint256) internal _defaultProfileByAddress;

    uint256 internal _profileCounter;
    address internal _governance;
    address internal _emergencyAdmin;
}
