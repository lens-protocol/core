// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';

library GovernanceLib {
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
        // If the sender is the emergency admin, prevent them from reducing restrictions.
        if (msg.sender == StorageLib.getEmergencyAdmin()) {
            if (newState <= prevState) revert Errors.EmergencyAdminCanOnlyPauseFurther();
        } else if (msg.sender != StorageLib.getGovernance()) {
            revert Errors.NotGovernanceOrEmergencyAdmin();
        }
        emit Events.StateSet(msg.sender, prevState, newState, block.timestamp);
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

    function whitelistFollowModule(address followModule, bool whitelist) external {
        StorageLib.followModuleWhitelisted()[followModule] = whitelist;
        emit Events.FollowModuleWhitelisted(followModule, whitelist, block.timestamp);
    }

    function whitelistReferenceModule(address referenceModule, bool whitelist) external {
        StorageLib.referenceModuleWhitelisted()[referenceModule] = whitelist;
        emit Events.ReferenceModuleWhitelisted(referenceModule, whitelist, block.timestamp);
    }

    function whitelistActionModule(address actionModule, bool whitelist) external {
        Types.ActionModuleWhitelistData memory actionModuleWhitelistData = StorageLib.actionModuleWhitelistData()[
            actionModule
        ];

        uint256 id;
        if (actionModuleWhitelistData.id == 0) {
            if (!whitelist) {
                revert('ModuleNotWhitelisted');
            }
            id = StorageLib.incrementMaxActionModuleIdUsed();

            StorageLib.actionModuleWhitelistData()[actionModule] = Types.ActionModuleWhitelistData(
                uint248(id),
                whitelist
            );
            StorageLib.actionModuleById()[id] = actionModule;
        } else {
            StorageLib.actionModuleWhitelistData()[actionModule].isWhitelisted = whitelist;
            id = actionModuleWhitelistData.id;
        }
        emit Events.ActionModuleWhitelisted(actionModule, id, whitelist, block.timestamp);
    }
}
