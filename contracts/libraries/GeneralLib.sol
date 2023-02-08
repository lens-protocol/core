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

    function changeDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        uint64 configNumber,
        address[] calldata executors,
        bool[] calldata approvals,
        bool switchToGivenConfig
    ) external {
        GeneralHelpers.validateAddressIsProfileOwner(msg.sender, delegatorProfileId);
        _changeDelegatedExecutorsConfig(
            delegatorProfileId,
            configNumber,
            executors,
            approvals,
            switchToGivenConfig
        );
    }

    function changeDelegatedExecutorsConfigWithSig(
        DataTypes.ChangeDelegatedExecutorsConfigWithSigData calldata vars
    ) external {
        MetaTxHelpers.baseChangeDelegatedExecutorsConfigWithSig(vars);
        _changeDelegatedExecutorsConfig(
            vars.delegatorProfileId,
            vars.configNumber,
            vars.executors,
            vars.approvals,
            vars.switchToGivenConfig
        );
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
        GeneralHelpers.validateAddressIsProfileOwnerOrDelegatedExecutor(
            msg.sender,
            followerProfileId
        );
        return
            InteractionHelpers.follow({
                followerProfileId: followerProfileId,
                executor: msg.sender,
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
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            vars.followerProfileId,
            vars.delegatedSigner
        );
        MetaTxHelpers.baseFollowWithSig(signer, vars);
        return
            InteractionHelpers.follow({
                followerProfileId: vars.followerProfileId,
                executor: signer,
                idsOfProfilesToFollow: vars.idsOfProfilesToFollow,
                followTokenIds: vars.followTokenIds,
                followModuleDatas: vars.datas
            });
    }

    function unfollow(uint256 unfollowerProfileId, uint256[] calldata idsOfProfilesToUnfollow)
        external
    {
        GeneralHelpers.validateAddressIsProfileOwnerOrDelegatedExecutor(
            msg.sender,
            unfollowerProfileId
        );
        return
            InteractionHelpers.unfollow({
                unfollowerProfileId: unfollowerProfileId,
                executor: msg.sender,
                idsOfProfilesToUnfollow: idsOfProfilesToUnfollow
            });
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `unfollowWithSig()` function.
     *
     * @param vars the UnfollowWithSigData struct containing the relevant parameters.
     */
    function unfollowWithSig(DataTypes.UnfollowWithSigData calldata vars) external {
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            vars.unfollowerProfileId,
            vars.delegatedSigner
        );
        MetaTxHelpers.baseUnfollowWithSig(signer, vars);
        return
            InteractionHelpers.unfollow({
                unfollowerProfileId: vars.unfollowerProfileId,
                executor: signer,
                idsOfProfilesToUnfollow: vars.idsOfProfilesToUnfollow
            });
    }

    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) external {
        GeneralHelpers.validateAddressIsProfileOwnerOrDelegatedExecutor(msg.sender, byProfileId);
        InteractionHelpers.setBlockStatus(byProfileId, idsOfProfilesToSetBlockStatus, blockStatus);
    }

    function setBlockStatusWithSig(DataTypes.SetBlockStatusWithSigData calldata vars) external {
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            vars.byProfileId,
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
        address transactionSigner = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            vars.collectorProfileId,
            vars.delegatedSigner
        );
        MetaTxHelpers.baseCollectWithSig(transactionSigner, vars);
        return
            InteractionHelpers.collect({
                collectorProfileId: vars.collectorProfileId,
                collectorProfileOwner: GeneralHelpers.ownerOf(vars.collectorProfileId),
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

    function _changeDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        uint64 configNumber,
        address[] calldata executors,
        bool[] calldata approvals,
        bool switchToGivenConfig
    ) private {
        DataTypes.DelegatedExecutorsConfig storage _delegatedExecutorsConfig = GeneralHelpers
            .getDelegatedExecutorsConfig(delegatorProfileId);
        uint64 configNumberToUse;
        bool configSwitched;
        if (configNumber == 0) {
            (configNumberToUse, configSwitched) = _prepareStorageToApplyChangesUnderCurrentConfig(
                _delegatedExecutorsConfig,
                configNumber,
                switchToGivenConfig
            );
        } else {
            (configNumberToUse, configSwitched) = _prepareStorageToApplyChangesUnderGivenConfig(
                _delegatedExecutorsConfig,
                configNumber,
                switchToGivenConfig
            );
        }
        uint256 i;
        while (i < executors.length) {
            _delegatedExecutorsConfig.isApproved[configNumberToUse][executors[i]] = approvals[i];
            unchecked {
                ++i;
            }
        }
        emit Events.DelegatedExecutorsConfigChanged(
            delegatorProfileId,
            configNumberToUse,
            executors,
            approvals,
            configSwitched
        );
    }

    /**
     * @param _delegatedExecutorsConfig The delegated executor configuration to prepare for changes.
     * @param configNumber The number of the configuration where the executor approval state is being set. Zero used as
     * an alias for the current configuration number.
     * @param switchToGivenConfig A boolean indicanting if the configuration will be switched to the one with the given
     * number. If the configuration number given is zero, this boolean will be ignored as it refers to the current one.
     *
     * @return (uint64, bool) A tuple that represents (uint64 configNumberToUse, bool configSwitched).
     */
    function _prepareStorageToApplyChangesUnderCurrentConfig(
        DataTypes.DelegatedExecutorsConfig storage _delegatedExecutorsConfig,
        uint64 configNumber,
        bool switchToGivenConfig
    ) private returns (uint64, bool) {
        bool configSwitched;
        uint64 configNumberToUse = _delegatedExecutorsConfig.configNumber;
        if (configNumberToUse == 0) {
            // First time setting the configuration and the user expects them to be applied under current one.
            // However, there is no configuration number chosen yet, so we default to 1 and switch to it.
            // This is equivalent to `configNumber = 1` and `switchToGivenConfig = true`.
            // If the user wants to prepare the configuration 1 but not switch to it, he will need to pass
            // `configNumber = 1` and `switchToGivenConfig = false`.
            _delegatedExecutorsConfig.configNumber = FIRST_DELEGATED_EXECUTORS_CONFIG_NUMBER;
            _delegatedExecutorsConfig.maxConfigNumberSet = FIRST_DELEGATED_EXECUTORS_CONFIG_NUMBER;
            configNumberToUse = FIRST_DELEGATED_EXECUTORS_CONFIG_NUMBER;
            configSwitched = true;
        }
        return (configNumberToUse, configSwitched);
    }

    /**
     * @param _delegatedExecutorsConfig The delegated executor configuration to prepare for changes.
     * @param configNumber The number of the configuration where the executor approval state is being set. Zero used as
     * an alias for the current configuration number.
     * @param switchToGivenConfig A boolean indicanting if the configuration will be switched to the one with the given
     * number. If the configuration number given is zero, this boolean will be ignored as it refers to the current one.
     *
     * @return (uint64, bool) A tuple that represents (uint64 configNumberToUse, bool configSwitched).
     */
    function _prepareStorageToApplyChangesUnderGivenConfig(
        DataTypes.DelegatedExecutorsConfig storage _delegatedExecutorsConfig,
        uint64 configNumber,
        bool switchToGivenConfig
    ) private returns (uint64, bool) {
        bool configSwitched;
        uint64 nextAvailableConfigNumber = _delegatedExecutorsConfig.maxConfigNumberSet + 1;
        if (configNumber == nextAvailableConfigNumber) {
            // The next configuration available is being changed, it must be marked.
            // Otherwise, on a profile transfer, the next owner can inherit a used/dirty configuration.
            _delegatedExecutorsConfig.maxConfigNumberSet = nextAvailableConfigNumber;
            configSwitched = switchToGivenConfig;
            if (configSwitched) {
                // The configuration is being switched, previous and current configuration numbers must be updated.
                _delegatedExecutorsConfig.prevConfigNumberSet = _delegatedExecutorsConfig
                    .configNumber;
                _delegatedExecutorsConfig.configNumber = nextAvailableConfigNumber;
            }
        } else if (configNumber > nextAvailableConfigNumber) {
            revert Errors.InvalidParameter();
        } else {
            // The configuration corresponding to the given number is not a fresh/clean one.
            uint64 currentConfigNumber = _delegatedExecutorsConfig.configNumber;
            if (configNumber != currentConfigNumber) {
                // We ensure that `configSwitched` can not be set to `true` if the given configuration matches the one
                // that is already in use.
                configSwitched = configSwitched;
            }
            if (configSwitched) {
                // The configuration is being switched, previous and current configuration numbers must be updated.
                _delegatedExecutorsConfig.prevConfigNumberSet = currentConfigNumber;
                _delegatedExecutorsConfig.configNumber = configNumber;
            }
        }
        return (configNumber, configSwitched);
    }
}
