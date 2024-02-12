// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {PermissionlessCreator} from 'contracts/misc/PermissionlessCreator.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

abstract contract PermissionlessCreatorTestBase is BaseTest {
    error OnlyOwner();

    using stdJson for string;

    PermissionlessCreator permissionlessCreator;
    address permissionlessCreatorOwner = makeAddr('PERMISSIONLESS_CREATOR_OWNER');

    function setUp() public virtual override {
        super.setUp();

        if (fork) {
            if (keyExists(json, string(abi.encodePacked('.', forkEnv, '.PermissionlessCreator')))) {
                permissionlessCreator = PermissionlessCreator(
                    json.readAddress(string(abi.encodePacked('.', forkEnv, '.PermissionlessCreator')))
                );
                permissionlessCreatorOwner = permissionlessCreator.OWNER();
            } else {
                console.log('PermissionlessCreator key does not exist');
                if (forkVersion == 1) {
                    console.log('No PermissionlessCreator address found - deploying new one');
                    permissionlessCreator = new PermissionlessCreator(
                        permissionlessCreatorOwner,
                        address(hub),
                        address(lensHandles),
                        address(tokenHandleRegistry)
                    );
                } else {
                    console.log('No PermissionlessCreator address found in addressBook, which is required for V2');
                    revert('No PermissionlessCreator address found in addressBook, which is required for V2');
                }
            }
        } else {
            permissionlessCreator = new PermissionlessCreator(
                permissionlessCreatorOwner,
                address(hub),
                address(lensHandles),
                address(tokenHandleRegistry)
            );
            vm.startPrank(permissionlessCreatorOwner);
            permissionlessCreator.setHandleCreationPrice(5 ether);
            permissionlessCreator.setProfileCreationPrice(5 ether);
            permissionlessCreator.setHandleLengthMin(5);
            vm.stopPrank();
        }

        vm.prank(governance);
        hub.whitelistProfileCreator(address(permissionlessCreator), true);
    }
}

