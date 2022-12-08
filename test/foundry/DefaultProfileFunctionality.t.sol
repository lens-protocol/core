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

    // SCENARIOS

    function testCanSetDefaultProfile() public {
        vm.prank(profileOwner);
        hub.setDefaultProfile(profileOwner, FIRST_PROFILE_ID);
        assertEq(hub.getDefaultProfile(profileOwner), FIRST_PROFILE_ID);
    }

    function testCanSetThenUnsetDefaultProfile() public {
        vm.startPrank(profileOwner);
        hub.setDefaultProfile(profileOwner, FIRST_PROFILE_ID);
        assertEq(hub.getDefaultProfile(profileOwner), FIRST_PROFILE_ID);
        hub.setDefaultProfile(profileOwner, 0);
        assertEq(hub.getDefaultProfile(profileOwner), 0);

        vm.stopPrank();
    }

    function testCanSetThenChangeDefaultProfile() public {
        vm.prank(profileOwner);
        hub.setDefaultProfile(profileOwner, FIRST_PROFILE_ID);
        assertEq(hub.getDefaultProfile(profileOwner), FIRST_PROFILE_ID);

        vm.prank(me);
        uint256 newProfileId = hub.createProfile(mockCreateProfileData);

        vm.prank(profileOwner);
        hub.setDefaultProfile(profileOwner, newProfileId);
        assertEq(hub.getDefaultProfile(profileOwner), newProfileId);
    }
}
