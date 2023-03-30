// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title IPublicationAction
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible Publication Actions.
 * Publication action modules allow users to execute actions directly from a publication, like:
 *  - Minting NFTs
 *  - Collecting a publication
 *  - Sending funds to the profile owner (tipping, etc)
 *  - etc
 * Referrers are supported, so any publication or profile that references the publication can receive a share from the
 * publication's action if the action module supports it.
 */
interface IPublicationActionModule {
    /**
     * @notice Initializes the action module for the given publication being published with this Action module.
     * @custom:permissions LensHub.
     *
     * @param profileId The profile ID of the author publishing the content with this Publication Action.
     * @param pubId The publication ID being published.
     * @param transactionExecutor The address of the transaction executor (e.g. for any funds to transferFrom).
     * @param data Arbitrary data passed from the user to be decoded by the Action Module during initialization.
     *
     * @return bytes An abi-encoded byte array encapsulating the execution's state changes. This will be emitted by the
     * hub alongside the collect module's address and should be consumed by front ends.
     * // TODO: Is the above return description correct?
     */
    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Initializes the action module for the given publication.
     * @custom:permissions LensHub
     *
     * @param processActionParams The parameters needed to execute the publication action.
     *
     * @return bytes Any custom ABI-encoded data depending on the module implementation.
     * // TODO: Do we need to return data? Reference modules do not return anything.
     */
    function processPublicationAction(
        Types.ProcessActionParams calldata processActionParams
    ) external returns (bytes memory);
}
