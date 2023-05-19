// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {ControllableByContract} from 'contracts/misc/access/ControllableByContract.sol';

contract MockControllableByContract is ControllableByContract {
    constructor(address owner) ControllableByContract(owner) {}

    function modifierRestricted() external view onlyOwnerOrControllerContract returns (bool) {
        return true;
    }
}

contract ControllableByContractTest is BaseTest {
    MockControllableByContract mockControllableByContract;

    event ControllerContractUpdated(address previousControllerContract, address newControllerContract);

    error Unauthorized();

    address owner = makeAddr('OWNER');

    function setUp() public override {
        mockControllableByContract = new MockControllableByContract(owner);
    }

    // NEGATIVES

    function testCannotCallModifierRestrictedFunction_IfNotOwnerOrControllerContract(
        address controllerContract,
        address otherAddress
    ) public {
        vm.assume(controllerContract != address(0));
        vm.assume(otherAddress != address(0));
        vm.assume(otherAddress != owner);
        vm.assume(otherAddress != controllerContract);

        vm.prank(owner);
        mockControllableByContract.setControllerContract(controllerContract);

        vm.expectRevert(Unauthorized.selector);

        vm.prank(otherAddress);
        mockControllableByContract.modifierRestricted();
    }

    function testCannotClearController_IfNotOwnerOrControllerContract(
        address controllerContract,
        address otherAddress
    ) public {
        vm.assume(otherAddress != address(0));
        vm.assume(otherAddress != owner);
        vm.assume(otherAddress != controllerContract);

        vm.prank(owner);
        mockControllableByContract.setControllerContract(controllerContract);

        assertEq(mockControllableByContract.controllerContract(), controllerContract);

        vm.prank(otherAddress);
        vm.expectRevert(Unauthorized.selector);
        mockControllableByContract.clearControllerContract();
    }

    function testCannotSetControllerContract_IfNotOwner(address controllerContract, address otherAddress) public {
        vm.assume(otherAddress != address(0));
        vm.assume(otherAddress != owner);

        assertEq(mockControllableByContract.controllerContract(), address(0));

        vm.prank(otherAddress);
        vm.expectRevert('Ownable: caller is not the owner');
        mockControllableByContract.setControllerContract(controllerContract);
    }

    function testCannotChangeControllerContract_IfNotOwner(
        address initialControllerContract,
        address newControllerContract,
        address otherAddress
    ) public {
        vm.assume(initialControllerContract != address(0));
        vm.assume(otherAddress != address(0));
        vm.assume(otherAddress != owner);

        vm.prank(owner);
        mockControllableByContract.setControllerContract(initialControllerContract);

        assertEq(mockControllableByContract.controllerContract(), initialControllerContract);

        vm.prank(otherAddress);
        vm.expectRevert('Ownable: caller is not the owner');
        mockControllableByContract.setControllerContract(newControllerContract);
    }

    // SCENARIOS

    function testInitialControllerContract_IsZero() public {
        assertEq(mockControllableByContract.controllerContract(), address(0));
    }

    function testCanCallModifierRestrictedFunction_IfOwnerOrControllerContract(address controllerContract) public {
        vm.assume(controllerContract != address(0));

        vm.prank(owner);
        mockControllableByContract.setControllerContract(controllerContract);

        vm.prank(owner);
        assertTrue(mockControllableByContract.modifierRestricted());

        vm.prank(controllerContract);
        assertTrue(mockControllableByContract.modifierRestricted());
    }

    function testClearControllerContractByOwner(address controllerContract) public {
        vm.prank(owner);
        mockControllableByContract.setControllerContract(controllerContract);

        assertEq(mockControllableByContract.controllerContract(), controllerContract);

        vm.expectEmit(true, true, true, true, address(mockControllableByContract));
        emit ControllerContractUpdated(controllerContract, address(0));

        vm.prank(owner);
        mockControllableByContract.clearControllerContract();

        assertEq(mockControllableByContract.controllerContract(), address(0));
    }

    function testClearControllerContractByControllerContract(address controllerContract) public {
        vm.prank(owner);
        mockControllableByContract.setControllerContract(controllerContract);

        assertEq(mockControllableByContract.controllerContract(), controllerContract);

        vm.expectEmit(true, true, true, true, address(mockControllableByContract));
        emit ControllerContractUpdated(controllerContract, address(0));

        vm.prank(controllerContract);
        mockControllableByContract.clearControllerContract();

        assertEq(mockControllableByContract.controllerContract(), address(0));
    }

    function testSetControllerContract(address controllerContract) public {
        assertEq(mockControllableByContract.controllerContract(), address(0));

        vm.expectEmit(true, true, true, true, address(mockControllableByContract));
        emit ControllerContractUpdated(address(0), controllerContract);

        vm.prank(owner);
        mockControllableByContract.setControllerContract(controllerContract);

        assertEq(mockControllableByContract.controllerContract(), controllerContract);
    }

    function testChangeControllerContract(address initialControllerContract, address newControllerContract) public {
        vm.assume(initialControllerContract != address(0));

        vm.prank(owner);
        mockControllableByContract.setControllerContract(initialControllerContract);

        assertEq(mockControllableByContract.controllerContract(), initialControllerContract);

        vm.expectEmit(true, true, true, true, address(mockControllableByContract));
        emit ControllerContractUpdated(initialControllerContract, newControllerContract);

        vm.prank(owner);
        mockControllableByContract.setControllerContract(newControllerContract);

        assertEq(mockControllableByContract.controllerContract(), newControllerContract);
    }
}
