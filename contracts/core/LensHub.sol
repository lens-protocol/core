// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {ILensHub} from '../interfaces/ILensHub.sol';
import {Events} from '../libraries/Events.sol';
import {Helpers} from '../libraries/Helpers.sol';
import {Constants} from '../libraries/Constants.sol';
import {DataTypes} from '../libraries/DataTypes.sol';
import {Errors} from '../libraries/Errors.sol';
import {PublishingLogic} from '../libraries/PublishingLogic.sol';
import {ProfileTokenURILogic} from '../libraries/ProfileTokenURILogic.sol';
import {InteractionLogic} from '../libraries/InteractionLogic.sol';
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
        _setState(DataTypes.ProtocolState.Paused);
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
        address prevEmergencyAdmin = _emergencyAdmin;
        _emergencyAdmin = newEmergencyAdmin;
        emit Events.EmergencyAdminSet(
            msg.sender,
            prevEmergencyAdmin,
            newEmergencyAdmin,
            block.timestamp
        );
    }

    /// @inheritdoc ILensHub
    function setState(DataTypes.ProtocolState newState) external override {
        if (msg.sender == _emergencyAdmin) {
            if (newState == DataTypes.ProtocolState.Unpaused)
                revert Errors.EmergencyAdminCannotUnpause();
            _validateNotPaused();
        } else if (msg.sender != _governance) {
            revert Errors.NotGovernanceOrEmergencyAdmin();
        }
        _setState(newState);
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

    /// @inheritdoc ILensHub
    function createProfile(DataTypes.CreateProfileData calldata vars)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        if (!_profileCreatorWhitelisted[msg.sender]) revert Errors.ProfileCreatorNotWhitelisted();
        unchecked {
            uint256 profileId = ++_profileCounter;
            _mint(vars.to, profileId);
            PublishingLogic.createProfile(
                vars,
                profileId,
                _profileIdByHandleHash,
                _profileById,
                _followModuleWhitelisted
            );
            return profileId;
        }
    }

    /// @inheritdoc ILensHub
    function setDefaultProfile(uint256 profileId) external override whenNotPaused {
        _setDefaultProfile(msg.sender, profileId);
    }

    /// @inheritdoc ILensHub
    function setDefaultProfileWithSig(DataTypes.SetDefaultProfileWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_DEFAULT_PROFILE_WITH_SIG_TYPEHASH,
                            vars.wallet,
                            vars.profileId,
                            sigNonces[vars.wallet]++,
                            vars.sig.deadline
                        )
                    )
                ),
                vars.wallet,
                vars.sig
            );
            _setDefaultProfile(vars.wallet, vars.profileId);
        }
    }

    /// @inheritdoc ILensHub
    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData
    ) external override whenNotPaused {
        _validateCallerIsProfileOwner(profileId);
        PublishingLogic.setFollowModule(
            profileId,
            followModule,
            followModuleInitData,
            _profileById[profileId],
            _followModuleWhitelisted
        );
    }

    /// @inheritdoc ILensHub
    function setFollowModuleWithSig(DataTypes.SetFollowModuleWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        address owner = ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_FOLLOW_MODULE_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            vars.followModule,
                            keccak256(vars.followModuleInitData),
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
        PublishingLogic.setFollowModule(
            vars.profileId,
            vars.followModule,
            vars.followModuleInitData,
            _profileById[vars.profileId],
            _followModuleWhitelisted
        );
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
        address owner = ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_DISPATCHER_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            vars.dispatcher,
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
        _setDispatcher(vars.profileId, vars.dispatcher);
    }

    /// @inheritdoc ILensHub
    function setProfileImageURI(uint256 profileId, string calldata imageURI)
        external
        override
        whenNotPaused
    {
        _validateCallerIsProfileOwnerOrDispatcher(profileId);
        _setProfileImageURI(profileId, imageURI);
    }

    /// @inheritdoc ILensHub
    function setProfileImageURIWithSig(DataTypes.SetProfileImageURIWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        address owner = ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_PROFILE_IMAGE_URI_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            keccak256(bytes(vars.imageURI)),
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
        _setProfileImageURI(vars.profileId, vars.imageURI);
    }

    /// @inheritdoc ILensHub
    function setFollowNFTURI(uint256 profileId, string calldata followNFTURI)
        external
        override
        whenNotPaused
    {
        _validateCallerIsProfileOwnerOrDispatcher(profileId);
        _setFollowNFTURI(profileId, followNFTURI);
    }

    /// @inheritdoc ILensHub
    function setFollowNFTURIWithSig(DataTypes.SetFollowNFTURIWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        address owner = ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_FOLLOW_NFT_URI_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            keccak256(bytes(vars.followNFTURI)),
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
        _setFollowNFTURI(vars.profileId, vars.followNFTURI);
    }

    /// @inheritdoc ILensHub
    function post(DataTypes.PostData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        _validateCallerIsProfileOwnerOrDispatcher(vars.profileId);
        return
            _createPost(
                vars.profileId,
                vars.contentURI,
                vars.collectModule,
                vars.collectModuleInitData,
                vars.referenceModule,
                vars.referenceModuleInitData
            );
    }

    /// @inheritdoc ILensHub
    function postWithSig(DataTypes.PostWithSigData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        address owner = ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            POST_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            keccak256(bytes(vars.contentURI)),
                            vars.collectModule,
                            keccak256(vars.collectModuleInitData),
                            vars.referenceModule,
                            keccak256(vars.referenceModuleInitData),
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
        return
            _createPost(
                vars.profileId,
                vars.contentURI,
                vars.collectModule,
                vars.collectModuleInitData,
                vars.referenceModule,
                vars.referenceModuleInitData
            );
    }

    /// @inheritdoc ILensHub
    function comment(DataTypes.CommentData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        _validateCallerIsProfileOwnerOrDispatcher(vars.profileId);
        return _createComment(vars);
    }

    /// @inheritdoc ILensHub
    function commentWithSig(DataTypes.CommentWithSigData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        address owner = ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            COMMENT_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            keccak256(bytes(vars.contentURI)),
                            vars.profileIdPointed,
                            vars.pubIdPointed,
                            keccak256(vars.referenceModuleData),
                            vars.collectModule,
                            keccak256(vars.collectModuleInitData),
                            vars.referenceModule,
                            keccak256(vars.referenceModuleInitData),
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
        return
            _createComment(
                DataTypes.CommentData(
                    vars.profileId,
                    vars.contentURI,
                    vars.profileIdPointed,
                    vars.pubIdPointed,
                    vars.referenceModuleData,
                    vars.collectModule,
                    vars.collectModuleInitData,
                    vars.referenceModule,
                    vars.referenceModuleInitData
                )
            );
    }

    /// @inheritdoc ILensHub
    function mirror(DataTypes.MirrorData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        _validateCallerIsProfileOwnerOrDispatcher(vars.profileId);
        return _createMirror(vars);
    }

    /// @inheritdoc ILensHub
    function mirrorWithSig(DataTypes.MirrorWithSigData calldata vars)
        external
        override
        whenPublishingEnabled
        returns (uint256)
    {
        address owner = ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            MIRROR_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            vars.profileIdPointed,
                            vars.pubIdPointed,
                            keccak256(vars.referenceModuleData),
                            vars.referenceModule,
                            keccak256(vars.referenceModuleInitData),
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
        return
            _createMirror(
                DataTypes.MirrorData(
                    vars.profileId,
                    vars.profileIdPointed,
                    vars.pubIdPointed,
                    vars.referenceModuleData,
                    vars.referenceModule,
                    vars.referenceModuleInitData
                )
            );
    }

    /**
     * @notice Burns a profile, this maintains the profile data struct, but deletes the
     * handle hash to profile ID mapping value.
     *
     * NOTE: This overrides the LensNFTBase contract's `burn()` function and calls it to fully burn
     * the NFT.
     */
    function burn(uint256 tokenId) public override whenNotPaused {
        super.burn(tokenId);
        _clearHandleHash(tokenId);
    }

    /**
     * @notice Burns a profile with a signature, this maintains the profile data struct, but deletes the
     * handle hash to profile ID mapping value.
     *
     * NOTE: This overrides the LensNFTBase contract's `burnWithSig()` function and calls it to fully burn
     * the NFT.
     */
    function burnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig)
        public
        override
        whenNotPaused
    {
        super.burnWithSig(tokenId, sig);
        _clearHandleHash(tokenId);
    }

    /// ***************************************
    /// *****PROFILE INTERACTION FUNCTIONS*****
    /// ***************************************

    /// @inheritdoc ILensHub
    function follow(uint256[] calldata profileIds, bytes[] calldata datas)
        external
        override
        whenNotPaused
        returns (uint256[] memory)
    {
        return
            InteractionLogic.follow(
                msg.sender,
                profileIds,
                datas,
                _profileById,
                _profileIdByHandleHash
            );
    }

    /// @inheritdoc ILensHub
    function followWithSig(DataTypes.FollowWithSigData calldata vars)
        external
        override
        whenNotPaused
        returns (uint256[] memory)
    {
        uint256 dataLength = vars.datas.length;
        bytes32[] memory dataHashes = new bytes32[](dataLength);
        for (uint256 i = 0; i < dataLength; ) {
            dataHashes[i] = keccak256(vars.datas[i]);
            unchecked {
                ++i;
            }
        }
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            FOLLOW_WITH_SIG_TYPEHASH,
                            keccak256(abi.encodePacked(vars.profileIds)),
                            keccak256(abi.encodePacked(dataHashes)),
                            sigNonces[vars.follower]++,
                            vars.sig.deadline
                        )
                    )
                ),
                vars.follower,
                vars.sig
            );
        }
        return
            InteractionLogic.follow(
                vars.follower,
                vars.profileIds,
                vars.datas,
                _profileById,
                _profileIdByHandleHash
            );
    }

    /// @inheritdoc ILensHub
    function collect(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external override whenNotPaused returns (uint256) {
        return
            InteractionLogic.collect(
                msg.sender,
                profileId,
                pubId,
                data,
                COLLECT_NFT_IMPL,
                _pubByIdByProfile,
                _profileById
            );
    }

    /// @inheritdoc ILensHub
    function collectWithSig(DataTypes.CollectWithSigData calldata vars)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            COLLECT_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            vars.pubId,
                            keccak256(vars.data),
                            sigNonces[vars.collector]++,
                            vars.sig.deadline
                        )
                    )
                ),
                vars.collector,
                vars.sig
            );
        }
        return
            InteractionLogic.collect(
                vars.collector,
                vars.profileId,
                vars.pubId,
                vars.data,
                COLLECT_NFT_IMPL,
                _pubByIdByProfile,
                _profileById
            );
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

    /// *********************************
    /// *****EXTERNAL VIEW FUNCTIONS*****
    /// *********************************

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
    function defaultProfile(address wallet) external view override returns (uint256) {
        return _defaultProfileByAddress[wallet];
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
    function getDispatcher(uint256 profileId) external view override returns (address) {
        return _dispatcherByProfile[profileId];
    }

    /// @inheritdoc ILensHub
    function getPubCount(uint256 profileId) external view override returns (uint256) {
        return _profileById[profileId].pubCount;
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
    function getHandle(uint256 profileId) external view override returns (string memory) {
        return _profileById[profileId].handle;
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
        (uint256 rootProfileId, uint256 rootPubId, ) = Helpers.getPointedIfMirror(
            profileId,
            pubId,
            _pubByIdByProfile
        );
        return _pubByIdByProfile[rootProfileId][rootPubId].contentURI;
    }

    /// @inheritdoc ILensHub
    function getProfileIdByHandle(string calldata handle) external view override returns (uint256) {
        bytes32 handleHash = keccak256(bytes(handle));
        return _profileIdByHandleHash[handleHash];
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
                _profileById[tokenId].handle,
                _profileById[tokenId].imageURI
            );
    }

    /// @inheritdoc ILensHub
    function getFollowNFTImpl() external view override returns (address) {
        return FOLLOW_NFT_IMPL;
    }

    /// @inheritdoc ILensHub
    function getCollectNFTImpl() external view override returns (address) {
        return COLLECT_NFT_IMPL;
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.GovernanceSet(msg.sender, prevGovernance, newGovernance, block.timestamp);
    }

    function _createPost(
        uint256 profileId,
        string memory contentURI,
        address collectModule,
        bytes memory collectModuleData,
        address referenceModule,
        bytes memory referenceModuleData
    ) internal returns (uint256) {
        unchecked {
            uint256 pubId = ++_profileById[profileId].pubCount;
            PublishingLogic.createPost(
                profileId,
                contentURI,
                collectModule,
                collectModuleData,
                referenceModule,
                referenceModuleData,
                pubId,
                _pubByIdByProfile,
                _collectModuleWhitelisted,
                _referenceModuleWhitelisted
            );
            return pubId;
        }
    }

    /*
     * If the profile ID is zero, this is the equivalent of "unsetting" a default profile.
     * Note that the wallet address should either be the message sender or validated via a signature
     * prior to this function call.
     */
    function _setDefaultProfile(address wallet, uint256 profileId) internal {
        if (profileId > 0 && wallet != ownerOf(profileId)) revert Errors.NotProfileOwner();

        _defaultProfileByAddress[wallet] = profileId;

        emit Events.DefaultProfileSet(wallet, profileId, block.timestamp);
    }

    function _createComment(DataTypes.CommentData memory vars) internal returns (uint256) {
        unchecked {
            uint256 pubId = ++_profileById[vars.profileId].pubCount;
            PublishingLogic.createComment(
                vars,
                pubId,
                _profileById,
                _pubByIdByProfile,
                _collectModuleWhitelisted,
                _referenceModuleWhitelisted
            );
            return pubId;
        }
    }

    function _createMirror(DataTypes.MirrorData memory vars) internal returns (uint256) {
        unchecked {
            uint256 pubId = ++_profileById[vars.profileId].pubCount;
            PublishingLogic.createMirror(
                vars,
                pubId,
                _pubByIdByProfile,
                _referenceModuleWhitelisted
            );
            return pubId;
        }
    }

    function _setDispatcher(uint256 profileId, address dispatcher) internal {
        _dispatcherByProfile[profileId] = dispatcher;
        emit Events.DispatcherSet(profileId, dispatcher, block.timestamp);
    }

    function _setProfileImageURI(uint256 profileId, string calldata imageURI) internal {
        if (bytes(imageURI).length > Constants.MAX_PROFILE_IMAGE_URI_LENGTH)
            revert Errors.ProfileImageURILengthInvalid();
        _profileById[profileId].imageURI = imageURI;
        emit Events.ProfileImageURISet(profileId, imageURI, block.timestamp);
    }

    function _setFollowNFTURI(uint256 profileId, string calldata followNFTURI) internal {
        _profileById[profileId].followNFTURI = followNFTURI;
        emit Events.FollowNFTURISet(profileId, followNFTURI, block.timestamp);
    }

    function _clearHandleHash(uint256 profileId) internal {
        bytes32 handleHash = keccak256(bytes(_profileById[profileId].handle));
        _profileIdByHandleHash[handleHash] = 0;
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

    function _validateCallerIsProfileOwnerOrDispatcher(uint256 profileId) internal view {
        if (msg.sender == ownerOf(profileId) || msg.sender == _dispatcherByProfile[profileId]) {
            return;
        }
        revert Errors.NotProfileOwnerOrDispatcher();
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
