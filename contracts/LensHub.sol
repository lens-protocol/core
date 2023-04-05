// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

// Interfaces
import {ILensProtocol} from 'contracts/interfaces/ILensProtocol.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';
// import {ILensHub} from 'contracts/interfaces/ILensHub.sol';

// Constants
import {Events} from 'contracts/libraries/constants/Events.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';

// Lens Hub Components
import {LensBaseERC721} from 'contracts/base/LensBaseERC721.sol';
import {LensHubStorage} from 'contracts/base/LensHubStorage.sol';
import {LensImplGetters} from 'contracts/base/LensImplGetters.sol';
import {LensGovernable} from 'contracts/base/LensGovernable.sol';
import {LensProfiles} from 'contracts/base/LensProfiles.sol';
import {LensHubEventHooks} from 'contracts/base/LensHubEventHooks.sol';

// Libraries
import {ActionLib} from 'contracts/libraries/ActionLib.sol';
import {CollectLib} from 'contracts/libraries/CollectLib.sol';
import {FollowLib} from 'contracts/libraries/FollowLib.sol';
import {GovernanceLib} from 'contracts/libraries/GovernanceLib.sol';
import {MetaTxLib} from 'contracts/libraries/MetaTxLib.sol';
import {ProfileLib} from 'contracts/libraries/ProfileLib.sol';
import {PublicationLib} from 'contracts/libraries/PublicationLib.sol';
import {ProfileTokenURILib} from 'contracts/libraries/ProfileTokenURILib.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';

