// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '../base/BaseTest.t.sol';

contract PublishingTest is BaseTest {
    // negatives
    function testPostNotExecutorFails() public {
        vm.expectRevert(Errors.CallerInvalid.selector);
        hub.post(mockPostData);
    }

    function testCommentNotExecutorFails() public {
        vm.prank(profileOwner);
        hub.post(mockPostData);

        vm.expectRevert(Errors.CallerInvalid.selector);
        hub.comment(mockCommentData);
    }

    function testMirrorNotExecutorFails() public {
        vm.prank(profileOwner);
        hub.post(mockPostData);

        vm.expectRevert(Errors.CallerInvalid.selector);
        hub.mirror(mockMirrorData);
    }

    // positives
    function testExecutorPost() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherUser, true);

        vm.prank(otherUser);
        hub.post(mockPostData);
    }

    function testExecutorComment() public {
        vm.startPrank(profileOwner);
        hub.post(mockPostData);
        hub.setDelegatedExecutorApproval(otherUser, true);
        vm.stopPrank();

        vm.prank(otherUser);
        hub.comment(mockCommentData);
    }

    function testExecutorMirror() public {
        vm.startPrank(profileOwner);
        hub.post(mockPostData);
        hub.setDelegatedExecutorApproval(otherUser, true);
        vm.stopPrank();

        vm.prank(otherUser);
        hub.mirror(mockMirrorData);
    }
}
