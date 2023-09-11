// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {ILensGovernable} from 'contracts/interfaces/ILensGovernable.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';

// TODO: Move to mocks/
contract MockNonLensHubGoverned {
    function testMockNonLensHubGoverned() public {
        // Prevents being counted in Foundry Coverage
    }

    address public governance;

    error CustomError();

    constructor(address newGovernance) {
        governance = newGovernance;
    }

    function requiresGovernance(bool pass) external view returns (bool) {
        require(msg.sender == governance, 'Unauthorized');
        if (!pass) revert('Failure');
        return true;
    }

    function failWithPanic() external pure {
        assert(false);
    }

    function failWithStringRevert() external pure {
        revert('Failure');
    }

    function failWithCustomError() external pure {
        revert CustomError();
    }

    function failWithNoErrorData() external pure {
        require(false);
    }
}

contract GovernanceTest is BaseTest {
    using stdJson for string;

    error Unauthorized();

    MockNonLensHubGoverned mockNonLensHubGoverned;

    address controllerContract = makeAddr('CONTROLLER_CONTRACT');
    address governanceOwner;

    function setUp() public override {
        super.setUp();

        loadOrDeploy_GovernanceContract();

        vm.prank(governanceMultisig);
        governanceContract.setControllerContract(controllerContract);

        governanceOwner = governanceContract.owner();

        vm.prank(hub.getGovernance());
        hub.setGovernance(address(governanceContract));

        mockNonLensHubGoverned = new MockNonLensHubGoverned(address(governanceContract));
    }

    // Negatives

    function testCannotSetGovernance_ifNotOwner(address newGovernance, address otherAddress) public {
        vm.assume(otherAddress != governanceOwner);

        vm.expectRevert('Ownable: caller is not the owner');

        vm.prank(otherAddress);
        governanceContract.lensHub_setGovernance(newGovernance);
    }

    function testCannotSetEmergencyAdmin_ifNotOwner(address newEmergencyAdmin, address otherAddress) public {
        vm.assume(otherAddress != governanceOwner);

        vm.expectRevert('Ownable: caller is not the owner');

        vm.prank(otherAddress);
        governanceContract.lensHub_setEmergencyAdmin(newEmergencyAdmin);
    }

    function testCannotWhitelistProfileCreator_ifNotOwnerOrControllerContract(
        address profileCreator,
        bool whitelist,
        address otherAddress
    ) public {
        vm.assume(otherAddress != governanceOwner && otherAddress != controllerContract);

        vm.expectRevert(Unauthorized.selector);

        vm.prank(otherAddress);
        governanceContract.lensHub_whitelistProfileCreator(profileCreator, whitelist);
    }

    function testCannotExecuteAsGovernance_ifNotOwnerOrControllerContract(
        address target,
        bytes memory data,
        address otherAddress
    ) public {
        vm.assume(otherAddress != governanceOwner && otherAddress != controllerContract);

        vm.expectRevert(Unauthorized.selector);

        vm.prank(otherAddress);
        governanceContract.executeAsGovernance(target, data);
    }

    function testCannotExecuteAsGovernance_ifCollectorContract_callingLensHub() public {
        vm.expectRevert(Unauthorized.selector);

        vm.prank(controllerContract);
        governanceContract.executeAsGovernance(
            address(hub),
            abi.encodeWithSelector(ILensGovernable.getGovernance.selector)
        );
    }

    // Scenarios

    // Only Owner functions

    function testSetGovernance_ifOwner(address newGovernance) public {
        vm.expectCall(address(hub), abi.encodeCall(ILensGovernable.setGovernance, (newGovernance)), 1);

        vm.prank(governanceOwner);
        governanceContract.lensHub_setGovernance(newGovernance);

        assertEq(hub.getGovernance(), address(newGovernance));
    }

    function testSetEmergencyAdmin_ifOwner(address newEmergencyAdmin) public {
        vm.expectCall(address(hub), abi.encodeCall(ILensGovernable.setEmergencyAdmin, (newEmergencyAdmin)), 1);

        vm.prank(governanceOwner);
        governanceContract.lensHub_setEmergencyAdmin(newEmergencyAdmin);

        // TODO: We really need a getter for emergencyAdmin in LensHub... Right now it's a contract space concern.
        assertEq(
            address(uint160(uint256(vm.load(address(hub), bytes32(StorageLib.EMERGENCY_ADMIN_SLOT))))),
            newEmergencyAdmin
        );
    }

    // Owner or ControllerContract functions

    function testWhitelistProfileCreator_ifOwner(address profileCreator, bool whitelist) public {
        vm.expectCall(
            address(hub),
            abi.encodeCall(ILensGovernable.whitelistProfileCreator, (profileCreator, whitelist)),
            1
        );

        vm.prank(governanceOwner);
        governanceContract.lensHub_whitelistProfileCreator(profileCreator, whitelist);

        assertEq(hub.isProfileCreatorWhitelisted(profileCreator), whitelist);
    }

    function testWhitelistProfileCreator_ifControllerContract(address profileCreator, bool whitelist) public {
        vm.expectCall(
            address(hub),
            abi.encodeCall(ILensGovernable.whitelistProfileCreator, (profileCreator, whitelist)),
            1
        );

        vm.prank(controllerContract);
        governanceContract.lensHub_whitelistProfileCreator(profileCreator, whitelist);

        assertEq(hub.isProfileCreatorWhitelisted(profileCreator), whitelist);
    }

    function testExecuteAsGovernance_ifOwner(address newGovernance) public {
        vm.expectCall(address(hub), abi.encodeCall(ILensGovernable.setGovernance, (newGovernance)), 1);

        vm.prank(governanceOwner);
        governanceContract.executeAsGovernance(
            address(hub),
            abi.encodeCall(ILensGovernable.setGovernance, (newGovernance))
        );
    }

    function testExecuteAsGovernance_ifControllerContract_success() public {
        vm.expectCall(
            address(mockNonLensHubGoverned),
            abi.encodeCall(MockNonLensHubGoverned.requiresGovernance, (true)),
            1
        );

        vm.prank(controllerContract);
        governanceContract.executeAsGovernance(
            address(mockNonLensHubGoverned),
            abi.encodeCall(MockNonLensHubGoverned.requiresGovernance, (true))
        );
    }

    function testExecuteAsGovernance_ifControllerContract_failure() public {
        vm.expectCall(
            address(mockNonLensHubGoverned),
            abi.encodeCall(MockNonLensHubGoverned.requiresGovernance, (false)),
            1
        );

        vm.expectRevert('Failure');

        vm.prank(controllerContract);
        governanceContract.executeAsGovernance(
            address(mockNonLensHubGoverned),
            abi.encodeCall(MockNonLensHubGoverned.requiresGovernance, (false))
        );
    }

    function testExecuteAsGovernance_RevertPanic() public {
        vm.expectCall(address(mockNonLensHubGoverned), abi.encodeCall(MockNonLensHubGoverned.failWithPanic, ()), 1);

        vm.expectRevert(stdError.assertionError);

        vm.prank(controllerContract);
        governanceContract.executeAsGovernance(
            address(mockNonLensHubGoverned),
            abi.encodeCall(MockNonLensHubGoverned.failWithPanic, ())
        );
    }

    function testExecuteAsGovernance_RevertCustomError() public {
        vm.expectCall(
            address(mockNonLensHubGoverned),
            abi.encodeCall(MockNonLensHubGoverned.failWithCustomError, ()),
            1
        );

        vm.expectRevert(MockNonLensHubGoverned.CustomError.selector);

        vm.prank(controllerContract);
        governanceContract.executeAsGovernance(
            address(mockNonLensHubGoverned),
            abi.encodeCall(MockNonLensHubGoverned.failWithCustomError, ())
        );
    }

    function testExecuteAsGovernance_RevertStringError() public {
        vm.expectCall(
            address(mockNonLensHubGoverned),
            abi.encodeCall(MockNonLensHubGoverned.failWithStringRevert, ()),
            1
        );

        vm.expectRevert('Failure');

        vm.prank(controllerContract);
        governanceContract.executeAsGovernance(
            address(mockNonLensHubGoverned),
            abi.encodeCall(MockNonLensHubGoverned.failWithStringRevert, ())
        );
    }

    function testExecuteAsGovernance_RevertNoErrorData() public {
        vm.expectCall(
            address(mockNonLensHubGoverned),
            abi.encodeCall(MockNonLensHubGoverned.failWithNoErrorData, ()),
            1
        );

        vm.expectRevert(bytes(''));

        vm.prank(controllerContract);
        governanceContract.executeAsGovernance(
            address(mockNonLensHubGoverned),
            abi.encodeCall(MockNonLensHubGoverned.failWithNoErrorData, ())
        );
    }
}
