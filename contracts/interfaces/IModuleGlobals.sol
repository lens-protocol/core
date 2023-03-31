// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title IModuleGlobals
 * @author Lens Protocol
 *
 * @notice This is the interface for the ModuleGlobals contract, a data-providing contract to be queried by modules
 * for the most up-to-date parameters.
 * ModuleGlobals contract handles the following:
 *  - Governance address for modules
 *  - Lens treasury address
 *  - Lens treasury fee
 *  - Whitelist of currencies allowed for use in modules
 */
interface IModuleGlobals {
    /**
     * @notice Sets the modules governance address.
     * @custom:permissions Modules Governance
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external;

    /**
     * @notice Sets the treasury address.
     * @custom:permissions Modules Governance
     *
     * @param newTreasury The new treasury address to set.
     */
    function setTreasury(address newTreasury) external;

    /**
     * @notice Sets the treasury fee.
     * @custom:permissions Modules Governance
     *
     * @param newTreasuryFee The new treasury fee to set.
     */
    function setTreasuryFee(uint16 newTreasuryFee) external;

    /**
     * @notice Adds or removes a currency from the whitelist.
     * @custom:permissions Modules Governance
     *
     * @param currency The currency to add or remove from the whitelist.
     * @param toWhitelist Whether to add (true) or remove (false) the currency from the whitelist.
     */
    function whitelistCurrency(address currency, bool toWhitelist) external;

    /////////////////////////////////
    ///       VIEW FUNCTIONS      ///
    /////////////////////////////////

    /**
     * @notice Returns whether a currency is whitelisted.
     *
     * @param currency The currency to query the whitelist for.
     *
     * @return bool True if the queried currency is whitelisted, false otherwise.
     */
    function isCurrencyWhitelisted(address currency) external view returns (bool);

    /**
     * @notice Returns the governance address.
     *
     * @return address The governance address.
     */
    function getGovernance() external view returns (address);

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
}
