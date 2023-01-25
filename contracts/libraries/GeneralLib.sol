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
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            wallet,
            vars.delegatedSigner
        );
        MetaTxHelpers.baseSetDefaultProfileWithSig(signer, vars);
        _setDefaultProfile(wallet, profileId);
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
     * @notice Follows the given profiles, executing the necessary logic and module calls before minting the follow
     * NFT(s) to the follower.
     *
     * @param followerProfileId The profile the follow is being executed for.
     * @param idsOfProfilesToFollow The array of profile token IDs to follow.
     * @param followTokenIds The array of follow token IDs to use for each follow.
     * @param followModuleDatas The array of follow module data parameters to pass to each profile's follow module.
     *
     * @return uint256[] An array of integers representing the minted follow NFTs token IDs.
     */
    function follow(
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata followModuleDatas
    ) external returns (uint256[] memory) {
        GeneralHelpers.validateCallerIsOwnerOrDelegatedExecutor(followerProfileId);
        return
            InteractionHelpers.follow({
                followerProfileId: followerProfileId,
                executor: msg.sender,
                followerProfileOwner: GeneralHelpers.ownerOf(followerProfileId),
                idsOfProfilesToFollow: idsOfProfilesToFollow,
                followTokenIds: followTokenIds,
                followModuleDatas: followModuleDatas
            });
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
        address followerProfileOwner = GeneralHelpers.ownerOf(vars.followerProfileId);
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            followerProfileOwner,
            vars.delegatedSigner
        );
        MetaTxHelpers.baseFollowWithSig(signer, vars);
        return
            InteractionHelpers.follow({
                followerProfileId: vars.followerProfileId,
                executor: signer,
                followerProfileOwner: followerProfileOwner,
                idsOfProfilesToFollow: vars.idsOfProfilesToFollow,
                followTokenIds: vars.followTokenIds,
                followModuleDatas: vars.datas
            });
    }

    function unfollow(uint256 unfollowerProfileId, uint256[] calldata idsOfProfilesToUnfollow)
        external
    {
        return
            InteractionHelpers.unfollow(
                unfollowerProfileId,
                msg.sender,
                GeneralHelpers.ownerOf(unfollowerProfileId),
                idsOfProfilesToUnfollow
            );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `unfollowWithSig()` function.
     *
     * @param vars the UnfollowWithSigData struct containing the relevant parameters.
     */
    function unfollowWithSig(DataTypes.UnfollowWithSigData calldata vars) external {
        address unfollowerProfileOwner = GeneralHelpers.ownerOf(vars.unfollowerProfileId);
        address signer = vars.delegatedSigner == address(0)
            ? unfollowerProfileOwner
            : vars.delegatedSigner;
        MetaTxHelpers.baseUnfollowWithSig(signer, vars);
        return
            InteractionHelpers.unfollow(
                vars.unfollowerProfileId,
                signer,
                unfollowerProfileOwner,
                vars.idsOfProfilesToUnfollow
            );
    }

    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) external {
        GeneralHelpers.validateCallerIsOwnerOrDelegatedExecutor(byProfileId);
        InteractionHelpers.setBlockStatus(byProfileId, idsOfProfilesToSetBlockStatus, blockStatus);
    }

    function setBlockStatusWithSig(DataTypes.SetBlockStatusWithSigData calldata vars) external {
        address blockerProfileOwner = GeneralHelpers.ownerOf(vars.byProfileId);
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            blockerProfileOwner,
            vars.delegatedSigner
        );
        MetaTxHelpers.baseSetBlockStatusWithSig(signer, vars);
        InteractionHelpers.setBlockStatus(
            vars.byProfileId,
            vars.idsOfProfilesToSetBlockStatus,
            vars.blockStatus
        );
    }

    /**
     * @notice Collects the given publication, executing the necessary logic and module call before minting the
     * collect NFT to the collector.
     *
     * @param collectorProfileId The profile that collect is being executed for.
     * @param publisherProfileId The token ID of the publisher profile of the collected publication.
     * @param pubId The publication ID of the publication being collected.
     * @param collectModuleData The data to pass to the publication's collect module.
     * @param collectNFTImpl The address of the collect NFT implementation, which has to be passed because it's an immutable in the hub.
     *
     * @return uint256 An integer representing the minted token ID.
     */
    function collect(
        uint256 collectorProfileId,
        uint256 publisherProfileId,
        uint256 pubId,
        bytes calldata collectModuleData,
        address collectNFTImpl
    ) external returns (uint256) {
        return
            InteractionHelpers.collect({
                collectorProfileId: collectorProfileId,
                collectorProfileOwner: GeneralHelpers.ownerOf(collectorProfileId),
                transactionExecutor: msg.sender,
                publisherProfileId: publisherProfileId,
                pubId: pubId,
                collectModuleData: collectModuleData,
                collectNFTImpl: collectNFTImpl
            });
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
        address collectorProfileOwner = GeneralHelpers.ownerOf(vars.collectorProfileId);
        address transactionSigner = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            collectorProfileOwner,
            vars.delegatedSigner
        );
        MetaTxHelpers.baseCollectWithSig(transactionSigner, vars);
        return
            InteractionHelpers.collect({
                collectorProfileId: vars.collectorProfileId,
                collectorProfileOwner: collectorProfileOwner,
                transactionExecutor: transactionSigner,
                publisherProfileId: vars.publisherProfileId,
                pubId: vars.pubId,
                collectModuleData: vars.data,
                collectNFTImpl: collectNFTImpl
            });
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

    function _validateCallerIsOnBehalfOfOrExecutor(address onBehalfOf) private view {
        if (onBehalfOf != msg.sender)
            GeneralHelpers.validateDelegatedExecutor(onBehalfOf, msg.sender);
    }
}
