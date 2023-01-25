// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './ERC721Test.t.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';
import {FollowNFT} from 'contracts/core/FollowNFT.sol';

contract FollowNFTTest is BaseTest, ERC721Test {
    uint256 constant MINT_NEW_TOKEN = 0;
    address targetProfileOwner;
    uint256 targetProfileId;
    address followerProfileOwner;
    uint256 followerProfileId;
    address alreadyFollowingProfileOwner;
    uint256 alreadyFollowingProfileId;
    address targetFollowNFT;
    uint256 lastAssignedTokenId;

    function setUp() public override {
        super.setUp();

        targetProfileOwner = address(0xC0FFEE);
        targetProfileId = _createProfile(targetProfileOwner);
        followerProfileOwner = me;
        followerProfileId = _createProfile(followerProfileOwner);

        alreadyFollowingProfileOwner = address(0xF01108);
        alreadyFollowingProfileId = _createProfile(alreadyFollowingProfileOwner);
        lastAssignedTokenId = _follow(
            alreadyFollowingProfileOwner,
            alreadyFollowingProfileId,
            targetProfileId,
            0,
            ''
        )[0];

        targetFollowNFT = hub.getFollowNFT(targetProfileId);
        followNFT = FollowNFT(targetFollowNFT);
    }

    function _mintERC721(address to) internal virtual override returns (uint256) {
        uint256 tokenId = _follow(to, _createProfile(to), targetProfileId, 0, '')[0];
        vm.prank(to);
        followNFT.untieAndWrap(tokenId);
        return tokenId;
    }

    function _burnERC721(uint256 tokenId) internal virtual override {
        return followNFT.burn(tokenId);
    }

    function _getERC721TokenAddress() internal view virtual override returns (address) {
        return targetFollowNFT;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Follow - General - Negatives
    //////////////////////////////////////////////////////////

    function testCannotCallFollowIfNotTheHub(address sender) public {
        vm.assume(sender != address(hub));
        vm.assume(sender != address(0));

        vm.prank(sender);

        vm.expectRevert(Errors.NotHub.selector);
        followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });
    }

    function testCannotFollowIfAlreadyFollowing() public {
        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.AlreadyFollowing.selector);
        followNFT.follow({
            followerProfileId: alreadyFollowingProfileId,
            executor: alreadyFollowingProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });
    }

    function testCannotFollowWithTokenIfTheTokenDoesNotExist(uint256 unexistentTokenId) public {
        vm.assume(unexistentTokenId != MINT_NEW_TOKEN);
        vm.assume(followNFT.getFollowerProfileId(unexistentTokenId) == 0);
        vm.assume(!followNFT.exists(unexistentTokenId));
        vm.assume(followNFT.getProfileIdAllowedToRecover(unexistentTokenId) == 0);

        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.FollowTokenDoesNotExist.selector);

        followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: unexistentTokenId
        });
    }

    //////////////////////////////////////////////////////////
    // Follow - Minting new token - Negatives
    //////////////////////////////////////////////////////////

    // No negatives when minting a new token, all the failing cases will occur at LensHub level. See `FollowTest.t.sol`.

    //////////////////////////////////////////////////////////
    // Follow - Minting new token - Scenarios
    //////////////////////////////////////////////////////////

    function testNewMintedTokenIdIsLastAssignedPlusOne() public {
        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        assertEq(assignedTokenId, lastAssignedTokenId + 1);
    }

    function testFollowingMintingNewTokenSetsFollowerStatusCorrectly() public {
        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        bool isFollowing = followNFT.isFollowing(followerProfileId);
        assertEq(isFollowing, true);

        uint256 followerProfileIdSet = followNFT.getFollowerProfileId(assignedTokenId);
        assertEq(followerProfileIdSet, followerProfileId);

        uint256 followIdByFollower = followNFT.getFollowTokenId(followerProfileId);
        assertEq(followIdByFollower, assignedTokenId);
    }

    function testExpectedFollowDataAfterMintingNewToken() public {
        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        IFollowNFT.FollowData memory followData = followNFT.getFollowData(assignedTokenId);

        assertEq(followData.followerProfileId, followerProfileId);
        assertEq(followData.originalFollowTimestamp, block.timestamp);
        assertEq(followData.followTimestamp, block.timestamp);
        assertEq(followData.profileIdAllowedToRecover, 0);
    }

    function testFollowTokenIsByDefaultUnwrapped() public {
        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        assertTrue(followNFT.isFollowing(followerProfileId));

        vm.expectRevert(Errors.ERC721Time_OwnerQueryForNonexistantToken.selector);
        followNFT.ownerOf(assignedTokenId);
    }

    //////////////////////////////////////////////////////////
    // Follow - With unwrapped token - Scenarios
    //////////////////////////////////////////////////////////

    function testFollowWithUnwrappedTokenWhenCurrentFollowerWasBurnedAndExecutorIsFollowerOwner()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        hub.burn(alreadyFollowingProfileId);
        assertFalse(hub.exists(alreadyFollowingProfileId));

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    function testFollowWithUnwrappedTokenWhenCurrentFollowerWasBurnedAndExecutorIsApprovedDelegatee(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != followerProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        hub.burn(alreadyFollowingProfileId);
        assertFalse(hub.exists(alreadyFollowingProfileId));

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: executorAsApprovedDelegatee,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    //////////////////////////////////////////////////////////
    // Follow - With wrapped token - Scenarios
    //////////////////////////////////////////////////////////

    function testFollowWithWrappedTokenWhenFollowerOwnerOwnsFollowTokenAndIsActingAsExecutor()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followerProfileOwner, followTokenId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
    }

    function testFollowWithWrappedTokenWhenFollowerOwnerAlsoOwnsFollowTokenAndExecutorIsApprovedDelegatee(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != followerProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followerProfileOwner, followTokenId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: executorAsApprovedDelegatee,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
    }

    function testFollowWithWrappedTokenWhenExecutorOwnsFollowTokenAndExecutorIsApprovedDelegatee(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != followerProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(
            alreadyFollowingProfileOwner,
            executorAsApprovedDelegatee,
            followTokenId
        );

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: executorAsApprovedDelegatee,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
    }

    function testFollowWithWrappedTokenWhenExecutorIsApprovedForAllAndExecutorIsFollowerOwner()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.setApprovalForAll(followerProfileOwner, true);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
    }

    function testFollowWithWrappedTokenWhenExecutorIsApprovedForAllAndExecutorIsApprovedDelegatee(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != followerProfileOwner);
        vm.assume(executorAsApprovedDelegatee != alreadyFollowingProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.setApprovalForAll(executorAsApprovedDelegatee, true);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: executorAsApprovedDelegatee,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
    }

    function testFollowWithWrappedTokenWhenProfileIsApprovedToFollowAndExecutorIsFollowerOwner()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    function testFollowWithWrappedTokenWhenProfileIsApprovedToFollowAndExecutorIsApprovedDelegatee(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != followerProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: executorAsApprovedDelegatee,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    //////////////////////////////////////////////////////////
    // Follow - Recovering token - Scenarios
    //////////////////////////////////////////////////////////

    function testFollowRecoveringToken() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));

        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: alreadyFollowingProfileOwner,
            isExecutorApproved: false,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: alreadyFollowingProfileId,
            executor: alreadyFollowingProfileOwner,
            followTokenId: followTokenId
        });

        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(alreadyFollowingProfileId), followTokenId);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Unfollow - Negatives
    //////////////////////////////////////////////////////////

    function testCannotCallUnfollowIfNotTheHub(address sender) public {
        vm.assume(sender != address(hub));
        vm.assume(sender != address(0));

        vm.prank(sender);

        vm.expectRevert(Errors.NotHub.selector);
        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: alreadyFollowingProfileOwner,
            isExecutorApproved: false,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });
    }

    function testCannotUnfollowIfNotAlreadyFollowing() public {
        assertFalse(followNFT.isFollowing(followerProfileId));

        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.NotFollowing.selector);
        followNFT.unfollow({
            unfollowerProfileId: followerProfileId,
            executor: followerProfileOwner,
            isExecutorApproved: false,
            unfollowerProfileOwner: followerProfileOwner
        });
    }

    function testCannotUnfollowIfTokenIsWrappedAndExecutorIsNotApprovedOrUnfollowerOwnerOrTokenOwnerOrApprovedForAll(
        address executor
    ) public {
        vm.assume(executor != alreadyFollowingProfileOwner);
        vm.assume(!hub.isDelegatedExecutorApproved(alreadyFollowingProfileOwner, executor));
        vm.assume(!followNFT.isApprovedForAll(alreadyFollowingProfileOwner, executor));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: executor,
            isExecutorApproved: false,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });
    }

    function testCannotUnfollowIfTokenIsUnwrappedAndExecutorIsNotApprovedOrUnfollowerOwner(
        address executor
    ) public {
        vm.assume(executor != alreadyFollowingProfileOwner);
        vm.assume(!hub.isDelegatedExecutorApproved(alreadyFollowingProfileOwner, executor));

        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: executor,
            isExecutorApproved: false,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });
    }

    //////////////////////////////////////////////////////////
    // Unfollow - Scenarios
    //////////////////////////////////////////////////////////

    function testUnfollowAsFollowerProfileOwnerWhenTokenIsWrapped() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(address(hub));

        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: alreadyFollowingProfileOwner,
            isExecutorApproved: false,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    function testUnfollowAsApprovedDelegatedExecutorOfFollowerOwnerWhenTokenIsWrapped(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != alreadyFollowingProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(address(hub));

        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: executorAsApprovedDelegatee,
            isExecutorApproved: true,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    function testUnfollowAsFollowTokenOwnerWhenTokenIsWrapped(address followTokenOwner) public {
        vm.assume(followTokenOwner != alreadyFollowingProfileOwner);
        vm.assume(followTokenOwner != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followTokenOwner, followTokenId);

        vm.prank(address(hub));

        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: followTokenOwner,
            isExecutorApproved: false,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    function testUnfollowAsApprovedForAllByTokenOwnerWhenTokenIsWrapped(address approvedForAll)
        public
    {
        vm.assume(approvedForAll != alreadyFollowingProfileOwner);
        vm.assume(approvedForAll != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.setApprovalForAll(approvedForAll, true);

        vm.prank(address(hub));

        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: approvedForAll,
            isExecutorApproved: false,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    function testUnfollowAsFollowerProfileOwnerWhenTokenIsUnwrapped() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));

        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: alreadyFollowingProfileOwner,
            isExecutorApproved: false,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);
    }

    function testUnfollowAsApprovedDelegatedExecutorOfFollowerOwnerWhenTokenIsUnwrapped(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != alreadyFollowingProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));

        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: executorAsApprovedDelegatee,
            isExecutorApproved: true,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Untie & Wrap - Negatives
    //////////////////////////////////////////////////////////

    function testCannotUntieAndWrapIfAlreadyWrapped() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);

        vm.expectRevert(IFollowNFT.AlreadyUntiedAndWrapped.selector);
        followNFT.untieAndWrap(followTokenId);
    }

    function testCannotUntieAndWrapIfTokenDoesNotExist(uint256 unexistentTokenId) public {
        vm.assume(followNFT.getFollowerProfileId(unexistentTokenId) == 0);
        vm.assume(!followNFT.exists(unexistentTokenId));

        vm.expectRevert(IFollowNFT.FollowTokenDoesNotExist.selector);
        followNFT.untieAndWrap(unexistentTokenId);
    }

    function testCannotUntieAndWrapIfSenderIsNotFollowerOwner(address notFollowerOwner) public {
        vm.assume(notFollowerOwner != alreadyFollowingProfileOwner);
        vm.assume(notFollowerOwner != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(notFollowerOwner);

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        followNFT.untieAndWrap(followTokenId);
    }

    //////////////////////////////////////////////////////////
    // Untie & Wrap - Scenarios
    //////////////////////////////////////////////////////////

    function testWrappedTokenOwnerIsFollowerProfileOwnerAfterUntyingAndWrapping() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        assertEq(followNFT.ownerOf(followTokenId), alreadyFollowingProfileOwner);
    }

    function testWrappedTokenStillHeldByPreviousFollowerOwnerAfterAFollowerProfileTransfer(
        address newFollowerProfileOwner
    ) public {
        vm.assume(newFollowerProfileOwner != followerProfileOwner);
        vm.assume(newFollowerProfileOwner != address(0));

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        vm.prank(followerProfileOwner);
        followNFT.untieAndWrap(assignedTokenId);

        assertEq(followNFT.ownerOf(assignedTokenId), followerProfileOwner);

        assertTrue(followNFT.isFollowing(followerProfileId));
        uint256 followerProfileIdSet = followNFT.getFollowerProfileId(assignedTokenId);
        assertEq(followerProfileIdSet, followerProfileId);

        vm.prank(followerProfileOwner);
        hub.transferFrom(followerProfileOwner, newFollowerProfileOwner, followerProfileId);

        assertEq(hub.ownerOf(followerProfileId), newFollowerProfileOwner);
        assertEq(followNFT.ownerOf(assignedTokenId), followerProfileOwner);

        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(followerProfileIdSet, followNFT.getFollowerProfileId(assignedTokenId));
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Unwrap & Tie - Negatives
    //////////////////////////////////////////////////////////

    function testCannotUnwrapAndTieIfTokenDoesNotHaveAFollowerSet() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(address(hub));
        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: alreadyFollowingProfileOwner,
            isExecutorApproved: false,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });

        vm.expectRevert(IFollowNFT.NotFollowing.selector);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.unwrapAndTie(followTokenId);
    }

    function testCannotUnwrapAndTieIfTokenIsAlreadyUnwrappedAndTied() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.expectRevert(Errors.ERC721Time_OperatorQueryForNonexistantToken.selector);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.unwrapAndTie(followTokenId);
    }

    function testCannotUnwrapAndTieIfSenderIsNotTokenOwnerOrApprovedOrApprovedForAll(address sender)
        public
    {
        // You can't approve a token that is not wrapped, so no need to check for `followNFT.getApproved(followTokenId)`
        vm.assume(sender != alreadyFollowingProfileOwner);
        vm.assume(sender != address(0));
        vm.assume(!followNFT.isApprovedForAll(alreadyFollowingProfileOwner, sender));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.expectRevert(Errors.NotOwnerOrApproved.selector);
        vm.prank(sender);
        followNFT.unwrapAndTie(followTokenId);
    }

    //////////////////////////////////////////////////////////
    // Unwrap & Tie - Scenarios
    //////////////////////////////////////////////////////////

    function testTokenOwnerCanUnwrapAndTieIt() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.unwrapAndTie(followTokenId);

        assertFalse(followNFT.exists(followTokenId));
    }

    function testApprovedForAllCanUnwrapAndTieAToken(address approvedForAll) public {
        vm.assume(approvedForAll != alreadyFollowingProfileOwner);
        vm.assume(approvedForAll != address(0));

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.setApprovalForAll(approvedForAll, true);

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(approvedForAll);
        followNFT.unwrapAndTie(followTokenId);

        assertFalse(followNFT.exists(followTokenId));
    }

    function testApprovedForATokenCanUnwrapAndTieIt(address approved) public {
        vm.assume(approved != alreadyFollowingProfileOwner);
        vm.assume(approved != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approve(approved, followTokenId);

        vm.prank(approved);
        followNFT.unwrapAndTie(followTokenId);

        assertFalse(followNFT.exists(followTokenId));
    }

    function testUnwrappedTokenStillTiedToFollowerProfileAfterAFollowerProfileTransfer(
        address newFollowerProfileOwner
    ) public {
        vm.assume(newFollowerProfileOwner != followerProfileOwner);
        vm.assume(newFollowerProfileOwner != address(0));

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        assertTrue(followNFT.isFollowing(followerProfileId));
        uint256 followerProfileIdSet = followNFT.getFollowerProfileId(assignedTokenId);
        assertEq(followerProfileIdSet, followerProfileId);

        vm.prank(followerProfileOwner);
        hub.transferFrom(followerProfileOwner, newFollowerProfileOwner, followerProfileId);

        assertEq(hub.ownerOf(followerProfileId), newFollowerProfileOwner);

        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(followerProfileIdSet, followNFT.getFollowerProfileId(assignedTokenId));

        vm.prank(newFollowerProfileOwner);
        followNFT.untieAndWrap(assignedTokenId);
        assertEq(followNFT.ownerOf(assignedTokenId), newFollowerProfileOwner);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Block - Negatives
    //////////////////////////////////////////////////////////

    function testCannotCallBlockIfNotTheHub(address sender) public {
        vm.assume(sender != address(hub));
        vm.assume(sender != address(0));

        vm.prank(sender);

        vm.expectRevert(Errors.NotHub.selector);
        followNFT.block(followerProfileId);
    }

    //////////////////////////////////////////////////////////
    // Block - Scenarios
    //////////////////////////////////////////////////////////

    function testCanBlockSomeoneAlreadyBlocked() public {
        vm.prank(address(hub));
        followNFT.block(followerProfileId);

        vm.prank(address(hub));
        followNFT.block(followerProfileId);
    }

    function testBlockingFollowerThatWasFollowingWithWrappedTokenMakesHimUnfollowButKeepsTheWrappedToken()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));

        vm.prank(address(hub));
        followNFT.block(alreadyFollowingProfileId);

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));

        assertEq(followNFT.ownerOf(followTokenId), alreadyFollowingProfileOwner);
    }

    function testBlockingFollowerThatWasFollowingWithUnwrappedFirstWrapsTokenAndThenMakesHimUnfollowKeepingItWrapped()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        assertFalse(followNFT.exists(followTokenId));
        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));

        vm.prank(address(hub));
        followNFT.block(alreadyFollowingProfileId);

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.ownerOf(followTokenId), alreadyFollowingProfileOwner);
    }

    function testBlockingProfileThatWasNotFollowingButItsOwnerHoldsWrappedFollowTokenDoesNotChangeAnything()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(address(hub));
        followNFT.unfollow({
            unfollowerProfileId: alreadyFollowingProfileId,
            executor: alreadyFollowingProfileOwner,
            isExecutorApproved: false,
            unfollowerProfileOwner: alreadyFollowingProfileOwner
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.ownerOf(followTokenId), alreadyFollowingProfileOwner);

        vm.prank(address(hub));
        followNFT.block(alreadyFollowingProfileId);

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.ownerOf(followTokenId), alreadyFollowingProfileOwner);
    }

    function testBlockingProfileThatWasNotFollowingButItsOwnerHoldsWrappedFollowTokenWithFollowerDoesNotChangeAnything()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followerProfileOwner, followTokenId);

        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.ownerOf(followTokenId), followerProfileOwner);

        vm.prank(address(hub));
        followNFT.block(followerProfileId);

        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.ownerOf(followTokenId), followerProfileOwner);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Approve follow - Negatives
    //////////////////////////////////////////////////////////

    function testCannotApproveFollowForUnexistentProfile(uint256 unexistentProfileId) public {
        vm.assume(!hub.exists(unexistentProfileId));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(unexistentProfileId, followTokenId);
    }

    function testCannotApproveFollowForUnexistentFollowToken(uint256 unexistentFollowTokenId)
        public
    {
        vm.assume(!followNFT.exists(unexistentFollowTokenId));
        vm.assume(followNFT.getFollowerProfileId(unexistentFollowTokenId) == 0);

        vm.expectRevert(IFollowNFT.FollowTokenDoesNotExist.selector);
        followNFT.approveFollow(followerProfileId, unexistentFollowTokenId);
    }

    function testCannotApproveFollowForWrappedTokenIfCallerIsNotItsOwnerOrApprovedForAllByHim(
        address sender
    ) public {
        vm.assume(sender != alreadyFollowingProfileOwner);
        vm.assume(!followNFT.isApprovedForAll(alreadyFollowingProfileOwner, sender));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        vm.prank(sender);
        followNFT.approveFollow(followerProfileId, followTokenId);
    }

    function testCannotApproveFollowIfTokenIsUnwrapped() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.expectRevert(IFollowNFT.OnlyWrappedFollowTokens.selector);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);
    }

    //////////////////////////////////////////////////////////
    // Approve follow - Scenarios
    //////////////////////////////////////////////////////////

    function testApproveFollowWhenTokenIsWrappedAndCallerIsItsOwner() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);
    }

    function testApproveFollowWhenTokenIsWrappedAndCallerIsApprovedForAllByItsOwner(
        address approvedForAll
    ) public {
        vm.assume(approvedForAll != alreadyFollowingProfileOwner);
        vm.assume(approvedForAll != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.setApprovalForAll(approvedForAll, true);

        vm.prank(approvedForAll);
        followNFT.approveFollow(followerProfileId, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);
    }

    function testFollowApprovalIsClearedAfterUnwrapping() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.unwrapAndTie(followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), 0);

        // Wraps again and checks that it keeps being clear.

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    function testFollowApprovalIsClearedAfterTransfer() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followerProfileOwner, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), 0);

        // Transfers back to previous owner and checks that it keeps being clear.

        vm.prank(followerProfileOwner);
        followNFT.transferFrom(followerProfileOwner, alreadyFollowingProfileOwner, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    function testFollowApprovalIsClearedAfterBurning() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.burn(followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }
}
