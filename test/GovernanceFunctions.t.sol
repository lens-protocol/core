// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';

contract GovernanceFunctionsTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    // NEGATIVES

    function testCannot_SetGovernance_IfNotGovernance(address nonGovernanceCaller, address randomAddress) public {
        vm.assume(nonGovernanceCaller != governance);
        vm.assume(nonGovernanceCaller != address(0));
        vm.assume(!_isLensHubProxyAdmin(nonGovernanceCaller));

        vm.expectRevert(Errors.NotGovernance.selector);
        vm.prank(nonGovernanceCaller);
        hub.setGovernance(randomAddress);
    }

    function testCannot_SetEmergencyAdmin_IfNotGovernance(address nonGovernanceCaller, address randomAddress) public {
        vm.assume(nonGovernanceCaller != governance);
        vm.assume(nonGovernanceCaller != address(0));
        vm.assume(!_isLensHubProxyAdmin(nonGovernanceCaller));

        vm.expectRevert(Errors.NotGovernance.selector);
        vm.prank(nonGovernanceCaller);
        hub.setEmergencyAdmin(randomAddress);
    }

    function testCannot_SetState_IfNotGovernanceOrEmergencyAdmin(
        address nonGovernanceOrEmergencyAdmin,
        uint8 state
    ) public {
        vm.assume(nonGovernanceOrEmergencyAdmin != governance);
        vm.assume(nonGovernanceOrEmergencyAdmin != address(0));
        vm.assume(!_isLensHubProxyAdmin(nonGovernanceOrEmergencyAdmin));

        state = uint8(bound(state, uint8(Types.ProtocolState.Unpaused), uint8(Types.ProtocolState.Paused)));

        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        vm.prank(nonGovernanceOrEmergencyAdmin);
        hub.setState(Types.ProtocolState(state));
    }

    function test_EmergencyAdminCanOnlyPauseFurtherDown(uint8 initialState, uint8 emergencyState) public {
        initialState = uint8(
            bound(initialState, uint8(Types.ProtocolState.Unpaused), uint8(Types.ProtocolState.PublishingPaused))
        );
        emergencyState = uint8(bound(emergencyState, initialState + 1, uint8(Types.ProtocolState.Paused)));

        address emergencyAdmin = makeAddr('EMERGENCY_ADMIN');
        vm.startPrank(governance);
        hub.setEmergencyAdmin(emergencyAdmin);
        hub.setState(Types.ProtocolState(initialState));
        vm.stopPrank();

        assertEq(uint8(hub.getState()), initialState);

        vm.prank(emergencyAdmin);
        hub.setState(Types.ProtocolState(emergencyState));
        assertEq(uint8(hub.getState()), emergencyState);
    }

    function testCannot_Unpause_IfEmergencyAdmin(uint8 emergencyState, uint8 unpausingState) public {
        emergencyState = uint8(
            bound(emergencyState, uint8(Types.ProtocolState.PublishingPaused), uint8(Types.ProtocolState.Paused))
        );
        unpausingState = uint8(bound(unpausingState, uint8(Types.ProtocolState.Unpaused), emergencyState - 1));

        address emergencyAdmin = makeAddr('EMERGENCY_ADMIN');
        vm.startPrank(governance);
        hub.setEmergencyAdmin(emergencyAdmin);
        hub.setState(Types.ProtocolState(emergencyState));
        vm.stopPrank();

        assertEq(uint8(hub.getState()), emergencyState);

        vm.expectRevert(Errors.EmergencyAdminCanOnlyPauseFurther.selector);
        vm.prank(emergencyAdmin);
        hub.setState(Types.ProtocolState(unpausingState));
    }

    function testCannot_WhitelistProfileCreator_IfNotGovernance(
        address nonGovernanceCaller,
        address addressToWhitelist,
        bool shouldWhitelist
    ) public {
        vm.assume(nonGovernanceCaller != governance);
        vm.assume(nonGovernanceCaller != address(0));
        vm.assume(!_isLensHubProxyAdmin(nonGovernanceCaller));

        vm.expectRevert(Errors.NotGovernance.selector);
        vm.prank(nonGovernanceCaller);
        hub.whitelistProfileCreator(addressToWhitelist, shouldWhitelist);
    }

    // SCENARIOS

    function testSetEmergencyAdmin_IfGovernance(address newEmergencyAdmin) public {
        vm.assume(newEmergencyAdmin != address(0));

        vm.prank(governance);
        hub.setEmergencyAdmin(newEmergencyAdmin);

        assertEq(
            vm.load(address(hub), bytes32(StorageLib.EMERGENCY_ADMIN_SLOT)),
            bytes32(uint256(uint160(newEmergencyAdmin)))
        );
    }

    function testSetGovernance_IfGovernance(address newGovernance) public {
        vm.assume(newGovernance != address(0));

        vm.prank(governance);
        hub.setGovernance(newGovernance);

        assertEq(newGovernance, hub.getGovernance());
    }

    function testSetState_IfGovernance(uint8 newState) public {
        newState = uint8(bound(newState, uint8(Types.ProtocolState.Unpaused), uint8(Types.ProtocolState.Paused)));

        vm.prank(governance);
        hub.setState(Types.ProtocolState(newState));

        assertEq(uint8(hub.getState()), newState);
    }

    function testWhitelistProfileCreator(address profileCreator, bool shouldWhitelist) public {
        vm.prank(governance);
        hub.whitelistProfileCreator(profileCreator, shouldWhitelist);

        assertEq(hub.isProfileCreatorWhitelisted(profileCreator), shouldWhitelist);
    }

    function testRegisterFollowModule(address followModule) public {
        hub.registerFollowModule(followModule);

        assertEq(hub.isFollowModuleRegistered(followModule), true);
    }

    function testRegisterReferenceModule(address referenceModule) public {
        hub.registerReferenceModule(referenceModule);

        assertEq(hub.isReferenceModuleRegistered(referenceModule), true);
    }

    function testWhitelistActionModule_initially(address actionModule) public {
        Types.ActionModuleRegisterData memory whitelistData = hub.getActionModuleRegisterData(actionModule);
        vm.assume(whitelistData.id == 0);
        vm.assume(whitelistData.isRegistered == false);

        hub.registerActionModule(actionModule);

        whitelistData = hub.getActionModuleRegisterData(actionModule);

        assertTrue(whitelistData.isRegistered);
    }

    function testGetActionModuleRegisterData(address secondActionModule) public {
        address firstActionModule = makeAddr('FIRST_ACTION_MODULE');
        vm.assume(firstActionModule != secondActionModule);

        Types.ActionModuleRegisterData memory registerData = hub.getActionModuleRegisterData(secondActionModule);
        vm.assume(registerData.id == 0);
        vm.assume(registerData.isRegistered == false);

        registerData = hub.getActionModuleRegisterData(firstActionModule);
        assertEq(registerData.id, 0);
        assertFalse(registerData.isRegistered);

        hub.registerActionModule(firstActionModule);

        registerData = hub.getActionModuleRegisterData(firstActionModule);
        uint256 firstActionModuleId = registerData.id;
        assertTrue(registerData.isRegistered);

        hub.registerActionModule(secondActionModule);

        registerData = hub.getActionModuleRegisterData(secondActionModule);
        uint256 secondActionModuleId = registerData.id;
        assertTrue(registerData.isRegistered);

        assertEq(secondActionModuleId, firstActionModuleId + 1);
    }
}
