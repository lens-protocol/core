// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title IPublicationAction
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible Publication Actions.
 */
interface IPublicationActionModule {
    /**
     * @notice Initializes the action module for the given publication.
     * @custom:permissions LensHub.
     *
     * @param profileId The profile ID of the author publishing the content with Publication Action.
     * @param pubId The publication ID of the content being published.
     * @param transactionExecutor The address of the transaction executor (e.g. for any funds to transferFrom).
     * @param data The data to be passed to the Publication Action.
     *
     * @return bytes Any custom ABI-encoded data depending on the module implementation.
     */
    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Initializes the action module for the given publication.
     * @custom:permissions LensHub.
     *
     * @param processActionParams The parameters needed to execute the publication action.
     *
     * @return bytes Any custom ABI-encoded data depending on the module implementation.
     */
    function processPublicationAction(
        Types.ProcessActionParams calldata processActionParams
    ) external returns (bytes memory);
}
