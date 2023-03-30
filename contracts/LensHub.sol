// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IERC721Timestamped} from 'contracts/interfaces/IERC721Timestamped.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';

import {Events} from 'contracts/libraries/constants/Events.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';

import {LensBaseERC721} from 'contracts/base/LensBaseERC721.sol';
import {LensMultiState} from 'contracts/base/LensMultiState.sol';
import {LensHubStorage} from 'contracts/base/LensHubStorage.sol';
import {VersionedInitializable} from 'contracts/base/upgradeability/VersionedInitializable.sol';

import {ActionLib} from 'contracts/libraries/ActionLib.sol';
import {CollectLib} from 'contracts/libraries/CollectLib.sol';
import {FollowLib} from 'contracts/libraries/FollowLib.sol';
import {GovernanceLib} from 'contracts/libraries/GovernanceLib.sol';
import {MetaTxLib} from 'contracts/libraries/MetaTxLib.sol';
import {ProfileLib} from 'contracts/libraries/ProfileLib.sol';
import {PublicationLib} from 'contracts/libraries/PublicationLib.sol';
import {ProfileTokenURILib} from 'contracts/libraries/ProfileTokenURILib.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {MigrationLib} from 'contracts/libraries/MigrationLib.sol';

import {LensHandles} from 'contracts/misc/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/misc/namespaces/TokenHandleRegistry.sol';

/**
 * @title LensHub
 * @author Lens Protocol
 *
 * @notice This is the main entry point of the Lens Protocol. It contains governance functionality as well as
 * publishing and profile interaction functionality.
 *
 * NOTE: The Lens Protocol is unique in that frontend operators need to track a potentially overwhelming
 * number of NFT contracts and interactions at once. For that reason, we've made two quirky design decisions:
 *      1. Both Follow & Collect NFTs invoke a LensHub callback on transfer with the sole purpose of emitting an event.
 *      2. Almost every event in the protocol emits the current block timestamp, reducing the need to fetch it manually.
 */