contract PermissionlessCreatorTest_PaidCreation is PermissionlessCreatorTestBase {
    function setUp() public override {
        super.setUp();
        vm.deal(
            address(this),
            (permissionlessCreator.getProfileCreationPrice() + permissionlessCreator.getHandleCreationPrice()) * 10
        );
    }

    // Paid creation

    // Negatives

    // Payment negatives
    function testCannot_CreateProfile_IfNotEnoughPayment(uint256 amount) public {
        amount = bound(amount, 0, permissionlessCreator.getProfileCreationPrice() - 1);

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: address(this),
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](0);

        vm.expectRevert(PermissionlessCreator.InvalidFunds.selector);
        permissionlessCreator.createProfile{value: amount}(createProfileParams, delegates);
    }

    function testCannot_CreateHandle_IfNotEnoughPayment(uint256 amount) public {
        string memory handle = 'testhandle_39453226';
        address to = address(this);

        amount = bound(amount, 0, permissionlessCreator.getHandleCreationPrice() - 1);

        vm.expectRevert(PermissionlessCreator.InvalidFunds.selector);
        permissionlessCreator.createHandle{value: amount}(to, handle);
    }

    function testCannot_CreateProfileWithHandle_IfNotEnoughPayment(uint256 amount) public {
        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: address(this),
            followModule: address(0),
            followModuleInitData: ''
        });

        string memory handle = 'testhandle_39453226';
        address[] memory delegates = new address[](0);

        amount = bound(amount, 0, permissionlessCreator.getProfileCreationPrice() - 1);

        vm.expectRevert(PermissionlessCreator.InvalidFunds.selector);
        permissionlessCreator.createProfileWithHandle{value: amount}(createProfileParams, handle, delegates);
    }

    // DelegatedExecutors negatives
    function testCannot_CreateProfile_WithDE_IfNotToHimself(address to) public {
        vm.assume(to != address(this));
        vm.assume(to != address(0));

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: to,
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        uint256 amount = permissionlessCreator.getProfileCreationPrice();

        vm.expectRevert(PermissionlessCreator.NotAllowed.selector);

        permissionlessCreator.createProfile{value: amount}(createProfileParams, delegates);
    }

    function testCannot_CreateProfileWithHandle_WithDE_IfNotToHimself(address to) public {
        vm.assume(to != address(this));
        vm.assume(to != address(0));

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: to,
            followModule: address(0),
            followModuleInitData: ''
        });

        string memory handle = 'testhandle_39453226';
        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        uint256 amount = permissionlessCreator.getProfileCreationPrice() +
            permissionlessCreator.getHandleCreationPrice();

        vm.expectRevert(PermissionlessCreator.NotAllowed.selector);

        permissionlessCreator.createProfileWithHandle{value: amount}(createProfileParams, handle, delegates);
    }

    // Handle Length negatives
    function testCannot_CreateHandle_IfHandleLengthIsLessThanMin() public {
        string memory handleTemplate = 'testin12345678901234567890';

        string memory handle = LibString.slice(handleTemplate, 0, permissionlessCreator.getHandleLengthMin() - 1);

        uint256 amount = permissionlessCreator.getHandleCreationPrice();

        vm.expectRevert(PermissionlessCreator.HandleLengthNotAllowed.selector);

        permissionlessCreator.createHandle{value: amount}(address(this), handle);
    }

    function testCannot_CreateProfileWithHandle_IfHandleLengthIsLessThanMin() public {
        string memory handleTemplate = 'testin12345678901234567890';

        string memory handle = LibString.slice(handleTemplate, 0, permissionlessCreator.getHandleLengthMin() - 1);

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: address(this),
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](0);

        uint256 amount = permissionlessCreator.getProfileCreationPrice() +
            permissionlessCreator.getHandleCreationPrice();

        vm.expectRevert(PermissionlessCreator.HandleLengthNotAllowed.selector);

        permissionlessCreator.createProfileWithHandle{value: amount}(createProfileParams, handle, delegates);
    }

    // Scenarios

    function testCreateProfile_WithDE(address owner) public {
        vm.assume(owner != address(0));

        vm.deal(
            owner,
            (permissionlessCreator.getProfileCreationPrice() + permissionlessCreator.getHandleCreationPrice()) * 10
        );

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: owner,
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        uint256 amount = permissionlessCreator.getProfileCreationPrice();

        vm.prank(owner);
        uint256 profileId = permissionlessCreator.createProfile{value: amount}(createProfileParams, delegates);

        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
        assertEq(hub.ownerOf(profileId), owner);
    }

    function testCreateProfile_WithoutDE(address owner, address to) public {
        vm.assume(owner != address(0));
        vm.assume(to != address(0));

        vm.deal(
            owner,
            (permissionlessCreator.getProfileCreationPrice() + permissionlessCreator.getHandleCreationPrice()) * 10
        );

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: to,
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](0);

        uint256 amount = permissionlessCreator.getProfileCreationPrice();

        vm.prank(owner);
        uint256 profileId = permissionlessCreator.createProfile{value: amount}(createProfileParams, delegates);

        assertEq(hub.ownerOf(profileId), to);
    }

    function testCreateHandle(address to) public {
        vm.assume(to != address(0));

        string memory handle = 'testhandle_39453226';

        uint256 amount = permissionlessCreator.getHandleCreationPrice();

        uint256 handleId = permissionlessCreator.createHandle{value: amount}(to, handle);

        assertEq(lensHandles.ownerOf(handleId), to);
    }

    function testCreateProfileWithHandle_WithDE(address owner) public {
        vm.assume(owner != address(0));

        vm.deal(
            owner,
            (permissionlessCreator.getProfileCreationPrice() + permissionlessCreator.getHandleCreationPrice()) * 10
        );

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: owner,
            followModule: address(0),
            followModuleInitData: ''
        });

        string memory handle = 'testhandle_39453226';
        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        uint256 amount = permissionlessCreator.getProfileCreationPrice() +
            permissionlessCreator.getHandleCreationPrice();

        vm.prank(owner);
        (uint256 profileId, uint256 handleId) = permissionlessCreator.createProfileWithHandle{value: amount}(
            createProfileParams,
            handle,
            delegates
        );

        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
        assertEq(hub.ownerOf(profileId), owner);
        assertEq(lensHandles.ownerOf(handleId), owner);
    }

    function testCreateProfileWithHandle_WithoutDE(address owner, address to) public {
        vm.assume(owner != address(0));
        vm.assume(to != address(0));

        vm.deal(
            owner,
            (permissionlessCreator.getProfileCreationPrice() + permissionlessCreator.getHandleCreationPrice()) * 10
        );

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: to,
            followModule: address(0),
            followModuleInitData: ''
        });

        string memory handle = 'testhandle_39453226';
        address[] memory delegates = new address[](0);

        uint256 amount = permissionlessCreator.getProfileCreationPrice() +
            permissionlessCreator.getHandleCreationPrice();

        vm.prank(owner);
        (uint256 profileId, uint256 handleId) = permissionlessCreator.createProfileWithHandle{value: amount}(
            createProfileParams,
            handle,
            delegates
        );

        assertEq(hub.ownerOf(profileId), to);
        assertEq(lensHandles.ownerOf(handleId), to);
    }
}

