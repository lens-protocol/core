// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IFollowNFT} from '../interfaces/IFollowNFT.sol';
import {ILensNFTBase} from '../interfaces/ILensNFTBase.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';

import {Events} from '../libraries/Events.sol';
import {DataTypes} from '../libraries/DataTypes.sol';
import {Errors} from '../libraries/Errors.sol';
import {GeneralLib} from '../libraries/GeneralLib.sol';
import {ProfileLib} from '../libraries/ProfileLib.sol';
import {PublishingLib} from '../libraries/PublishingLib.sol';
import {ProfileTokenURILogic} from '../libraries/ProfileTokenURILogic.sol';
import '../libraries/Constants.sol';

import {LensNFTBase} from './base/LensNFTBase.sol';
import {LensMultiState} from './base/LensMultiState.sol';
import {LensHubStorage} from './storage/LensHubStorage.sol';
import {VersionedInitializable} from '../upgradeability/VersionedInitializable.sol';
import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

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
contract LensHub is LensNFTBase, VersionedInitializable, LensMultiState, LensHubStorage, ILensHub {
    uint256 internal constant REVISION = 1;

    address internal immutable FOLLOW_NFT_IMPL;
    address internal immutable COLLECT_NFT_IMPL;

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
    constructor(address followNFTImpl, address collectNFTImpl) {
        if (followNFTImpl == address(0)) revert Errors.InitParamsInvalid();
        if (collectNFTImpl == address(0)) revert Errors.InitParamsInvalid();
        FOLLOW_NFT_IMPL = followNFTImpl;
        COLLECT_NFT_IMPL = collectNFTImpl;
    }

    /// @inheritdoc ILensHub
    function initialize(
        string calldata name,
        string calldata symbol,
        address newGovernance
    ) external override initializer {
        super._initialize(name, symbol);
        GeneralLib.initState(DataTypes.ProtocolState.Paused);
        _setGovernance(newGovernance);
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    /// @inheritdoc ILensHub
    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    /// @inheritdoc ILensHub
    function setEmergencyAdmin(address newEmergencyAdmin) external override onlyGov {
        GeneralLib.setEmergencyAdmin(newEmergencyAdmin);
    }

    /// @inheritdoc ILensHub
    function setState(DataTypes.ProtocolState newState) external override {
        GeneralLib.setState(newState);
    }

    ///@inheritdoc ILensHub
    function whitelistProfileCreator(address profileCreator, bool whitelist)
        external
        override
        onlyGov
    {
        _profileCreatorWhitelisted[profileCreator] = whitelist;
        emit Events.ProfileCreatorWhitelisted(profileCreator, whitelist, block.timestamp);
    }

    /// @inheritdoc ILensHub
    function whitelistFollowModule(address followModule, bool whitelist) external override onlyGov {
        _followModuleWhitelisted[followModule] = whitelist;
        emit Events.FollowModuleWhitelisted(followModule, whitelist, block.timestamp);
    }

    /// @inheritdoc ILensHub
    function whitelistReferenceModule(address referenceModule, bool whitelist)
        external
        override
        onlyGov
    {
        _referenceModuleWhitelisted[referenceModule] = whitelist;
        emit Events.ReferenceModuleWhitelisted(referenceModule, whitelist, block.timestamp);
    }

    /// @inheritdoc ILensHub
    function whitelistCollectModule(address collectModule, bool whitelist)
        external
        override
        onlyGov
    {
        _collectModuleWhitelisted[collectModule] = whitelist;
        emit Events.CollectModuleWhitelisted(collectModule, whitelist, block.timestamp);
    }

    /// *********************************
    /// *****PROFILE OWNER FUNCTIONS*****
    /// *********************************

    /// @inheritdoc ILensNFTBase
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        GeneralLib.permit(spender, tokenId, sig);
    }

    /// @inheritdoc ILensNFTBase
    function permitForAll(
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        GeneralLib.permitForAll(owner, operator, approved, sig);
    }

    /// @inheritdoc ILensHub
    function createProfile(DataTypes.CreateProfileData calldata vars)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        unchecked {
            uint256 profileId = ++_profileCounter;
            _mint(vars.to, profileId);
            ProfileLib.createProfile(vars, profileId);
            return profileId;
        }
    }

    /// @inheritdoc ILensHub
    function setDefaultProfile(address onBehalfOf, uint256 profileId)
        external
        override
        whenNotPaused
    {
        GeneralLib.setDefaultProfile(onBehalfOf, profileId);
    }

    /// @inheritdoc ILensHub
    function setDefaultProfileWithSig(DataTypes.SetDefaultProfileWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        GeneralLib.setDefaultProfileWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function setProfileMetadataURI(uint256 profileId, string calldata metadataURI)
        external
        override
        whenNotPaused
    {
        ProfileLib.setProfileMetadataURI(profileId, metadataURI);
    }

    /// @inheritdoc ILensHub
    function setProfileMetadataURIWithSig(DataTypes.SetProfileMetadataURIWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        ProfileLib.setProfileMetadataURIWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData
    ) external override whenNotPaused {
        ProfileLib.setFollowModule(profileId, followModule, followModuleInitData);
    }

    /// @inheritdoc ILensHub
    function setFollowModuleWithSig(DataTypes.SetFollowModuleWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        ProfileLib.setFollowModuleWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function setDispatcher(uint256 profileId, address dispatcher) external override whenNotPaused {
        _validateCallerIsProfileOwner(profileId);
        _setDispatcher(profileId, dispatcher);
    }

    /// @inheritdoc ILensHub
    function setDispatcherWithSig(DataTypes.SetDispatcherWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        ProfileLib.setDispatcherWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function setDelegatedExecutorApproval(address executor, bool approved)
        external
        override
        whenNotPaused
    {
        GeneralLib.setDelegatedExecutorApproval(executor, approved);
    }

    /// @inheritdoc ILensHub
    function setDelegatedExecutorApprovalWithSig(
        DataTypes.SetDelegatedExecutorApprovalWithSigData calldata vars
    ) external override whenNotPaused {
        GeneralLib.setDelegatedExecutorApprovalWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function setProfileImageURI(uint256 profileId, string calldata imageURI)
        external
        override
        whenNotPaused
    {
        ProfileLib.setProfileImageURI(profileId, imageURI);
    }

    /// @inheritdoc ILensHub
    function setProfileImageURIWithSig(DataTypes.SetProfileImageURIWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        ProfileLib.setProfileImageURIWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function setFollowNFTURI(uint256 profileId, string calldata followNFTURI)
        external
        override
        whenNotPaused
    {
        ProfileLib.setFollowNFTURI(profileId, followNFTURI);
    }

    /// @inheritdoc ILensHub
    function setFollowNFTURIWithSig(DataTypes.SetFollowNFTURIWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        ProfileLib.setFollowNFTURIWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function post(DataTypes.PostData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        return PublishingLib.post(vars);
    }

    /// @inheritdoc ILensHub
    function postWithSig(DataTypes.PostWithSigData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        return PublishingLib.postWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function comment(DataTypes.CommentData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        return PublishingLib.comment(vars);
    }

    /// @inheritdoc ILensHub
    function commentWithSig(DataTypes.CommentWithSigData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        return PublishingLib.commentWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function mirror(DataTypes.MirrorData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        return PublishingLib.mirror(vars);
    }

    /// @inheritdoc ILensHub
    function mirrorWithSig(DataTypes.MirrorWithSigData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        return PublishingLib.mirrorWithSig(vars);
    }

    /**
     * @notice Burns a profile, this maintains the profile data struct.
     */
    function burn(uint256 tokenId) public override whenNotPaused {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Errors.NotOwnerOrApproved();
        _burn(tokenId);
    }

    /**
     * @notice Burns a profile with a signature, this maintains the profile data struct.
     */
    function burnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig)
        public
        override
        whenNotPaused
    {
        GeneralLib.baseBurnWithSig(tokenId, sig);
        _burn(tokenId);
    }

    /// ***************************************
    /// *****PROFILE INTERACTION FUNCTIONS*****
    /// ***************************************

    /// @inheritdoc ILensHub
    function follow(
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata datas
    ) external override whenNotPaused returns (uint256[] memory) {
        return GeneralLib.follow(followerProfileId, idsOfProfilesToFollow, followTokenIds, datas);
    }

    /// @inheritdoc ILensHub
    function followWithSig(DataTypes.FollowWithSigData calldata vars)
        external
        override
        whenNotPaused
        returns (uint256[] memory)
    {
        return GeneralLib.followWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function unfollow(uint256 unfollowerProfileId, uint256[] calldata idsOfProfilesToUnfollow)
        external
        override
        whenNotPaused
    {
        return GeneralLib.unfollow(unfollowerProfileId, idsOfProfilesToUnfollow);
    }

    /// @inheritdoc ILensHub
    function unfollowWithSig(DataTypes.UnfollowWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        return GeneralLib.unfollowWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) external override whenNotPaused {
        return GeneralLib.setBlockStatus(byProfileId, idsOfProfilesToSetBlockStatus, blockStatus);
    }

    /// @inheritdoc ILensHub
    function setBlockStatusWithSig(DataTypes.SetBlockStatusWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        return GeneralLib.setBlockStatusWithSig(vars);
    }

    /// @inheritdoc ILensHub
    function collect(
        uint256 collectorProfileId,
        uint256 publisherProfileId, // TODO: Think if we can have better naming
        uint256 pubId,
        bytes calldata data
    ) external override whenNotPaused returns (uint256) {
        return
            GeneralLib.collect({
                collectorProfileId: collectorProfileId,
                publisherProfileId: publisherProfileId,
                pubId: pubId,
                collectModuleData: data,
                collectNFTImpl: COLLECT_NFT_IMPL
            });
    }

    /// @inheritdoc ILensHub
    function collectWithSig(DataTypes.CollectWithSigData calldata vars)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        return GeneralLib.collectWithSig(vars, COLLECT_NFT_IMPL);
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
        emit Events.CollectNFTTransferred(
            profileId,
            pubId,
            collectNFTId,
            from,
            to,
            block.timestamp
        );
    }

    /// @inheritdoc ILensHub
    function emitUnfollowedEvent(uint256 unfollowerProfileId, uint256 idOfProfileUnfollowed)
        external
        override
    {
        address expectedFollowNFT = _profileById[idOfProfileUnfollowed].followNFT;
        if (msg.sender != expectedFollowNFT) {
            revert Errors.CallerNotFollowNFT();
        }
        emit Events.Unfollowed(unfollowerProfileId, idOfProfileUnfollowed, block.timestamp);
    }

    /// *********************************
    /// *****EXTERNAL VIEW FUNCTIONS*****
    /// *********************************

    function isFollowing(uint256 followerProfileId, uint256 followedProfileId)
        external
        view
        returns (bool)
    {
        address followNFT = _profileById[followedProfileId].followNFT;
        return followNFT != address(0) && IFollowNFT(followNFT).isFollowing(followerProfileId);
    }

    /// @inheritdoc ILensHub
    function isProfileCreatorWhitelisted(address profileCreator)
        external
        view
        override
        returns (bool)
    {
        return _profileCreatorWhitelisted[profileCreator];
    }

    /// @inheritdoc ILensHub
    function isFollowModuleWhitelisted(address followModule) external view override returns (bool) {
        return _followModuleWhitelisted[followModule];
    }

    /// @inheritdoc ILensHub
    function isReferenceModuleWhitelisted(address referenceModule)
        external
        view
        override
        returns (bool)
    {
        return _referenceModuleWhitelisted[referenceModule];
    }

    /// @inheritdoc ILensHub
    function isCollectModuleWhitelisted(address collectModule)
        external
        view
        override
        returns (bool)
    {
        return _collectModuleWhitelisted[collectModule];
    }

    /// @inheritdoc ILensHub
    function getGovernance() external view override returns (address) {
        return _governance;
    }

    /// @inheritdoc ILensHub
    function isDelegatedExecutorApproved(address wallet, address executor)
        external
        view
        returns (bool)
    {
        return _delegatedExecutorApproval[wallet][executor];
    }

    /// @inheritdoc ILensHub
    function isBlocked(uint256 profileId, uint256 byProfileId) external view returns (bool) {
        return _blockStatusByBlockeeProfileIdByProfileId[byProfileId][profileId];
    }

    /// @inheritdoc ILensHub
    function getDefaultProfile(address wallet) external view override returns (uint256) {
        return _defaultProfileByAddress[wallet];
    }

    /// @inheritdoc ILensHub
    function getProfileMetadataURI(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        return _metadataByProfile[profileId];
    }

    /// @inheritdoc ILensHub
    function getDispatcher(uint256 profileId) external view override returns (address) {
        return _dispatcherByProfile[profileId];
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
    function getCollectNFT(uint256 profileId, uint256 pubId)
        external
        view
        override
        returns (address)
    {
        return _pubByIdByProfile[profileId][pubId].collectNFT;
    }

    /// @inheritdoc ILensHub
    function getFollowModule(uint256 profileId) external view override returns (address) {
        return _profileById[profileId].followModule;
    }

    /// @inheritdoc ILensHub
    function getCollectModule(uint256 profileId, uint256 pubId)
        external
        view
        override
        returns (address)
    {
        return _pubByIdByProfile[profileId][pubId].collectModule;
    }

    /// @inheritdoc ILensHub
    function getReferenceModule(uint256 profileId, uint256 pubId)
        external
        view
        override
        returns (address)
    {
        return _pubByIdByProfile[profileId][pubId].referenceModule;
    }

    /// @inheritdoc ILensHub
    function getPubPointer(uint256 profileId, uint256 pubId)
        external
        view
        override
        returns (uint256, uint256)
    {
        uint256 profileIdPointed = _pubByIdByProfile[profileId][pubId].profileIdPointed;
        uint256 pubIdPointed = _pubByIdByProfile[profileId][pubId].pubIdPointed;
        return (profileIdPointed, pubIdPointed);
    }

    /// @inheritdoc ILensHub
    function getContentURI(uint256 profileId, uint256 pubId)
        external
        view
        override
        returns (string memory)
    {
        return GeneralLib.getContentURI(profileId, pubId);
    }

    /// @inheritdoc ILensHub
    function getProfile(uint256 profileId)
        external
        view
        override
        returns (DataTypes.ProfileStruct memory)
    {
        return _profileById[profileId];
    }

    /// @inheritdoc ILensHub
    function getPub(uint256 profileId, uint256 pubId)
        external
        view
        override
        returns (DataTypes.PublicationStruct memory)
    {
        return _pubByIdByProfile[profileId][pubId];
    }

    /// @inheritdoc ILensHub
    function getPubType(uint256 profileId, uint256 pubId)
        external
        view
        override
        returns (DataTypes.PubType)
    {
        if (pubId == 0 || _profileById[profileId].pubCount < pubId) {
            return DataTypes.PubType.Nonexistent;
        } else if (_pubByIdByProfile[profileId][pubId].collectModule == address(0)) {
            return DataTypes.PubType.Mirror;
        } else if (_pubByIdByProfile[profileId][pubId].profileIdPointed == 0) {
            return DataTypes.PubType.Post;
        } else {
            return DataTypes.PubType.Comment;
        }
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
     * @dev Overrides the LensNFTBase function to compute the domain separator in the GeneralLib.
     */
    function getDomainSeparator() external view override returns (bytes32) {
        return GeneralLib.getDomainSeparator();
    }

    /**
     * @dev Overrides the ERC721 tokenURI function to return the associated URI with a given profile.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address followNFT = _profileById[tokenId].followNFT;
        return
            ProfileTokenURILogic.getProfileTokenURI(
                tokenId,
                followNFT == address(0) ? 0 : IERC721Enumerable(followNFT).totalSupply(),
                ownerOf(tokenId),
                'Lens Profile',
                _profileById[tokenId].imageURI
            );
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _setGovernance(address newGovernance) internal {
        GeneralLib.setGovernance(newGovernance);
    }

    function _setDispatcher(uint256 profileId, address dispatcher) internal {
        _dispatcherByProfile[profileId] = dispatcher;
        emit Events.DispatcherSet(profileId, dispatcher, block.timestamp);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        if (_dispatcherByProfile[tokenId] != address(0)) {
            _setDispatcher(tokenId, address(0));
        }

        if (_defaultProfileByAddress[from] == tokenId) {
            _defaultProfileByAddress[from] = 0;
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _validateCallerIsProfileOwner(uint256 profileId) internal view {
        if (msg.sender != ownerOf(profileId)) revert Errors.NotProfileOwner();
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
