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

    // Follow - General - Negatives

    function testCannotCallFollowIfNotTheHub(address sender) public {
        vm.assume(sender != address(hub));
        vm.assume(sender != address(0));

        vm.prank(sender);

        vm.expectRevert(Errors.NotHub.selector);
        followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
            followTokenId: MINT_NEW_TOKEN
        });
    }

    function testCannotFollowIfAlreadyFollowing() public {
        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.AlreadyFollowing.selector);
        followNFT.follow({
            followerProfileId: alreadyFollowingProfileId,
            executor: alreadyFollowingProfileOwner,
            followerProfileOwner: alreadyFollowingProfileOwner,
            isExecutorApproved: false,
            followTokenId: MINT_NEW_TOKEN
        });
    }

    // Follow - General - Scenarios

    function testUnwrappedTokenStillTiedToFollowerProfileAfterAFollowerProfileTransfer(
        address newFollowerProfileOwner
    ) public {
        vm.assume(newFollowerProfileOwner != followerProfileOwner);
        vm.assume(newFollowerProfileOwner != address(0));

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
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

    function testWrappedTokenStillHeldByPreviousFollowerOwnerAfterAFollowerProfileTransfer(
        address newFollowerProfileOwner
    ) public {
        vm.assume(newFollowerProfileOwner != followerProfileOwner);
        vm.assume(newFollowerProfileOwner != address(0));

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
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

    // Follow - Minting new token - Negatives

    function testCannotFollowMintingNewTokenIfExecutorIsNotTheProfileOwnerOrHisApprovedExecutor(
        address executor
    ) public {
        vm.assume(executor != followerProfileOwner);
        vm.assume(executor != address(0));
        vm.assume(!hub.isDelegatedExecutorApproved(followerProfileOwner, executor));

        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);

        followNFT.follow({
            followerProfileId: followerProfileId,
            executor: executor,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
            followTokenId: MINT_NEW_TOKEN
        });
    }

    // Follow - Minting new token - Scenarios

    function testNewMintedTokenIdIsLastAssignedPlusOne() public {
        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
            followTokenId: MINT_NEW_TOKEN
        });

        assertEq(assignedTokenId, lastAssignedTokenId + 1);
    }

    function testFollowMintingNewTokenIncrementsFollowersByOne() public {
        uint256 followersBefore = followNFT.getFollowers();

        vm.prank(address(hub));

        uint256 followersAfter = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
            followTokenId: MINT_NEW_TOKEN
        });

        assertEq(followersAfter, followersBefore + 1);
    }

    function testFollowingMintingNewTokenSetsFollowerStatusCorrectly() public {
        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
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
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
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
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
            followTokenId: MINT_NEW_TOKEN
        });

        assertTrue(followNFT.isFollowing(followerProfileId));

        vm.expectRevert(Errors.ERC721Time_OwnerQueryForNonexistantToken.selector);
        followNFT.ownerOf(assignedTokenId);
    }

    // Follow - With unwrapped token - Negatives

    function testCannotFollowWithUnwrappedTokenIfExecutorIsNotTheProfileOwnerOrHisApprovedExecutor(
        address executor
    ) public {
        vm.assume(executor != followerProfileOwner);
        vm.assume(executor != address(0));
        vm.assume(!hub.isDelegatedExecutorApproved(followerProfileOwner, executor));

        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        assertFalse(followNFT.exists(followTokenId));

        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);

        followNFT.follow({
            followerProfileId: followerProfileId,
            executor: executor,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
            followTokenId: followTokenId
        });
    }

    // Follow - With unwrapped token - Scenarios

    function testFollowWithUnwrappedTokenWhenExecutorOwnsCurrentAndNewFollowerProfile() public {
        vm.prank(followerProfileOwner);
        hub.transferFrom(followerProfileOwner, alreadyFollowingProfileOwner, followerProfileId);

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: alreadyFollowingProfileOwner,
            followerProfileOwner: alreadyFollowingProfileOwner,
            isExecutorApproved: false,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
    }

    function testFollowWithUnwrappedTokenWhenExecutorOwnsCurrentFollowerProfileAndIsApprovedDelegateeOfNewFollowerProfileOwner()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: alreadyFollowingProfileOwner,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: true,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
    }

    function testFollowWithUnwrappedTokenWhenProfileIsApprovedToFollowAndExecutorIsFollowerOwner()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: followerProfileOwner,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    function testFollowWithUnwrappedTokenWhenProfileIsApprovedToFollowAndExecutorIsApprovedDelegatee(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != followerProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            executor: executorAsApprovedDelegatee,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: true,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

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
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
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
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: true,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    // Follow - With wrapped token - Negatives

    function testCannotFollowWithWrappedTokenIfExecutorIsNotTheProfileOwnerOrHisApprovedExecutor(
        address executor
    ) public {
        vm.assume(executor != followerProfileOwner);
        vm.assume(executor != address(0));
        vm.assume(!hub.isDelegatedExecutorApproved(followerProfileOwner, executor));

        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.untieAndWrap(followTokenId);

        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);

        followNFT.follow({
            followerProfileId: followerProfileId,
            executor: executor,
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
            followTokenId: followTokenId
        });
    }

    // Follow - With wrapped token - Scenarios

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
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
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
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: true,
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
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: true,
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
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
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
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: true,
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
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: false,
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
            followerProfileOwner: followerProfileOwner,
            isExecutorApproved: true,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    // Follow - Recovering token - Scenarios

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
            followerProfileOwner: alreadyFollowingProfileOwner,
            isExecutorApproved: false,
            followTokenId: followTokenId
        });

        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(alreadyFollowingProfileId), followTokenId);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }
}
