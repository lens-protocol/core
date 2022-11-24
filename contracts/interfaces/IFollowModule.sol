// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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
     * @param followId The ID of the follow token used to follow. Zero if a new one was minted, in this case, the follow ID assigned
     * can be queried from the Follow NFT collection if needed.
     * @param executor The follower or an approved delegated executor.
     * @param profileId The token ID of the profile being followed.
     * @param data Arbitrary data passed by the follower.
     */
    function processFollow(
        uint256 followerProfileId,
        uint256 followId,
        address executor,
        uint256 profileId,
        bytes calldata data
    ) external;

    /**
     * @notice This is a helper function that could be used in conjunction with specific collect modules.
     *
     * NOTE: This function IS meant to replace a check on follower NFT ownership.
     *
     * NOTE: It is assumed that not all collect modules are aware of the token ID to pass. In these cases,
     * this should receive a `followNFTTokenId` of 0, which is impossible regardless.
     *
     * One example of a use case for this would be a subscription-based following system:
     *      1. The collect module:
     *          - Decodes a follower NFT token ID from user-passed data.
     *          - Fetches the follow module from the hub.
     *          - Calls `isFollowing` passing the profile ID, follower & follower token ID and checks it returned true.
     *      2. The follow module:
     *          - Validates the subscription status for that given NFT, reverting on an invalid subscription.
     *
     * @param followerProfileId The LensHub profile token ID of the follower's profile (currently unused, preemptive interface upgrade).
     * @param profileId The token ID of the profile to validate the follow for.
     * @param follower The follower address to validate the follow for.
     * @param followNFTTokenId The followNFT token ID to validate the follow for.
     *
     * @return true if the given address is following the given profile ID, false otherwise.
     */
    function isFollowing(
        uint256 followerProfileId,
        uint256 profileId,
        address follower,
        uint256 followNFTTokenId
    ) external view returns (bool);
}
