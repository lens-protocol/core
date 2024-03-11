// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {ModuleTypes} from '../libraries/constants/ModuleTypes.sol';

/**
 * @title ICollectModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible CollectModules.
 * Collect modules allow users to execute custom logic upon a collect action over a publication, like:
 *  - Only allow the collect if the collector is following the publication author.
 *  - Only allow the collect if the collector has made a payment to
 *  - Allow any collect but only during the first 24 hours.
 *  - Etc.
 */
interface ICollectModule {
    /**
     * @notice Initializes data for a given publication being published.
     * @custom:permissions LensHub.
     *
     * @param profileId The token ID of the profile publishing the publication.
     * @param pubId The associated publication's LensHub publication ID.
     * @param transactionExecutor The owner or an approved delegated executor.
     * @param data Arbitrary data __passed from the user!__ to be decoded.
     *
     * @return bytes Any custom ABI-encoded data. This will be a LensHub event params that can be used by
     * indexers or UIs.
     */
    function initializePublicationCollectModule(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Processes a collect action for a given publication.
     * @custom:permissions LensHub.
     *
     * @param processCollectParams The parameters for the collect action.
     *
     * @return bytes Any custom ABI-encoded data. This will be a LensHub event params that can be used by
     * indexers or UIs.
     */
    function processCollect(
        ModuleTypes.ProcessCollectParams calldata processCollectParams
    ) external returns (bytes memory);
}
