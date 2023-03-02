// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';
import {ProfileLib} from 'contracts/libraries/ProfileLib.sol';
import {PublicationLib} from 'contracts/libraries/PublicationLib.sol';
import {ProfileTokenURILib} from 'contracts/libraries/ProfileTokenURILib.sol';
import {LensBaseERC721} from 'contracts/base/LensBaseERC721.sol';
import {LensMultiState} from 'contracts/base/LensMultiState.sol';
import {LensHubStorage} from 'contracts/base/LensHubStorage.sol';
import {VersionedInitializable} from 'contracts/base/upgradeability/VersionedInitializable.sol';
import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import {MetaTxLib} from 'contracts/libraries/MetaTxLib.sol';
import {GovernanceLib} from 'contracts/libraries/GovernanceLib.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {FollowLib} from 'contracts/libraries/FollowLib.sol';
import {CollectLib} from 'contracts/libraries/CollectLib.sol';

///////////////////////////////////// Migration imports ////////////////////////////////////
import {LensHandles} from 'contracts/misc/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/misc/namespaces/TokenHandleRegistry.sol';

/**
 * @title LensHub
 * @author Lens Protocol
 *
 * @notice This is the main entrypoint of the Lens Protocol. It contains governance functionality as well as
 * publishing and profile interaction functionality.
 *
 * NOTE: The Lens Protocol is unique in that frontend operators need to track a potentially overwhelming
 * number of NFT contracts and interactions at once. For that reason, we've made two quirky design decisions:
 *      1. Both Follow & Collect NFTs invoke an LensHub callback on transfer with the sole purpose of emitting an event.
 *      2. Almost every event in the protocol emits the current block timestamp, reducing the need to fetch it manually.
 */
