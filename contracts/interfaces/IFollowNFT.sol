// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {Types} from '../libraries/constants/Types.sol';

/**
 * @title IFollowNFT
 * @author Lens Protocol
 *
 * @notice This is the interface for the FollowNFT contract, which is cloned upon the first follow for any profile.
 * By default the Follow tokens are tied to the follower profile, which means that they will be automatically
 * transferred with it.
 * This is achieved by them not being ERC-721 initially. However, the Follow NFT collections support converting them to
 * ERC-721 tokens (i.e. wrapping) natively, enabling composability with existing ERC-721-based protocols.
 */
interface IFollowNFT {
    error AlreadyFollowing();
    error NotFollowing();
    error FollowTokenDoesNotExist();
    error AlreadyWrapped();
    error OnlyWrappedFollowTokens();
    error DoesNotHavePermissions();

    /**
     * @notice Initializes the follow NFT.
     * @custom:permissions LensHub.
     *
     * @dev Sets the targeted profile, and the token royalties.
     *
     * @param profileId The ID of the profile targeted by the follow tokens minted by this collection.
     */
    function initialize(uint256 profileId) external;

    /**
     * @notice Makes the passed profile follow the profile targeted in this contract.
     * @custom:permissions LensHub.
     *
     * @param followerProfileId The ID of the profile acting as the follower.
     * @param transactionExecutor The address of the transaction executor (e.g. for any funds to transferFrom).
     * @param followTokenId The ID of the follow token to be used for this follow operation. Zero if a new follow token
     * should be minted.
     *
     * @return uint256 The ID of the token used to follow.
     */
    function follow(
        uint256 followerProfileId,
        address transactionExecutor,
        uint256 followTokenId
    ) external returns (uint256);

    /**
     * @notice Makes the passed profile unfollow the profile targeted in this contract.
     * @custom:permissions LensHub.
     *
     * @param unfollowerProfileId The ID of the profile that is performing the unfollow operation.
     */
    function unfollow(uint256 unfollowerProfileId) external;

    /**
     * @notice Removes the follower from the given follow NFT.
     * @custom:permissions Follow token owner or approved-for-all.

     * @dev Only on wrapped token.
     *
     * @param followTokenId The ID of the follow token to remove the follower from.
     */
    function removeFollower(uint256 followTokenId) external;

    /**
     * @notice Approves the given profile to follow with the given wrapped token.
     * @custom:permissions Follow token owner or approved-for-all.
     *
     * @dev Only on wrapped tokens.
     * It approves setting a follower on the given wrapped follow token, which lets the follow token owner to allow
     * a profile to follow with his token without losing its ownership. This approval is cleared on transfers, as well
     * as when unwrapping.
     *
     * @param approvedProfileId The ID of the profile approved to follow with the given token.
     * @param followTokenId The ID of the follow token to be approved for the given profile.
     */
    function approveFollow(uint256 approvedProfileId, uint256 followTokenId) external;

    /**
     * @notice Unties the follow token from the follower's profile one, and wraps it into the ERC-721 untied follow
     * tokens collection. Untied follow tokens will NOT be automatically transferred with their follower profile.
     * @custom:permissions Follower profile owner.
     *
     * @dev Only on unwrapped follow tokens.
     *
     * @param followTokenId The ID of the follow token to untie and wrap.
     */
    function wrap(uint256 followTokenId) external;

    /**
     * @notice Unties the follow token from the follower's profile one, and wraps it into the ERC-721 untied follow
     * tokens collection. Untied follow tokens will NOT be automatically transferred with their follower profile.
     * @custom:permissions Follower profile owner.
     *
     * @dev Only on unwrapped follow tokens.
     *
     * @param followTokenId The ID of the follow token to untie and wrap.
     * @param wrappedTokenReceiver The address where the follow token is minted to when being wrapped as ERC-721.
     */
    function wrap(uint256 followTokenId, address wrappedTokenReceiver) external;

    /**
     * @notice Unwraps the follow token from the ERC-721 untied follow tokens collection, and ties it to the follower's
     * profile token. Tokens that are tied to the follower profile will be automatically transferred with it.
     *
     * @param followTokenId The ID of the follow token to unwrap and tie to its follower.
     */
    function unwrap(uint256 followTokenId) external;

    /**
     * @notice Processes logic when the given profile is being blocked. If it was following the targeted profile,
     * this will make it unfollow.
     * @custom:permissions LensHub.
     *
     * @param followerProfileId The ID of the follow token to unwrap and tie.
     *
     * @return bool True if the given profile was following and now has unfollowed, false otherwise.
     */
    function processBlock(uint256 followerProfileId) external returns (bool);

    ///////////////////////////
    ///       GETTERS       ///
    ///////////////////////////

    /**
     * @notice Gets the ID of the profile following with the given follow token.
     *
     * @param followTokenId The ID of the follow token whose follower should be queried.
     *
     * @return uint256 The ID of the profile following with the given token, zero if it is not being used to follow.
     */
    function getFollowerProfileId(uint256 followTokenId) external view returns (uint256);

    /**
     * @notice Gets the original follow timestamp of the given follow token.
     *
     * @param followTokenId The ID of the follow token whose original follow timestamp should be queried.
     *
     * @return uint256 The timestamp of the first follow performed with the token, zero if was not used to follow yet.
     */
    function getOriginalFollowTimestamp(uint256 followTokenId) external view returns (uint256);

    /**
     * @notice Gets the current follow timestamp of the given follow token.
     *
     * @param followTokenId The ID of the follow token whose follow timestamp should be queried.
     *
     * @return uint256 The timestamp of the current follow of the token, zero if it is not being used to follow.
     */
    function getFollowTimestamp(uint256 followTokenId) external view returns (uint256);

    /**
     * @notice Gets the ID of the profile allowed to recover the given follow token.
     *
     * @param followTokenId The ID of the follow token whose allowed profile to recover should be queried.
     *
     * @return uint256 The ID of the profile allowed to recover the given follow token, zero if none of them is allowed.
     */
    function getProfileIdAllowedToRecover(uint256 followTokenId) external view returns (uint256);

    /**
     * @notice Gets the follow data of the given follow token.
     *
     * @param followTokenId The ID of the follow token whose follow data should be queried.
     *
     * @return FollowData The token data associated with the given follow token.
     */
    function getFollowData(uint256 followTokenId) external view returns (Types.FollowData memory);

    /**
     * @notice Tells if the given profile is following the profile targeted in this contract.
     *
     * @param followerProfileId The ID of the profile whose following state should be queried.
     *
     * @return uint256 The ID of the profile set as a follower in the given token, zero if it is not being used to follow.
     */
    function isFollowing(uint256 followerProfileId) external view returns (bool);

    /**
     * @notice Gets the ID of the token being used to follow by the given follower.
     *
     * @param followerProfileId The ID of the profile whose follow ID should be queried.
     *
     * @return uint256 The ID of the token being used to follow by the given follower, zero if he is not following.
     */
    function getFollowTokenId(uint256 followerProfileId) external view returns (uint256);

    /**
     * @notice Gets the ID of the profile approved to follow with the given token.
     *
     * @param followTokenId The ID of the token whose approved to follow should be queried.
     *
     * @return uint256 The ID of the profile approved to follow with the given token, zero if none of them is approved.
     */
    function getFollowApproved(uint256 followTokenId) external view returns (uint256);

    /**
     * @notice Gets the count of the followers of the profile targeted in this contract.
     * @notice This number might be out of sync if one of the followers burns their profile.
     *
     * @return uint256 The count of the followers of the profile targeted in this contract.
     */
    function getFollowerCount() external view returns (uint256);
}
