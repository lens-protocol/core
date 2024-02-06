// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/LensBaseERC721Test.t.sol';
import {Base64} from 'solady/utils/Base64.sol';
import {LibString} from 'solady/utils/LibString.sol';
import {ProfileTokenURI} from 'contracts/misc/token-uris/ProfileTokenURI.sol';
import {IProfileTokenURI} from 'contracts/interfaces/IProfileTokenURI.sol';
import {ILensProfiles} from 'contracts/interfaces/ILensProfiles.sol';
import {MockTokenHolderContract} from 'test/mocks/MockTokenHolderContract.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

interface IGuardedToken is IERC721 {
    function DANGER__disableTokenGuardian() external;

    function enableTokenGuardian() external;

    function getTokenGuardianDisablingTimestamp(address wallet) external view returns (uint256);

    function transferFromKeepingDelegates(address from, address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}

contract TransferKeepingDelegatesTest is BaseTest {
    using Address for address;

    function _getERC721TokenAddress() internal view virtual returns (address) {
        return address(hub);
    }

    function _LensProfiles() private view returns (ILensProfiles) {
        return ILensProfiles(_getERC721TokenAddress());
    }

    function _mintERC721(address to) internal virtual returns (uint256) {
        vm.assume(!_isLensHubProxyAdmin(to));
        return _createProfile(to);
    }

    function _burnERC721(uint256 tokenId) internal virtual {
        return hub.burn(tokenId);
    }

    function _disableGuardian(address wallet) internal {
        _effectivelyDisableProfileGuardian(wallet);
    }

    function _assumeNotProxyAdmin(address account) internal view virtual {
        vm.assume(!_isLensHubProxyAdmin(account));
    }

    function _TOKEN_GUARDIAN_COOLDOWN() internal view returns (uint256) {
        return fork ? hub.TOKEN_GUARDIAN_COOLDOWN() : PROFILE_GUARDIAN_COOLDOWN;
    }

    function _guardedToken() private view returns (IGuardedToken) {
        return IGuardedToken(_getERC721TokenAddress());
    }

    MockTokenHolderContract tokenHolderContract;
    uint256 tokenIdHeldByEOA;
    uint256 tokenIdHeldByNonEOA;

    function setUp() public virtual override {
        super.setUp();
        tokenHolderContract = new MockTokenHolderContract();
        tokenHolderContract.setCollection(address(_guardedToken()));
        tokenIdHeldByEOA = _mintERC721(defaultAccount.owner);
        tokenIdHeldByNonEOA = _mintERC721(address(this));
        _guardedToken().safeTransferFrom(address(this), address(tokenHolderContract), tokenIdHeldByNonEOA);
    }

    // TokenGuardian tests

    function testCannot_transferFrom_ifEOA_andTokenGuardianEnabled(address to) public {
        vm.assume(to != address(0));

        vm.prank(governance);
        hub.whitelistProfileCreator(defaultAccount.owner, true);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFromKeepingDelegates(defaultAccount.owner, to, tokenIdHeldByEOA);
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

        vm.prank(governance);
        hub.whitelistProfileCreator(defaultAccount.owner, true);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFromKeepingDelegates(defaultAccount.owner, to, tokenIdHeldByEOA);
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    function testTransferFrom_ifEOA_onlyAfterTokenGuardianIsEffectivelyDisabled(address to) public {
        vm.assume(to != address(0));
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        vm.prank(governance);
        hub.whitelistProfileCreator(defaultAccount.owner, true);

        vm.prank(defaultAccount.owner);
        _guardedToken().transferFromKeepingDelegates(defaultAccount.owner, to, tokenIdHeldByEOA);

        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), to);
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

        vm.prank(governance);
        hub.whitelistProfileCreator(defaultAccount.owner, true);

        // But, you cannot transfer even if approved, because the protection is enabled
        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFromKeepingDelegates(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);
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

        vm.prank(governance);
        hub.whitelistProfileCreator(defaultAccount.owner, true);

        // But, you cannot transfer even if ApprovedForAll, because the protection is enabled
        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.GuardianEnabled.selector);
        _guardedToken().transferFromKeepingDelegates(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);
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

        vm.prank(governance);
        hub.whitelistProfileCreator(defaultAccount.owner, true);

        // UserTwo receives a profile from User
        vm.prank(defaultAccount.owner);
        _guardedToken().transferFromKeepingDelegates(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);

