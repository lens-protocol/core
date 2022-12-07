// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract GovernanceFunctionsTest is BaseTest {
    function setUp() public virtual override {
        TestSetup.setUp();
    }

    // NEGATIVES

    function testUserCannotCallGovernanceFunctions() public {
        vm.startPrank(profileOwner);

        vm.expectRevert(Errors.NotGovernance.selector);
        hub.setGovernance(profileOwner);

        vm.expectRevert(Errors.NotGovernance.selector);
        hub.whitelistFollowModule(profileOwner, true);

        vm.expectRevert(Errors.NotGovernance.selector);
        hub.whitelistReferenceModule(profileOwner, true);

        vm.expectRevert(Errors.NotGovernance.selector);
        hub.whitelistCollectModule(profileOwner, true);

        vm.stopPrank();
    }

    // SCENARIOS

    function testGovernanceCanWhitelistModules() public {}

    function testGovernanceCanUnwhitelistModules() public {}

    function testGovernanceCanChangeGovernanceAddress() public {}
}