contract LensHub is LensBaseERC721, VersionedInitializable, LensMultiState, LensHubStorage, ILensHub {
    // Constant for upgradeability purposes, see VersionedInitializable. Do not confuse it with the EIP-712 version number.
    uint256 internal constant REVISION = 1;

    address internal immutable FOLLOW_NFT_IMPL;
    address internal immutable COLLECT_NFT_IMPL;

    // Added in Lens V2:
    LensHandles internal immutable lensHandles;
    TokenHandleRegistry internal immutable tokenHandleRegistry;

    // Migration constants:
    address internal immutable FEE_FOLLOW_MODULE;
    address internal immutable PROFILE_FOLLOW_MODULE;
    address internal immutable NEW_FEE_FOLLOW_MODULE;

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    /**
     * @dev The constructor sets the immutable follow & collect NFT implementations.
     *
     * @param followNFTImpl The follow NFT implementation address.
     * @param collectNFTImpl The collect NFT implementation address.
     */
    constructor(
        address followNFTImpl,
        address collectNFTImpl, // We still pass the deprecated CollectNFTImpl for legacy Collects to work
        address lensHandlesAddress,
        address tokenHandleRegistryAddress,
        address legacyFeeFollowModule,
        address legacyProfileFollowModule,
        address newFeeFollowModule
    ) {
        if (followNFTImpl == address(0)) revert Errors.InitParamsInvalid();
        if (collectNFTImpl == address(0)) revert Errors.InitParamsInvalid();
        FOLLOW_NFT_IMPL = followNFTImpl;
        COLLECT_NFT_IMPL = collectNFTImpl;
        lensHandles = LensHandles(lensHandlesAddress);
        tokenHandleRegistry = TokenHandleRegistry(tokenHandleRegistryAddress);
        FEE_FOLLOW_MODULE = legacyFeeFollowModule;
        PROFILE_FOLLOW_MODULE = legacyProfileFollowModule;
        NEW_FEE_FOLLOW_MODULE = newFeeFollowModule;
    }

    /// @inheritdoc ILensHub
    function initialize(
        string calldata name,
        string calldata symbol,
        address newGovernance
    ) external override initializer {
        super._initialize(name, symbol);
        GovernanceLib.initState(Types.ProtocolState.Paused);
        GovernanceLib.setGovernance(newGovernance);
    }

    /////////////////////////////////
    ///        GOV FUNCTIONS      ///
    /////////////////////////////////

    /// @inheritdoc ILensHub
    function setGovernance(address newGovernance) external onlyGov {
        GovernanceLib.setGovernance(newGovernance);
    }

    /// @inheritdoc ILensHub
    function setEmergencyAdmin(address newEmergencyAdmin) external override onlyGov {
        GovernanceLib.setEmergencyAdmin(newEmergencyAdmin);
    }

    /// @inheritdoc ILensHub
    function setState(Types.ProtocolState newState) external override {
        GovernanceLib.setState(newState);
    }

    ///@inheritdoc ILensHub
    function whitelistProfileCreator(address profileCreator, bool whitelist) external override onlyGov {
        GovernanceLib.whitelistProfileCreator(profileCreator, whitelist);
    }

    /// @inheritdoc ILensHub
    function whitelistFollowModule(address followModule, bool whitelist) external override onlyGov {
        GovernanceLib.whitelistFollowModule(followModule, whitelist);
    }

    /// @inheritdoc ILensHub
    function whitelistReferenceModule(address referenceModule, bool whitelist) external override onlyGov {
        GovernanceLib.whitelistReferenceModule(referenceModule, whitelist);
    }

    /// @inheritdoc ILensHub
    function whitelistActionModule(address actionModule, bool whitelist) external override onlyGov {
        GovernanceLib.whitelistActionModule(actionModule, whitelist);
    }

    ///////////////////////////////////////////
    ///      V1->V2 MIGRATION FUNCTIONS     ///
    ///////////////////////////////////////////

    function batchMigrateProfiles(uint256[] calldata profileIds) external {
        MigrationLib.batchMigrateProfiles(profileIds, lensHandles, tokenHandleRegistry);
    }

    function batchMigrateFollows(
        uint256[] calldata followerProfileIds,
        uint256[] calldata idsOfProfileFollowed,
        address[] calldata followNFTAddresses,
        uint256[] calldata followTokenIds
    ) external {
        MigrationLib.batchMigrateFollows(followerProfileIds, idsOfProfileFollowed, followNFTAddresses, followTokenIds);
    }

    function batchMigrateFollowModules(uint256[] calldata profileIds) external {
        MigrationLib.batchMigrateFollowModules(
            profileIds,
            FEE_FOLLOW_MODULE,
            PROFILE_FOLLOW_MODULE,
            NEW_FEE_FOLLOW_MODULE
        );
    }

    ///////////////////////////////////////////
    ///        PROFILE OWNER FUNCTIONS      ///
    ///////////////////////////////////////////

    /// @inheritdoc ILensHub
    function createProfile(
        Types.CreateProfileParams calldata createProfileParams
    ) external override whenNotPaused returns (uint256) {
        unchecked {
            uint256 profileId = ++_profileCounter;
            _mint(createProfileParams.to, profileId);
            ProfileLib.createProfile(createProfileParams, profileId);
            return profileId;
        }
    }

    /// @inheritdoc ILensHub
    function setProfileMetadataURI(
        uint256 profileId,
        string calldata metadataURI
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(msg.sender, profileId) {
        ProfileLib.setProfileMetadataURI(profileId, metadataURI);
    }

    /// @inheritdoc ILensHub
    function setProfileMetadataURIWithSig(
        uint256 profileId,
        string calldata metadataURI,
        Types.EIP712Signature calldata signature
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(signature.signer, profileId) {
        MetaTxLib.validateSetProfileMetadataURISignature(signature, profileId, metadataURI);
        ProfileLib.setProfileMetadataURI(profileId, metadataURI);
    }

    /// @inheritdoc ILensHub
    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(msg.sender, profileId) {
        ProfileLib.setFollowModule(profileId, followModule, followModuleInitData);
    }

    /// @inheritdoc ILensHub
    function setFollowModuleWithSig(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData,
        Types.EIP712Signature calldata signature
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(signature.signer, profileId) {
        MetaTxLib.validateSetFollowModuleSignature(signature, profileId, followModule, followModuleInitData);
        ProfileLib.setFollowModule(profileId, followModule, followModuleInitData);
    }

    /// @inheritdoc ILensHub
    function changeDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) external override whenNotPaused onlyProfileOwner(msg.sender, delegatorProfileId) {
        ProfileLib.changeGivenDelegatedExecutorsConfig(
            delegatorProfileId,
            delegatedExecutors,
            approvals,
            configNumber,
            switchToGivenConfig
        );
    }

    function changeCurrentDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals
    ) external override whenNotPaused onlyProfileOwner(msg.sender, delegatorProfileId) {
        ProfileLib.changeCurrentDelegatedExecutorsConfig(delegatorProfileId, delegatedExecutors, approvals);
    }

    /// @inheritdoc ILensHub
    function changeDelegatedExecutorsConfigWithSig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig,
        Types.EIP712Signature calldata signature
    ) external override whenNotPaused onlyProfileOwner(signature.signer, delegatorProfileId) {
        MetaTxLib.validateChangeDelegatedExecutorsConfigSignature(
            signature,
            delegatorProfileId,
            delegatedExecutors,
            approvals,
            configNumber,
            switchToGivenConfig
        );
        ProfileLib.changeGivenDelegatedExecutorsConfig(
            delegatorProfileId,
            delegatedExecutors,
            approvals,
            configNumber,
            switchToGivenConfig
        );
    }

    /// @inheritdoc ILensHub
    function setProfileImageURI(
        uint256 profileId,
        string calldata imageURI
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(msg.sender, profileId) {
        ProfileLib.setProfileImageURI(profileId, imageURI);
    }

    /// @inheritdoc ILensHub
    function setProfileImageURIWithSig(
        uint256 profileId,
        string calldata imageURI,
        Types.EIP712Signature calldata signature
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(signature.signer, profileId) {
        MetaTxLib.validateSetProfileImageURISignature(signature, profileId, imageURI);
        ProfileLib.setProfileImageURI(profileId, imageURI);
    }

    ////////////////////////////////////////
    ///        PUBLISHING FUNCTIONS      ///
    ////////////////////////////////////////

    /// @inheritdoc ILensHub
    function post(
        Types.PostParams calldata postParams
    )
        external
        override
        whenPublishingEnabled
        onlyProfileOwnerOrDelegatedExecutor(msg.sender, postParams.profileId)
        returns (uint256)
    {
        return PublicationLib.post({postParams: postParams, transactionExecutor: msg.sender});
    }

    /// @inheritdoc ILensHub
    function postWithSig(
        Types.PostParams calldata postParams,
        Types.EIP712Signature calldata signature
    )
        external
        override
        whenPublishingEnabled
        onlyProfileOwnerOrDelegatedExecutor(signature.signer, postParams.profileId)
        returns (uint256)
    {
        MetaTxLib.validatePostSignature(signature, postParams);
        return PublicationLib.post({postParams: postParams, transactionExecutor: signature.signer});
    }

    /// @inheritdoc ILensHub
    function comment(
        Types.CommentParams calldata commentParams
    )
        external
        override
        whenPublishingEnabled
        onlyProfileOwnerOrDelegatedExecutor(msg.sender, commentParams.profileId)
        returns (uint256)
    {
        return PublicationLib.comment({commentParams: commentParams, transactionExecutor: msg.sender});
    }

    /// @inheritdoc ILensHub
    function commentWithSig(
        Types.CommentParams calldata commentParams,
        Types.EIP712Signature calldata signature
    )
        external
        override
        whenPublishingEnabled
        onlyProfileOwnerOrDelegatedExecutor(signature.signer, commentParams.profileId)
        returns (uint256)
    {
        MetaTxLib.validateCommentSignature(signature, commentParams);
        return PublicationLib.comment({commentParams: commentParams, transactionExecutor: signature.signer});
    }

    /// @inheritdoc ILensHub
    function mirror(
        Types.MirrorParams calldata mirrorParams
    )
        external
        override
        whenPublishingEnabled
        onlyProfileOwnerOrDelegatedExecutor(msg.sender, mirrorParams.profileId)
        returns (uint256)
    {
        return PublicationLib.mirror({mirrorParams: mirrorParams, transactionExecutor: msg.sender});
    }

    /// @inheritdoc ILensHub
    function mirrorWithSig(
        Types.MirrorParams calldata mirrorParams,
        Types.EIP712Signature calldata signature
    )
        external
        override
        whenPublishingEnabled
        onlyProfileOwnerOrDelegatedExecutor(signature.signer, mirrorParams.profileId)
        returns (uint256)
    {
        MetaTxLib.validateMirrorSignature(signature, mirrorParams);
        return PublicationLib.mirror({mirrorParams: mirrorParams, transactionExecutor: signature.signer});
    }

    /// @inheritdoc ILensHub
    function quote(
        Types.QuoteParams calldata quoteParams
    )
        external
        override
        whenPublishingEnabled
        onlyProfileOwnerOrDelegatedExecutor(msg.sender, quoteParams.profileId)
        returns (uint256)
    {
        return PublicationLib.quote({quoteParams: quoteParams, transactionExecutor: msg.sender});
    }

    /// @inheritdoc ILensHub
    function quoteWithSig(
        Types.QuoteParams calldata quoteParams,
        Types.EIP712Signature calldata signature
    )
        external
        override
        whenPublishingEnabled
        onlyProfileOwnerOrDelegatedExecutor(signature.signer, quoteParams.profileId)
        returns (uint256)
    {
        MetaTxLib.validateQuoteSignature(signature, quoteParams);
        return PublicationLib.quote({quoteParams: quoteParams, transactionExecutor: signature.signer});
    }

    /**
     * @notice Burns a profile, this maintains the profile data struct.
     */
    function burn(uint256 tokenId) public override whenNotPaused onlyProfileOwner(msg.sender, tokenId) {
        _burn(tokenId);
    }

    /////////////////////////////////////////////////
    ///        PROFILE INTERACTION FUNCTIONS      ///
    /////////////////////////////////////////////////

    /// @inheritdoc ILensHub
    function follow(
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata datas
    )
        external
        override
        whenNotPaused
        onlyProfileOwnerOrDelegatedExecutor(msg.sender, followerProfileId)
        returns (uint256[] memory)
    {
        return
            FollowLib.follow({
                followerProfileId: followerProfileId,
                idsOfProfilesToFollow: idsOfProfilesToFollow,
                followTokenIds: followTokenIds,
                followModuleDatas: datas,
                transactionExecutor: msg.sender
            });
    }

    /// @inheritdoc ILensHub
    function followWithSig(
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata datas,
        Types.EIP712Signature calldata signature
    )
        external
        override
        whenNotPaused
        onlyProfileOwnerOrDelegatedExecutor(signature.signer, followerProfileId)
        returns (uint256[] memory)
    {
        MetaTxLib.validateFollowSignature(signature, followerProfileId, idsOfProfilesToFollow, followTokenIds, datas);
        return
            FollowLib.follow({
                followerProfileId: followerProfileId,
                idsOfProfilesToFollow: idsOfProfilesToFollow,
                followTokenIds: followTokenIds,
                followModuleDatas: datas,
                transactionExecutor: signature.signer
            });
    }

    /// @inheritdoc ILensHub
    function unfollow(
        uint256 unfollowerProfileId,
        uint256[] calldata idsOfProfilesToUnfollow
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(msg.sender, unfollowerProfileId) {
        return
            FollowLib.unfollow({
                unfollowerProfileId: unfollowerProfileId,
                idsOfProfilesToUnfollow: idsOfProfilesToUnfollow,
                transactionExecutor: msg.sender
            });
    }

    /// @inheritdoc ILensHub
    function unfollowWithSig(
        uint256 unfollowerProfileId,
        uint256[] calldata idsOfProfilesToUnfollow,
        Types.EIP712Signature calldata signature
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(signature.signer, unfollowerProfileId) {
        MetaTxLib.validateUnfollowSignature(signature, unfollowerProfileId, idsOfProfilesToUnfollow);

        return
            FollowLib.unfollow({
                unfollowerProfileId: unfollowerProfileId,
                idsOfProfilesToUnfollow: idsOfProfilesToUnfollow,
                transactionExecutor: signature.signer
            });
    }

    /// @inheritdoc ILensHub
    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(msg.sender, byProfileId) {
        return ProfileLib.setBlockStatus(byProfileId, idsOfProfilesToSetBlockStatus, blockStatus);
    }

    /// @inheritdoc ILensHub
    function setBlockStatusWithSig(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus,
        Types.EIP712Signature calldata signature
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(signature.signer, byProfileId) {
        MetaTxLib.validateSetBlockStatusSignature(signature, byProfileId, idsOfProfilesToSetBlockStatus, blockStatus);
        return ProfileLib.setBlockStatus(byProfileId, idsOfProfilesToSetBlockStatus, blockStatus);
    }

    /// @inheritdoc ILensHub
    function collect(
        Types.CollectParams calldata collectParams
    )
        external
        override
        whenNotPaused
        onlyProfileOwnerOrDelegatedExecutor(msg.sender, collectParams.collectorProfileId)
        returns (uint256)
    {
        return
            CollectLib.collect({
                collectParams: collectParams,
                transactionExecutor: msg.sender,
                collectorProfileOwner: ownerOf(collectParams.collectorProfileId),
                collectNFTImpl: COLLECT_NFT_IMPL
            });
    }

    /// @inheritdoc ILensHub
    function collectWithSig(
        Types.CollectParams calldata collectParams,
        Types.EIP712Signature calldata signature
    )
        external
        override
        whenNotPaused
        onlyProfileOwnerOrDelegatedExecutor(signature.signer, collectParams.collectorProfileId)
        returns (uint256)
    {
        MetaTxLib.validateCollectSignature(signature, collectParams);
        return
            CollectLib.collect({
                collectParams: collectParams,
                transactionExecutor: signature.signer,
                collectorProfileOwner: ownerOf(collectParams.collectorProfileId),
                collectNFTImpl: COLLECT_NFT_IMPL
            });
    }

    /// @inheritdoc ILensHub
    function act(
        Types.PublicationActionParams calldata publicationActionParams
    )
        external
        override
        whenNotPaused
        onlyProfileOwnerOrDelegatedExecutor(msg.sender, publicationActionParams.actorProfileId)
        returns (bytes memory)
    {
        return
            ActionLib.act({
                publicationActionParams: publicationActionParams,
                transactionExecutor: msg.sender,
                actorProfileOwner: ownerOf(publicationActionParams.actorProfileId)
            });
    }

    /// @inheritdoc ILensHub
    function actWithSig(
        Types.PublicationActionParams calldata publicationActionParams,
        Types.EIP712Signature calldata signature
    )
        external
        override
        whenNotPaused
        onlyProfileOwnerOrDelegatedExecutor(signature.signer, publicationActionParams.actorProfileId)
        returns (bytes memory)
    {
        MetaTxLib.validateActSignature(signature, publicationActionParams);
        return
            ActionLib.act({
                publicationActionParams: publicationActionParams,
                transactionExecutor: signature.signer,
                actorProfileOwner: ownerOf(publicationActionParams.actorProfileId)
            });
    }

    /// @inheritdoc ILensHub
    function emitUnfollowedEvent(uint256 unfollowerProfileId, uint256 idOfProfileUnfollowed) external override {
        address expectedFollowNFT = _profileById[idOfProfileUnfollowed].followNFT;
        if (msg.sender != expectedFollowNFT) {
            revert Errors.CallerNotFollowNFT();
        }
        emit Events.Unfollowed(unfollowerProfileId, idOfProfileUnfollowed, block.timestamp);
    }

    ///////////////////////////////////////////
    ///        EXTERNAL VIEW FUNCTIONS      ///
    ///////////////////////////////////////////

    function isFollowing(uint256 followerProfileId, uint256 followedProfileId) external view returns (bool) {
        address followNFT = _profileById[followedProfileId].followNFT;
        return followNFT != address(0) && IFollowNFT(followNFT).isFollowing(followerProfileId);
    }

    /// @inheritdoc ILensHub
    function isProfileCreatorWhitelisted(address profileCreator) external view override returns (bool) {
        return _profileCreatorWhitelisted[profileCreator];
    }

    /// @inheritdoc ILensHub
    function isFollowModuleWhitelisted(address followModule) external view override returns (bool) {
        return _followModuleWhitelisted[followModule];
    }

    /// @inheritdoc ILensHub
    function isReferenceModuleWhitelisted(address referenceModule) external view override returns (bool) {
        return _referenceModuleWhitelisted[referenceModule];
    }

    /// @inheritdoc ILensHub
    function getActionModuleWhitelistData(
        address actionModule
    ) external view override returns (Types.ActionModuleWhitelistData memory) {
        return _actionModuleWhitelistData[actionModule];
    }

    /// @inheritdoc ILensHub
    function getGovernance() external view override returns (address) {
        return _governance;
    }

    /// @inheritdoc ILensHub
    function isDelegatedExecutorApproved(
        uint256 delegatorProfileId,
        address delegatedExecutor,
        uint64 configNumber
    ) external view returns (bool) {
        return StorageLib.getDelegatedExecutorsConfig(delegatorProfileId).isApproved[configNumber][delegatedExecutor];
    }

    /// @inheritdoc ILensHub
    function isDelegatedExecutorApproved(
        uint256 delegatorProfileId,
        address delegatedExecutor
    ) external view returns (bool) {
        return ProfileLib.isExecutorApproved(delegatorProfileId, delegatedExecutor);
    }

    /// @inheritdoc ILensHub
    function getDelegatedExecutorsConfigNumber(uint256 delegatorProfileId) external view returns (uint64) {
        return StorageLib.getDelegatedExecutorsConfig(delegatorProfileId).configNumber;
    }

    /// @inheritdoc ILensHub
    function getDelegatedExecutorsPrevConfigNumber(uint256 delegatorProfileId) external view returns (uint64) {
        return StorageLib.getDelegatedExecutorsConfig(delegatorProfileId).prevConfigNumber;
    }

    /// @inheritdoc ILensHub
    function getDelegatedExecutorsMaxConfigNumberSet(uint256 delegatorProfileId) external view returns (uint64) {
        return StorageLib.getDelegatedExecutorsConfig(delegatorProfileId).maxConfigNumberSet;
    }

    /// @inheritdoc ILensHub
    function isBlocked(uint256 profileId, uint256 byProfileId) external view returns (bool) {
        return _blockedStatus[byProfileId][profileId];
    }

    /// @inheritdoc ILensHub
    function getProfileMetadataURI(uint256 profileId) external view override returns (string memory) {
        return StorageLib.getProfile(profileId).metadataURI;
    }

    /// @inheritdoc ILensHub
    function getPubCount(uint256 profileId) external view override returns (uint256) {
        return _profileById[profileId].pubCount;
    }

    /// @inheritdoc ILensHub
    function getProfileImageURI(uint256 profileId) external view override returns (string memory) {
        return _profileById[profileId].imageURI;
    }

    /// @inheritdoc ILensHub
    function getFollowNFT(uint256 profileId) external view override returns (address) {
        return _profileById[profileId].followNFT;
    }

    // /// @inheritdoc ILensHub
    // TODO: Consider removing this if it's not used
    // function getCollectNFT(uint256 profileId, uint256 pubId) external view override returns (address) {
    //     return _pubByIdByProfile[profileId][pubId].__DEPRECATED__collectNFT;
    // }

    /// @inheritdoc ILensHub
    function getFollowModule(uint256 profileId) external view override returns (address) {
        return _profileById[profileId].followModule;
    }

    /// @inheritdoc ILensHub
    // TODO: Consider removing this if it's not used
    // function getCollectModule(uint256 profileId, uint256 pubId) external view override returns (address) {
    //     return _pubByIdByProfile[profileId][pubId].__DEPRECATED__collectModule;
    // }

    /// @inheritdoc ILensHub
    function getReferenceModule(uint256 profileId, uint256 pubId) external view override returns (address) {
        return _pubByIdByProfile[profileId][pubId].referenceModule;
    }

    /// @inheritdoc ILensHub
    function getActionModulesBitmap(uint256 profileId, uint256 pubId) external view override returns (uint256) {
        return _pubByIdByProfile[profileId][pubId].actionModulesBitmap;
    }

    /// @inheritdoc ILensHub
    function getPubPointer(uint256 profileId, uint256 pubId) external view override returns (uint256, uint256) {
        return (_pubByIdByProfile[profileId][pubId].pointedProfileId, _pubByIdByProfile[profileId][pubId].pointedPubId);
    }

    /// @inheritdoc ILensHub
    function getContentURI(uint256 profileId, uint256 pubId) external view override returns (string memory) {
        // This function is used by the Collect NFTs' tokenURI function.
        return PublicationLib.getContentURI(profileId, pubId);
    }

    /// @inheritdoc ILensHub
    function getProfile(uint256 profileId) external view override returns (Types.Profile memory) {
        return _profileById[profileId];
    }

    /// @inheritdoc ILensHub
    function getPub(uint256 profileId, uint256 pubId) external view override returns (Types.Publication memory) {
        return _pubByIdByProfile[profileId][pubId];
    }

    /// @inheritdoc ILensHub
    function getPublicationType(
        uint256 profileId,
        uint256 pubId
    ) external view override returns (Types.PublicationType) {
        return PublicationLib.getPublicationType(profileId, pubId);
    }

    /// @inheritdoc ILensHub
    function getFollowNFTImpl() external view override returns (address) {
        return FOLLOW_NFT_IMPL;
    }

    /// @inheritdoc ILensHub
    function getCollectNFTImpl() external view override returns (address) {
        return COLLECT_NFT_IMPL;
    }

    function getActionModuleById(uint256 id) external view override returns (address) {
        return _actionModuleById[id];
    }

    /**
     * @dev Overrides the ERC721 tokenURI function to return the associated URI with a given profile.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address followNFT = _profileById[tokenId].followNFT;
        return
            ProfileTokenURILib.getProfileTokenURI(
                tokenId,
                followNFT == address(0) ? 0 : IERC721Timestamped(followNFT).totalSupply(),
                ownerOf(tokenId),
                'Lens Profile',
                _profileById[tokenId].imageURI
            );
    }

    //////////////////////////////////////
    ///        INTERNAL FUNCTIONS      ///
    //////////////////////////////////////

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        // Switches to new fresh delegated executors configuration (except on minting, as it already has a fresh setup).
        if (from != address(0)) {
            ProfileLib.switchToNewFreshDelegatedExecutorsConfig(tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }

    //////////////////////////////////////
    ///       DEPRECATED FUNCTIONS     ///
    //////////////////////////////////////

    // Deprecated in V2. Kept here just for backwards compatibility with Lens V1 Collect NFTs.
    function emitCollectNFTTransferEvent(uint256, uint256, uint256, address, address) external {}
}
