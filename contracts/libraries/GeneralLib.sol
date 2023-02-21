// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {GeneralHelpers} from './GeneralHelpers.sol';
import {MetaTxLib} from './MetaTxLib.sol';
import {InteractionHelpers} from './InteractionHelpers.sol';
import {Types} from './constants/Types.sol';
import {Errors} from './constants/Errors.sol';
import {Events} from './constants/Events.sol';
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
        emit Events.EmergencyAdminSet(msg.sender, prevEmergencyAdmin, newEmergencyAdmin, block.timestamp);
    }

    /**
     * @notice Sets the protocol state, only meant to be called at initialization since
     * this does nto validate the caller.
     *
     * @param newState The new protocol state to set.
     */
    function initState(Types.ProtocolState newState) external {
        Types.ProtocolState prevState;
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
    function setState(Types.ProtocolState newState) external {
        address emergencyAdmin;
        address governance;
        Types.ProtocolState prevState;

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

    function switchToNewFreshDelegatedExecutorsConfig(uint256 profileId) external {
        Types.DelegatedExecutorsConfig storage _delegatedExecutorsConfig = GeneralHelpers.getDelegatedExecutorsConfig({
            delegatorProfileId: profileId
        });
        _changeDelegatedExecutorsConfig({
            _delegatedExecutorsConfig: _delegatedExecutorsConfig,
            delegatorProfileId: profileId,
            executors: new address[](0),
            approvals: new bool[](0),
            configNumber: _delegatedExecutorsConfig.maxConfigNumberSet + 1,
            switchToGivenConfig: true
        });
    }

    function changeCurrentDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata executors,
        bool[] calldata approvals
    ) external {
        Types.DelegatedExecutorsConfig storage _delegatedExecutorsConfig = GeneralHelpers.getDelegatedExecutorsConfig(
            delegatorProfileId
        );
        _changeDelegatedExecutorsConfig(
            _delegatedExecutorsConfig,
            delegatorProfileId,
            executors,
            approvals,
            _delegatedExecutorsConfig.configNumber,
            false
        );
    }

    function changeGivenDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata executors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) external {
        _changeDelegatedExecutorsConfig(
            GeneralHelpers.getDelegatedExecutorsConfig(delegatorProfileId),
            delegatorProfileId,
            executors,
            approvals,
            configNumber,
            switchToGivenConfig
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
        bytes[] calldata followModuleDatas,
        address transactionExecutor
    ) external returns (uint256[] memory) {
        return
            InteractionHelpers.follow({
                followerProfileId: followerProfileId,
                executor: transactionExecutor, // TODO: Why do we still need to know the executor there?
                idsOfProfilesToFollow: idsOfProfilesToFollow,
                followTokenIds: followTokenIds,
                followModuleDatas: followModuleDatas
            });
    }

    function unfollow(
        uint256 unfollowerProfileId,
        uint256[] calldata idsOfProfilesToUnfollow,
        address transactionExecutor
    ) external {
        return
            InteractionHelpers.unfollow({
                unfollowerProfileId: unfollowerProfileId,
                executor: transactionExecutor, // TODO: Why do we still need to know the executor there?
                idsOfProfilesToUnfollow: idsOfProfilesToUnfollow
            });
    }

    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) external {
        InteractionHelpers.setBlockStatus(byProfileId, idsOfProfilesToSetBlockStatus, blockStatus);
    }

    function collect(
        Types.CollectParams calldata collectParams,
        address transactionExecutor,
        address collectNFTImpl
    ) external returns (uint256) {
        return InteractionHelpers.collect(collectParams, transactionExecutor, collectNFTImpl);
    }

    function getContentURI(uint256 profileId, uint256 pubId) external view returns (string memory) {
        (uint256 rootProfileId, uint256 rootPubId, ) = GeneralHelpers.getPointedIfMirror(profileId, pubId);
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
        Types.DelegatedExecutorsConfig storage _delegatedExecutorsConfig,
        uint256 delegatorProfileId,
        address[] memory executors,
        bool[] memory approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) private {
        if (executors.length != approvals.length) {
            revert Errors.ArrayMismatch();
        }
        bool configSwitched = _prepareStorageToApplyChangesUnderGivenConfig(
            _delegatedExecutorsConfig,
            configNumber,
            switchToGivenConfig
        );
        uint256 i;
        while (i < executors.length) {
            _delegatedExecutorsConfig.isApproved[configNumber][executors[i]] = approvals[i];
            unchecked {
                ++i;
            }
        }
        emit Events.DelegatedExecutorsConfigChanged(
            delegatorProfileId,
            configNumber,
            executors,
            approvals,
            configSwitched
        );
    }

    function _prepareStorageToApplyChangesUnderGivenConfig(
        Types.DelegatedExecutorsConfig storage _delegatedExecutorsConfig,
        uint64 configNumber,
        bool switchToGivenConfig
    ) private returns (bool) {
        uint64 nextAvailableConfigNumber = _delegatedExecutorsConfig.maxConfigNumberSet + 1;
        if (configNumber > nextAvailableConfigNumber) {
            revert Errors.InvalidParameter();
        }
        bool configSwitched;
        if (configNumber == nextAvailableConfigNumber) {
            // The next configuration available is being changed, it must be marked.
            // Otherwise, on a profile transfer, the next owner can inherit a used/dirty configuration.
            _delegatedExecutorsConfig.maxConfigNumberSet = nextAvailableConfigNumber;
            configSwitched = switchToGivenConfig;
            if (configSwitched) {
                // The configuration is being switched, previous and current configuration numbers must be updated.
                _delegatedExecutorsConfig.prevConfigNumber = _delegatedExecutorsConfig.configNumber;
                _delegatedExecutorsConfig.configNumber = nextAvailableConfigNumber;
            }
        } else {
            // The configuration corresponding to the given number is not a fresh/clean one.
            uint64 currentConfigNumber = _delegatedExecutorsConfig.configNumber;
            // If the given configuration matches the one that is already in use, we keep `configSwitched` as `false`.
            if (configNumber != currentConfigNumber) {
                configSwitched = switchToGivenConfig;
            }
            if (configSwitched) {
                // The configuration is being switched, previous and current configuration numbers must be updated.
                _delegatedExecutorsConfig.prevConfigNumber = currentConfigNumber;
                _delegatedExecutorsConfig.configNumber = configNumber;
            }
        }
        return configSwitched;
    }
}
