// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {ILensGovernable} from 'contracts/interfaces/ILensGovernable.sol';
import {Governance, ILensHub_V1} from 'contracts/misc/access/Governance.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';

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

    Governance governanceContract;
    MockNonLensHubGoverned mockNonLensHubGoverned;

    address governanceOwner = makeAddr('GOVERNANCE_OWNER');
    address controllerContract = makeAddr('CONTROLLER_CONTRACT');

    function setUp() public override {
        super.setUp();
        if (fork) {
            governanceContract = Governance(
                json.readAddress(string(abi.encodePacked('.', forkEnv, '.GovernanceContract')))
            );
        } else {
            governanceContract = new Governance(address(hub), governanceOwner);
        }
        vm.prank(governanceOwner);
        governanceContract.setControllerContract(controllerContract);

        vm.prank(governance);
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

    function testCannotWhitelistFollowModule_ifNotOwnerOrControllerContract(
        address followModule,
        bool whitelist,
        address otherAddress
    ) public {
        vm.assume(otherAddress != governanceOwner && otherAddress != controllerContract);

        vm.expectRevert(Unauthorized.selector);

        vm.prank(otherAddress);
        governanceContract.lensHub_whitelistFollowModule(followModule, whitelist);
    }

    function testCannotWhitelistReferenceModule_ifNotOwnerOrControllerContract(
        address referenceModule,
        bool whitelist,
        address otherAddress
    ) public {
        vm.assume(otherAddress != governanceOwner && otherAddress != controllerContract);

        vm.expectRevert(Unauthorized.selector);

        vm.prank(otherAddress);
        governanceContract.lensHub_whitelistReferenceModule(referenceModule, whitelist);
    }

    function testCannotWhitelistActionModule_ifNotOwnerOrControllerContract(
        address actionModule,
        bool whitelist,
        address otherAddress
    ) public {
        vm.assume(otherAddress != governanceOwner && otherAddress != controllerContract);

        vm.expectRevert(Unauthorized.selector);

        vm.prank(otherAddress);
        governanceContract.lensHub_whitelistActionModule(actionModule, whitelist);
    }

    function testCannotWhitelistCollectModule_ifNotOwnerOrControllerContract(
        address collectModule,
        bool whitelist,
        address otherAddress
    ) public {
        vm.assume(otherAddress != governanceOwner && otherAddress != controllerContract);

        vm.expectRevert(Unauthorized.selector);

        vm.prank(otherAddress);
        governanceContract.lensHub_whitelistCollectModule(collectModule, whitelist);
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

    function testWhitelistFollowModule_IfOwner(address followModule, bool whitelist) public {
        vm.expectCall(
            address(hub),
            abi.encodeCall(ILensGovernable.whitelistFollowModule, (followModule, whitelist)),
            1
        );

        vm.prank(governanceOwner);
        governanceContract.lensHub_whitelistFollowModule(followModule, whitelist);

        assertEq(hub.isFollowModuleWhitelisted(followModule), whitelist);
    }

    function testWhitelistFollowModule_IfControllerContract(address followModule, bool whitelist) public {
        vm.expectCall(
            address(hub),
            abi.encodeCall(ILensGovernable.whitelistFollowModule, (followModule, whitelist)),
            1
        );

        vm.prank(controllerContract);
        governanceContract.lensHub_whitelistFollowModule(followModule, whitelist);

        assertEq(hub.isFollowModuleWhitelisted(followModule), whitelist);
    }

    function testWhitelistReferenceModule_ifOwner(address referenceModule, bool whitelist) public {
        vm.expectCall(
            address(hub),
            abi.encodeCall(ILensGovernable.whitelistReferenceModule, (referenceModule, whitelist)),
            1
        );

        vm.prank(governanceOwner);
        governanceContract.lensHub_whitelistReferenceModule(referenceModule, whitelist);

        assertEq(hub.isReferenceModuleWhitelisted(referenceModule), whitelist);
    }

    function testWhitelistReferenceModule_ifControllerContract(address referenceModule, bool whitelist) public {
        vm.expectCall(
            address(hub),
            abi.encodeCall(ILensGovernable.whitelistReferenceModule, (referenceModule, whitelist)),
            1
        );

        vm.prank(controllerContract);
        governanceContract.lensHub_whitelistReferenceModule(referenceModule, whitelist);

        assertEq(hub.isReferenceModuleWhitelisted(referenceModule), whitelist);
    }

    function testWhitelistActionModule_ifOwner(address actionModule) public {
        vm.expectCall(address(hub), abi.encodeCall(ILensGovernable.whitelistActionModule, (actionModule, true)), 1);

        vm.prank(governanceOwner);
        governanceContract.lensHub_whitelistActionModule(actionModule, true);

        assertTrue(hub.getActionModuleWhitelistData(actionModule).isWhitelisted);
    }

    function testWhitelistActionModule_ifControllerContract(address actionModule) public {
        vm.expectCall(address(hub), abi.encodeCall(ILensGovernable.whitelistActionModule, (actionModule, true)), 1);

        vm.prank(controllerContract);
        governanceContract.lensHub_whitelistActionModule(actionModule, true);

        assertTrue(hub.getActionModuleWhitelistData(actionModule).isWhitelisted);
    }

    function testUnwhitelistActionModule_ifOwner(address actionModule) public {
        vm.prank(governanceOwner);
        governanceContract.lensHub_whitelistActionModule(actionModule, true);

        vm.expectCall(address(hub), abi.encodeCall(ILensGovernable.whitelistActionModule, (actionModule, false)), 1);

        vm.prank(governanceOwner);
        governanceContract.lensHub_whitelistActionModule(actionModule, false);

        assertFalse(hub.getActionModuleWhitelistData(actionModule).isWhitelisted);
    }

    function testUnwhitelistActionModule_ifControllerContract(address actionModule) public {
        vm.prank(controllerContract);
        governanceContract.lensHub_whitelistActionModule(actionModule, true);

        vm.expectCall(address(hub), abi.encodeCall(ILensGovernable.whitelistActionModule, (actionModule, false)), 1);

        vm.prank(controllerContract);
        governanceContract.lensHub_whitelistActionModule(actionModule, false);

        assertFalse(hub.getActionModuleWhitelistData(actionModule).isWhitelisted);
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

    // V1 functions for upgrade

    function testWhitelistCollectModule_ifOwner(address collectModule, bool whitelist) public {
        vm.expectCall(address(hub), abi.encodeCall(ILensHub_V1.whitelistCollectModule, (collectModule, whitelist)), 1);

        // Lens V2 does not support collect module whitelisting as top level feature.
        // But we still test that Governance contract allows and does such a call to V1 implementation interface.
        vm.expectRevert();

        vm.prank(governanceOwner);
        governanceContract.lensHub_whitelistCollectModule(collectModule, whitelist);
    }

    function testWhitelistCollectModule_ifControllerContract(address collectModule, bool whitelist) public {
        vm.expectCall(address(hub), abi.encodeCall(ILensHub_V1.whitelistCollectModule, (collectModule, whitelist)), 1);

        // Lens V2 does not support collect module whitelisting as top level feature.
        // But we still test that Governance contract allows and does such a call to V1 implementation interface.
        vm.expectRevert();

        vm.prank(controllerContract);
        governanceContract.lensHub_whitelistCollectModule(collectModule, whitelist);
    }
}
