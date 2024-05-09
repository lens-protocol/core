// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library Typehash {

    bytes32 constant ACT = keccak256('Act(uint256 publicationActedProfileId,uint256 publicationActedId,uint256 actorProfileId,uint256[] referrerProfileIds,uint256[] referrerPubIds,address actionModuleAddress,bytes actionModuleData,uint256 nonce,uint256 deadline)');

    bytes32 constant CHANGE_DELEGATED_EXECUTORS_CONFIG = keccak256('ChangeDelegatedExecutorsConfig(uint256 delegatorProfileId,address[] delegatedExecutors,bool[] approvals,uint64 configNumber,bool switchToGivenConfig,uint256 nonce,uint256 deadline)');

    bytes32 constant COLLECT_LEGACY = keccak256('CollectLegacy(uint256 publicationCollectedProfileId,uint256 publicationCollectedId,uint256 collectorProfileId,uint256 referrerProfileId,uint256 referrerPubId,bytes collectModuleData,uint256 nonce,uint256 deadline)');

    bytes32 constant COMMENT = keccak256('Comment(uint256 profileId,string contentURI,uint256 pointedProfileId,uint256 pointedPubId,uint256[] referrerProfileIds,uint256[] referrerPubIds,bytes referenceModuleData,address[] actionModules,bytes[] actionModulesInitDatas,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)');

    bytes32 constant EIP712_DOMAIN = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

    bytes32 constant FOLLOW = keccak256('Follow(uint256 followerProfileId,uint256[] idsOfProfilesToFollow,uint256[] followTokenIds,bytes[] datas,uint256 nonce,uint256 deadline)');

    bytes32 constant MIRROR = keccak256('Mirror(uint256 profileId,string metadataURI,uint256 pointedProfileId,uint256 pointedPubId,uint256[] referrerProfileIds,uint256[] referrerPubIds,bytes referenceModuleData,uint256 nonce,uint256 deadline)');

    bytes32 constant POST = keccak256('Post(uint256 profileId,string contentURI,address[] actionModules,bytes[] actionModulesInitDatas,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)');

    bytes32 constant QUOTE = keccak256('Quote(uint256 profileId,string contentURI,uint256 pointedProfileId,uint256 pointedPubId,uint256[] referrerProfileIds,uint256[] referrerPubIds,bytes referenceModuleData,address[] actionModules,bytes[] actionModulesInitDatas,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)');

    bytes32 constant SET_BLOCK_STATUS = keccak256('SetBlockStatus(uint256 byProfileId,uint256[] idsOfProfilesToSetBlockStatus,bool[] blockStatus,uint256 nonce,uint256 deadline)');

    bytes32 constant SET_FOLLOW_MODULE = keccak256('SetFollowModule(uint256 profileId,address followModule,bytes followModuleInitData,uint256 nonce,uint256 deadline)');

    bytes32 constant SET_PROFILE_METADATA_URI = keccak256('SetProfileMetadataURI(uint256 profileId,string metadataURI,uint256 nonce,uint256 deadline)');

    bytes32 constant UNFOLLOW = keccak256('Unfollow(uint256 unfollowerProfileId,uint256[] idsOfProfilesToUnfollow,uint256 nonce,uint256 deadline)');

    bytes32 constant PUBLIC_PAID_ACT = keccak256('PublicPaidAct(uint256 publicationActedProfileId,uint256 publicationActedId,uint256 actorProfileId,uint256[] referrerProfileIds,uint256[] referrerPubIds,address actionModuleAddress,bytes actionModuleData,address currency,uint256 amount,address approveTo,uint256 nonce,uint256 deadline)');
}
