// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title IReferenceModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible ReferenceModules.
 * Reference modules allow executing some action when a publication is referenced, like:
 *  - rewards for mirroring/commenting/quoting a publication
 *  - token-gated comments/mirrors/quotes of a publication
 *  - etc
 */
interface IReferenceModule {
    /**
     * @notice Initializes data for the given publication being published with this Reference module.
     * @custom:permissions LensHub
     *
     * @param profileId The token ID of the profile publishing the publication.
     * @param transactionExecutor The address of the transaction executor (e.g. for any funds to transferFrom).
     * @param pubId The associated publication's LensHub publication ID.
     * @param data Arbitrary data passed from the user to be decoded by the Reference Module during initialization.
     *
     * @return bytes An abi-encoded byte array encapsulating the execution's state changes. This will be emitted by the
     * hub alongside the collect module's address and should be consumed by front ends.
     */
    function initializeReferenceModule(
        uint256 profileId,
        address transactionExecutor,
        uint256 pubId, // TODO: Move this near profileId
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Processes a comment being published. This includes any additional module logic like transferring tokens,
     * checking for conditions (e.g. token-gated), etc.
     * @custom:permissions LensHub
     *
     * @param processCommentParams The parameters for processing a comment.
     */
    function processComment(Types.ProcessCommentParams calldata processCommentParams) external;

    /**
     * @notice Processes a quote being published. This includes any additional module logic like transferring tokens,
     * checking for conditions (e.g. token-gated), etc.
     * @custom:permissions LensHub
     *
     * @param processQuoteParams The parameters for processing a quote.
     */
    function processQuote(Types.ProcessQuoteParams calldata processQuoteParams) external;

    /**
     * @notice Processes a mirror being published. This includes any additional module logic like transferring tokens,
     * checking for conditions (e.g. token-gated), etc.
     * @custom:permissions LensHub
     *
     * @param processMirrorParams The parameters for processing a mirror.
     */
    function processMirror(Types.ProcessMirrorParams calldata processMirrorParams) external;
}
