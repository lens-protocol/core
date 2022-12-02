// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import {SigSetup} from './helpers/SignatureHelpers.sol';

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

contract MultiStateHubTest_PausedState_Direct is BaseTest {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Paused);
    }

    function _mockSetFollowModule() internal virtual {
        _setFollowModule(profileOwner, newProfileId, address(0), '');
    }

    function _mockSetDelegatedExecutorApproval() internal virtual {
        address executor = otherSigner;
        bool approved = true;
        _setDelegatedExecutorApproval(profileOwner, executor, approved);
    }

    // Negatives
    function testCantTransferProfileWhilePaused() public virtual {
        vm.expectRevert(Errors.Paused.selector);
        _transferProfile({
            msgSender: profileOwner,
            from: profileOwner,
            to: address(111),
            tokenId: newProfileId
        });
    }

    function testCantCreateProfileWhilePaused() public virtual {
        vm.expectRevert(Errors.Paused.selector);
        _createProfile(address(this));

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _createProfile(address(this));
    }

    function testCantSetFollowModuleWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockSetFollowModule();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockSetFollowModule();
        // TODO: Consider if we should check if the follow module was set (or its enough to do that in Follow module tests)
    }

    function testCantSetDelegatedExecutorWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockSetDelegatedExecutorApproval();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockSetDelegatedExecutorApproval();
        // TODO: Consider if we should check if the delegated executor was set (or its enough to do that in DE tests)
        // assertEq(hub.isDelegatedExecutorApproved(profileOwner, executor), approved);
    }
}

contract MultiStateHubTest_PausedState_WithSig is MultiStateHubTest_PausedState_Direct, SigSetup {
    function setUp() public override(MultiStateHubTest_PausedState_Direct, SigSetup) {
        MultiStateHubTest_PausedState_Direct.setUp();
        SigSetup.setUp();
    }

    function _mockSetFollowModule() internal override {
        bytes32 digest = _getSetFollowModuleTypedDataHash(
            newProfileId,
            address(0),
            '',
            nonce,
            deadline
        );

        return
            _setFollowModuleWithSig(
                DataTypes.SetFollowModuleWithSigData({
                    delegatedSigner: address(0),
                    profileId: newProfileId,
                    followModule: address(0),
                    followModuleInitData: '',
                    sig: _getSigStruct(profileOwnerKey, digest, deadline)
                })
            );
    }

    // Positives
    function _mockSetDelegatedExecutorApproval() internal override {
        address onBehalfOf = profileOwner;
        address executor = otherSigner;

        bytes32 digest = _getSetDelegatedExecutorApprovalTypedDataHash({
            onBehalfOf: onBehalfOf,
            executor: executor,
            approved: true,
            nonce: nonce,
            deadline: deadline
        });
        hub.setDelegatedExecutorApprovalWithSig(
            _buildSetDelegatedExecutorApprovalWithSigData({
                onBehalfOf: onBehalfOf,
                executor: executor,
                approved: true,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    // Methods that cannot be called with sig
    function testCantTransferProfileWhilePaused() public override {}

    function testCantCreateProfileWhilePaused() public override {}
}
