// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract MultiStateHubTest is BaseTest {
    // Negatives
    function testCannotSetStateAsRegularUser() public {
        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(DataTypes.ProtocolState.Paused);

        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(DataTypes.ProtocolState.PublishingPaused);

        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(DataTypes.ProtocolState.Unpaused);
    }

    function testCannotSetEmergencyAdminAsRegularUser() public {
        vm.expectRevert(Errors.NotGovernance.selector);
        _setEmergencyAdmin(address(this));
    }

    function testCannotUnpauseAsEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        vm.expectRevert(Errors.EmergencyAdminCanOnlyPauseFurther.selector);
        _setState(DataTypes.ProtocolState.Unpaused);
    }

    function testCannotSetLowerStateAsEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        _setState(DataTypes.ProtocolState.Paused);

        vm.expectRevert(Errors.EmergencyAdminCanOnlyPauseFurther.selector);
        _setState(DataTypes.ProtocolState.PublishingPaused);

        vm.expectRevert(Errors.EmergencyAdminCanOnlyPauseFurther.selector);
        _setState(DataTypes.ProtocolState.Paused);
    }

    function testCannotSetEmergencyAdminAsEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        vm.expectRevert(Errors.NotGovernance.selector);
        _setEmergencyAdmin(address(0));
    }

    // Scenarios
    function testSetProtocolStateAsEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        DataTypes.ProtocolState[2] memory states = [
            DataTypes.ProtocolState.PublishingPaused,
            DataTypes.ProtocolState.Paused
        ];

        for (uint256 i = 0; i < states.length; i++) {
            DataTypes.ProtocolState newState = states[i];
            DataTypes.ProtocolState prevState = _getState();
            _setState(newState);
            DataTypes.ProtocolState curState = _getState();
            assertTrue(newState == curState);
            assertTrue(curState != prevState);
        }
    }

    function testSetProtocolStateAsGovernance() public {
        vm.startPrank(governance);

        DataTypes.ProtocolState[6] memory states = [
            DataTypes.ProtocolState.PublishingPaused,
            DataTypes.ProtocolState.Paused,
            DataTypes.ProtocolState.Unpaused,
            DataTypes.ProtocolState.Paused,
            DataTypes.ProtocolState.PublishingPaused,
            DataTypes.ProtocolState.Unpaused
        ];

        for (uint256 i = 0; i < states.length; i++) {
            DataTypes.ProtocolState newState = states[i];
            DataTypes.ProtocolState prevState = _getState();
            _setState(newState);
            DataTypes.ProtocolState curState = _getState();
            assertTrue(newState == curState);
            assertTrue(curState != prevState);
        }
        vm.stopPrank();
    }

    function testGovernanceCanRevokeEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        _setState(DataTypes.ProtocolState.PublishingPaused);

        vm.prank(governance);
        _setEmergencyAdmin(address(0));

        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(DataTypes.ProtocolState.Paused);
    }

    function _setState(DataTypes.ProtocolState newState) internal {
        hub.setState(newState);
    }

    function _getState() internal view returns (DataTypes.ProtocolState) {
        return hub.getState();
    }

    function _setEmergencyAdmin(address newEmergencyAdmin) internal {
        hub.setEmergencyAdmin(newEmergencyAdmin);
    }
}
