// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {DataTypes} from 'contracts/libraries/DataTypes.sol';

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

    /**
     * @notice Processes a collect action for a given publication, this can only be called by the hub.
     *
     * @param publicationCollectedProfileId The token ID of the profile associated with the publication being collected.
     * @param publicationCollectedId The LensHub publication ID associated with the publication being collected.
     * @param collectorProfileId The LensHub profile token ID of the collector's profile.
     * @param collectorProfileOwner The collector address.
     * @param executor The collector or an approved delegated executor.
     * @param referrerProfileId TODO
     * @param referrerPubId TODO
     * @param referrerPubType TODO
     * @param data Arbitrary data __passed from the collector!__ to be decoded.
     */
    function processCollect(
        uint256 publicationCollectedProfileId,
        uint256 publicationCollectedId,
        uint256 collectorProfileId,
        address collectorProfileOwner,
        address executor,
        uint256 referrerProfileId,
        uint256 referrerPubId,
        DataTypes.PublicationType referrerPubType,
        bytes calldata data
    ) external;
}
