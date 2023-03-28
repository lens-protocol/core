// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title IReferenceModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible ReferenceModules.
 */
interface IReferenceModule {
    /**
     * @notice Initializes data for a given publication being published. This can only be called by the hub.
     *
     * @param profileId The token ID of the profile publishing the publication.
     * @param transactionExecutor The owner or an approved delegated executor.
     * @param pubId The associated publication's LensHub publication ID.
     * @param data Arbitrary data passed from the user to be decoded.
     *
     * @return bytes An abi-encoded byte array encapsulating the execution's state changes. This will be emitted by the
     * hub alongside the collect module's address and should be consumed by front ends.
     */
    function initializeReferenceModule(
        uint256 profileId,
        address transactionExecutor,
        uint256 pubId,
        bytes calldata data
    ) external returns (bytes memory);

    function processComment(Types.ProcessCommentParams calldata processCommentParams) external;

    function processQuote(Types.ProcessQuoteParams calldata processQuoteParams) external;

    function processMirror(Types.ProcessMirrorParams calldata processMirrorParams) external;
}
