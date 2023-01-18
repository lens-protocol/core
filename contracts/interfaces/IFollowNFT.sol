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
    error AlreadyFollowing();
    error NotFollowing();
    error FollowTokenDoesNotExist();
    error AlreadyUntiedAndWrapped();
    error OnlyWrappedFollowTokens();
    error DoesNotHavePermissions();

    /**
     * @notice A struct containing token follow-related data.
     *
     * @param followerProfileId The ID of the profile using the token to follow.
     * @param originalFollowTimestamp The timestamp of the first follow performed with the token.
     * @param followTimestamp The timestamp of the current follow, if a profile is using the token to follow.
     * @param profileIdAllowedToRecover The ID of the profile allowed to recover the follow ID, if any.
     */
    struct FollowData {
        uint160 followerProfileId;
        uint48 originalFollowTimestamp;
        uint48 followTimestamp;
        uint256 profileIdAllowedToRecover;
    }

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
     * @param followTokenId The ID of the follow token to be used for this follow operation. Zero if a new follow token
     * should be minted.
     *
     * @return uint256 The ID of the token used to follow.
     */
    function follow(
        uint256 followerProfileId,
        address executor,
        address followerProfileOwner,
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
    function getFollowData(uint256 followTokenId) external view returns (FollowData memory);

    /**
     * @notice Tells if the given profile is following the profile targeted in this contract.
     *
     * @param followerProfileId The ID of the profile whose following state should be queried.
     *
     * @return uint256 The ID of the profile set as follower in the given token, zero if it is not being used to follow.
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
     * @notice Approves the given profile to follow with the given wrapped token.
     *
     * @dev It approves setting a follower on the given wrapped follow token, which lets the follow token owner to allow
     * a profile to follow with his token without losing its ownership. This approval is cleared on transfers, as well
     * as when unwrapping.
     *
     * @param approvedProfileId The ID of the profile approved to follow with the given token.
     * @param followTokenId The ID of the follow token to be approved for the given profile.
     */
    function approveFollow(uint256 approvedProfileId, uint256 followTokenId) external;

    /**
     * @notice Unties the follow token from the follower's profile token, and wraps it into the ERC-721 untied follow
     * tokens collection.
     *
     * @param followTokenId The ID of the follow token to untie and wrap.
     */
    function untieAndWrap(uint256 followTokenId) external;

    /**
     * @notice Unwraps the follow token from the ERC-721 untied follow tokens collection, and ties it to the follower's
     * profile token.
     *
     * @param followTokenId The ID of the follow token to unwrap and tie to its follower.
     */
    function unwrapAndTie(uint256 followTokenId) external;

    /**
     * @notice Blocks the given profile. If it was following the targetted profile, this will make it to unfollow.
     *
     * @dev This must be only callable by the LensHub contract.
     *
     * @param followerProfileId The ID of the follow token to unwrap and tie.
     */
    function block(uint256 followerProfileId) external;
}
