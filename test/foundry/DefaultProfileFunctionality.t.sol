// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract DefaultProfileFunctionalityTest is BaseTest {
    function setUp() public override {
        TestSetup.setUp();
    }

    // NEGATIVES

    function testCannotSetProfileOwnedByAnotherAccount() public {
        vm.prank(otherSigner);
        vm.expectRevert(Errors.NotProfileOwner.selector);
        hub.setDefaultProfile(otherSigner, FIRST_PROFILE_ID);
    }
}
