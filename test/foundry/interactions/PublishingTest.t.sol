// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '../base/BaseTest.t.sol';

contract PublishingTest is BaseTest {
    // negatives
    function testPostCallerInvalidFails() public {
        vm.prank(otherUser);
        vm.expectRevert(Errors.CallerInvalid.selector);
        hub.post(mockPostData);
    }
}
