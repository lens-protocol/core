// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {GeneralHelpers} from './helpers/GeneralHelpers.sol';
import {MetaTxHelpers} from './helpers/MetaTxHelpers.sol';
import {InteractionHelpers} from './helpers/InteractionHelpers.sol';
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {IReferenceModule} from '../interfaces/IReferenceModule.sol';
import {IDeprecatedFollowModule} from '../interfaces/IDeprecatedFollowModule.sol';
import {IDeprecatedCollectModule} from '../interfaces/IDeprecatedCollectModule.sol';
import {IDeprecatedReferenceModule} from '../interfaces/IDeprecatedReferenceModule.sol';

import './Constants.sol';

/**
 * @title GeneralLib
 * @author Lens Protocol
 *
 * @notice This is the library that contains logic to be called by the hub via `delegateCall`.
 *
 * Note: The setDispatcher non-signature function was not migrated as it was more space-efficient
 * to leave it in the hub.
 */
library GeneralLib {
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
     * @notice Sets the protocol state, only meant to be called at initialization since
     * this does nto validate the caller.
     *
     * @param newState The new protocol state to set.
     */
    function initState(DataTypes.ProtocolState newState) external {
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
    function setState(DataTypes.ProtocolState newState) external {
        address emergencyAdmin;
        address governance;
        DataTypes.ProtocolState prevState;

        // Load the emergency admin, governance and protocol state, then store the new protocol
        // state via assembly.
        assembly {
            emergencyAdmin := sload(EMERGENCY_ADMIN_SLOT)
            governance := sload(GOVERNANCE_SLOT)
            prevState := sload(PROTOCOL_STATE_SLOT)
            sstore(PROTOCOL_STATE_SLOT, newState)
        }

        // If the sender is the emergency admin, prevent them from reducing restrictions.
        if (msg.sender == emergencyAdmin) {
            if (newState <= prevState) revert Errors.EmergencyAdminCanOnlyPauseFurther();
        } else if (msg.sender != governance) {
            revert Errors.NotGovernanceOrEmergencyAdmin();
        }
        emit Events.StateSet(msg.sender, prevState, newState, block.timestamp);
    }

    /**
     * @notice Creates a profile with the given parameters to the given address. Minting happens
     * in the hub.
     *
     * @param vars The CreateProfileData struct containing the following parameters:
     *      to: The address receiving the profile.
     *      handle: The handle to set for the profile, must be unique and non-empty.
     *      imageURI: The URI to set for the profile image.
     *      followModule: The follow module to use, can be the zero address.
     *      followModuleInitData: The follow module initialization data, if any
     *      followNFTURI: The URI to set for the follow NFT.
     * @param profileId The profile ID to associate with this profile NFT (token ID).
     */
    function createProfile(DataTypes.CreateProfileData calldata vars, uint256 profileId) external {
        _validateProfileCreatorWhitelisted();
        _validateHandle(vars.handle);

        if (bytes(vars.imageURI).length > MAX_PROFILE_IMAGE_URI_LENGTH)
            revert Errors.ProfileImageURILengthInvalid();

        bytes32 handleHash = keccak256(bytes(vars.handle));
        uint256 resolvedProfileId;
        uint256 handleHashSlot;

        // Load the profile ID the passed handle's hash resolves to, if it is non-zero, revert.
        assembly {
            mstore(0, handleHash)
            mstore(32, PROFILE_ID_BY_HANDLE_HASH_MAPPING_SLOT)
            handleHashSlot := keccak256(0, 64)
            resolvedProfileId := sload(handleHashSlot)
        }
        if (resolvedProfileId != 0) revert Errors.HandleTaken();

        // Store the profile ID so that the handle's hash now resolves to it.
        assembly {
            sstore(handleHashSlot, profileId)
        }

        _setProfileString(profileId, PROFILE_HANDLE_OFFSET, vars.handle);
        _setProfileString(profileId, PROFILE_IMAGE_URI_OFFSET, vars.imageURI);
        _setProfileString(profileId, PROFILE_FOLLOW_NFT_URI_OFFSET, vars.followNFTURI);

        bytes memory followModuleReturnData;
        if (vars.followModule != address(0)) {
            // Load the follow module to be used in the next assembly block.
            address followModule = vars.followModule;

            // Store the follow module for the new profile. We opt not to use the
            // _setFollowModule() private function to avoid unnecessary checks.
            assembly {
                mstore(0, profileId)
                mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
                let slot := add(keccak256(0, 64), PROFILE_FOLLOW_MODULE_OFFSET)
                sstore(slot, followModule)
            }

            // @note We don't need to check for deprecated modules here because deprecated modules
            // are no longer whitelisted.
            // Initialize the follow module.
            followModuleReturnData = _initFollowModule(
                profileId,
                vars.to,
                vars.followModule,
                vars.followModuleInitData
            );
        }
        emit Events.ProfileCreated(
            profileId,
            msg.sender,
            vars.to,
            vars.handle,
            vars.imageURI,
            vars.followModule,
            followModuleReturnData,
            vars.followNFTURI,
            block.timestamp
        );
    }

    /**
     * @notice Sets the default profile for a given wallet.
     *
     * @param onBehalfOf The wallet to set the default profile for.
     * @param profileId The profile ID to set.
     */
    function setDefaultProfile(address onBehalfOf, uint256 profileId) external {
        _validateCallerIsOnBehalfOfOrExecutor(onBehalfOf);
        _setDefaultProfile(onBehalfOf, profileId);
    }

    /**
     * @notice Sets the default profile via signature for a given owner.
     *
     * @param vars the SetDefaultProfileWithSigData struct containing the relevant parameters.
     */
    function setDefaultProfileWithSig(DataTypes.SetDefaultProfileWithSigData calldata vars)
        external
    {
        uint256 profileId = vars.profileId;
        address wallet = vars.wallet;
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(wallet, vars.delegatedSigner);
        MetaTxHelpers.baseSetDefaultProfileWithSig(signer, vars);
        _setDefaultProfile(wallet, profileId);
    }

    function setProfileMetadataURI(uint256 profileId, string calldata metadataURI) external {
        GeneralHelpers.validateCallerIsOwnerOrDispatcherOrExecutor(profileId);
        _setProfileMetadataURI(profileId, metadataURI);
    }

    function setProfileMetadataURIWithSig(DataTypes.SetProfileMetadataURIWithSigData calldata vars)
        external
    {
        uint256 profileId = vars.profileId;
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            GeneralHelpers.unsafeOwnerOf(profileId),
            vars.delegatedSigner
        );
        MetaTxHelpers.baseSetProfileMetadataURIWithSig(signer, vars);
        _setProfileMetadataURI(vars.profileId, vars.metadataURI);
    }

    /**
     * @notice Sets the follow module for a given profile.
     *
     * @param profileId The profile ID to set the follow module for.
     * @param followModule The follow module to set for the given profile, if any.
     * @param followModuleInitData The data to pass to the follow module for profile initialization.
     */
    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData
    ) external {
        GeneralHelpers.validateCallerIsOwnerOrDispatcherOrExecutor(profileId);
        _setFollowModule(profileId, msg.sender, followModule, followModuleInitData);
    }

    /**
     * @notice sets the follow module via signature for a given profile.
     *
     * @param vars the SetFollowModuleWithSigData struct containing the relevant parameters.
     */
    function setFollowModuleWithSig(DataTypes.SetFollowModuleWithSigData calldata vars) external {
        uint256 profileId = vars.profileId;
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            GeneralHelpers.unsafeOwnerOf(profileId),
            vars.delegatedSigner
        );
        MetaTxHelpers.baseSetFollowModuleWithSig(signer, vars);
        _setFollowModule(vars.profileId, signer, vars.followModule, vars.followModuleInitData);
    }

    /**
     * @notice Sets the dispatcher for a given profile via signature.
     *
     * @param vars the setDispatcherWithSigData struct containing the relevant parameters.
     */
    function setDispatcherWithSig(DataTypes.SetDispatcherWithSigData calldata vars) external {
        MetaTxHelpers.baseSetDispatcherWithSig(vars);
        uint256 profileId = vars.profileId;
        address dispatcher = vars.dispatcher;

        // Store the dispatcher in the appropriate slot for the given profile ID.
        assembly {
            mstore(0, profileId)
            mstore(32, DISPATCHER_BY_PROFILE_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            sstore(slot, dispatcher)
        }
        emit Events.DispatcherSet(profileId, dispatcher, block.timestamp);
    }

    function setDelegatedExecutorApproval(address executor, bool approved) external {
        _setDelegatedExecutorApproval(msg.sender, executor, approved);
    }

    function setDelegatedExecutorApprovalWithSig(
        DataTypes.SetDelegatedExecutorApprovalWithSigData calldata vars
    ) external {
        MetaTxHelpers.baseSetDelegatedExecutorApprovalWithSig(vars);
        _setDelegatedExecutorApproval(vars.onBehalfOf, vars.executor, vars.approved);
    }

    /**
     * @notice Sets the profile image URI for a given profile.
     * 
     * @param profileId The profile ID.
     * @param imageURI The image URI to set.

     */
    function setProfileImageURI(uint256 profileId, string calldata imageURI) external {
        GeneralHelpers.validateCallerIsOwnerOrDispatcherOrExecutor(profileId);
        _setProfileImageURI(profileId, imageURI);
    }

    /**
     * @notice Sets the profile image URI via signature for a given profile.
     *
     * @param vars the SetProfileImageURIWithSigData struct containing the relevant parameters.
     */
    function setProfileImageURIWithSig(DataTypes.SetProfileImageURIWithSigData calldata vars)
        external
    {
        uint256 profileId = vars.profileId;
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            GeneralHelpers.unsafeOwnerOf(profileId),
            vars.delegatedSigner
        );
        MetaTxHelpers.baseSetProfileImageURIWithSig(signer, vars);
        _setProfileImageURI(vars.profileId, vars.imageURI);
    }

    /**
     * @notice Sets the follow NFT URI for a given profile.
     *
     * @param profileId The profile ID.
     * @param followNFTURI The follow NFT URI to set.
     */
    function setFollowNFTURI(uint256 profileId, string calldata followNFTURI) external {
        GeneralHelpers.validateCallerIsOwnerOrDispatcherOrExecutor(profileId);
        _setFollowNFTURI(profileId, followNFTURI);
    }

    /**
     * @notice Sets the follow NFT URI via signature for a given profile.
     *
     * @param vars the SetFollowNFTURIWithSigData struct containing the relevant parameters.
     */
    function setFollowNFTURIWithSig(DataTypes.SetFollowNFTURIWithSigData calldata vars) external {
        uint256 profileId = vars.profileId;
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            GeneralHelpers.unsafeOwnerOf(profileId),
            vars.delegatedSigner
        );
        MetaTxHelpers.baseSetFollowNFTURIWithSig(signer, vars);
        _setFollowNFTURI(vars.profileId, vars.followNFTURI);
    }

    /**
     * @notice Follows the given profiles, executing the necessary logic and module calls before minting the follow
     * NFT(s) to the follower.
     *
     * @param onBehalfOf The address the follow is being executed for, different from the sender for delegated executors.
     * @param profileIds The array of profile token IDs to follow.
     * @param followModuleDatas The array of follow module data parameters to pass to each profile's follow module.
     *
     * @return uint256[] An array of integers representing the minted follow NFTs token IDs.
     */
    function follow(
        address onBehalfOf,
        uint256[] calldata profileIds,
        bytes[] calldata followModuleDatas
    ) external returns (uint256[] memory) {
        _validateCallerIsOnBehalfOfOrExecutor(onBehalfOf);
        return InteractionHelpers.follow(onBehalfOf, msg.sender, profileIds, followModuleDatas);
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `followWithSig()` function.
     *
     * @param vars the FollowWithSigData struct containing the relevant parameters.
     */
    function followWithSig(DataTypes.FollowWithSigData calldata vars)
        external
        returns (uint256[] memory)
    {
        address follower = vars.follower;
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(follower, vars.delegatedSigner);
        MetaTxHelpers.baseFollowWithSig(signer, vars);
        return InteractionHelpers.follow(follower, signer, vars.profileIds, vars.datas);
    }

    /**
     * @notice Collects the given publication, executing the necessary logic and module call before minting the
     * collect NFT to the collector.
     *
     * @param onBehalfOf The address the collect is being executed for, different from the sender for delegated executors.
     * @param profileId The token ID of the publication being collected's parent profile.
     * @param pubId The publication ID of the publication being collected.
     * @param collectModuleData The data to pass to the publication's collect module.
     * @param collectNFTImpl The address of the collect NFT implementation, which has to be passed because it's an immutable in the hub.
     *
     * @return uint256 An integer representing the minted token ID.
     */
    function collect(
        address onBehalfOf,
        uint256 profileId,
        uint256 pubId,
        bytes calldata collectModuleData,
        address collectNFTImpl
    ) external returns (uint256) {
        _validateCallerIsOnBehalfOfOrExecutor(onBehalfOf);
        return
            InteractionHelpers.collect(
                onBehalfOf,
                msg.sender,
                profileId,
                pubId,
                collectModuleData,
                collectNFTImpl
            );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `collectWithSig()` function.
     *
     * @param vars the CollectWithSigData struct containing the relevant parameters.
     */
    function collectWithSig(DataTypes.CollectWithSigData calldata vars, address collectNFTImpl)
        external
        returns (uint256)
    {
        address collector = vars.collector;
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(collector, vars.delegatedSigner);
        MetaTxHelpers.baseCollectWithSig(signer, vars);
        return
            InteractionHelpers.collect(
                collector,
                signer,
                vars.profileId,
                vars.pubId,
                vars.data,
                collectNFTImpl
            );
    }

    /**
     * @notice Approves an address to spend a token using via signature.
     *
     * @param spender The spender to approve.
     * @param tokenId The token ID to approve the spender for.
     * @param sig the EIP712Signature struct containing the token owner's signature.
     */
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external {
        // The `Approved()` event is emitted from `basePermit()`.
        MetaTxHelpers.basePermit(spender, tokenId, sig);

        // Store the approved address in the token's approval mapping slot.
        assembly {
            mstore(0, tokenId)
            mstore(32, TOKEN_APPROVAL_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            sstore(slot, spender)
        }
    }

    /**
     * @notice Approves a user to operate on all of an owner's tokens via signature.
     *
     * @param owner The owner to approve the operator for, this is the signer.
     * @param operator The operator to approve for the owner.
     * @param approved Whether or not the operator should be approved.
     * @param sig the EIP712Signature struct containing the token owner's signature.
     */
    function permitForAll(
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external {
        // The `ApprovedForAll()` event is emitted from `basePermitForAll()`.
        MetaTxHelpers.basePermitForAll(owner, operator, approved, sig);

        // Store whether the operator is approved in the appropriate mapping slot.
        assembly {
            mstore(0, owner)
            mstore(32, OPERATOR_APPROVAL_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, operator)
            let slot := keccak256(0, 64)
            sstore(slot, approved)
        }
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `burnWithSig()` function.
     *
     * @param tokenId The token ID to burn.
     * @param sig the EIP712Signature struct containing the token owner's signature.
     */
    function baseBurnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig) external {
        MetaTxHelpers.baseBurnWithSig(tokenId, sig);
    }

    /**
     * @notice Returns the domain separator.
     *
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32) {
        return MetaTxHelpers.getDomainSeparator();
    }

    function getContentURI(uint256 profileId, uint256 pubId) external view returns (string memory) {
        (uint256 rootProfileId, uint256 rootPubId) = GeneralHelpers.getPointedIfMirror(
            profileId,
            pubId
        );
        string memory ptr;
        assembly {
            // Load the free memory pointer, where we'll return the value
            ptr := mload(64)

            // Load the slot, which either contains the content URI + 2*length if length < 32 or
            // 2*length+1 if length >= 32, and the actual string starts at slot keccak256(slot)
            mstore(0, rootProfileId)
            mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, rootPubId)

            let slot := add(keccak256(0, 64), PUBLICATION_CONTENT_URI_OFFSET)

            let slotLoad := sload(slot)
            let size
            // Determine if the length > 32 by checking the lowest order bit, meaning the string
            // itself is stored at keccak256(slot)
            switch and(slotLoad, 1)
            case 0 {
                // The content URI is in the same slot
                // Determine the size by dividing the last byte's value by 2
                size := shr(1, and(slotLoad, 255))

                // Store the size in the first slot
                mstore(ptr, size)

                // Store the actual string in the second slot (without the size)
                mstore(add(ptr, 32), and(slotLoad, not(255)))
            }
            case 1 {
                // The content URI is not in the same slot
                // Determine the size by dividing the value in the whole slot minus 1 by 2
                size := shr(1, sub(slotLoad, 1))

                // Store the size in the first slot
                mstore(ptr, size)

                // Compute the total memory slots we need, this is (size + 31) / 32
                let totalMemorySlots := shr(5, add(size, 31))

                mstore(0, slot)
                let uriSlot := keccak256(0, 32)

                // Iterate through the words in memory and store the string word by word
                // prettier-ignore
                for { let i := 0 } lt(i, totalMemorySlots) { i := add(i, 1) } {
                    mstore(add(add(ptr, 32), mul(32, i)), sload(add(uriSlot, i)))
                }
            }
            // Store the new memory pointer in the free memory pointer slot
            mstore(64, add(add(ptr, 32), size))
        }
        return ptr;
    }

    function _setDefaultProfile(address wallet, uint256 profileId) private {
        if (profileId != 0 && wallet != GeneralHelpers.unsafeOwnerOf(profileId))
            revert Errors.NotProfileOwner();

        // Store the default profile in the appropriate slot for the given wallet.
        assembly {
            mstore(0, wallet)
            mstore(32, DEFAULT_PROFILE_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            sstore(slot, profileId)
        }
        emit Events.DefaultProfileSet(wallet, profileId, block.timestamp);
    }

    function _setProfileMetadataURI(uint256 profileId, string calldata metadataURI) private {
        assembly {
            let length := metadataURI.length
            let cdOffset := metadataURI.offset
            mstore(0, profileId)
            mstore(32, PROFILE_METADATA_MAPPING_SLOT)
            let slot := keccak256(0, 64)

            // If the length is greater than 31, storage rules are different.
            switch gt(length, 31)
            case 1 {
                // The length is > 31, so we need to store the actual string in a new slot,
                // equivalent to keccak256(startSlot), and store length*2+1 in startSlot.
                sstore(slot, add(shl(1, length), 1))

                // Calculate the amount of storage slots we need to store the full string.
                // This is equivalent to (string.length + 31)/32.
                let totalStorageSlots := shr(5, add(length, 31))

                // Compute the slot where the actual string will begin, which is the keccak256
                // hash of the slot where we stored the modified length.
                mstore(0, slot)
                slot := keccak256(0, 32)

                // Write the actual string to storage starting at the computed slot.
                // prettier-ignore
                for { let i := 0 } lt(i, totalStorageSlots) { i := add(i, 1) } {
                    sstore(add(slot, i), calldataload(add(cdOffset, mul(32, i))))
                }
            }
            default {
                // The length is <= 31 so store the string and the length*2 in the same slot.
                sstore(slot, or(calldataload(cdOffset), shl(1, length)))
            }
        }
    }

    function _setFollowModule(
        uint256 profileId,
        address executor,
        address followModule,
        bytes calldata followModuleInitData
    ) private {
        // Store the follow module in the appropriate slot for the given profile ID, but
        // only if it is not the same as the previous follow module.
        assembly {
            mstore(0, profileId)
            mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
            let slot := add(keccak256(0, 64), PROFILE_FOLLOW_MODULE_OFFSET)
            let currentFollowModule := sload(slot)
            if iszero(eq(followModule, currentFollowModule)) {
                sstore(slot, followModule)
            }
        }

        // Initialize the follow module if it is non-zero.
        bytes memory followModuleReturnData;
        if (followModule != address(0))
            followModuleReturnData = _initFollowModule(
                profileId,
                executor,
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

    function _setDelegatedExecutorApproval(
        address onBehalfOf,
        address executor,
        bool approved
    ) private {
        // Store the approval in the appropriate slot for the given caller and executor.
        assembly {
            mstore(0, onBehalfOf)
            mstore(32, DELEGATED_EXECUTOR_APPROVAL_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, executor)
            let slot := keccak256(0, 64)
            sstore(slot, approved)
        }
        emit Events.DelegatedExecutorApprovalSet(onBehalfOf, executor, approved);
    }

    function _setProfileImageURI(uint256 profileId, string calldata imageURI) private {
        if (bytes(imageURI).length > MAX_PROFILE_IMAGE_URI_LENGTH)
            revert Errors.ProfileImageURILengthInvalid();
        _setProfileString(profileId, PROFILE_IMAGE_URI_OFFSET, imageURI);
        emit Events.ProfileImageURISet(profileId, imageURI, block.timestamp);
    }

    function _setFollowNFTURI(uint256 profileId, string calldata followNFTURI) private {
        _setProfileString(profileId, PROFILE_FOLLOW_NFT_URI_OFFSET, followNFTURI);
        emit Events.FollowNFTURISet(profileId, followNFTURI, block.timestamp);
    }

    function _setProfileString(
        uint256 profileId,
        uint256 profileOffset,
        string calldata value
    ) private {
        assembly {
            let length := value.length
            let cdOffset := value.offset
            mstore(0, profileId)
            mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
            let slot := add(keccak256(0, 64), profileOffset)

            // If the length is greater than 31, storage rules are different.
            switch gt(length, 31)
            case 1 {
                // The length is > 31, so we need to store the actual string in a new slot,
                // equivalent to keccak256(startSlot), and store length*2+1 in startSlot.
                sstore(slot, add(shl(1, length), 1))

                // Calculate the amount of storage slots we need to store the full string.
                // This is equivalent to (string.length + 31)/32.
                let totalStorageSlots := shr(5, add(length, 31))

                // Compute the slot where the actual string will begin, which is the keccak256
                // hash of the slot where we stored the modified length.
                mstore(0, slot)
                slot := keccak256(0, 32)

                // Write the actual string to storage starting at the computed slot.
                // prettier-ignore
                for { let i := 0 } lt(i, totalStorageSlots) { i := add(i, 1) } {
                    sstore(add(slot, i), calldataload(add(cdOffset, mul(32, i))))
                }
            }
            default {
                // The length is <= 31 so store the string and the length*2 in the same slot.
                sstore(slot, or(calldataload(cdOffset), shl(1, length)))
            }
        }
    }

    function _initFollowModule(
        uint256 profileId,
        address executor,
        address followModule,
        bytes memory followModuleInitData
    ) private returns (bytes memory) {
        _validateFollowModuleWhitelisted(followModule);
        return
            IFollowModule(followModule).initializeFollowModule(
                profileId,
                executor,
                followModuleInitData
            );
    }

    function _validateCallerIsOnBehalfOfOrExecutor(address onBehalfOf) private view {
        if (onBehalfOf != msg.sender)
            GeneralHelpers.validateDelegatedExecutor(onBehalfOf, msg.sender);
    }

    function _validateProfileCreatorWhitelisted() private view {
        bool whitelisted;

        // Load whether the caller is whitelisted as a profile creator.
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

        // Load whether the given follow module is whitelisted.
        assembly {
            mstore(0, followModule)
            mstore(32, FOLLOW_MODULE_WHITELIST_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            whitelist := sload(slot)
        }
        if (!whitelist) revert Errors.FollowModuleNotWhitelisted();
    }

    function _validateHandle(string calldata handle) private pure {
        bytes memory byteHandle = bytes(handle);
        if (byteHandle.length == 0 || byteHandle.length > MAX_HANDLE_LENGTH)
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