        // UserTwo now holds the profile
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), anotherAddress);

        vm.prank(governance);
        hub.whitelistProfileCreator(anotherAddress, true);

        // The profile is unprotected, and User is ApproveForAll by UserTwo, so can transfer the profile back
        vm.prank(anotherAddress);
        _guardedToken().transferFromKeepingDelegates(anotherAddress, defaultAccount.owner, tokenIdHeldByEOA);

        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), defaultAccount.owner);
    }

    function testTransfersDoNotAffectProtectionState_OutboundTransfer(address anotherAddress) public {
        vm.assume(anotherAddress != address(0));
        vm.assume(anotherAddress != defaultAccount.owner);

        // Disables protection
        _effectivelyDisableGuardian(address(_guardedToken()), defaultAccount.owner);

        vm.prank(governance);
        hub.whitelistProfileCreator(defaultAccount.owner, true);

        // Transfers the profile to UserTwo
        vm.prank(defaultAccount.owner);
        _guardedToken().transferFromKeepingDelegates(defaultAccount.owner, anotherAddress, tokenIdHeldByEOA);

        // User does not have the profile anymore
        assertEq(_guardedToken().ownerOf(tokenIdHeldByEOA), anotherAddress);

        // Transfers does not affect protection state, so User can execute ApproveForAll even after transfer
        vm.prank(defaultAccount.owner);
        _guardedToken().setApprovalForAll(anotherAddress, true);
        assertTrue(_guardedToken().isApprovedForAll(defaultAccount.owner, anotherAddress));
    }

    // General ERC721.TransferFrom tests

    function testTransferFromKeepingDelegates_SenderIsApproved(address owner, address approvedTo, address to) public {
        vm.assume(owner != address(0));
        vm.assume(approvedTo != address(0));
        vm.assume(owner != approvedTo);
        vm.assume(to != address(0));

        uint256 tokenId = _mintERC721(owner);

        _disableGuardian(owner);

        vm.prank(owner);
        _LensProfiles().approve(approvedTo, tokenId);

        uint256 ownerBalanceBefore = _LensProfiles().balanceOf(owner);
        uint256 toBalanceBefore = _LensProfiles().balanceOf(to);

        _assumeNotProxyAdmin(approvedTo);

        _disableGuardian(approvedTo);

        vm.prank(governance);
        hub.whitelistProfileCreator(approvedTo, true);

        vm.prank(approvedTo);
        _LensProfiles().transferFromKeepingDelegates(owner, to, tokenId);

        uint256 ownerBalanceAfter = _LensProfiles().balanceOf(owner);
        uint256 toBalanceAfter = _LensProfiles().balanceOf(to);

        assertEq(_LensProfiles().getApproved(tokenId), address(0));
        assertEq(_LensProfiles().ownerOf(tokenId), to);

        if (owner != to) {
            assertEq(ownerBalanceAfter, ownerBalanceBefore - 1);
            assertEq(toBalanceAfter, toBalanceBefore + 1);
        }
    }

    function testTransferFromKeepingDelegates_SenderIsTheOwner(address owner, address to) public {
        vm.assume(owner != address(0));
        vm.assume(to != address(0));

        uint256 tokenId = _mintERC721(owner);

        uint256 ownerBalanceBefore = _LensProfiles().balanceOf(owner);
        uint256 toBalanceBefore = _LensProfiles().balanceOf(to);

        _disableGuardian(owner);

        vm.prank(governance);
        hub.whitelistProfileCreator(owner, true);

        vm.prank(owner);
        _LensProfiles().transferFromKeepingDelegates(owner, to, tokenId);

        uint256 ownerBalanceAfter = _LensProfiles().balanceOf(owner);
        uint256 toBalanceAfter = _LensProfiles().balanceOf(to);

        assertEq(_LensProfiles().getApproved(tokenId), address(0));
        assertEq(_LensProfiles().ownerOf(tokenId), to);

        if (owner != to) {
            assertEq(ownerBalanceAfter, ownerBalanceBefore - 1);
            assertEq(toBalanceAfter, toBalanceBefore + 1);
        }
    }

    function testTransferFromKeepingDelegates_SenderIsApprovedForAll(
        address owner,
        address approvedTo,
        address to
    ) public {
        vm.assume(owner != address(0));
        vm.assume(approvedTo != address(0));
        vm.assume(owner != approvedTo);
        vm.assume(to != address(0));

        uint256 tokenId = _mintERC721(owner);

        _disableGuardian(owner);

        vm.prank(owner);
        _LensProfiles().setApprovalForAll(approvedTo, true);

        uint256 ownerBalanceBefore = _LensProfiles().balanceOf(owner);
        uint256 toBalanceBefore = _LensProfiles().balanceOf(to);

        _assumeNotProxyAdmin(approvedTo);

        _disableGuardian(approvedTo);

        vm.prank(governance);
        hub.whitelistProfileCreator(approvedTo, true);

        vm.prank(approvedTo);
        _LensProfiles().transferFromKeepingDelegates(owner, to, tokenId);

        uint256 ownerBalanceAfter = _LensProfiles().balanceOf(owner);
        uint256 toBalanceAfter = _LensProfiles().balanceOf(to);

        assertEq(_LensProfiles().ownerOf(tokenId), to);

        if (owner != to) {
            assertEq(ownerBalanceAfter, ownerBalanceBefore - 1);
            assertEq(toBalanceAfter, toBalanceBefore + 1);
        }
    }

    function testCannot_TransferFromKeepingDelegates_NotOwner(address owner, address to, address otherAddress) public {
        vm.assume(owner != to);
        vm.assume(owner != otherAddress);
        vm.assume(to != address(0));
        vm.assume(owner != address(0));
        vm.assume(otherAddress != address(0));

        uint256 tokenId = _mintERC721(owner);

        _assumeNotProxyAdmin(otherAddress);

        vm.prank(governance);
        hub.whitelistProfileCreator(otherAddress, true);

        vm.expectRevert(Errors.NotOwnerOrApproved.selector);
        vm.prank(otherAddress);
        _LensProfiles().transferFromKeepingDelegates(owner, to, tokenId);
    }

    function testCannotTransferFromKeepingDelegates_WrongFromParameter_SenderOwner(
        address owner,
        address from,
        address to
    ) public {
        _assumeNotProxyAdmin(owner);
        vm.assume(owner != to);
        vm.assume(owner != from);
        vm.assume(owner != address(0));
        vm.assume(to != address(0));

        uint256 tokenId = _mintERC721(owner);

        vm.prank(governance);
        hub.whitelistProfileCreator(owner, true);

        vm.expectRevert(Errors.InvalidOwner.selector);

        vm.prank(owner);
        _LensProfiles().transferFromKeepingDelegates(from, to, tokenId);
    }

    function testCannot_TransferFromKeepingDelegates_NonexistingToken(
        uint256 tokenId,
        address from,
        address to
    ) public {
        vm.assume(from != address(0));
        vm.assume(to != address(0));

        vm.assume(_LensProfiles().exists(tokenId) == false);

        vm.prank(governance);
        hub.whitelistProfileCreator(address(this), true);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        _LensProfiles().transferFromKeepingDelegates(from, to, tokenId);
    }

    function testCannot_TransferFromKeepingDelegates_ToZero(address owner) public {
        vm.assume(owner != address(0));
        uint256 tokenId = _mintERC721(owner);

        vm.prank(governance);
        hub.whitelistProfileCreator(owner, true);

        vm.expectRevert(Errors.InvalidParameter.selector);

        vm.prank(owner);
        _LensProfiles().transferFromKeepingDelegates(owner, address(0), tokenId);
    }

    // Tests list for TransferFromKeepingDelegates function:

    // Negatives

    function testCannot_TransferFromKeepingDelegates_IfNotWhitelistedProfileCreator(
        address owner,
        address to,
        address approvedTo
    ) public {
        vm.assume(owner != to);
        vm.assume(to != address(0));
        vm.assume(owner != address(0));
        vm.assume(approvedTo != address(0));
        vm.assume(hub.isProfileCreatorWhitelisted(approvedTo) == false);
        _assumeNotProxyAdmin(approvedTo);
        _assumeNotProxyAdmin(owner);

        _disableGuardian(owner);

        uint256 tokenId = _mintERC721(owner);

        if (owner != approvedTo) {
            vm.prank(owner);
            _LensProfiles().approve(approvedTo, tokenId);
        }

        vm.expectRevert(Errors.NotAllowed.selector);
        vm.prank(approvedTo);
        _LensProfiles().transferFromKeepingDelegates(owner, to, tokenId);
    }

    // Scenarios

    function testTransferFromKeepingDelegates(address owner, address to, address approvedTo) public {
        vm.assume(owner != to);
        vm.assume(to != address(0));
        vm.assume(owner != address(0));
        vm.assume(approvedTo != address(0));
        _assumeNotProxyAdmin(approvedTo);

        _disableGuardian(owner);

        uint256 tokenId = _mintERC721(owner);

        vm.prank(governance);
        hub.whitelistProfileCreator(approvedTo, true);

        if (owner != approvedTo) {
            vm.prank(owner);
            _LensProfiles().approve(approvedTo, tokenId);
        }

        address[] memory delegatedExecutors = new address[](3);
        delegatedExecutors[0] = makeAddr('DE0');
        delegatedExecutors[1] = makeAddr('DE1');
        delegatedExecutors[2] = makeAddr('DE2');

        // Initialize an array of bools with the same length as delegatedExecutors
        bool[] memory executorEnabled = new bool[](delegatedExecutors.length);

        // Fill the array with `true`
        for (uint256 i = 0; i < delegatedExecutors.length; i++) {
            executorEnabled[i] = true;
        }

        vm.prank(owner);
        hub.changeDelegatedExecutorsConfig(tokenId, delegatedExecutors, executorEnabled);

        vm.prank(approvedTo);
        _LensProfiles().transferFromKeepingDelegates(owner, to, tokenId);

        for (uint256 i = 0; i < delegatedExecutors.length; i++) {
            assertTrue(hub.isDelegatedExecutorApproved(tokenId, delegatedExecutors[i]));
        }
    }
}