// Lens Migrations V1 to V2
import {LensV2Migration} from 'contracts/misc/LensV2Migration.sol';

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
contract LensHub is
    LensProfiles,
    LensGovernable,
    LensV2Migration,
    LensImplGetters,
    LensHubEventHooks,
    LensHubStorage,
    ILensProtocol
{
    modifier onlyProfileOwnerOrDelegatedExecutor(address expectedOwnerOrDelegatedExecutor, uint256 profileId) {
        ValidationLib.validateAddressIsProfileOwnerOrDelegatedExecutor(expectedOwnerOrDelegatedExecutor, profileId);
        _;
    }

    constructor(
        address moduleGlobals,
        address followNFTImpl,
        address collectNFTImpl, // We still pass the deprecated CollectNFTImpl for legacy Collects to work
        address lensHandlesAddress,
        address tokenHandleRegistryAddress,
        address legacyFeeFollowModule,
        address legacyProfileFollowModule,
        address newFeeFollowModule
    )
        LensProfiles(moduleGlobals)
        LensV2Migration(
            legacyFeeFollowModule,
            legacyProfileFollowModule,
            newFeeFollowModule,
            lensHandlesAddress,
            tokenHandleRegistryAddress
        )
        LensImplGetters(followNFTImpl, collectNFTImpl)
    {}

    ///////////////////////////////////////////
    ///        PROFILE OWNER FUNCTIONS      ///
    ///////////////////////////////////////////

    /// @inheritdoc ILensProtocol
    function createProfile(
        Types.CreateProfileParams calldata createProfileParams
    ) external override whenNotPaused returns (uint256) {
        ValidationLib.validateProfileCreatorWhitelisted(msg.sender);
        unchecked {
            uint256 profileId = ++_profileCounter;
            _mint(createProfileParams.to, profileId);
            ProfileLib.createProfile(createProfileParams, profileId);
            return profileId;
        }
    }

    /// @inheritdoc ILensProtocol
    function setProfileMetadataURI(
        uint256 profileId,
        string calldata metadataURI
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(msg.sender, profileId) {
        ProfileLib.setProfileMetadataURI(profileId, metadataURI);
    }

    /// @inheritdoc ILensProtocol
    function setProfileMetadataURIWithSig(
        uint256 profileId,
        string calldata metadataURI,
        Types.EIP712Signature calldata signature
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(signature.signer, profileId) {
        MetaTxLib.validateSetProfileMetadataURISignature(signature, profileId, metadataURI);
        ProfileLib.setProfileMetadataURI(profileId, metadataURI);
    }

    /// @inheritdoc ILensProtocol
    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(msg.sender, profileId) {
        ProfileLib.setFollowModule(profileId, followModule, followModuleInitData);
    }

    /// @inheritdoc ILensProtocol
    function setFollowModuleWithSig(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData,
        Types.EIP712Signature calldata signature
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(signature.signer, profileId) {
        MetaTxLib.validateSetFollowModuleSignature(signature, profileId, followModule, followModuleInitData);
        ProfileLib.setFollowModule(profileId, followModule, followModuleInitData);
    }

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
    function setProfileImageURI(
        uint256 profileId,
        string calldata imageURI
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(msg.sender, profileId) {
        ProfileLib.setProfileImageURI(profileId, imageURI);
    }

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /////////////////////////////////////////////////
    ///        PROFILE INTERACTION FUNCTIONS      ///
    /////////////////////////////////////////////////

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(msg.sender, byProfileId) {
        return ProfileLib.setBlockStatus(byProfileId, idsOfProfilesToSetBlockStatus, blockStatus);
    }

    /// @inheritdoc ILensProtocol
    function setBlockStatusWithSig(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus,
        Types.EIP712Signature calldata signature
    ) external override whenNotPaused onlyProfileOwnerOrDelegatedExecutor(signature.signer, byProfileId) {
        MetaTxLib.validateSetBlockStatusSignature(signature, byProfileId, idsOfProfilesToSetBlockStatus, blockStatus);
        return ProfileLib.setBlockStatus(byProfileId, idsOfProfilesToSetBlockStatus, blockStatus);
    }

    /// @inheritdoc ILensProtocol
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
                collectNFTImpl: this.getCollectNFTImpl()
            });
    }

    /// @inheritdoc ILensProtocol
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
                collectNFTImpl: this.getCollectNFTImpl()
            });
    }

    /// @inheritdoc ILensProtocol
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

    /// @inheritdoc ILensProtocol
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

    ///////////////////////////////////////////
    ///        EXTERNAL VIEW FUNCTIONS      ///
    ///////////////////////////////////////////

    /// @inheritdoc ILensProtocol
    function isFollowing(uint256 followerProfileId, uint256 followedProfileId) external view returns (bool) {
        address followNFT = _profiles[followedProfileId].followNFT;
        return followNFT != address(0) && IFollowNFT(followNFT).isFollowing(followerProfileId);
    }

    /// @inheritdoc ILensProtocol
    function isDelegatedExecutorApproved(
        uint256 delegatorProfileId,
        address delegatedExecutor,
        uint64 configNumber
    ) external view returns (bool) {
        return StorageLib.getDelegatedExecutorsConfig(delegatorProfileId).isApproved[configNumber][delegatedExecutor];
    }

    /// @inheritdoc ILensProtocol
    function isDelegatedExecutorApproved(
        uint256 delegatorProfileId,
        address delegatedExecutor
    ) external view returns (bool) {
        return ProfileLib.isExecutorApproved(delegatorProfileId, delegatedExecutor);
    }

    /// @inheritdoc ILensProtocol
    function getDelegatedExecutorsConfigNumber(uint256 delegatorProfileId) external view returns (uint64) {
        return StorageLib.getDelegatedExecutorsConfig(delegatorProfileId).configNumber;
    }

    /// @inheritdoc ILensProtocol
    function getDelegatedExecutorsPrevConfigNumber(uint256 delegatorProfileId) external view returns (uint64) {
        return StorageLib.getDelegatedExecutorsConfig(delegatorProfileId).prevConfigNumber;
    }

    /// @inheritdoc ILensProtocol
    function getDelegatedExecutorsMaxConfigNumberSet(uint256 delegatorProfileId) external view returns (uint64) {
        return StorageLib.getDelegatedExecutorsConfig(delegatorProfileId).maxConfigNumberSet;
    }

    /// @inheritdoc ILensProtocol
    function isBlocked(uint256 profileId, uint256 byProfileId) external view returns (bool) {
        return _blockedStatus[byProfileId][profileId];
    }

    /// @inheritdoc ILensProtocol
    function getProfileMetadataURI(uint256 profileId) external view override returns (string memory) {
        return StorageLib.getProfile(profileId).metadataURI;
    }

    /// @inheritdoc ILensProtocol
    function getPubCount(uint256 profileId) external view override returns (uint256) {
        return _profiles[profileId].pubCount;
    }

    /// @inheritdoc ILensProtocol
    function getProfileImageURI(uint256 profileId) external view override returns (string memory) {
        return _profiles[profileId].imageURI;
    }

    /// @inheritdoc ILensProtocol
    function getFollowNFT(uint256 profileId) external view override returns (address) {
        return _profiles[profileId].followNFT;
    }

    /// @inheritdoc ILensProtocol
    function getFollowModule(uint256 profileId) external view override returns (address) {
        return _profiles[profileId].followModule;
    }

    /// @inheritdoc ILensProtocol
    function getReferenceModule(uint256 profileId, uint256 pubId) external view override returns (address) {
        return _publications[profileId][pubId].referenceModule;
    }

    /// @inheritdoc ILensProtocol
    function getActionModulesBitmap(uint256 profileId, uint256 pubId) external view override returns (uint256) {
        return _publications[profileId][pubId].actionModulesBitmap;
    }

    /// @inheritdoc ILensProtocol
    function getPubPointer(uint256 profileId, uint256 pubId) external view override returns (uint256, uint256) {
        return (_publications[profileId][pubId].pointedProfileId, _publications[profileId][pubId].pointedPubId);
    }

    /// @inheritdoc ILensProtocol
    function getContentURI(uint256 profileId, uint256 pubId) external view override returns (string memory) {
        // This function is used by the Collect NFTs' tokenURI function.
        return PublicationLib.getContentURI(profileId, pubId);
    }

    /// @inheritdoc ILensProtocol
    function getProfile(uint256 profileId) external view override returns (Types.Profile memory) {
        return _profiles[profileId];
    }

    /// @inheritdoc ILensProtocol
    function getPub(uint256 profileId, uint256 pubId) external view override returns (Types.Publication memory) {
        return _publications[profileId][pubId];
    }

    /// @inheritdoc ILensProtocol
    function getPublicationType(
        uint256 profileId,
        uint256 pubId
    ) external view override returns (Types.PublicationType) {
        return PublicationLib.getPublicationType(profileId, pubId);
    }

    function getActionModuleById(uint256 id) external view override returns (address) {
        return _actionModules[id];
    }
}
