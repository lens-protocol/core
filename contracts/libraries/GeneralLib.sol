// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Helpers} from './Helpers.sol';
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {IReferenceModule} from '../interfaces/IReferenceModule.sol';

// TODO: Migrate governance/admin logic here. (incl events)

// TODO: Migrate complex storage here. (incl events)
/**
 * @title GeneralLib
 * @author Lens Protocol
 *
 * @notice This is the library that contains the logic for profile creation, publication, 
 * admin, and governance functionality.
 *
 * @dev The functions are external, so they are called from the hub via `delegateCall` under 
 * the hood. Furthermore, expected events are emitted from this library instead of from the
 * hub to alleviate code size concerns.
 */
library GeneralLib {
    uint256 constant PROTOCOL_STATE_SLOT = 12;
    uint256 constant PROFILE_CREATOR_WHITELIST_MAPPING_SLOT = 13;
    uint256 constant FOLLOW_MODULE_WHITELIST_MAPPING_SLOT = 14;
    uint256 constant COLLECT_MODULE_WHITELIST_MAPPING_SLOT = 15;
    uint256 constant REFERENCE_MODULE_WHITELIST_MAPPING_SLOT = 16;
    uint256 constant GOVERNANCE_SLOT = 23;
    uint256 constant EMERGENCY_ADMIN_SLOT = 24;

    /**
     * @notice Sets the governance address.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external {
        address prevGovernance;
        assembly {
            prevGovernance := sload(GOVERNANCE_SLOT)
            sstore(GOVERNANCE_SLOT, newGovernance)
        }
        emit Events.GovernanceSet(msg.sender, prevGovernance, newGovernance, block.timestamp);
    }

    /**
     * @notice Sets the emergency admin address.
     * 
     * @param newEmergencyAdmin The new governance address to set.
     */
    function setEmergencyAdmin(address newEmergencyAdmin) external {
        address prevEmergencyAdmin;
        assembly {
            prevEmergencyAdmin := sload(EMERGENCY_ADMIN_SLOT)
            sstore(EMERGENCY_ADMIN_SLOT, newEmergencyAdmin)
        }
        emit Events.EmergencyAdminSet(
            msg.sender,
            prevEmergencyAdmin,
            newEmergencyAdmin,
            block.timestamp
        );
    }

    /**
     * @notice Sets the protocol state.
     *
     * @param newState The new protocol state to set.
     *
     * Note: This does NOT validate the caller, and is only to be used for initialization.
     */
    function setStateSimple(DataTypes.ProtocolState newState) external {
        DataTypes.ProtocolState prevState;
        assembly {
            prevState := sload(PROTOCOL_STATE_SLOT)
            sstore(PROTOCOL_STATE_SLOT, newState)
        }
        emit Events.StateSet(msg.sender, prevState, newState, block.timestamp);
    }

    /**
     * @notice Sets the protocol state and validates the caller. The emergency admin can only
     * pause further (Unpaused => PublishingPaused => Paused). Whereas governance can set any
     * state. 
     *
     * @param newState The new protocol state to set.
     */
    function setStateFull(DataTypes.ProtocolState newState) external {
        address emergencyAdmin;
        address governance;
        DataTypes.ProtocolState prevState;
        assembly {
            emergencyAdmin := sload(EMERGENCY_ADMIN_SLOT)
            governance := sload(GOVERNANCE_SLOT)
            prevState := sload(PROTOCOL_STATE_SLOT)
            sstore(PROTOCOL_STATE_SLOT, newState)
        }
        if (msg.sender == emergencyAdmin) {
            if (newState == DataTypes.ProtocolState.Unpaused)
                revert Errors.EmergencyAdminCannotUnpause();
            if (prevState == DataTypes.ProtocolState.Paused) revert Errors.Paused();
        } else if (msg.sender != governance) {
            revert Errors.NotGovernanceOrEmergencyAdmin();
        }
        emit Events.StateSet(msg.sender, prevState, newState, block.timestamp);
    }

    /**
     * @notice Executes the logic to create a profile with the given parameters to the given address.
     *
     * @param vars The CreateProfileData struct containing the following parameters:
     *      to: The address receiving the profile.
     *      handle: The handle to set for the profile, must be unique and non-empty.
     *      imageURI: The URI to set for the profile image.
     *      followModule: The follow module to use, can be the zero address.
     *      followModuleInitData: The follow module initialization data, if any
     *      followNFTURI: The URI to set for the follow NFT.
     * @param profileId The profile ID to associate with this profile NFT (token ID).
     * @param _profileIdByHandleHash The storage reference to the mapping of profile IDs by handle hash.
     * @param _profileById The storage reference to the mapping of profile structs by IDs.
     */
    function createProfile(
        DataTypes.CreateProfileData calldata vars,
        uint256 profileId,
        mapping(bytes32 => uint256) storage _profileIdByHandleHash,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById
    ) external {
        _validateProfileCreatorWhitelisted();
        _validateHandle(vars.handle);

        if (bytes(vars.imageURI).length > Constants.MAX_PROFILE_IMAGE_URI_LENGTH)
            revert Errors.ProfileImageURILengthInvalid();

        bytes32 handleHash = keccak256(bytes(vars.handle));

        if (_profileIdByHandleHash[handleHash] != 0) revert Errors.HandleTaken();

        _profileIdByHandleHash[handleHash] = profileId;
        _profileById[profileId].handle = vars.handle;
        _profileById[profileId].imageURI = vars.imageURI;
        _profileById[profileId].followNFTURI = vars.followNFTURI;

        bytes memory followModuleReturnData;
        if (vars.followModule != address(0)) {
            _profileById[profileId].followModule = vars.followModule;
            followModuleReturnData = _initFollowModule(
                profileId,
                vars.followModule,
                vars.followModuleInitData
            );
        }

        _emitProfileCreated(profileId, vars, followModuleReturnData);
    }

    /**
     * @notice Sets the follow module for a given profile.
     *
     * @param profileId The profile ID to set the follow module for.
     * @param followModule The follow module to set for the given profile, if any.
     * @param followModuleInitData The data to pass to the follow module for profile initialization.
     * @param _profile The storage reference to the profile struct associated with the given profile ID.
     */
    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData,
        DataTypes.ProfileStruct storage _profile
    ) external {
        if (followModule != _profile.followModule) {
            _profile.followModule = followModule;
        }

        bytes memory followModuleReturnData;
        if (followModule != address(0))
            followModuleReturnData = _initFollowModule(
                profileId,
                followModule,
                followModuleInitData
            );
        emit Events.FollowModuleSet(
            profileId,
            followModule,
            followModuleReturnData,
            block.timestamp
        );
    }

    /**
     * @notice Creates a post publication mapped to the given profile.
     *
     * @dev To avoid a stack too deep error, reference parameters are passed in memory rather than calldata.
     *
     * @param profileId The profile ID to associate this publication to.
     * @param contentURI The URI to set for this publication.
     * @param collectModule The collect module to set for this publication.
     * @param collectModuleInitData The data to pass to the collect module for publication initialization.
     * @param referenceModule The reference module to set for this publication, if any.
     * @param referenceModuleInitData The data to pass to the reference module for publication initialization.
     * @param pubId The publication ID to associate with this publication.
     * @param _pubByIdByProfile The storage reference to the mapping of publications by publication ID by profile ID.
     */
    function createPost(
        uint256 profileId,
        string memory contentURI,
        address collectModule,
        bytes memory collectModuleInitData,
        address referenceModule,
        bytes memory referenceModuleInitData,
        uint256 pubId,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile //,
    ) external {
        _pubByIdByProfile[profileId][pubId].contentURI = contentURI;

        // Collect module initialization
        bytes memory collectModuleReturnData = _initPubCollectModule(
            profileId,
            pubId,
            collectModule,
            collectModuleInitData,
            _pubByIdByProfile
        );

        // Reference module initialization
        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            profileId,
            pubId,
            referenceModule,
            referenceModuleInitData,
            _pubByIdByProfile
        );

        emit Events.PostCreated(
            profileId,
            pubId,
            contentURI,
            collectModule,
            collectModuleReturnData,
            referenceModule,
            referenceModuleReturnData,
            block.timestamp
        );
    }

    /**
     * @notice Creates a comment publication mapped to the given profile.
     *
     * @dev This function is unique in that it requires many variables, so, unlike the other publishing functions,
     * we need to pass the full CommentData struct in memory to avoid a stack too deep error.
     *
     * @param vars The CommentData struct to use to create the comment.
     * @param pubId The publication ID to associate with this publication.
     * @param _profileById The storage reference to the mapping of profile structs by IDs.
     * @param _pubByIdByProfile The storage reference to the mapping of publications by publication ID by profile ID.
     */
    function createComment(
        DataTypes.CommentData memory vars,
        uint256 pubId,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile
    ) external {
        // Validate existence of the pointed publication
        uint256 pubCount = _profileById[vars.profileIdPointed].pubCount;
        if (pubCount < vars.pubIdPointed || vars.pubIdPointed == 0)
            revert Errors.PublicationDoesNotExist();

        // Ensure the pointed publication is not the comment being created
        if (vars.profileId == vars.profileIdPointed && vars.pubIdPointed == pubId)
            revert Errors.CannotCommentOnSelf();

        _pubByIdByProfile[vars.profileId][pubId].contentURI = vars.contentURI;
        _pubByIdByProfile[vars.profileId][pubId].profileIdPointed = vars.profileIdPointed;
        _pubByIdByProfile[vars.profileId][pubId].pubIdPointed = vars.pubIdPointed;

        // Collect Module Initialization
        bytes memory collectModuleReturnData = _initPubCollectModule(
            vars.profileId,
            pubId,
            vars.collectModule,
            vars.collectModuleInitData,
            _pubByIdByProfile
        );

        // Reference module initialization
        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            vars.profileId,
            pubId,
            vars.referenceModule,
            vars.referenceModuleInitData,
            _pubByIdByProfile
        );

        // Reference module validation
        address refModule = _pubByIdByProfile[vars.profileIdPointed][vars.pubIdPointed]
            .referenceModule;
        if (refModule != address(0)) {
            IReferenceModule(refModule).processComment(
                vars.profileId,
                vars.profileIdPointed,
                vars.pubIdPointed,
                vars.referenceModuleData
            );
        }

        // Prevents a stack too deep error
        _emitCommentCreated(vars, pubId, collectModuleReturnData, referenceModuleReturnData);
    }

    /**
     * @notice Creates a mirror publication mapped to the given profile.
     *
     * @param vars The MirrorData struct to use to create the mirror.
     * @param pubId The publication ID to associate with this publication.
     * @param _pubByIdByProfile The storage reference to the mapping of publications by publication ID by profile ID.
     * param _referenceModuleWhitelisted The storage reference to the mapping of whitelist status by reference module address.
     */
    function createMirror(
        DataTypes.MirrorData memory vars,
        uint256 pubId,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile
    ) external {
        (uint256 rootProfileIdPointed, uint256 rootPubIdPointed, ) = Helpers.getPointedIfMirror(
            vars.profileIdPointed,
            vars.pubIdPointed,
            _pubByIdByProfile
        );

        _pubByIdByProfile[vars.profileId][pubId].profileIdPointed = rootProfileIdPointed;
        _pubByIdByProfile[vars.profileId][pubId].pubIdPointed = rootPubIdPointed;

        // Reference module initialization
        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            vars.profileId,
            pubId,
            vars.referenceModule,
            vars.referenceModuleInitData,
            _pubByIdByProfile
        );

        // Reference module validation
        address refModule = _pubByIdByProfile[rootProfileIdPointed][rootPubIdPointed]
            .referenceModule;
        if (refModule != address(0)) {
            IReferenceModule(refModule).processMirror(
                vars.profileId,
                rootProfileIdPointed,
                rootPubIdPointed,
                vars.referenceModuleData
            );
        }

        emit Events.MirrorCreated(
            vars.profileId,
            pubId,
            rootProfileIdPointed,
            rootPubIdPointed,
            vars.referenceModuleData,
            vars.referenceModule,
            referenceModuleReturnData,
            block.timestamp
        );
    }

    function _initFollowModule(
        uint256 profileId,
        address followModule,
        bytes memory followModuleInitData
    ) private returns (bytes memory) {
        _validateFollowModuleWhitelisted(followModule);
        return IFollowModule(followModule).initializeFollowModule(profileId, followModuleInitData);
    }

    function _initPubCollectModule(
        uint256 profileId,
        uint256 pubId,
        address collectModule,
        bytes memory collectModuleInitData,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile
    ) private returns (bytes memory) {
        _validateCollectModuleWhitelisted(collectModule);
        _pubByIdByProfile[profileId][pubId].collectModule = collectModule;
        return
            ICollectModule(collectModule).initializePublicationCollectModule(
                profileId,
                pubId,
                collectModuleInitData
            );
    }

    function _initPubReferenceModule(
        uint256 profileId,
        uint256 pubId,
        address referenceModule,
        bytes memory referenceModuleInitData,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile
    ) private returns (bytes memory) {
        if (referenceModule == address(0)) return new bytes(0);
        _validateReferenceModuleWhitelisted(referenceModule);
        _pubByIdByProfile[profileId][pubId].referenceModule = referenceModule;
        return
            IReferenceModule(referenceModule).initializeReferenceModule(
                profileId,
                pubId,
                referenceModuleInitData
            );
    }

    function _validateProfileCreatorWhitelisted() private view {
        bool whitelisted;
        assembly {
            mstore(0, caller())
            mstore(32, PROFILE_CREATOR_WHITELIST_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            whitelisted := sload(slot)
        }
        if (!whitelisted) revert Errors.ProfileCreatorNotWhitelisted();
    }

    function _validateFollowModuleWhitelisted(address followModule) private view {
        bool whitelist;
        assembly {
            mstore(0, followModule)
            mstore(32, FOLLOW_MODULE_WHITELIST_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            whitelist := sload(slot)
        }
        if (!whitelist) revert Errors.FollowModuleNotWhitelisted();
    }

    function _validateCollectModuleWhitelisted(address collectModule) private view {
        bool whitelisted;
        assembly {
            mstore(0, collectModule)
            mstore(32, COLLECT_MODULE_WHITELIST_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            whitelisted := sload(slot)
        }
        if (!whitelisted) revert Errors.CollectModuleNotWhitelisted();
    }

    function _validateReferenceModuleWhitelisted(address referenceModule) private view {
        bool whitelisted;
        assembly {
            mstore(0, referenceModule)
            mstore(32, REFERENCE_MODULE_WHITELIST_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            whitelisted := sload(slot)
        }
        if (!whitelisted) revert Errors.ReferenceModuleNotWhitelisted();
    }

    function _emitCommentCreated(
        DataTypes.CommentData memory vars,
        uint256 pubId,
        bytes memory collectModuleReturnData,
        bytes memory referenceModuleReturnData
    ) private {
        emit Events.CommentCreated(
            vars.profileId,
            pubId,
            vars.contentURI,
            vars.profileIdPointed,
            vars.pubIdPointed,
            vars.referenceModuleData,
            vars.collectModule,
            collectModuleReturnData,
            vars.referenceModule,
            referenceModuleReturnData,
            block.timestamp
        );
    }

    function _emitProfileCreated(
        uint256 profileId,
        DataTypes.CreateProfileData calldata vars,
        bytes memory followModuleReturnData
    ) internal {
        emit Events.ProfileCreated(
            profileId,
            msg.sender, // Creator is always the msg sender
            vars.to,
            vars.handle,
            vars.imageURI,
            vars.followModule,
            followModuleReturnData,
            vars.followNFTURI,
            block.timestamp
        );
    }

    function _validateHandle(string calldata handle) private pure {
        bytes memory byteHandle = bytes(handle);
        if (byteHandle.length == 0 || byteHandle.length > Constants.MAX_HANDLE_LENGTH)
            revert Errors.HandleLengthInvalid();

        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            if (
                (byteHandle[i] < '0' ||
                    byteHandle[i] > 'z' ||
                    (byteHandle[i] > '9' && byteHandle[i] < 'a')) &&
                byteHandle[i] != '.' &&
                byteHandle[i] != '-' &&
                byteHandle[i] != '_'
            ) revert Errors.HandleContainsInvalidCharacters();
            unchecked {
                ++i;
            }
        }
    }
}
