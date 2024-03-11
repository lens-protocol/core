// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from './constants/Types.sol';
import {Errors} from './constants/Errors.sol';
import {StorageLib} from './StorageLib.sol';
import {Events} from './constants/Events.sol';

library GovernanceLib {
    uint16 internal constant BPS_MAX = 10000;

    /**
     * @notice Sets the governance address.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external {
        address prevGovernance = StorageLib.getGovernance();
        StorageLib.setGovernance(newGovernance);
        emit Events.GovernanceSet(msg.sender, prevGovernance, newGovernance, block.timestamp);
    }

    /**
     * @notice Sets the emergency admin address.
     *
     * @param newEmergencyAdmin The new governance address to set.
     */
    function setEmergencyAdmin(address newEmergencyAdmin) external {
        address prevEmergencyAdmin = StorageLib.getEmergencyAdmin();
        StorageLib.setEmergencyAdmin(newEmergencyAdmin);
        emit Events.EmergencyAdminSet(msg.sender, prevEmergencyAdmin, newEmergencyAdmin, block.timestamp);
    }

    /**
     * @notice Sets the protocol state, only meant to be called at initialization since
     * this does not validate the caller.
     *
     * @param newState The new protocol state to set.
     */
    function initState(Types.ProtocolState newState) external {
        _setState(newState);
    }

    /**
     * @notice Sets the protocol state and validates the caller. The emergency admin can only
     * pause further (Unpaused => PublishingPaused => Paused). Whereas governance can set any
     * state.
     *
     * @param newState The new protocol state to set.
     */
    function setState(Types.ProtocolState newState) external {
        // NOTE: This does not follow the CEI-pattern, but there is no interaction and this allows to abstract `_setState` logic.
        Types.ProtocolState prevState = _setState(newState);

        if (msg.sender != StorageLib.getGovernance()) {
            // If the sender is the emergency admin, prevent them from reducing restrictions.
            if (msg.sender == StorageLib.getEmergencyAdmin()) {
                if (newState <= prevState) {
                    revert Errors.EmergencyAdminCanOnlyPauseFurther();
                }
            } else {
                revert Errors.NotGovernanceOrEmergencyAdmin();
            }
        }
    }

    function _setState(Types.ProtocolState newState) private returns (Types.ProtocolState) {
        Types.ProtocolState prevState = StorageLib.getState();
        StorageLib.setState(newState);
        emit Events.StateSet(msg.sender, prevState, newState, block.timestamp);
        return prevState;
    }

    function whitelistProfileCreator(address profileCreator, bool whitelist) external {
        StorageLib.profileCreatorWhitelisted()[profileCreator] = whitelist;
        emit Events.ProfileCreatorWhitelisted(profileCreator, whitelist, block.timestamp);
    }

    function setTreasury(address newTreasury) internal {
        if (newTreasury == address(0)) {
            revert Errors.InitParamsInvalid();
        }
        Types.TreasuryData storage _treasuryData = StorageLib.getTreasuryData();

        address prevTreasury = _treasuryData.treasury;
        _treasuryData.treasury = newTreasury;

        emit Events.TreasurySet(prevTreasury, newTreasury, block.timestamp);
    }

    function setTreasuryFee(uint16 newTreasuryFee) internal {
        if (newTreasuryFee >= BPS_MAX / 2) {
            revert Errors.InitParamsInvalid();
        }
        Types.TreasuryData storage _treasuryData = StorageLib.getTreasuryData();

        uint16 prevTreasuryFee = _treasuryData.treasuryFeeBPS;
        _treasuryData.treasuryFeeBPS = newTreasuryFee;

        emit Events.TreasuryFeeSet(prevTreasuryFee, newTreasuryFee, block.timestamp);
    }

    function setProfileTokenURIContract(address profileTokenURIContract) external {
        StorageLib.setProfileTokenURIContract(profileTokenURIContract);
    }

    function setFollowTokenURIContract(address followTokenURIContract) external {
        StorageLib.setFollowTokenURIContract(followTokenURIContract);
    }
}
