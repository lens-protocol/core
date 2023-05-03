// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';

contract GovernanceFunctionsTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    // NEGATIVES

    function testUserCannotCallGovernanceFunctions() public {
        vm.startPrank(defaultAccount.owner);

        vm.expectRevert(Errors.NotGovernance.selector);
        hub.setGovernance(defaultAccount.owner);

        vm.expectRevert(Errors.NotGovernance.selector);
        hub.whitelistFollowModule(defaultAccount.owner, true);

        vm.expectRevert(Errors.NotGovernance.selector);
        hub.whitelistReferenceModule(defaultAccount.owner, true);

        // TODO: Proper test
        // vm.expectRevert(Errors.NotGovernance.selector);
        // hub.whitelistCollectModule(defaultAccount.owner, true);

        vm.stopPrank();
    }

    // SCENARIOS

    function testGovernanceCanWhitelistAndUnwhitelistModules() public {
        vm.startPrank(governance);

        // Whitelist

        assertEq(hub.isFollowModuleWhitelisted(defaultAccount.owner), false);
        hub.whitelistFollowModule(defaultAccount.owner, true);
        assertEq(hub.isFollowModuleWhitelisted(defaultAccount.owner), true);

        assertEq(hub.isReferenceModuleWhitelisted(defaultAccount.owner), false);
        hub.whitelistReferenceModule(defaultAccount.owner, true);
        assertEq(hub.isReferenceModuleWhitelisted(defaultAccount.owner), true);

        // TODO: Proper test
        // assertEq(hub.isCollectModuleWhitelisted(defaultAccount.owner), false);
        // hub.whitelistCollectModule(defaultAccount.owner, true);
        // assertEq(hub.isCollectModuleWhitelisted(defaultAccount.owner), true);

        // Unwhitelist

        hub.whitelistFollowModule(defaultAccount.owner, false);
        assertEq(hub.isFollowModuleWhitelisted(defaultAccount.owner), false);

        hub.whitelistReferenceModule(defaultAccount.owner, false);
        assertEq(hub.isReferenceModuleWhitelisted(defaultAccount.owner), false);

        // TODO: Proper test
        // hub.whitelistCollectModule(defaultAccount.owner, false);
        // assertEq(hub.isCollectModuleWhitelisted(defaultAccount.owner), false);

        vm.stopPrank();
    }

    function testGovernanceCanChangeGovernanceAddress() public {
        vm.startPrank(governance);

        assertEq(hub.getGovernance(), governance);
        hub.setGovernance(defaultAccount.owner);
        assertEq(hub.getGovernance(), defaultAccount.owner);

        vm.stopPrank();
    }
}
