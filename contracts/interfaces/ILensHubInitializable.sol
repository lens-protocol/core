// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title ILensHub
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract, the main entry point for the Lens Protocol.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface ILensHubInitializable {
    /**
     * @notice Initializes the LensHub, setting the initial governance address, the name and symbol of the profiles
     * in the LensNFTBase contract, and Protocol State (Paused).
     * @dev This is assuming a proxy pattern is implemented.
     * @custom:permissions Callable once.
     *
     * @param name The name of the Profile NFT.
     * @param symbol The symbol of the Profile NFT.
     * @param newGovernance The governance address to set.
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        address newGovernance
    ) external;
}
