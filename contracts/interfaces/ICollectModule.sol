// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title ICollectModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible CollectModules.
 */
interface ICollectModule {
    /**
     * @notice Initializes data for a given publication being published. This can only be called by the hub.
     *
     * @param profileId The token ID of the profile publishing the publication.
     * @param pubId The associated publication's LensHub publication ID.
     * @param executor The owner or an approved delegated executor.
     * @param data Arbitrary data __passed from the user!__ to be decoded.
     *
     * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
     * hub alongside the collect module's address and should be consumed by front ends.
     */
    function initializePublicationCollectModule(
        uint256 profileId,
        uint256 pubId,
        address executor,
        bytes calldata data
    ) external returns (bytes memory);

    function processCollect(Types.ProcessCollectParams calldata processCollectParams) external returns (bytes memory);
}
