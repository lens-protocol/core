// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {Types} from '../libraries/constants/Types.sol';

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
     * @notice Sets the profile token URI contract.
     * @custom:permissions Governance.
     *
     * @param profileTokenURIContract The profile token URI contract to set.
     */
    function setProfileTokenURIContract(address profileTokenURIContract) external;

    /**
     * @notice Sets the follow token URI contract.
     * @custom:permissions Governance.
     *
     * @param followTokenURIContract The follow token URI contract to set.
     */
    function setFollowTokenURIContract(address followTokenURIContract) external;

    /**
     * @notice Sets the treasury address.
     * @custom:permissions Governance
     *
     * @param newTreasury The new treasury address to set.
     */
    function setTreasury(address newTreasury) external;

    /**
     * @notice Sets the treasury fee.
     * @custom:permissions Governance
     *
     * @param newTreasuryFee The new treasury fee to set.
     */
    function setTreasuryFee(uint16 newTreasuryFee) external;

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
     * @notice Returns the treasury address.
     *
     * @return address The treasury address.
     */
    function getTreasury() external view returns (address);

    /**
     * @notice Returns the treasury fee.
     *
     * @return uint16 The treasury fee.
     */
    function getTreasuryFee() external view returns (uint16);

    /**
     * @notice Returns the treasury address and treasury fee in a single call.
     *
     * @return tuple First, the treasury address, second, the treasury fee.
     */
    function getTreasuryData() external view returns (address, uint16);

    /**
     * @notice Gets the profile token URI contract.
     *
     * @return address The profile token URI contract.
     */
    function getProfileTokenURIContract() external view returns (address);

    /**
     * @notice Gets the follow token URI contract.
     *
     * @return address The follow token URI contract.
     */
    function getFollowTokenURIContract() external view returns (address);
}
