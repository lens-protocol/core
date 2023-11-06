// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {MockTokenHolderContract} from 'test/mocks/MockTokenHolderContract.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ERC721Test} from 'test/ERC721.t.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

interface IGuardedToken is IERC721 {
    function DANGER__disableTokenGuardian() external;

    function enableTokenGuardian() external;

    function getTokenGuardianDisablingTimestamp(address wallet) external view returns (uint256);

    function burn(uint256 tokenId) external;
}

abstract contract TokenGuardianTest_Default_On is ERC721Test {
    using Address for address;
    MockTokenHolderContract tokenHolderContract;

    uint256 tokenIdHeldByEOA;
    uint256 tokenIdHeldByNonEOA;

    function _TOKEN_GUARDIAN_COOLDOWN() internal view virtual returns (uint256);

    function _guardedToken() private view returns (IGuardedToken) {
        return IGuardedToken(_getERC721TokenAddress());
    }

    function setUp() public virtual override {
        super.setUp();
        tokenHolderContract = new MockTokenHolderContract();
        tokenHolderContract.setCollection(address(_guardedToken()));
        tokenIdHeldByEOA = _mintERC721(defaultAccount.owner);
        tokenIdHeldByNonEOA = _mintERC721(address(this));
        _guardedToken().safeTransferFrom(address(this), address(tokenHolderContract), tokenIdHeldByNonEOA);
    }

    //////////////////////////
    // Non-EOA token holder
    //////////////////////////

    ///////// Negatives

    function testCannot_disableTokenGuardian_ifNonEOA() public {
        vm.expectRevert(Errors.NotEOA.selector);
        tokenHolderContract.executeDisableTokenGuardian();
    }

    function testCannot_enableTokenGuardian_ifNonEOA() public {
        vm.expectRevert(Errors.NotEOA.selector);
        tokenHolderContract.executeEnableTokenGuardian();
    }

    ///////// Scenarios

    function testCan_approve_ifNonEOA() public {
        assertEq(_guardedToken().getApproved(tokenIdHeldByNonEOA), address(0));
        tokenHolderContract.executeApprove(address(this));
        assertEq(_guardedToken().getApproved(tokenIdHeldByNonEOA), address(this));
    }

    function testCan_setApprovalForAll_ifNonEOA() public {
        assertEq(_guardedToken().isApprovedForAll(address(tokenHolderContract), address(this)), false);
        tokenHolderContract.executeSetApprovalForAll(address(this), true);
        assertEq(_guardedToken().isApprovedForAll(address(tokenHolderContract), address(this)), true);
    }

    function testCan_burn_ifNonEOA() public {
        uint256 balance = _guardedToken().balanceOf(address(tokenHolderContract));
        assertTrue(balance > 0);
        tokenHolderContract.executeBurn();
        assertEq(_guardedToken().balanceOf(address(tokenHolderContract)), balance - 1);
    }

    function testCan_transferFrom_ifNonEOA() public {
        assertEq(_guardedToken().ownerOf(tokenIdHeldByNonEOA), address(tokenHolderContract));
        tokenHolderContract.executeTransferFrom(address(this));
        assertEq(_guardedToken().ownerOf(tokenIdHeldByNonEOA), address(this));
    }

    function testCan_safeTransferFrom_ifNonEOA() public {
        assertEq(_guardedToken().ownerOf(tokenIdHeldByNonEOA), address(tokenHolderContract));
        tokenHolderContract.executeSafeTransferFrom(defaultAccount.owner);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByNonEOA), defaultAccount.owner);
    }

    //////////////////////////
    // EOA token holder
    //////////////////////////

    ////////////////// Negatives

    function testCannot_DisableGuardian_MultipleTimes(uint256 elapsedTimeAfterDisabling) public {
        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        uint256 expectedProtectionRemovalTimestamp = block.timestamp + _TOKEN_GUARDIAN_COOLDOWN();
        assertEq(
            _guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner),
            expectedProtectionRemovalTimestamp
        );

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.expectRevert(Errors.DisablingAlreadyTriggered.selector);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        assertEq(
            _guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner),
            expectedProtectionRemovalTimestamp
        );
    }

    function testCannot_EnableGuardian_IfAlreadyEnabled() public {
        // Already enabled
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.AlreadyEnabled.selector);
        _guardedToken().enableTokenGuardian();
    }

    ////////////////// Protection enabled by default

    function testCannot_approve_ifEOA_andTokenGuardianEnabled() public {
        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), address(0));

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().approve(address(this), tokenIdHeldByEOA);

        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), address(0));
    }

    function testCannot_setApprovalForAll_ifEOA_andTokenGuardianEnabled() public {
        assertEq(_guardedToken().isApprovedForAll(defaultAccount.owner, address(this)), false);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().setApprovalForAll(address(this), true);

        assertEq(_guardedToken().isApprovedForAll(defaultAccount.owner, address(this)), false);
    }

    function testCannot_burn_ifEOA_andTokenGuardianEnabled() public {
        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().burn(tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    function testCannot_transferFrom_ifEOA_andTokenGuardianEnabled(address to) public {
        vm.assume(to != address(0));
        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    function testCannot_safeTransferFrom_ifEOA_andTokenGuardianEnabled(address to) public {
        vm.assume(to != address(0));
        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().safeTransferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    ////////////////// Protection disabled but have not taken effect yet

    function testCannot_approve_ifEOA_andTokenGuardianDisabled_butNotTakenEffectYet(
        uint256 elapsedTimeAfterDisabling
    ) public {
        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), address(0));

        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().approve(address(this), tokenIdHeldByEOA);

        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), address(0));
    }

    function testCannot_setApprovalForAll_ifEOA_andTokenGuardianDisabled_butNotTakenEffectYet(
        uint256 elapsedTimeAfterDisabling
    ) public {
        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        assertEq(_guardedToken().isApprovedForAll(defaultAccount.owner, address(this)), false);

        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().setApprovalForAll(address(this), true);

        assertEq(_guardedToken().isApprovedForAll(defaultAccount.owner, address(this)), false);
    }

    function testCannot_burn_ifEOA_andTokenGuardianDisabled_butNotTakenEffectYet(
        uint256 elapsedTimeAfterDisabling
    ) public {
        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().burn(tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    function testCannot_transferFrom_ifEOA_andTokenGuardianDisabled_butNotTakenEffectYet(
        uint256 elapsedTimeAfterDisabling,
        address to
    ) public {
        vm.assume(to != address(0));
        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    function testCannot_safeTransferFrom_ifEOA_andTokenGuardianDisabled_butNotTakenEffectYet(
        uint256 elapsedTimeAfterDisabling,
        address to
    ) public {
        vm.assume(to != address(0));
        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().safeTransferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    ////////////////// Scenarios - Events

    function testDisablingProtection_emitsExpectedEvent() public {
        vm.expectEmit(true, true, true, true, address(_guardedToken()));
        emit Events.TokenGuardianStateChanged(
            defaultAccount.owner,
            false,
            block.timestamp + _TOKEN_GUARDIAN_COOLDOWN(),
            block.timestamp
        );

        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();
    }

    function testEnablingProtection_emitsExpectedEvent() public {
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        vm.expectEmit(true, true, true, true, address(_guardedToken()));
        emit Events.TokenGuardianStateChanged(defaultAccount.owner, true, 0, block.timestamp);

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();
    }

    ////////////////// Protection removal timestamp

    function testDisableProtection_timestampMustBe_NowPlusTokenGuardianCooldown() public {
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();
        assertEq(
            _guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner),
            block.timestamp + _TOKEN_GUARDIAN_COOLDOWN()
        );
    }

    function testEnableProtection_timestampMustBeResetTo0() public {
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        assertTrue(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner) > 0);

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);
    }

    function testEnableProtection_afterDisabling_ButNotBeforeEffectivelyDisabled(
        uint256 elapsedTimeAfterDisabling
    ) public {
        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();
        assertEq(
            _guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner),
            block.timestamp + _TOKEN_GUARDIAN_COOLDOWN()
        );

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);
    }

    function testTimestampResetsToZero_WhenEnabling_AfterBeingEffectivelyDisabled() public {
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);

        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        assertTrue(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner) > 0);

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);
    }

    ////////////////// Protection effectively disabled

    function testCanApprove_ifEOA_onlyAfterTokenGuardianIs_EffectivelyDisabled(address addressToApprove) public {
        vm.assume(addressToApprove != defaultAccount.owner);
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        vm.prank(defaultAccount.owner);
        _guardedToken().approve(addressToApprove, tokenIdHeldByEOA);

        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), addressToApprove);
    }

    function testCanSetApprovalForAll_ifEOA_onlyAfterTokenGuardianIs_EffectivelyDisabled(
        address addressToApprove
    ) public {
        vm.assume(addressToApprove != defaultAccount.owner);
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        vm.prank(defaultAccount.owner);

        _guardedToken().setApprovalForAll(addressToApprove, true);

        assertTrue(_guardedToken().isApprovedForAll(defaultAccount.owner, addressToApprove));
    }

    function testCanBurn_ifEOA_onlyAfterTokenGuardianIs_EffectivelyDisabled() public {
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        vm.prank(defaultAccount.owner);
        _guardedToken().burn(tokenIdHeldByEOA);

        vm.expectRevert();
        _guardedToken().ownerOf(tokenIdHeldByEOA);
    }

    function testTransferFrom_ifEOA_onlyAfterTokenGuardianIsEffectivelyDisabled(address to) public {
        vm.assume(to != address(0));
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        vm.prank(defaultAccount.owner);
        _guardedToken().transferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);

        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), to);
    }

    function testSafeTransferFrom_ifEOA_onlyAfterTokenGuardianIsEffectivelyDisabled(address to) public {
        vm.assume(to != address(0));
        vm.assume(to.isContract() == false);

        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        vm.prank(defaultAccount.owner);
        _guardedToken().safeTransferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);

        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), to);
    }

    ////////////////// Protection enabled

    function testCanRevokaApproval_IfEOA_EvenWhenGuardianEnabled() public {
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);

        vm.prank(defaultAccount.owner);
        _guardedToken().approve(address(0), tokenIdHeldByEOA);

        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), address(0));
    }

    function testCanRemoveSetApprovalForAll_ifEOA_evenIfProtectionEnabled(address addressToRevokeApproval) public {
        vm.assume(addressToRevokeApproval != defaultAccount.owner);

        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);

        vm.prank(defaultAccount.owner);
        _guardedToken().setApprovalForAll(addressToRevokeApproval, false);

        assertFalse(_guardedToken().isApprovedForAll(defaultAccount.owner, addressToRevokeApproval));
    }

    function testApprovalStateDoesNotChange_afterProtectionStateChanges(address anotherAddress) public {
        vm.assume(anotherAddress != address(0));
        vm.assume(anotherAddress != defaultAccount.owner);

        // Disable protection
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        // Approve
        vm.prank(defaultAccount.owner);
        _guardedToken().approve(anotherAddress, tokenIdHeldByEOA);

        // Approve state has changed
        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), anotherAddress);

        // Enable protection
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        // Approve state remains the same after enabling protection
        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), anotherAddress);

        // But, you cannot transfer even if approved, because the protection is enabled
        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFrom(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);
    }

    function testApproveForAllState_DoesNotChange_AfterGuardianStateChanges(address anotherAddress) public {
        vm.assume(anotherAddress != address(0));
        vm.assume(anotherAddress != defaultAccount.owner);

        // Disable protection
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        // ApproveForAll
        vm.prank(defaultAccount.owner);
        _guardedToken().setApprovalForAll(anotherAddress, true);

        // ApproveForAll state has changed
        assertTrue(_guardedToken().isApprovedForAll(defaultAccount.owner, anotherAddress));

        // Enable protection
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        // ApproveForAll state remains the same after enabling protection
        assertTrue(_guardedToken().isApprovedForAll(defaultAccount.owner, anotherAddress));

        // But, you cannot transfer even if ApprovedForAll, because the protection is enabled
        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFrom(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);
    }

    function testTransfersDoesNotAffectProtectionState_InboundTransfer(address anotherAddress) public {
        vm.assume(anotherAddress != address(0));
        vm.assume(anotherAddress != defaultAccount.owner);
        vm.assume(anotherAddress.code.length == 0);

        // UserTwo does not have any profile
        vm.assume(_guardedToken().balanceOf(anotherAddress) == 0);

        // User disables protection, so it can perform a transfer later
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        // UserTwo disables protection
        _effectivelyDisableGuardian(address(_guardedToken()), anotherAddress);

        // UserTwo ApproveForAll User
        vm.prank(anotherAddress);
        _guardedToken().setApprovalForAll(defaultAccount.owner, true);

        // UserTwo receives a profile from User
        vm.prank(defaultAccount.owner);
        _guardedToken().transferFrom(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);

        // UserTwo now holds the profile
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), anotherAddress);

        // The profile is unprotected, and User is ApproveForAll by UserTwo, so can transfer the profile back
        vm.prank(anotherAddress);
        _guardedToken().transferFrom(anotherAddress, defaultAccount.owner, tokenIdHeldByEOA);

        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    function testTransfersDoNotAffectProtectionState_OutboundTransfer(address anotherAddress) public {
        vm.assume(anotherAddress != address(0));
        vm.assume(anotherAddress != defaultAccount.owner);

        // Disables protection
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        // Transfers the profile to UserTwo
        vm.prank(defaultAccount.owner);
        _guardedToken().transferFrom(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);

        // User does not have the profile anymore
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), anotherAddress);

        // Transfers does not affect protection state, so User can execute ApproveForAll even after transfer
        vm.prank(defaultAccount.owner);
        _guardedToken().setApprovalForAll(anotherAddress, true);
        assertTrue(_guardedToken().isApprovedForAll(defaultAccount.owner, anotherAddress));
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

