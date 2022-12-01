// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {DataTypes} from '../libraries/DataTypes.sol';

/**
 * @title IFollowNFT
 * @author Lens Protocol
 *
 * @notice This is the interface for the FollowNFT contract, which is cloned upon the first follow for any profile.
 */
interface IFollowNFT {
    /**
     * @notice Initializes the follow NFT, setting the hub as the privileged minter and storing the associated profile ID.
     *
     * @param profileId The token ID of the profile in the hub associated with this followNFT, used for transfer hooks.
     */
    function initialize(uint256 profileId) external;

    function follow(
        uint256 followerProfileId,
        address executor,
        address followerProfileOwner,
        bool isExecutorApproved,
        uint256 followId
    ) external returns (uint256);

    function unfollow(
        uint256 unfollowerProfileId,
        address executor,
        bool isExecutorApproved,
        address unfollowerProfileOwner
    ) external;

    function block(uint256 followerProfileId) external;

    function getFollowerProfileId(uint256 followId) external view returns (uint256);

    function isFollowing(uint256 followerProfileId) external view returns (bool);

    function getFollowId(uint256 followerProfileId) external view returns (uint256);

    function delegate(uint256 delegatorProfile, address delegatee) external;

    function delegateBySig(
        uint256 delegatorProfile,
        address delegatee,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Returns the governance power for a given user at a specified block number.
     *
     * @param user The user to query governance power for.
     * @param blockNumber The block number to query the user's governance power at.
     *
     * @return uint256 The power of the given user at the given block number.
     */
    function getPowerByBlockNumber(address user, uint256 blockNumber) external returns (uint256);

    /**
     * @notice Returns the total delegated supply at a specified block number. This is the sum of all
     * current available voting power at a given block.
     *
     * @param blockNumber The block number to query the delegated supply at.
     *
     * @return uint256 The delegated supply at the given block number.
     */
    function getDelegatedSupplyByBlockNumber(uint256 blockNumber) external returns (uint256);
}
