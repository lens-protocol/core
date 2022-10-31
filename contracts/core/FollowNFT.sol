// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IFollowNFT} from '../interfaces/IFollowNFT.sol';
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';
import {MetaTxHelpers} from '../libraries/helpers/MetaTxHelpers.sol';
import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';
import {DataTypes} from '../libraries/DataTypes.sol';
import {LensNFTBase} from './base/LensNFTBase.sol';
import '../libraries/Constants.sol';

/**
 * TODO: Right now the `TokenData` is stored like this:
 *
 *                  struct TokenData {
 *                      address owner;
 *                      uint96 mintTimestamp;
 *                  }
 *
 * We should check how `owner` and `mintTimestamp` are being aligned in the slot, as maybe we can migrate to this...
 *
 *                  struct FollowData {
 *                      address owner;
 *                      uint48 mintTimestamp;
 *                      uint48 followTimestamp;
 *                      uint256 follower;
 *                  }
 *
 * ...maintaining the old storage and just writing the new struct fields.
 */
struct FollowData {
    uint256 follower;
    uint48 followTimestamp;
    uint48 mintTimestamp;
    address owner;
}

contract FollowNFT {
    error AlreadyFollowing();
    error NotFollowing();
    error FollowTokenDoesNotExist();
    error AlreadyUntied();
    error AlreadyTied();
    error Blocked();
    error OnlyFollowOwner();
    error OnlyWrappedFollows();
    error DoesNotHavePermissions();

    address immutable HUB;

    uint256 internal _profile;
    uint128 internal _followers;
    uint128 internal _lastFollowId;
    mapping(uint256 => FollowData) internal _followDataByFollowId;
    mapping(uint256 => uint256) internal _followIdByFollowerId;
    mapping(uint256 => uint256) internal _approvedToFollowByFollowerId;
    mapping(uint256 => address) internal _approvedToSetFollowerByFollowId;
    mapping(uint256 => address) internal _approvedByFollowId;

    /**
     * @param follower The ID of the profile acting as the follower.
     * @param executor The address executing the operation.
     * @param followId The follow token ID to be used for this follow operation. Use zero if a new follow token should
     * be minted.
     * @param tied Whether the follow should be tied to the profile or untied as ERC-721.
     * @param data Custom data for processing the follow.
     */
    function follow(
        uint256 follower,
        address executor,
        uint256 followId,
        bytes calldata data
    ) onlyHub returns (uint256) {
        if (_followIdByFollowerId[follower] != 0) {
            revert AlreadyFollowing();
        }

        uint256 followIdUsed = followId;
        address followerOwner = IERC721(HUB).ownerOf(follower);
        address currentOwner;
        uint256 currentFollower;

        if (followId == 0) {
            followIdUsed = _followWithoutToken(follower, executor, followerOwner);
        } else if ((currentOwner = _followDataByFollowId[followId].owner) != adderss(0)) {
            _followWithWrappedToken(follower, executor, followId, followerOwner, currentOwner);
        } else if ((currentFollower = _followDataByFollowId[followId].follower) != 0) {
            _followWithUnwrappedToken(follower, executor, followId, followerOwner, currentFollower);
        } else {
            revert FollowTokenDoesNotExist();
        }

        // `Followed` event will be emitted by the hub itself after finishing this execution

        // TODO: This is probably the biggest question. Should follwing with followId != 0 call processFollow again?
        // If not, means the follow NFT works as a "right to follow", no matter which follow module you have now.
        // If yes, means you can customize it. It could make the follow NFT useless, for example rejecting all follows
        // with followId != 0, or having a module with a followId blacklist.

        // The processFollow call passes the followId, so then the follow module decides if allows follows
        // automatically when using a followId, or if it will re-process the conditions

        // processFollow(...); <-- This call is actually in the Hub after this execution finishes

        return followIdUsed;
    }

    function _followWithoutToken(
        uint256 follower,
        address executor,
        address followerOwner
    ) returns (uint256) {
        if (
            followerOwner == executor ||
            ILensHub(HUB).isDelegatedExecutorApproved(followerOwner, executor)
        ) {
            uint128 followId = ++_lastFollowId;
            _followers++;
            _followIdByFollowerId[followId] = follower;
            _followDataByFollowId[followId] = FollowData(
                follower,
                block.timestamp,
                block.timestamp,
                address(0)
            );
            return followId;
        } else {
            revert DoesNotHavePermissions();
        }
    }

    function _followWithWrappedToken(
        uint256 follower,
        address executor,
        uint256 followId,
        address followerOwner,
        address currentOwner
    ) {
        if (
            followerOwner == currentOwner ||
            executor == currentOwner ||
            _approvedToSetFollowerByFollowId[followId] == executor
        ) {
            // The executor is allowed to write the follower in that wrapped token.
            // TODO: Allow approvedForAll operators of currentOwner?
            if (followerOwner != currentOwner && executor != currentOwner) {
                // The `_approvedToSetFollowerByFollowId` was used, now needs to be cleared.
                _approvedToSetFollowerByFollowId[followId] = address(0);
            }
            bool approvedToFollowUsed;
            if (
                executor == followerOwner ||
                ILensHub(HUB).isDelegatedExecutorApproved(followerOwner, executor) ||
                approvedToFollowUsed = (_approvedToFollowByFollowerId[follower] == followId)
            ) {
                // The executor is allowed to follow on behalf.
                if (approvedToFollowUsed) {
                    // The `_approvedToFollowByFollowerId` was used, now needs to be cleared.
                    _approvedToFollowByFollowerId[follower] = 0;
                }
                uint256 currentFollower = _followDataByFollowId[followId].follower;
                if (currentFollower != 0) {
                    // As it has a follower, unfollow first.
                    _followIdByFollowerId[currentFollower] = 0;
                    // TODO: Call hub to emit event.
                    // ILensHub(HUB).emitUnfollowedEvent(...);
                } else {
                    _followers++;
                }
                // Perform the follow.
                _followIdByFollowerId[follower] = followId;
                _followDataByFollowId[followId].follower = follower;
                _followDataByFollowId[followId].followTimestamp = block.timestamp;
            } else {
                revert DoesNotHavePermissions();
            }
        }
    }

    function _followWithUnwrappedToken(
        uint256 follower,
        address executor,
        uint256 followId,
        address followerOwner,
        uint256 currentFollower
    ) {
        address currentFollowerOwner = IERC721(HUB).ownerOf(currentFollower);
        if (currentFollowerOwner == executor || _approvedByFollowId[followId] == executor) {
            // The executor is allowed to transfer the follow.
            // TODO: Allow approvedForAll operators of currentFollowerOwner?
            if (currentFollowerOwner != executor) {
                // `_approvedByFollowId` used, now needs to be cleared.
                _approvedByFollowId[followId] = address(0);
                emit Approval(currentFollowerOwner, address(0), followId);
            }
            bool approvedToFollowUsed;
            if (
                executor == followerOwner ||
                ILensHub(HUB).isDelegatedExecutorApproved(followerOwner, executor) ||
                approvedToFollowUsed = (_approvedToFollowByFollowerId[follower] == followId)
            ) {
                // The executor is allowed to follow on behalf.
                if (approvedToFollowUsed) {
                    // The `_approvedToFollowByFollowerId` was used, now needs to be cleared.
                    _approvedToFollowByFollowerId[follower] = 0;
                }
                // Perform the unfollow.
                _followIdByFollowerId[currentFollower] = 0;
                // TODO: Call hub to emit event.
                // ILensHub(HUB).emitUnfollowedEvent(...);

                // Perform the follow.
                _followIdByFollowerId[follower] = followId;
                _followDataByFollowId[followId].follower = follower;
                _followDataByFollowId[followId].followTimestamp = block.timestamp;
            } else {
                revert DoesNotHavePermissions();
            }
        }
    }

    /**
     * @param follower The ID of the profile that is perfrorming the unfollow operation.
     * @param executor The address executing the operation.
     */
    // TODO: Still wondering if maybe the best solution is wrapping when the unfollow is done by DE, so you always keep
    // the asset.
    function unfollow(uint256 follower, address executor) onlyHub {
        uint256 followId = _followIdByFollowerId[follower];
        if (followId == 0) {
            revert NotFollowing();
        }
        address followerOwner = ILensHub(HUB).ownerOf(follower);

        address owner = _followDataByFollowId[followId].owner;
        _followIdByFollowerId[follower] = 0;
        _followDataByFollowId[followId].follower = 0;
        _followers--;
    }

    function _burn(uint256 followId, address owner) {
        _followDataByFollowId[followId].follower = 0;
        _followDataByFollowId[followId].owner = address(0);
        emit Transfer(owner, address(0), followId);
    }

    // Get the follower profile from a given follow token.
    // Zero if not being used as a follow.
    function getFollower(uint256 followId) public view returns (uint256) {
        FollowData memory followData = _followDataByFollowId[followId];
        if (followData.mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        return followData.follower;
    }

    function isFollowing(uint256 follower) public returns (bool) {
        return _followIdByFollowerId[follower] != 0;
    }

    // Approve someone to set me as follower on a specific asset.
    // For any asset you must use delegated execution feature with a contract adding restrictions.
    function approveFollow(uint256 follower, uint256 followId) {
        // TODO: followId exists, and verify msg.sender owns the follower.
        _approvedToFollowByFollowerId[follower] = followId;
    }

    // Approve someone to set any follower on one of my wrapped tokens.
    // To get the follow you can use `approve`.
    function approveSetFollower(address operator, uint256 followId) {
        address owner;
        if (
            _followDataByFollowId[followId].follower == 0 &&
            (owner = _followDataByFollowId[followId].owner) == address(0)
        ) {
            revert FollowTokenDoesNotExist();
        }
        if (owner == address(0)) {
            revert OnlyWrappedFollows();
        }
        if (msg.sender != owner) {
            revert OnlyFollowOwner();
        }
        _approvedToSetFollower[followId] = operator;
    }

    // TODO
    function _transferHook(uint256 followId) internal {
        _approvedToSetFollower[followId] = address(0);
    }

    /**
     * @dev Unties the follow token from the follower's profile token, and wrapps it into the ERC-721 untied follow
     * collection.
     */
    // TODO: Add a recipient of the wrapped token? so it works like an atomic wrap and transferFrom?
    function untieAndWrap(uint256 followId) {
        FollowData memory followData = _followDataByFollowId[followId];
        if (followData.mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        if (followData.owner != address(0)) {
            revert AlreadyUntied();
        }
        address followerOwner = IERC721(HUB).ownerOf(followData.follower);
        followData.owner = followerOwner;
        // Mint IERC721 untied collection
        _mint(IERC721(HUB).ownerOf(followData.follower), followId);
    }

    /**
     * @dev Unwrapps the follow token from the ERC-721 untied follow collection, and ties it to the follower's profile
     * token.
     */
    // TODO: Add the profile to which should be tied to? or it has to be following already?
    function unwrapAndTie() {
        //
    }

    // Burns the NFT
    function burn() {
        // Burns
        //
        // if has follower...
        // ILensHub(HUB).emitUnfollowEvent();
    }

    // Blocks follow but not having the asset!
    // Maybe this should be in the lenshub? So we don't allow to comment/mirror if blocked
    // But should collect be allowed?
    // And this function should be called by the hub when blockling, so the follow nft is aware of it
    function block(uint256 follower, bool blocked) onlyHub {
        if (isFollowing[follower]) {
            // Unfollows
            // Wraps and unties
        }
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        //
    }

    /////////////////////////////
    //         ERC-721         //
    /////////////////////////////

    function balanceOf(address _owner) external view returns (uint256) {
        // Default ERC-721 impl, take from NFT base contract
    }

    function ownerOf(uint256 followId) external view returns (address) {
        // Default ERC-721 impl, take from NFT base contract
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 followId,
        bytes data
    ) external payable {
        // Default ERC-721 impl, take from NFT base contract
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 followId
    ) external payable {
        // Default ERC-721 impl, take from NFT base contract
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 followId
    ) external payable {
        // Default ERC-721 impl, take from NFT base contract
    }

    /// NOTE: We allow approve for unwrapped assets to, which is not supposed to be part of ERC-721.
    function approve(address operator, uint256 followId) external payable {
        uint256 follower;
        address owner;
        if (
            (follower = _followDataByFollowId[followId].follower) == 0 &&
            (owner = _followDataByFollowId[followId].owner) == address(0)
        ) {
            revert FollowTokenDoesNotExist();
        }
        if (msg.sender != owner) {
            // TODO: Allow approved-for-all operators too
            revert OnlyFollowOwner();
        }
        _approvedByFollowId[followId] = operator;
        emit Approval(
            owner == address(0) ? IERC721(HUB).ownerOf(follower) : owner,
            operator,
            followId
        );
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        // Default ERC-721 impl, take from NFT base contract
    }

    function getApproved(uint256 followId) external view returns (address) {
        // Default ERC-721 impl, take from NFT base contract
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        // Default ERC-721 impl, take from NFT base contract
    }
}
