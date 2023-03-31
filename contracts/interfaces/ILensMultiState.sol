// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title ILensMultiState
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensMultiState contract that is responsible for handling the protocol state.
 * Lens Protocol State can be one of the following:
 *  - Unpaused: The protocol is fully operational.
 *  - PublishingPaused: The protocol is paused for publishing operations, but it is still operational for other actions.
 *  - Paused: The protocol is paused for all operations.
 */
interface ILensMultiState {
    // TODO: Why don't we have setState in the interface?

    /**
     * @notice Gets the state currently set in the protocol. It could be a global pause, a publishing pause or an
     * unpaused state.
     * @custom:permissions Anyone.
     *
     * @return Types.ProtocolState The state currently set in the protocol.
     */
    function getState() external view returns (Types.ProtocolState);
}
