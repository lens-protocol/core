// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title IFollowModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible FollowModules.
 */
interface IFollowModule {
    /**
     * @notice Initializes a follow module for a given Lens profile. This can only be called by the hub contract.
     *
     * @param profileId The token ID of the profile to initialize this follow module for.
     * @param executor The owner or an approved delegated executor.
     * @param data Arbitrary data passed by the profile creator.
     *
     * @return bytes The encoded data to emit in the hub.
     */
    function initializeFollowModule(
        uint256 profileId,
        address executor,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Processes a given follow, this can only be called from the LensHub contract.
     *
     * @param followerProfileId The LensHub profile token ID of the follower's profile (currently unused, preemptive interface upgrade).
     * @param followTokenId The ID of the follow token used to follow. Zero if a new one was minted, in this case, the follow ID assigned
     * can be queried from the Follow NFT collection if needed.
     * @param executor The follower or an approved delegated executor.
     * @param profileId The token ID of the profile being followed.
     * @param data Arbitrary data passed by the follower.
     */
    function processFollow(
        uint256 followerProfileId,
        uint256 followTokenId,
        address executor,
        uint256 profileId,
        bytes calldata data
    ) external;
}
