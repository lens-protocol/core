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
     * @notice Initializes the follow NFT.
     *
     * @dev Sets the hub as priviliged sender, the targeted profile, and the token royalties.
     *
     * @param profileId The ID of the profile targeted by the follow tokens minted by this collection.
     */
    function initialize(uint256 profileId) external;

    /**
     * @notice Makes the passed profile to follow the profile targetted in this contract.
     *
     * @dev This must be only callable by the LensHub contract.
     *
     * @param followerProfileId The ID of the profile acting as the follower.
     * @param executor The address executing the operation, which is the signer in case of using meta-transactions or
     * the sender otherwise.
     * @param followerProfileOwner The address holding the follower profile.
     * @param isExecutorApproved A boolean indicading whether the executor is an approved delegated executor of the
     * follower profile's owner.
     * @param followTokenId The ID of the follow token to be used for this follow operation. Zero if a new follow token
     * should be minted.
     *
     * @return uint256 The ID of the token used to follow.
     */
    function follow(
        uint256 followerProfileId,
        address executor,
        address followerProfileOwner,
        bool isExecutorApproved,
        uint256 followTokenId
    ) external returns (uint256);

    /**
     * @notice Makes the passed profile to unfollow the profile targetted in this contract.
     *
     * @dev This must be only callable by the LensHub contract.
     *
     * @param unfollowerProfileId The ID of the profile that is perfrorming the unfollow operation.
     * @param executor The address executing the operation, which is the signer in case of using meta-transactions or
     * the sender otherwise.
     * @param isExecutorApproved A boolean indicading whether the executor is an approved delegated executor of the
     * unfollower profile's owner.
     * @param unfollowerProfileOwner The address holding the unfollower profile.
     */
    function unfollow(
        uint256 unfollowerProfileId,
        address executor,
        bool isExecutorApproved,
        address unfollowerProfileOwner
    ) external;

    /**
     * @notice Gets the ID of the profile following with the given follow token.
     *
     * @param followTokenId The ID of the follow token whose follower should be queried.
     *
     * @return uint256 The ID of the profile set as follower in the given token, zero if it is not being used to follow.
     */
    function getFollowerProfileId(uint256 followTokenId) external view returns (uint256);

    /**
     * @notice Tells if the given profile is following the profile targeted in this contract.
     *
     * @param followerProfileId The ID of the profile whose following state should be queried.
     *
     * @return uint256 The ID of the profile set as follower in the given token, zero if it is not being used to follow.
     */
    function isFollowing(uint256 followerProfileId) external view returns (bool);

    /**
     * @notice Tells if the given profile is following the profile targeted in this contract.
     *
     * @param followerProfileId The ID of the profile whose following state should be queried.
     *
     * @return uint256 The ID of the profile set as follower in the given token, zero if it is not being used to follow.
     */
    function getFollowTokenId(uint256 followerProfileId) external view returns (uint256);

    /**
     * @notice Approves the given profile to follow with the given follow token.
     *
     * @param followerProfileId The ID of the profile to approve to follow.
     * @param followTokenId The ID of the follow token to approve to follow with.
     */
    function approveFollowWithToken(uint256 followerProfileId, uint256 followTokenId) external; // TODO: maybe rename to approveProfileToFollowWithToken

    /**
     * @notice Approves the given address to set a follower on a given wrapped token.
     *
     * @param operator The address to approve to set the follower in the token.
     * @param followTokenId The ID of the follow token to approve for the follower to be set in.
     */
    function approveSetFollowerInToken(address operator, uint256 followTokenId) external; // TODO: maybe rename to approveTokenToBeUsedToFollowByProfile

    /**
     * @notice Unties the follow token from the follower's profile token, and wrapps it into the ERC-721 untied follow
     * tokens collection.
     *
     * @param followTokenId The ID of the follow token to untie and wrap.
     */
    function untieAndWrap(uint256 followTokenId) external;

    /**
     * @notice Unwrapps the follow token from the ERC-721 untied follow tokens collection, and ties it to the follower's
     * profile token.
     *
     * @param followerProfileId The ID of the profile whose token being used to follow should be unwrapped and tied.
     */
    function unwrapAndTie(uint256 followerProfileId) external;

    /**
     * @notice Blocks the given profile. If it was following the targetted profile, this will make it to unfollow.
     *
     * @dev This must be only callable by the LensHub contract.
     *
     * @param followerProfileId The ID of the follow token to unwrap and tie.
     */
    function block(uint256 followerProfileId) external;

    /**
     * @notice Delegates voting power from the given profile to the given address.
     *
     * @dev The profile must be following to be able to have or delegate voting power.
     *
     * @param delegatorProfileId The ID of the profile delegating voting power.
     * @param delegatee The address which voting power is delegated to.
     */
    function delegate(uint256 delegatorProfileId, address delegatee) external;

    /**
     * @notice Delegates voting power from the given profile to the given address through meta-transactions.
     *
     * @dev The profile must be following to be able to have or delegate voting power.
     *
     * @param delegatorProfileId The ID of the profile delegating voting power.
     * @param delegatee The address which voting power is delegated to.
     * @param sig An EIP712Signature struct containing the signature for the `DelegateBySig` message.
     */
    function delegateBySig(
        uint256 delegatorProfileId,
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