contract LensHub is LensBaseERC721, VersionedInitializable, LensMultiState, LensHubStorage, ILensHub {
    // Constant for upgradeability purposes, see VersionedInitializable. Do not confuse with EIP-712 version number.
    uint256 internal constant REVISION = 1;

    address internal immutable FOLLOW_NFT_IMPL;
    address internal immutable COLLECT_NFT_IMPL;

    ///////////////////////////////////// Migration constants ////////////////////////////////////
    uint256 internal constant LENS_PROTOCOL_PROFILE_ID = 1;
    address internal immutable migrator;
    LensHandles internal immutable lensHandles;
    TokenHandleRegistry internal immutable tokenHandleRegistry;
    ///////////////////////////////// End of migration constants /////////////////////////////////

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
        address collectNFTImpl,
        address migratorAddress,
        address lensHandlesAddress,
        address tokenHandleRegistryAddress
    ) {
        if (followNFTImpl == address(0)) revert Errors.InitParamsInvalid();
        if (collectNFTImpl == address(0)) revert Errors.InitParamsInvalid();
        FOLLOW_NFT_IMPL = followNFTImpl;
        COLLECT_NFT_IMPL = collectNFTImpl;
        migrator = migratorAddress;
        lensHandles = LensHandles(lensHandlesAddress);
        tokenHandleRegistry = TokenHandleRegistry(tokenHandleRegistryAddress);
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

    // TODO: Move to GovernanceLib?
    ///@inheritdoc ILensHub
    function whitelistProfileCreator(address profileCreator, bool whitelist) external override onlyGov {
        _profileCreatorWhitelisted[profileCreator] = whitelist;
        emit Events.ProfileCreatorWhitelisted(profileCreator, whitelist, block.timestamp);
    }

    // TODO: Move to GovernanceLib?
    /// @inheritdoc ILensHub
    function whitelistFollowModule(address followModule, bool whitelist) external override onlyGov {
        _followModuleWhitelisted[followModule] = whitelist;
        emit Events.FollowModuleWhitelisted(followModule, whitelist, block.timestamp);
    }

    // TODO: Move to GovernanceLib?
    /// @inheritdoc ILensHub
    function whitelistReferenceModule(address referenceModule, bool whitelist) external override onlyGov {
        _referenceModuleWhitelisted[referenceModule] = whitelist;
        emit Events.ReferenceModuleWhitelisted(referenceModule, whitelist, block.timestamp);
    }

    // TODO: Move to GovernanceLib?
    /// @inheritdoc ILensHub
    function whitelistCollectModule(address collectModule, bool whitelist) external override onlyGov {
        _collectModuleWhitelisted[collectModule] = whitelist;
        emit Events.CollectModuleWhitelisted(collectModule, whitelist, block.timestamp);
    }

    ///////////////////////////////////////////
    ///      V1->V2 MIGRATION FUNCTIONS     ///
    ///////////////////////////////////////////

    function migrateProfile(uint256 profileId, bytes32 handleHash) external {
        require(msg.sender == migrator, 'Only migrator');
        delete _profileById[profileId].handleDeprecated;
        delete _profileIdByHandleHash[handleHash];
    }

    event ProfileMigrated(uint256 profileId, address profileDestination, string handle, uint256 handleId);

    function _migrateProfilePublic(uint256 profileId) internal {
        address profileOwner = StorageLib.getTokenData(profileId).owner;
        if (profileOwner != address(0)) {
            string memory handle = _profileById[profileId].handleDeprecated;
            bytes32 handleHash = keccak256(bytes(handle));
            // "lensprotocol" is the only edge case without .lens suffix:
            if (profileId != LENS_PROTOCOL_PROFILE_ID) {
                assembly {
                    let handle_length := mload(handle)
                    mstore(handle, sub(handle_length, 5)) // Cut 5 chars (.lens) from the end
                }
            }
            delete _profileById[profileId].handleDeprecated;
            delete _profileIdByHandleHash[handleHash];

            uint256 handleId = lensHandles.mintHandle(profileOwner, handle);
            tokenHandleRegistry.migrationLinkHandleWithToken(handleId, profileId);
            emit ProfileMigrated(profileId, profileOwner, handle, handleId);
        }
    }

    function batchMigrateProfiles(uint256[] calldata profileIds) external {
        for (uint256 i = 0; i < profileIds.length; i++) {
            _migrateProfilePublic(profileIds[i]);
        }
    }

    ///////////////////////////////////////////
    ///  END OF V1->V2 MIGRATION FUNCTIONS  ///
    ///////////////////////////////////////////

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
        address[] calldata executors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) external override whenNotPaused onlyProfileOwner(msg.sender, delegatorProfileId) {
        ProfileLib.changeGivenDelegatedExecutorsConfig(
            delegatorProfileId,
            executors,
            approvals,
            configNumber,
            switchToGivenConfig
        );
    }

    function changeCurrentDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata executors,
        bool[] calldata approvals
    ) external override whenNotPaused onlyProfileOwner(msg.sender, delegatorProfileId) {
        ProfileLib.changeCurrentDelegatedExecutorsConfig(delegatorProfileId, executors, approvals);
    }

    /// @inheritdoc ILensHub
    function changeDelegatedExecutorsConfigWithSig(
        uint256 delegatorProfileId,
        address[] calldata executors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig,
        Types.EIP712Signature calldata signature
    ) external override whenNotPaused onlyProfileOwner(signature.signer, delegatorProfileId) {
        MetaTxLib.validateChangeDelegatedExecutorsConfigSignature(
            signature,
            delegatorProfileId,
            executors,
            approvals,
            configNumber,
            switchToGivenConfig
        );
        ProfileLib.changeGivenDelegatedExecutorsConfig(
            delegatorProfileId,
            executors,
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

    /// @inheritdoc ILensHub
    function setFollowNFTURI(
        uint256 profileId,
        string calldata followNFTURI
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(msg.sender, profileId) {
        ProfileLib.setFollowNFTURI(profileId, followNFTURI);
    }

    /// @inheritdoc ILensHub
    function setFollowNFTURIWithSig(
        uint256 profileId,
        string calldata followNFTURI,
        Types.EIP712Signature calldata signature
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(signature.signer, profileId) {
        MetaTxLib.validateSetFollowNFTURISignature(signature, profileId, followNFTURI);
        ProfileLib.setFollowNFTURI(profileId, followNFTURI);
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
        onlyValidPointedPub(commentParams.pointedProfileId, commentParams.pointedPubId)
        whenNotBlocked(commentParams.profileId, commentParams.pointedProfileId)
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
        onlyValidPointedPub(commentParams.pointedProfileId, commentParams.pointedPubId)
        whenNotBlocked(commentParams.profileId, commentParams.pointedProfileId)
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
        onlyValidPointedPub(mirrorParams.pointedProfileId, mirrorParams.pointedPubId)
        whenNotBlocked(mirrorParams.profileId, mirrorParams.pointedProfileId)
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
        onlyValidPointedPub(mirrorParams.pointedProfileId, mirrorParams.pointedPubId)
        whenNotBlocked(mirrorParams.profileId, mirrorParams.pointedProfileId)
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
        onlyValidPointedPub(quoteParams.pointedProfileId, quoteParams.pointedPubId)
        whenNotBlocked(quoteParams.profileId, quoteParams.pointedProfileId)
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
        onlyValidPointedPub(quoteParams.pointedProfileId, quoteParams.pointedPubId)
        whenNotBlocked(quoteParams.profileId, quoteParams.pointedProfileId)
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

    /// TODO: Inherit natspec
    function collect(
        Types.CollectParams calldata collectParams
    )
        external
        override
        whenNotPaused
        onlyProfileOwnerOrDelegatedExecutor(msg.sender, collectParams.collectorProfileId)
        whenNotBlocked(collectParams.collectorProfileId, collectParams.publicationCollectedProfileId)
        returns (uint256)
    {
        return
            CollectLib.collect({
                collectParams: collectParams,
                transactionExecutor: msg.sender,
                collectorProfileOwner: ownerOf(collectParams.collectorProfileId),
                collectNFTImpl: COLLECT_NFT_IMPL // TODO: Think how we can not pass this
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
        whenNotBlocked(collectParams.collectorProfileId, collectParams.publicationCollectedProfileId)
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
    function emitFollowNFTTransferEvent(
        uint256 profileId,
        uint256 followNFTId,
        address from,
        address to
    ) external override {
        address expectedFollowNFT = _profileById[profileId].followNFT;
        if (msg.sender != expectedFollowNFT) revert Errors.CallerNotFollowNFT();
        emit Events.FollowNFTTransferred(profileId, followNFTId, from, to, block.timestamp);
    }

    /// @inheritdoc ILensHub
    function emitCollectNFTTransferEvent(
        uint256 profileId,
        uint256 pubId,
        uint256 collectNFTId,
        address from,
        address to
    ) external override {
        address expectedCollectNFT = _pubByIdByProfile[profileId][pubId].collectNFT;
        if (msg.sender != expectedCollectNFT) revert Errors.CallerNotCollectNFT();
        emit Events.CollectNFTTransferred(profileId, pubId, collectNFTId, from, to, block.timestamp);
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
    function isCollectModuleWhitelisted(address collectModule) external view override returns (bool) {
        return _collectModuleWhitelisted[collectModule];
    }

    /// @inheritdoc ILensHub
    function getGovernance() external view override returns (address) {
        return _governance;
    }

    /// @inheritdoc ILensHub
    function isDelegatedExecutorApproved(
        uint256 delegatorProfileId,
        address executor,
        uint64 configNumber
    ) external view returns (bool) {
        return StorageLib.getDelegatedExecutorsConfig(delegatorProfileId).isApproved[configNumber][executor];
    }

    /// @inheritdoc ILensHub
    function isDelegatedExecutorApproved(uint256 delegatorProfileId, address executor) external view returns (bool) {
        return ProfileLib.isExecutorApproved(delegatorProfileId, executor);
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

    /// @inheritdoc ILensHub
    function getFollowNFTURI(uint256 profileId) external view override returns (string memory) {
        return _profileById[profileId].followNFTURI;
    }

    /// @inheritdoc ILensHub
    function getCollectNFT(uint256 profileId, uint256 pubId) external view override returns (address) {
        return _pubByIdByProfile[profileId][pubId].collectNFT;
    }

    /// @inheritdoc ILensHub
    function getFollowModule(uint256 profileId) external view override returns (address) {
        return _profileById[profileId].followModule;
    }

    /// @inheritdoc ILensHub
    function getCollectModule(uint256 profileId, uint256 pubId) external view override returns (address) {
        return _pubByIdByProfile[profileId][pubId].collectModule;
    }

    /// @inheritdoc ILensHub
    function getReferenceModule(uint256 profileId, uint256 pubId) external view override returns (address) {
        return _pubByIdByProfile[profileId][pubId].referenceModule;
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

    /**
     * @dev Overrides the ERC721 tokenURI function to return the associated URI with a given profile.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address followNFT = _profileById[tokenId].followNFT;
        return
            ProfileTokenURILib.getProfileTokenURI(
                tokenId,
                followNFT == address(0) ? 0 : IERC721Enumerable(followNFT).totalSupply(),
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
}