contract PermissionlessCreatorTest_Credits is PermissionlessCreatorTestBase {
    address creditProvider = makeAddr('CREDIT_PROVIDER');
    address approvedProfileCreator = makeAddr('CREDIT_CREATOR');

    function setUp() public override {
        super.setUp();

        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.addCreditProvider(creditProvider);

        vm.prank(creditProvider);
        permissionlessCreator.increaseCredits(approvedProfileCreator, 1);

        _effectivelyDisableProfileGuardian(approvedProfileCreator);
    }

    // Creation with credits

    // Negatives

    // Credits negatives
    function testCannot_CreateProfileUsingCredits_IfNotEnoughCredits(address creator, address to) public {
        vm.assume(to != address(0));
        vm.assume(creator != address(0));
        vm.assume(permissionlessCreator.getCreditBalance(creator) < 1);

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: to,
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(creator);
        permissionlessCreator.createProfileUsingCredits(createProfileParams, delegates);
    }

    function testCannot_CreateHandleUsingCredits_IfNotEnoughCredits(address creator, address to) public {
        vm.assume(to != address(0));
        vm.assume(creator != address(0));
        vm.assume(permissionlessCreator.getCreditBalance(creator) < 1);

        string memory handle = 'testhandle_39453226';

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(creator);
        permissionlessCreator.createHandleUsingCredits(to, handle);
    }

    function testCannot_CreateProfileWithHandleUsingCredits_IfNotEnoughCredits(address creator, address to) public {
        vm.assume(to != address(0));
        vm.assume(creator != address(0));
        vm.assume(permissionlessCreator.getCreditBalance(creator) < 1);

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: to,
            followModule: address(0),
            followModuleInitData: ''
        });

        string memory handle = 'testhandle_39453226';
        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(creator);
        permissionlessCreator.createProfileWithHandleUsingCredits(createProfileParams, handle, delegates);
    }

    // TrustRevoked negatives
    // testCannot_CreateProfileUsingCredits_IfTrustRevoked
    // testCannot_CreateHandleUsingCredits_IfTrustRevoked
    // testCannot_CreateProfileWithHandleUsingCredits_IfTrustRevoked

    // Handle Length negatives
    function testCannot_CreateHandleUsingCredits_IfHandleLengthIsLessThanMin() public {
        string memory handleTemplate = 'testin12345678901234567890';

        string memory handle = LibString.slice(handleTemplate, 0, permissionlessCreator.getHandleLengthMin() - 1);

        vm.expectRevert(PermissionlessCreator.HandleLengthNotAllowed.selector);
        vm.prank(approvedProfileCreator);
        permissionlessCreator.createHandleUsingCredits(address(this), handle);
    }

    function testCannot_CreateProfileWithHandleUsingCredits_IfHandleLengthIsLessThanMin() public {
        string memory handleTemplate = 'testin12345678901234567890';

        string memory handle = LibString.slice(handleTemplate, 0, permissionlessCreator.getHandleLengthMin() - 1);

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: address(this),
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](0);

        vm.expectRevert(PermissionlessCreator.HandleLengthNotAllowed.selector);
        vm.prank(approvedProfileCreator);
        permissionlessCreator.createProfileWithHandleUsingCredits(createProfileParams, handle, delegates);
    }

    // Scenarios

    function testCreateProfileUsingCredits(address to) public {
        vm.assume(to != address(0));

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: to,
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        uint256 creatorCreditsBefore = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        vm.prank(approvedProfileCreator);
        uint256 profileId = permissionlessCreator.createProfileUsingCredits(createProfileParams, delegates);

        uint256 creatorCreditsAfter = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        assertEq(creatorCreditsBefore - 1, creatorCreditsAfter);
        assertEq(hub.ownerOf(profileId), to);
        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
        assertEq(permissionlessCreator.getProfileCreatorUsingCredits(profileId), approvedProfileCreator);
    }

    function testCreateHandleUsingCredits(address to) public {
        vm.assume(to != address(0));

        string memory handle = 'testhandle_39453226';

        uint256 creatorCreditsBefore = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        vm.prank(approvedProfileCreator);
        uint256 handleId = permissionlessCreator.createHandleUsingCredits(to, handle);

        uint256 creatorCreditsAfter = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        assertEq(creatorCreditsBefore - 1, creatorCreditsAfter);
        assertEq(lensHandles.ownerOf(handleId), to);
    }

    function testCreateProfileWithHandleUsingCredits(address to) public {
        vm.assume(to != address(0));

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: to,
            followModule: address(0),
            followModuleInitData: ''
        });

        string memory handle = 'testhandle_39453226';
        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        uint256 creatorCreditsBefore = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        vm.prank(approvedProfileCreator);
        (uint256 profileId, uint256 handleId) = permissionlessCreator.createProfileWithHandleUsingCredits(
            createProfileParams,
            handle,
            delegates
        );

        uint256 creatorCreditsAfter = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        assertEq(creatorCreditsBefore - 1, creatorCreditsAfter);
        assertEq(hub.ownerOf(profileId), to);
        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
        assertEq(permissionlessCreator.getProfileCreatorUsingCredits(profileId), approvedProfileCreator);
        assertEq(lensHandles.ownerOf(handleId), to);
    }

    // Trust Revoking

    function testCannot_CreateProfileUsingTokens_IfTrustRevoked(address to) public {
        vm.assume(to != address(0));

        vm.prank(creditProvider);
        permissionlessCreator.increaseCredits(approvedProfileCreator, 10);

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: to,
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        uint256 creatorCreditsBefore = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        vm.prank(approvedProfileCreator);
        uint256 profileId = permissionlessCreator.createProfileUsingCredits(createProfileParams, delegates);

        uint256 creatorCreditsAfter = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        assertEq(creatorCreditsBefore - 1, creatorCreditsAfter);
        assertEq(hub.ownerOf(profileId), to);
        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
        assertEq(permissionlessCreator.getProfileCreatorUsingCredits(profileId), approvedProfileCreator);

        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setTrustStatus(approvedProfileCreator, true);

        assertEq(permissionlessCreator.isUntrusted(approvedProfileCreator), true);
        assertEq(permissionlessCreator.getCreditBalance(approvedProfileCreator), 0);

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(approvedProfileCreator);
        permissionlessCreator.createProfileUsingCredits(createProfileParams, delegates);
    }

    function testCannot_CreateHandleUsingTokens_IfTrustRevoked(address to) public {
        vm.assume(to != address(0));

        vm.prank(creditProvider);
        permissionlessCreator.increaseCredits(approvedProfileCreator, 10);

        string memory handle = 'testhandle_39453226';

        uint256 creatorCreditsBefore = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        vm.prank(approvedProfileCreator);
        uint256 handleId = permissionlessCreator.createHandleUsingCredits(to, handle);

        uint256 creatorCreditsAfter = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        assertEq(creatorCreditsBefore - 1, creatorCreditsAfter);
        assertEq(lensHandles.ownerOf(handleId), to);

        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setTrustStatus(approvedProfileCreator, true);

        assertEq(permissionlessCreator.isUntrusted(approvedProfileCreator), true);
        assertEq(permissionlessCreator.getCreditBalance(approvedProfileCreator), 0);

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(approvedProfileCreator);
        permissionlessCreator.createHandleUsingCredits(to, handle);
    }

    function testCannot_CreateProfileWithHandleUsingTokens_IfTrustRevoked(address to) public {
        vm.assume(to != address(0));

        vm.prank(creditProvider);
        permissionlessCreator.increaseCredits(approvedProfileCreator, 10);

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: to,
            followModule: address(0),
            followModuleInitData: ''
        });

        string memory handle = 'testhandle_39453226';
        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        uint256 creatorCreditsBefore = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        vm.prank(approvedProfileCreator);
        (uint256 profileId, uint256 handleId) = permissionlessCreator.createProfileWithHandleUsingCredits(
            createProfileParams,
            handle,
            delegates
        );

        uint256 creatorCreditsAfter = permissionlessCreator.getCreditBalance(approvedProfileCreator);

        assertEq(creatorCreditsBefore - 1, creatorCreditsAfter);
        assertEq(hub.ownerOf(profileId), to);
        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
        assertEq(permissionlessCreator.getProfileCreatorUsingCredits(profileId), approvedProfileCreator);
        assertEq(lensHandles.ownerOf(handleId), to);

        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setTrustStatus(approvedProfileCreator, true);

        assertEq(permissionlessCreator.isUntrusted(approvedProfileCreator), true);
        assertEq(permissionlessCreator.getCreditBalance(approvedProfileCreator), 0);

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(approvedProfileCreator);
        permissionlessCreator.createProfileWithHandleUsingCredits(createProfileParams, handle, delegates);
    }

    // TransferFromKeepingDelegates helper function

    // Negatives

    function testCannot_TransferFromKeepingDelegates_IfTrustRevoked(address to) public {
        vm.assume(to != address(0));

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: approvedProfileCreator,
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        vm.prank(approvedProfileCreator);
        uint256 profileId = permissionlessCreator.createProfileUsingCredits(createProfileParams, delegates);

        assertEq(hub.ownerOf(profileId), approvedProfileCreator);
        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
        assertEq(permissionlessCreator.getProfileCreatorUsingCredits(profileId), approvedProfileCreator);

        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setTrustStatus(approvedProfileCreator, true);

        vm.startPrank(approvedProfileCreator);
        hub.approve(address(permissionlessCreator), profileId);
        vm.expectRevert(PermissionlessCreator.NotAllowed.selector);
        permissionlessCreator.transferFromKeepingDelegates(approvedProfileCreator, to, profileId);
        vm.stopPrank();
    }

    function testCannot_TransferFromKeepingDelegates_IfWasNotCreator(address to, address owner) public {
        vm.assume(to != address(0));
        vm.assume(owner != address(0));
        vm.assume(owner != approvedProfileCreator);

        _effectivelyDisableProfileGuardian(owner);

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: owner,
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        vm.prank(approvedProfileCreator);
        uint256 profileId = permissionlessCreator.createProfileUsingCredits(createProfileParams, delegates);

        assertEq(hub.ownerOf(profileId), owner);
        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
        assertEq(permissionlessCreator.getProfileCreatorUsingCredits(profileId), approvedProfileCreator);

        vm.prank(creditProvider);
        permissionlessCreator.increaseCredits(owner, 10);

        vm.startPrank(owner);
        hub.approve(address(permissionlessCreator), profileId);
        vm.expectRevert(PermissionlessCreator.NotAllowed.selector);
        permissionlessCreator.transferFromKeepingDelegates(owner, to, profileId);
        vm.stopPrank();
    }

    // Scenarios

    function testTransferFromKeepingDelegates_withApprove(address to) public {
        vm.assume(to != address(0));

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: approvedProfileCreator,
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        vm.prank(approvedProfileCreator);
        uint256 profileId = permissionlessCreator.createProfileUsingCredits(createProfileParams, delegates);

        assertEq(hub.ownerOf(profileId), approvedProfileCreator);
        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
        assertEq(permissionlessCreator.getProfileCreatorUsingCredits(profileId), approvedProfileCreator);

        vm.startPrank(approvedProfileCreator);
        hub.approve(address(permissionlessCreator), profileId);
        permissionlessCreator.transferFromKeepingDelegates(approvedProfileCreator, to, profileId);
        vm.stopPrank();

        assertEq(hub.ownerOf(profileId), to);
        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
    }

    function testTransferFromKeepingDelegates_withApprovalForAll(address to) public {
        vm.assume(to != address(0));

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: approvedProfileCreator,
            followModule: address(0),
            followModuleInitData: ''
        });

        address[] memory delegates = new address[](1);
        delegates[0] = makeAddr('DE0');

        vm.prank(approvedProfileCreator);
        uint256 profileId = permissionlessCreator.createProfileUsingCredits(createProfileParams, delegates);

        assertEq(hub.ownerOf(profileId), approvedProfileCreator);
        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
        assertEq(permissionlessCreator.getProfileCreatorUsingCredits(profileId), approvedProfileCreator);

        vm.startPrank(approvedProfileCreator);
        hub.setApprovalForAll(address(permissionlessCreator), true);
        permissionlessCreator.transferFromKeepingDelegates(approvedProfileCreator, to, profileId);
        vm.stopPrank();

        assertEq(hub.ownerOf(profileId), to);
        assertTrue(hub.isDelegatedExecutorApproved(profileId, delegates[0]));
    }

    // Credit Provider functions

    // Negatives

    function testCannot_IncreaseCredit_IfNotCreditProvider(address notCreditProvider) public {
        vm.assume(permissionlessCreator.isCreditProvider(notCreditProvider) == false);

        vm.expectRevert(PermissionlessCreator.OnlyCreditProviders.selector);
        vm.prank(notCreditProvider);
        permissionlessCreator.increaseCredits(approvedProfileCreator, 1);
    }

    function testCannot_DecreaseCredit_IfNotCreditProvider(address notCreditProvider) public {
        vm.assume(permissionlessCreator.isCreditProvider(notCreditProvider) == false);

        vm.expectRevert(PermissionlessCreator.OnlyCreditProviders.selector);
        vm.prank(notCreditProvider);
        permissionlessCreator.decreaseCredits(approvedProfileCreator, 1);
    }

    function testCannot_IncreaseCredit_IfTrustRevoked() public {
        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setTrustStatus(approvedProfileCreator, true);

        vm.expectRevert(PermissionlessCreator.NotAllowed.selector);
        vm.prank(creditProvider);
        permissionlessCreator.increaseCredits(approvedProfileCreator, 1);
    }

    // Scenarios

    function testIncreaseCredit(address profileCreator) public {
        vm.assume(profileCreator != address(0));

        uint256 creditsBefore = permissionlessCreator.getCreditBalance(profileCreator);

        vm.prank(creditProvider);
        permissionlessCreator.increaseCredits(profileCreator, 123);

        uint256 creditsAfter = permissionlessCreator.getCreditBalance(profileCreator);

        assertEq(creditsBefore + 123, creditsAfter);
    }

    function testDecreaseCredit(address profileCreator) public {
        vm.assume(profileCreator != address(0));

        vm.prank(creditProvider);
        permissionlessCreator.increaseCredits(profileCreator, 123456);

        uint256 creditsBefore = permissionlessCreator.getCreditBalance(profileCreator);

        vm.prank(creditProvider);
        permissionlessCreator.decreaseCredits(profileCreator, 123);

        uint256 creditsAfter = permissionlessCreator.getCreditBalance(profileCreator);

        assertEq(creditsBefore - 123, creditsAfter);
    }

    // Owner functions

    // Negatives

    function testCannot_WithdrawFunds_IfNotOwner(address notOwner) public {
        vm.assume(notOwner != permissionlessCreatorOwner);
        vm.assume(notOwner != address(0));

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(notOwner);
        permissionlessCreator.withdrawFunds();
    }

    function testCannot_AddCreditProvider_IfNotOwner(address notOwner, address newCreditProvider) public {
        vm.assume(notOwner != permissionlessCreatorOwner);
        vm.assume(notOwner != address(0));
        vm.assume(newCreditProvider != address(0));

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(notOwner);
        permissionlessCreator.addCreditProvider(newCreditProvider);
    }

    function testCannot_RemoveCreditProvider_IfNotOwner(address notOwner, address existingCreditProvider) public {
        vm.assume(notOwner != permissionlessCreatorOwner);
        vm.assume(notOwner != address(0));
        vm.assume(existingCreditProvider != address(0));

        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.addCreditProvider(existingCreditProvider);

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(notOwner);
        permissionlessCreator.removeCreditProvider(existingCreditProvider);

        assertTrue(permissionlessCreator.isCreditProvider(existingCreditProvider));
    }

    function testCannot_SetProfileCreationPrice_IfNotOwner(address notOwner, uint128 newPrice) public {
        vm.assume(notOwner != permissionlessCreatorOwner);
        vm.assume(notOwner != address(0));

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(notOwner);
        permissionlessCreator.setProfileCreationPrice(newPrice);
    }

    function testCannot_SetHandleCreationPrice_IfNotOwner(address notOwner, uint128 newPrice) public {
        vm.assume(notOwner != permissionlessCreatorOwner);
        vm.assume(notOwner != address(0));

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(notOwner);
        permissionlessCreator.setHandleCreationPrice(newPrice);
    }

    function testCannot_SetHandleLengthMin_IfNotOwner(address notOwner, uint8 newMinLength) public {
        vm.assume(notOwner != permissionlessCreatorOwner);
        vm.assume(notOwner != address(0));

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(notOwner);
        permissionlessCreator.setHandleLengthMin(newMinLength);
    }

    function testCannot_SetTrustStatus_IfNotOwner(address notOwner, address targetAddress, bool newStatus) public {
        vm.assume(notOwner != permissionlessCreatorOwner);
        vm.assume(notOwner != address(0));
        vm.assume(targetAddress != address(0));

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(notOwner);
        permissionlessCreator.setTrustStatus(targetAddress, newStatus);
    }

    // Scenarios

    function testWithdrawCredits() public {
        vm.deal(address(permissionlessCreator), 123456789);

        uint256 contractBalanceBefore = address(permissionlessCreator).balance;
        uint256 ownerBalanceBefore = permissionlessCreatorOwner.balance;

        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.withdrawFunds();

        uint256 contractBalanceAfter = address(permissionlessCreator).balance;
        uint256 ownerBalanceAfter = permissionlessCreatorOwner.balance;

        assertEq(contractBalanceAfter, 0);
        assertEq(ownerBalanceBefore + contractBalanceBefore, ownerBalanceAfter);
    }

    function testAddCreditProvider(address newCreditProvider) public {
        vm.assume(newCreditProvider != address(0));
        vm.assume(permissionlessCreator.isCreditProvider(newCreditProvider) == false);

        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.addCreditProvider(newCreditProvider);

        assertTrue(permissionlessCreator.isCreditProvider(newCreditProvider));
    }

    function testRemoveCreditProvider(address existingCreditProvider) public {
        vm.assume(existingCreditProvider != address(0));

        if (permissionlessCreator.isCreditProvider(existingCreditProvider) == false) {
            vm.prank(permissionlessCreatorOwner);
            permissionlessCreator.addCreditProvider(existingCreditProvider);
        }

        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.removeCreditProvider(existingCreditProvider);

        assertTrue(permissionlessCreator.isCreditProvider(existingCreditProvider) == false);
    }

    function testSetProfileCreationPrice(uint128 newPrice) public {
        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setProfileCreationPrice(newPrice);

        assertEq(permissionlessCreator.getProfileCreationPrice(), newPrice);
    }

    function testSetHandleCreationPrice(uint128 newPrice) public {
        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setHandleCreationPrice(newPrice);

        assertEq(permissionlessCreator.getHandleCreationPrice(), newPrice);
    }

    function testSetHandleLengthMin(uint8 newMinLength) public {
        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setHandleLengthMin(newMinLength);

        assertEq(permissionlessCreator.getHandleLengthMin(), newMinLength);
    }

    function testSetTrustStatus(address targetAddress, bool newStatus) public {
        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setTrustStatus(targetAddress, newStatus);

        assertEq(permissionlessCreator.isUntrusted(targetAddress), newStatus);
    }

    // Getters

    function testGetProfileWithHandleCreationPrice() public {
        assertEq(
            permissionlessCreator.getProfileWithHandleCreationPrice(),
            permissionlessCreator.getProfileCreationPrice() + permissionlessCreator.getHandleCreationPrice()
        );

        vm.startPrank(permissionlessCreatorOwner);
        permissionlessCreator.setProfileCreationPrice(123);
        permissionlessCreator.setHandleCreationPrice(456);
        vm.stopPrank();

        assertEq(
            permissionlessCreator.getProfileWithHandleCreationPrice(),
            permissionlessCreator.getProfileCreationPrice() + permissionlessCreator.getHandleCreationPrice()
        );
    }

    function testGetProfileCreationPrice(uint128 newPrice) public {
        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setProfileCreationPrice(newPrice);

        assertEq(permissionlessCreator.getProfileCreationPrice(), newPrice);
    }

    function testGetHandleCreationPrice(uint128 newPrice) public {
        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setHandleCreationPrice(newPrice);

        assertEq(permissionlessCreator.getHandleCreationPrice(), newPrice);
    }

    function testGetHandleLengthMin(uint8 newMinLength) public {
        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setHandleLengthMin(newMinLength);

        assertEq(permissionlessCreator.getHandleLengthMin(), newMinLength);
    }

    function testisUntrusted(address targetAddress, bool newStatus) public {
        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.setTrustStatus(targetAddress, newStatus);

        assertEq(permissionlessCreator.isUntrusted(targetAddress), newStatus);
    }

    function testIsCreditProvider(address targetAddress) public {
        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.addCreditProvider(targetAddress);

        assertTrue(permissionlessCreator.isCreditProvider(targetAddress));
    }

    function testGetCreditBalance(address targetAddress, uint256 addBalance, uint256 subBalance) public {
        addBalance = bound(addBalance, 0, 100 ether);
        subBalance = bound(subBalance, 0, addBalance);
        uint256 balanceBefore = permissionlessCreator.getCreditBalance(targetAddress);

        vm.prank(creditProvider);
        permissionlessCreator.increaseCredits(targetAddress, addBalance);

        assertEq(permissionlessCreator.getCreditBalance(targetAddress), balanceBefore + addBalance);

        vm.prank(creditProvider);
        permissionlessCreator.decreaseCredits(targetAddress, subBalance);

        assertEq(permissionlessCreator.getCreditBalance(targetAddress), balanceBefore + addBalance - subBalance);
    }
}
