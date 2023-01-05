// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./base/BaseTest.t.sol";

import { Events } from 'contracts/libraries/Events.sol';

contract EventTest is BaseTest {
    function setUp() public override {
        TestSetup.setUp();
    }

    // MISC

    function testProxyInitEmitsExpectedEvents() public {

        
        // Events to detect on proxy init:
        // Upgraded
        // AdminChanged
        // GovernanceSet
        // StateSet
        // BaseInitialized
    }

    // HUB GOVERNANCE

    function testGovernanceEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.GovernanceSet(governance, governance, me, block.timestamp);
        hub.setGovernance(me);
    }

    function testEmergencyAdminChangeEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.EmergencyAdminSet(governance, address(0), me, block.timestamp);
        hub.setEmergencyAdmin(me);
    }

    function testProtocolStateChangeByGovEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(governance, DataTypes.ProtocolState.Unpaused, DataTypes.ProtocolState.Paused, block.timestamp);
        hub.setState(DataTypes.ProtocolState.Paused);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(governance, DataTypes.ProtocolState.Paused, DataTypes.ProtocolState.PublishingPaused, block.timestamp);
        hub.setState(DataTypes.ProtocolState.PublishingPaused);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(governance, DataTypes.ProtocolState.PublishingPaused, DataTypes.ProtocolState.Unpaused, block.timestamp);
        hub.setState(DataTypes.ProtocolState.Unpaused);
    }

    function testProtocolStateChangeByEmergencyAdminEmitsExpectedEvents() public {
        vm.prank(governance);
        hub.setEmergencyAdmin(profileOwner);

        vm.prank(profileOwner);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(profileOwner, DataTypes.ProtocolState.Unpaused, DataTypes.ProtocolState.PublishingPaused, block.timestamp);
        hub.setState(DataTypes.ProtocolState.PublishingPaused);

        vm.prank(profileOwner);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(profileOwner, DataTypes.ProtocolState.PublishingPaused, DataTypes.ProtocolState.Paused, block.timestamp);
        hub.setState(DataTypes.ProtocolState.Paused);
    }

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
