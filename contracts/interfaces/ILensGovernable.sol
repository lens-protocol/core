// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title ILensGovernable
 * @author Lens Protocol
 *
 * @notice This is the interface for the Lens Protocol main governance functions.
 */
interface ILensGovernable {
    /**
     * @notice Sets the privileged governance role.
     * @custom:permissions Governance.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external;

    /**
     * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state.
     * @custom:permissions Governance.
     *
     * @param newEmergencyAdmin The new emergency admin address to set.
     */
    function setEmergencyAdmin(address newEmergencyAdmin) external;

    /**
     * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state.
     * @custom:permissions Governance or Emergency Admin. Emergency Admin can only restrict more.
     *
     * @param newState The state to set. It can be one of the following:
     *  - Unpaused: The protocol is fully operational.
     *  - PublishingPaused: The protocol is paused for publishing, but it is still operational for others operations.
     *  - Paused: The protocol is paused for all operations.
     */
    function setState(Types.ProtocolState newState) external;

    /**
     * @notice Adds or removes a profile creator from the whitelist.
     * @custom:permissions Governance.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(address profileCreator, bool whitelist) external;

    /**
     * @notice Adds or removes a follow module from the whitelist.
     * @custom:permissions Governance.
     *
     * @param followModule The follow module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the follow module should be whitelisted.
     */
    function whitelistFollowModule(address followModule, bool whitelist) external;

    /**
     * @notice Adds or removes a reference module from the whitelist.
     * @custom:permissions Governance.
     *
     * @param referenceModule The reference module contract to add or remove from the whitelist.
     * @param whitelist Whether or not the reference module should be whitelisted.
     */
    function whitelistReferenceModule(address referenceModule, bool whitelist) external;

    /**
     * @notice Adds or removes an action module from the whitelist. This function can only be called by the current
     * governance address.
     * @custom:permissions Governance.
     *
     * @param actionModule The action module contract address to add or remove from the whitelist.
     * @param whitelist True if the action module should be whitelisted, false if it should be unwhitelisted.
     */
    function whitelistActionModule(address actionModule, bool whitelist) external;

    /**
     * @notice Returns the currently configured governance address.
     *
     * @return address The address of the currently configured governance.
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Gets the state currently set in the protocol. It could be a global pause, a publishing pause or an
     * unpaused state.
     * @custom:permissions Anyone.
     *
     * @return Types.ProtocolState The state currently set in the protocol.
     */
    function getState() external view returns (Types.ProtocolState);

    /**
     * @notice Returns whether or not a profile creator is whitelisted.
     *
     * @param profileCreator The address of the profile creator to check.
     *
     * @return bool True if the profile creator is whitelisted, false otherwise.
     */
    function isProfileCreatorWhitelisted(address profileCreator) external view returns (bool);

    /**
     * @notice Returns whether or not a follow module is whitelisted.
     *
     * @param followModule The address of the follow module to check.
     *
     * @return bool True if the follow module is whitelisted, false otherwise.
     */
    function isFollowModuleWhitelisted(address followModule) external view returns (bool);

    /**
     * @notice Returns whether or not a reference module is whitelisted.
     *
     * @param referenceModule The address of the reference module to check.
     *
     * @return bool True if the reference module is whitelisted, false otherwise.
     */
    function isReferenceModuleWhitelisted(address referenceModule) external view returns (bool);

    /**
     * @notice Returns whether or not an action module is whitelisted, and its ID assigned.
     * @dev If the ID is zero, it means the module has never been whitelisted, so no ID assigned to it yet.
     *
     * @param actionModule The address of the action module to get whitelist data of.
     *
     * @return ActionModuleWhitelistData The data containing the ID and whitelist status of the given module.
     */
    function getActionModuleWhitelistData(
        address actionModule
    ) external view returns (Types.ActionModuleWhitelistData memory);
}
