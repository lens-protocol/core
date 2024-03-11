// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {Types} from '../libraries/constants/Types.sol';

/**
 * @title IPublicationAction
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible Publication Actions.
 * Publication action modules allow users to execute actions directly from a publication, like:
 *  - Minting NFTs.
 *  - Collecting a publication.
 *  - Sending funds to the publication author (e.g. tipping).
 *  - Etc.
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
     * @return bytes Any custom ABI-encoded data. This will be a LensHub event params that can be used by
     * indexers or UIs.
     */
    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Processes the action for a given publication. This includes the action's logic and any monetary/token
     * operations.
     * @custom:permissions LensHub.
     *
     * @param processActionParams The parameters needed to execute the publication action.
     *
     * @return bytes Any custom ABI-encoded data. This will be a LensHub event params that can be used by
     * indexers or UIs.
     */
    function processPublicationAction(Types.ProcessActionParams calldata processActionParams)
        external
        returns (bytes memory);
}
