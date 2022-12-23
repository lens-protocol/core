// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./base/BaseTest.t.sol";

contract EventTest is BaseTest {
    function setUp() public override {
        TestSetup.setUp();
    }

    // MISC

    function testProxyInitEmitsExpectedEvents() public {}

    // HUB GOVERNANCE

    function testGovernanceEmitsExpectedEvents() public {}

    function testEmergencyAdminChangeEmitsExpectedEvents() public {}

    function testProtocolStateChangeEmitsExpectedEvents() public {}

    function testFollowModuleWhitelistEmitsExpectedEvents() public {}

    function testReferenceModuleWhitelistEmitsExpectedEvents() public {}

    function testCollectModuleWhitelistEmitsExpectedEvents() public {}

    // HUB INTERACTION

    function testProfileCreationEmitsExpectedEvents() public {}

    function testProfileCreationForOtherUserEmitsExpectedEvents() public {}

    function testSettingFollowModuleEmitsExpectedEvents() public {}

    function testSettingDispatcherEmitsExpectedEvents() public {}

    function testPostingEmitsExpectedEvents() public {}

    function testCommentingEmitsExpectedEvents() public {}

    function testMirroringEmitsExpectedEvents() public {}

    function testFollowingEmitsExpectedEvents() public {}

    function testCollectingEmitsExpectedEvents() public {}

    function testCollectingFromMirrorEmitsExpectedEvents() public {}

    // MODULE GLOBALS GOVERNANCE

    function testGovernanceChangeEmitsExpectedEvents() public {}

    function testTreasuryChangeEmitsExpectedEvents() public {}

    function testTreasuryFeeChangeEmitsExpectedEvents() public {}

    function testCurrencyWhitelistEmitsExpectedEvents() public {}
}
