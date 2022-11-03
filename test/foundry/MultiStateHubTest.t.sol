// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract MultiStateHubTest_Common is BaseTest {
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
}

contract MultiStateHubTest_PausedState is BaseTest {
    function setUp() public override {
        super.setUp();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Paused);
    }

    // Negatives
    function testCantTransferProfileWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _transferProfile({
            msgSender: profileOwner,
            from: profileOwner,
            to: address(111),
            tokenId: firstProfileId
        });
    }

    function testCantCreateProfileWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _createProfile(address(this));

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _createProfile(address(this));
    }

    function testCantSetFollowModuleWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _setFollowModule(profileOwner, firstProfileId, address(0), '');

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _setFollowModule(profileOwner, firstProfileId, address(0), '');
    }
}
