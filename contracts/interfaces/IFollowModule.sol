// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title IFollowModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible Follow Modules.
 * These are responsible for processing the follow actions and can be used to implement any kind of follow logic.
 * For example:
 *  - Token-gated follows (e.g. a user must hold a certain amount of a token to follow a profile).
 *  - Paid follows (e.g. a user must pay a certain amount of a token to follow a profile).
 *  - Rewarding users for following a profile.
 *  - Etc.
 */
interface IFollowModule {
    /**
     * @notice Initializes a follow module for a given Lens profile.
     * @custom:permissions LensHub.
     *
     * @param profileId The Profile ID to initialize this follow module for.
     * @param transactionExecutor The address of the transaction executor (e.g. for any funds to transferFrom).
     * @param data Arbitrary data passed from the user to be decoded by the Follow Module during initialization.
     *
     * @return bytes The encoded data to be emitted from the hub.
     */
    function initializeFollowModule(
        uint256 profileId,
        address transactionExecutor,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Processes a given follow.
     * @custom:permissions LensHub.
     *
     * @param followerProfileId The Profile ID of the follower's profile.
     * @param followTokenId The Follow Token ID that is being used to follow. Zero if we are processing a new fresh
     * follow, in this case, the follow ID assigned can be queried from the Follow NFT collection if needed.
     * @param transactionExecutor The address of the transaction executor (e.g. for any funds to transferFrom).
     * @param targetProfileId The token ID of the profile being followed.
     * @param data Arbitrary data passed by the follower.
     *
     * @return bytes Any custom ABI-encoded data. This will be a LensHub event params that can be used by
     * indexers or UIs.
     */
    function processFollow(
        uint256 followerProfileId,
        uint256 followTokenId,
        address transactionExecutor,
        uint256 targetProfileId,
        bytes calldata data
    ) external returns (bytes memory);
}