abstract contract TokenGuardianTest_Default_Off is ERC721Test {
    using Address for address;
    MockTokenHolderContract tokenHolderContract;

    uint256 tokenIdHeldByEOA;
    uint256 tokenIdHeldByNonEOA;
    uint256 internal constant GUARDIAN_ENABLED = type(uint256).max;

    function _TOKEN_GUARDIAN_COOLDOWN() internal view virtual returns (uint256);

    function _guardedToken() private view returns (IGuardedToken) {
        return IGuardedToken(_getERC721TokenAddress());
    }

    function setUp() public virtual override {
        super.setUp();
        tokenHolderContract = new MockTokenHolderContract();
        tokenHolderContract.setCollection(address(_guardedToken()));
        tokenIdHeldByEOA = _mintERC721(defaultAccount.owner);
        tokenIdHeldByNonEOA = _mintERC721(address(this));
        _guardedToken().safeTransferFrom(address(this), address(tokenHolderContract), tokenIdHeldByNonEOA);
    }

    //////////////////////////
    // Non-EOA token holder
    //////////////////////////

    ///////// Negatives

    function testCannot_disableTokenGuardian_ifNonEOA() public {
        vm.expectRevert(Errors.NotEOA.selector);
        tokenHolderContract.executeDisableTokenGuardian();
    }

    function testCannot_enableTokenGuardian_ifNonEOA() public {
        vm.expectRevert(Errors.NotEOA.selector);
        tokenHolderContract.executeEnableTokenGuardian();
    }

    ///////// Scenarios

    function testCan_approve_ifNonEOA() public {
        assertEq(_guardedToken().getApproved(tokenIdHeldByNonEOA), address(0));
        tokenHolderContract.executeApprove(address(this));
        assertEq(_guardedToken().getApproved(tokenIdHeldByNonEOA), address(this));
    }

    function testCan_setApprovalForAll_ifNonEOA() public {
        assertEq(_guardedToken().isApprovedForAll(address(tokenHolderContract), address(this)), false);
        tokenHolderContract.executeSetApprovalForAll(address(this), true);
        assertEq(_guardedToken().isApprovedForAll(address(tokenHolderContract), address(this)), true);
    }

    function testCan_burn_ifNonEOA() public {
        uint256 balance = _guardedToken().balanceOf(address(tokenHolderContract));
        assertTrue(balance > 0);
        tokenHolderContract.executeBurn();
        assertEq(_guardedToken().balanceOf(address(tokenHolderContract)), balance - 1);
    }

    function testCan_transferFrom_ifNonEOA() public {
        assertEq(_guardedToken().ownerOf(tokenIdHeldByNonEOA), address(tokenHolderContract));
        tokenHolderContract.executeTransferFrom(address(this));
        assertEq(_guardedToken().ownerOf(tokenIdHeldByNonEOA), address(this));
    }

    function testCan_safeTransferFrom_ifNonEOA() public {
        assertEq(_guardedToken().ownerOf(tokenIdHeldByNonEOA), address(tokenHolderContract));
        tokenHolderContract.executeSafeTransferFrom(defaultAccount.owner);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByNonEOA), defaultAccount.owner);
    }

    //////////////////////////
    // EOA token holder
    //////////////////////////

    ////////////////// Negatives

    function testCannot_DisableGuardian_MultipleTimes() public {
        vm.expectRevert(Errors.DisablingAlreadyTriggered.selector);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);
    }

    function testCannot_EnableGuardian_IfAlreadyEnabled() public {
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        // Already enabled
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), GUARDIAN_ENABLED);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.AlreadyEnabled.selector);
        _guardedToken().enableTokenGuardian();
    }

    ////////////////// Protection enabled

    function testCannot_approve_ifEOA_andTokenGuardianEnabled() public {
        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), address(0));

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().approve(address(this), tokenIdHeldByEOA);

        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), address(0));
    }

    function testCannot_setApprovalForAll_ifEOA_andTokenGuardianEnabled() public {
        assertEq(_guardedToken().isApprovedForAll(defaultAccount.owner, address(this)), false);

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().setApprovalForAll(address(this), true);

        assertEq(_guardedToken().isApprovedForAll(defaultAccount.owner, address(this)), false);
    }

    function testCannot_burn_ifEOA_andTokenGuardianEnabled() public {
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().burn(tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    function testCannot_transferFrom_ifEOA_andTokenGuardianEnabled(address to) public {
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        vm.assume(to != address(0));
        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    function testCannot_safeTransferFrom_ifEOA_andTokenGuardianEnabled(address to) public {
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        vm.assume(to != address(0));
        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().safeTransferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    ////////////////// Protection disabled but have not taken effect yet

    function testCannot_approve_ifEOA_andTokenGuardianDisabled_butNotTakenEffectYet(
        uint256 elapsedTimeAfterDisabling
    ) public {
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), address(0));

        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().approve(address(this), tokenIdHeldByEOA);

        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), address(0));
    }

    function testCannot_setApprovalForAll_ifEOA_andTokenGuardianDisabled_butNotTakenEffectYet(
        uint256 elapsedTimeAfterDisabling
    ) public {
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        assertEq(_guardedToken().isApprovedForAll(defaultAccount.owner, address(this)), false);

        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().setApprovalForAll(address(this), true);

        assertEq(_guardedToken().isApprovedForAll(defaultAccount.owner, address(this)), false);
    }

    function testCannot_burn_ifEOA_andTokenGuardianDisabled_butNotTakenEffectYet(
        uint256 elapsedTimeAfterDisabling
    ) public {
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().burn(tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    function testCannot_transferFrom_ifEOA_andTokenGuardianDisabled_butNotTakenEffectYet(
        uint256 elapsedTimeAfterDisabling,
        address to
    ) public {
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        vm.assume(to != address(0));
        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    function testCannot_safeTransferFrom_ifEOA_andTokenGuardianDisabled_butNotTakenEffectYet(
        uint256 elapsedTimeAfterDisabling,
        address to
    ) public {
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        vm.assume(to != address(0));
        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().safeTransferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    ////////////////// Scenarios - Events

    function testDisablingProtection_emitsExpectedEvent() public {
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        vm.expectEmit(true, true, true, true, address(_guardedToken()));
        emit Events.TokenGuardianStateChanged(
            defaultAccount.owner,
            false,
            block.timestamp + _TOKEN_GUARDIAN_COOLDOWN(),
            block.timestamp
        );

        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();
    }

    function testEnablingProtection_emitsExpectedEvent() public {
        vm.expectEmit(true, true, true, true, address(_guardedToken()));
        emit Events.TokenGuardianStateChanged(defaultAccount.owner, true, GUARDIAN_ENABLED, block.timestamp);

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();
    }

    ////////////////// Protection removal timestamp

    function testDisableProtection_timestampMustBe_NowPlusTokenGuardianCooldown() public {
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), GUARDIAN_ENABLED);

        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();
        assertEq(
            _guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner),
            block.timestamp + _TOKEN_GUARDIAN_COOLDOWN()
        );
    }

    function testEnableProtection_timestampMustBeResetToMaxUint256() public {
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), GUARDIAN_ENABLED);
    }

    function testEnableProtection_afterDisabling_ButNotBeforeEffectivelyDisabled(
        uint256 elapsedTimeAfterDisabling
    ) public {
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        elapsedTimeAfterDisabling = bound(elapsedTimeAfterDisabling, 0, _TOKEN_GUARDIAN_COOLDOWN() - 1);
        vm.prank(defaultAccount.owner);
        _guardedToken().DANGER__disableTokenGuardian();
        assertEq(
            _guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner),
            block.timestamp + _TOKEN_GUARDIAN_COOLDOWN()
        );

        vm.warp(block.timestamp + elapsedTimeAfterDisabling);

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), GUARDIAN_ENABLED);
    }

    function testTimestampResetsToZero_WhenEnabling_AfterBeingEffectivelyDisabled() public {
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), GUARDIAN_ENABLED);

        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        assertTrue(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner) > 0);

        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), GUARDIAN_ENABLED);
    }

    ////////////////// Protection disabled (by default)

    function testCanApprove_ifEOA_disabledByDefault(address addressToApprove) public {
        vm.assume(addressToApprove != defaultAccount.owner);

        vm.prank(defaultAccount.owner);
        _guardedToken().approve(addressToApprove, tokenIdHeldByEOA);

        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), addressToApprove);
    }

    function testCanSetApprovalForAll_ifEOA_disabledByDefault(address addressToApprove) public {
        vm.assume(addressToApprove != defaultAccount.owner);

        vm.prank(defaultAccount.owner);

        _guardedToken().setApprovalForAll(addressToApprove, true);

        assertTrue(_guardedToken().isApprovedForAll(defaultAccount.owner, addressToApprove));
    }

    function testCanBurn_ifEOA_disabledByDefault() public {
        vm.prank(defaultAccount.owner);
        _guardedToken().burn(tokenIdHeldByEOA);

        vm.expectRevert();
        _guardedToken().ownerOf(tokenIdHeldByEOA);
    }

    function testTransferFrom_ifEOA_disabledByDefault(address to) public {
        vm.assume(to != address(0));

        vm.prank(defaultAccount.owner);
        _guardedToken().transferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);

        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), to);
    }

    function testSafeTransferFrom_ifEOA_disabledByDefault(address to) public {
        vm.assume(to != address(0));
        vm.assume(to.isContract() == false);

        vm.prank(defaultAccount.owner);
        _guardedToken().safeTransferFrom(defaultAccount.owner, to, tokenIdHeldByEOA);

        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), to);
    }

    ////////////////// Protection enabled

    function testCanRevokaApproval_IfEOA_EvenWhenGuardianEnabled() public {
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);

        vm.prank(defaultAccount.owner);
        _guardedToken().approve(address(0), tokenIdHeldByEOA);

        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), address(0));
    }

    function testCanRemoveSetApprovalForAll_ifEOA_evenIfProtectionEnabled(address addressToRevokeApproval) public {
        vm.assume(addressToRevokeApproval != defaultAccount.owner);

        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(defaultAccount.owner), 0);

        vm.prank(defaultAccount.owner);
        _guardedToken().setApprovalForAll(addressToRevokeApproval, false);

        assertFalse(_guardedToken().isApprovedForAll(defaultAccount.owner, addressToRevokeApproval));
    }

    function testApprovalStateDoesNotChange_afterProtectionStateChanges(address anotherAddress) public {
        vm.assume(anotherAddress != address(0));
        vm.assume(anotherAddress != defaultAccount.owner);

        // Approve
        vm.prank(defaultAccount.owner);
        _guardedToken().approve(anotherAddress, tokenIdHeldByEOA);

        // Approve state has changed
        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), anotherAddress);

        // Enable protection
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        // Approve state remains the same after enabling protection
        assertEq(_guardedToken().getApproved(tokenIdHeldByEOA), anotherAddress);

        // But, you cannot transfer even if approved, because the protection is enabled
        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFrom(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);
    }

    function testApproveForAllState_DoesNotChange_AfterGuardianStateChanges(address anotherAddress) public {
        vm.assume(anotherAddress != address(0));
        vm.assume(anotherAddress != defaultAccount.owner);

        // ApproveForAll
        vm.prank(defaultAccount.owner);
        _guardedToken().setApprovalForAll(anotherAddress, true);

        // ApproveForAll state has changed
        assertTrue(_guardedToken().isApprovedForAll(defaultAccount.owner, anotherAddress));

        // Enable protection
        vm.prank(defaultAccount.owner);
        _guardedToken().enableTokenGuardian();

        // ApproveForAll state remains the same after enabling protection
        assertTrue(_guardedToken().isApprovedForAll(defaultAccount.owner, anotherAddress));

        // But, you cannot transfer even if ApprovedForAll, because the protection is enabled
        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFrom(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);
    }

    function testTransfersDoesNotAffectProtectionState_InboundTransfer(address anotherAddress) public {
        vm.assume(anotherAddress != address(0));
        vm.assume(anotherAddress != defaultAccount.owner);
        vm.assume(anotherAddress.code.length == 0);
        vm.assume(_guardedToken().getTokenGuardianDisablingTimestamp(anotherAddress) != GUARDIAN_ENABLED);

        // UserTwo does not have any profile
        vm.assume(_guardedToken().balanceOf(anotherAddress) == 0);

        // UserTwo enables protection
        vm.prank(anotherAddress);
        _guardedToken().enableTokenGuardian();
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(anotherAddress), GUARDIAN_ENABLED);

        // UserTwo receives a profile from User
        vm.prank(defaultAccount.owner);
        _guardedToken().transferFrom(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);

        // UserTwo now holds the profile
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), anotherAddress);

        // UserTwo still has guardian enabled
        assertEq(_guardedToken().getTokenGuardianDisablingTimestamp(anotherAddress), GUARDIAN_ENABLED);
    }

    function testTransfersDoNotAffectProtectionState_OutboundTransfer(address anotherAddress) public {
        vm.assume(anotherAddress != address(0));
        vm.assume(anotherAddress != defaultAccount.owner);

        // Transfers the profile to UserTwo
        vm.prank(defaultAccount.owner);
        _guardedToken().transferFrom(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);

        // User does not have the profile anymore
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), anotherAddress);

        // Transfers does not affect protection state, so User can execute ApproveForAll even after transfer
        vm.prank(defaultAccount.owner);
        _guardedToken().setApprovalForAll(anotherAddress, true);
        assertTrue(_guardedToken().isApprovedForAll(defaultAccount.owner, anotherAddress));
    }
}
