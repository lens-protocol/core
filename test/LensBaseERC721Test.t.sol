// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import 'forge-std/Test.sol';

import {ILensERC721} from 'contracts/interfaces/ILensERC721.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Timestamped} from 'contracts/interfaces/IERC721Timestamped.sol';
import {IERC721Burnable} from 'contracts/interfaces/IERC721Burnable.sol';
import {IERC721MetaTx} from 'contracts/interfaces/IERC721MetaTx.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

contract ERC721Recipient is IERC721Receiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function testERC721Recipient() public {
        // Prevents being counted in Foundry Coverage
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return IERC721Receiver.onERC721Received.selector;
    }
}

contract RevertingERC721Recipient is IERC721Receiver {
    function testRevertingERC721Recipient() public {
        // Prevents being counted in Foundry Coverage
    }

    function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
        revert(string(abi.encodePacked(IERC721Receiver.onERC721Received.selector)));
    }
}

contract WrongReturnDataERC721Recipient is IERC721Receiver {
    function testWrongReturnDataERC721Recipient() public {
        // Prevents being counted in Foundry Coverage
    }

    function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient {}

abstract contract LensBaseERC721Test is Test {
    function _getERC721TokenAddress() internal view virtual returns (address);

    function _mintERC721(address to) internal virtual returns (uint256);

    function _burnERC721(uint256 tokenId) internal virtual;

    function _getNotOwnerError() internal virtual returns (bytes4) {
        return Errors.NotOwnerOrApproved.selector;
    }

    function _assumeNotProxyAdmin(address /* account */) internal view virtual {}

    function _LensERC721() private view returns (ILensERC721) {
        return ILensERC721(_getERC721TokenAddress());
    }

    function testMint(address to) public {
        vm.assume(to != address(0));

        uint256 balanceBeforeMint = _LensERC721().balanceOf(to);

        uint256 tokenId = _mintERC721(to);

        uint256 balanceAfterMint = _LensERC721().balanceOf(to);

        assertEq(balanceAfterMint, balanceBeforeMint + 1);
        assertEq(_LensERC721().ownerOf(tokenId), to);
    }

    function testBurn(address owner) public {
        vm.assume(owner != address(0));
        uint256 tokenId = _mintERC721(owner);

        uint256 currentBalance = _LensERC721().balanceOf(owner);

        vm.prank(owner);
        _burnERC721(tokenId);

        uint256 balanceAfterBurn = _LensERC721().balanceOf(owner);

        assertEq(balanceAfterBurn, currentBalance - 1);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        _LensERC721().ownerOf(tokenId);
    }

    function testApprove(address owner, address to) public {
        vm.assume(owner != address(0));
        vm.assume(to != address(0));
        vm.assume(owner != to);

        uint256 tokenId = _mintERC721(owner);

        vm.prank(owner);
        _LensERC721().approve(to, tokenId);

        assertEq(_LensERC721().getApproved(tokenId), to);
    }

    function testApproveAll(address msgSender, address to) public {
        vm.assume(msgSender != address(0));
        vm.assume(msgSender != to);
        vm.assume(to != address(0));

        _assumeNotProxyAdmin(msgSender);
        vm.prank(msgSender);
        _LensERC721().setApprovalForAll(to, true);

        assertTrue(_LensERC721().isApprovedForAll(msgSender, to));
    }

    function testTransferFrom(address owner, address approvedTo, address to) public {
        vm.assume(owner != address(0));
        vm.assume(approvedTo != address(0));
        vm.assume(owner != approvedTo);
        vm.assume(to != address(0));

        uint256 tokenId = _mintERC721(owner);

        vm.prank(owner);
        _LensERC721().approve(approvedTo, tokenId);

        uint256 ownerBalanceBefore = _LensERC721().balanceOf(owner);
        uint256 toBalanceBefore = _LensERC721().balanceOf(to);

        _assumeNotProxyAdmin(approvedTo);
        vm.prank(approvedTo);
        _LensERC721().transferFrom(owner, to, tokenId);

        uint256 ownerBalanceAfter = _LensERC721().balanceOf(owner);
        uint256 toBalanceAfter = _LensERC721().balanceOf(to);

        assertEq(_LensERC721().getApproved(tokenId), address(0));
        assertEq(_LensERC721().ownerOf(tokenId), to);

        if (owner != to) {
            assertEq(ownerBalanceAfter, ownerBalanceBefore - 1);
            assertEq(toBalanceAfter, toBalanceBefore + 1);
        }
    }

    function testTransferFromSelf(address owner, address to) public {
        vm.assume(owner != address(0));
        vm.assume(to != address(0));

        uint256 tokenId = _mintERC721(owner);

        uint256 ownerBalanceBefore = _LensERC721().balanceOf(owner);
        uint256 toBalanceBefore = _LensERC721().balanceOf(to);

        vm.prank(owner);
        _LensERC721().transferFrom(owner, to, tokenId);

        uint256 ownerBalanceAfter = _LensERC721().balanceOf(owner);
        uint256 toBalanceAfter = _LensERC721().balanceOf(to);

        assertEq(_LensERC721().getApproved(tokenId), address(0));
        assertEq(_LensERC721().ownerOf(tokenId), to);

        if (owner != to) {
            assertEq(ownerBalanceAfter, ownerBalanceBefore - 1);
            assertEq(toBalanceAfter, toBalanceBefore + 1);
        }
    }

    function testTransferFromApproveAll(address owner, address approvedTo, address to) public {
        vm.assume(owner != address(0));
        vm.assume(approvedTo != address(0));
        vm.assume(owner != approvedTo);
        vm.assume(to != address(0));

        uint256 tokenId = _mintERC721(owner);

        vm.prank(owner);
        _LensERC721().setApprovalForAll(approvedTo, true);

        uint256 ownerBalanceBefore = _LensERC721().balanceOf(owner);
        uint256 toBalanceBefore = _LensERC721().balanceOf(to);

        _assumeNotProxyAdmin(approvedTo);
        vm.prank(approvedTo);
        _LensERC721().transferFrom(owner, to, tokenId);

        uint256 ownerBalanceAfter = _LensERC721().balanceOf(owner);
        uint256 toBalanceAfter = _LensERC721().balanceOf(to);

        assertEq(_LensERC721().getApproved(tokenId), address(0));
        assertEq(_LensERC721().ownerOf(tokenId), to);

        if (owner != to) {
            assertEq(ownerBalanceAfter, ownerBalanceBefore - 1);
            assertEq(toBalanceAfter, toBalanceBefore + 1);
        }
    }

    function testSafeTransferFromToEOA(address owner, address approvedTo, address to) public {
        vm.assume(owner != address(0));
        vm.assume(to != address(0));
        vm.assume(approvedTo != address(0));
        vm.assume(owner != approvedTo);
        vm.assume(to.code.length == 0);

        uint256 tokenId = _mintERC721(owner);

        vm.prank(owner);
        _LensERC721().setApprovalForAll(approvedTo, true);

        uint256 ownerBalanceBefore = _LensERC721().balanceOf(owner);
        uint256 toBalanceBefore = _LensERC721().balanceOf(to);

        _assumeNotProxyAdmin(approvedTo);
        vm.prank(approvedTo);
        _LensERC721().safeTransferFrom(owner, to, tokenId);

        uint256 ownerBalanceAfter = _LensERC721().balanceOf(owner);
        uint256 toBalanceAfter = _LensERC721().balanceOf(to);

        assertEq(_LensERC721().getApproved(tokenId), address(0));
        assertEq(_LensERC721().ownerOf(tokenId), to);

        if (owner != to) {
            assertEq(ownerBalanceAfter, ownerBalanceBefore - 1);
            assertEq(toBalanceAfter, toBalanceBefore + 1);
        }
    }

    function testSafeTransferFromToERC721Recipient(address owner, address approvedTo) public {
        vm.assume(owner != address(0));
        vm.assume(approvedTo != address(0));
        vm.assume(owner != approvedTo);

        ERC721Recipient recipient = new ERC721Recipient();

        uint256 tokenId = _mintERC721(owner);

        vm.prank(owner);
        _LensERC721().setApprovalForAll(approvedTo, true);

        uint256 ownerBalanceBefore = _LensERC721().balanceOf(owner);
        uint256 recipientBalanceBefore = _LensERC721().balanceOf(address(recipient));

        _assumeNotProxyAdmin(approvedTo);
        vm.prank(approvedTo);
        _LensERC721().safeTransferFrom(owner, address(recipient), tokenId);

        uint256 ownerBalanceAfter = _LensERC721().balanceOf(owner);
        uint256 recipientBalanceAfter = _LensERC721().balanceOf(address(recipient));

        assertEq(_LensERC721().getApproved(tokenId), address(0));
        assertEq(_LensERC721().ownerOf(tokenId), address(recipient));

        assertEq(ownerBalanceAfter, ownerBalanceBefore - 1);
        assertEq(recipientBalanceAfter, recipientBalanceBefore + 1);

        assertEq(recipient.operator(), approvedTo);
        assertEq(recipient.from(), owner);
        assertEq(recipient.id(), tokenId);
        assertEq(recipient.data(), '');
    }

    function testSafeTransferFromToERC721RecipientWithData(address owner, address approvedTo) public {
        vm.assume(owner != address(0));
        vm.assume(approvedTo != address(0));
        vm.assume(owner != approvedTo);

        ERC721Recipient recipient = new ERC721Recipient();
        vm.assume(owner != address(recipient));

        uint256 tokenId = _mintERC721(owner);

        vm.prank(owner);
        _LensERC721().setApprovalForAll(approvedTo, true);

        uint256 ownerBalanceBefore = _LensERC721().balanceOf(owner);
        uint256 recipientBalanceBefore = _LensERC721().balanceOf(address(recipient));

        _assumeNotProxyAdmin(approvedTo);
        vm.prank(approvedTo);
        _LensERC721().safeTransferFrom(owner, address(recipient), tokenId, 'testing 123');

        uint256 ownerBalanceAfter = _LensERC721().balanceOf(owner);
        uint256 recipientBalanceAfter = _LensERC721().balanceOf(address(recipient));

        assertEq(_LensERC721().getApproved(tokenId), address(0));
        assertEq(_LensERC721().ownerOf(tokenId), address(recipient));

        assertEq(ownerBalanceAfter, ownerBalanceBefore - 1);
        assertEq(recipientBalanceAfter, recipientBalanceBefore + 1);

        assertEq(recipient.operator(), approvedTo);
        assertEq(recipient.from(), owner);
        assertEq(recipient.id(), tokenId);
        assertEq(recipient.data(), 'testing 123');
    }

    function testCannot_MintToZero() public {
        vm.expectRevert(Errors.InvalidParameter.selector);
        _mintERC721(address(0));
    }

    function testCannot_Burn_NonOwner_NorApproved_NorApprovedForAll(address owner, address otherAddress) public {
        vm.assume(owner != address(0));
        vm.assume(otherAddress != address(0));
        vm.assume(owner != otherAddress);
        vm.assume(_LensERC721().isApprovedForAll(owner, otherAddress) == false);

        uint256 tokenId = _mintERC721(owner);

        vm.assume(_LensERC721().getApproved(tokenId) != otherAddress);

        _assumeNotProxyAdmin(otherAddress);

        vm.expectRevert(_getNotOwnerError());
        vm.prank(otherAddress);
        _burnERC721(tokenId);
    }

    function testCannot_Burn_NotMinted(uint256 tokenId) public {
        vm.assume(_LensERC721().exists(tokenId) == false);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        _burnERC721(tokenId);
    }

    function testCannot_DoubleBurn(address to) public {
        vm.assume(to != address(0));

        uint256 tokenId = _mintERC721(to);

        vm.prank(to);
        _burnERC721(tokenId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        vm.prank(to);
        _burnERC721(tokenId);
    }

    function testCannot_Approve_NotMinted(uint256 tokenId, address to) public {
        vm.assume(to != address(0));
        vm.assume(_LensERC721().exists(tokenId) == false);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        _LensERC721().approve(to, tokenId);
    }

    function testCannot_Approve_Unauthorized(address to, address otherAddress, address approveTo) public {
        vm.assume(to != otherAddress);
        vm.assume(to != address(0));
        vm.assume(otherAddress != address(0));
        vm.assume(approveTo != otherAddress);
        vm.assume(approveTo != address(0));
        uint256 tokenId = _mintERC721(to);

        _assumeNotProxyAdmin(otherAddress);

        vm.expectRevert(Errors.NotOwnerOrApproved.selector);
        vm.prank(otherAddress);
        _LensERC721().approve(approveTo, tokenId);
    }

    function testCannot_Approve_ToOwner(address to) public {
        vm.assume(to != address(0));

        uint256 tokenId = _mintERC721(to);

        vm.expectRevert(Errors.InvalidParameter.selector);

        vm.prank(to);
        _LensERC721().approve(to, tokenId);
    }

    function testCannot_TransferFrom_NotOwner(address owner, address to, address otherAddress) public {
        vm.assume(owner != to);
        vm.assume(owner != otherAddress);
        vm.assume(to != address(0));
        vm.assume(owner != address(0));
        vm.assume(otherAddress != address(0));

        uint256 tokenId = _mintERC721(owner);

        vm.expectRevert(Errors.NotOwnerOrApproved.selector);

        _assumeNotProxyAdmin(otherAddress);
        vm.prank(otherAddress);
        _LensERC721().transferFrom(owner, to, tokenId);
    }

    function testCannot_TransferFrom_NonexistingToken(uint256 tokenId, address from, address to) public {
        vm.assume(from != address(0));
        vm.assume(to != address(0));

        vm.assume(_LensERC721().exists(tokenId) == false);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        _LensERC721().transferFrom(from, to, tokenId);
    }

    function testCannot_TransferFrom_ToZero(address owner) public {
        vm.assume(owner != address(0));
        uint256 tokenId = _mintERC721(owner);

        vm.expectRevert(Errors.InvalidParameter.selector);

        vm.prank(owner);
        _LensERC721().transferFrom(owner, address(0), tokenId);
    }

    function testCannot_SafeTransferFrom_ToNonERC721Recipient(address owner) public {
        vm.assume(owner != address(0));
        uint256 tokenId = _mintERC721(owner);

        vm.expectRevert(Errors.NonERC721ReceiverImplementer.selector);

        vm.prank(owner);
        _LensERC721().safeTransferFrom(owner, address(new NonERC721Recipient()), tokenId);
    }

    function testCannot_SafeTransferFrom_ToNonERC721Recipient_WithData(address owner) public {
        vm.assume(owner != address(0));
        uint256 tokenId = _mintERC721(owner);

        vm.expectRevert(Errors.NonERC721ReceiverImplementer.selector);

        vm.prank(owner);
        _LensERC721().safeTransferFrom(owner, address(new NonERC721Recipient()), tokenId, 'testing 123');
    }

    function testCannot_SafeTransferFrom_ToRevertingERC721Recipient(address owner) public {
        vm.assume(owner != address(0));
        uint256 tokenId = _mintERC721(owner);

        vm.expectRevert(IERC721Receiver.onERC721Received.selector);

        vm.prank(owner);
        _LensERC721().safeTransferFrom(owner, address(new RevertingERC721Recipient()), tokenId);
    }

    function testCannot_SafeTransferFrom_ToRevertingERC721Recipient_WithData(address owner) public {
        vm.assume(owner != address(0));
        uint256 tokenId = _mintERC721(owner);

        vm.expectRevert(IERC721Receiver.onERC721Received.selector);

        vm.prank(owner);
        _LensERC721().safeTransferFrom(owner, address(new RevertingERC721Recipient()), tokenId, 'testing 123');
    }

    function testCannot_SafeTransferFrom_ToERC721Recipient_WithWrongReturnData(address owner) public {
        vm.assume(owner != address(0));
        uint256 tokenId = _mintERC721(owner);

        vm.expectRevert(Errors.NonERC721ReceiverImplementer.selector);

        vm.prank(owner);
        _LensERC721().safeTransferFrom(owner, address(new WrongReturnDataERC721Recipient()), tokenId);
    }

    function testCannot_SafeTransferFrom_ToERC721Recipient_WithWrongReturnData_WithData(address owner) public {
        vm.assume(owner != address(0));
        uint256 tokenId = _mintERC721(owner);

        vm.expectRevert(Errors.NonERC721ReceiverImplementer.selector);

        vm.prank(owner);
        _LensERC721().safeTransferFrom(owner, address(new WrongReturnDataERC721Recipient()), tokenId, 'testing 123');
    }

    function testCannot_BalanceOfZeroAddress() public {
        vm.expectRevert(Errors.InvalidParameter.selector);
        _LensERC721().balanceOf(address(0));
    }

    function testCannot_OwnerOfUnminted(uint256 tokenId) public {
        vm.assume(_LensERC721().exists(tokenId) == false);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        _LensERC721().ownerOf(tokenId);
    }

    //////////////////////

    function testSupportsExpectedInterfaces() public {
        assertTrue(_LensERC721().supportsInterface(type(IERC165).interfaceId));
        assertTrue(_LensERC721().supportsInterface(type(IERC721).interfaceId));
        assertTrue(_LensERC721().supportsInterface(type(IERC721Timestamped).interfaceId));
        assertTrue(_LensERC721().supportsInterface(type(IERC721Burnable).interfaceId));
        assertTrue(_LensERC721().supportsInterface(type(IERC721MetaTx).interfaceId));
        assertTrue(_LensERC721().supportsInterface(type(IERC721Metadata).interfaceId));
    }

    function testDoesNotSupportOtherThanTheExpectedInterfaces(uint32 interfaceId) public virtual {
        vm.assume(bytes4(interfaceId) != type(IERC165).interfaceId);
        vm.assume(bytes4(interfaceId) != type(IERC721).interfaceId);
        vm.assume(bytes4(interfaceId) != type(IERC721Timestamped).interfaceId);
        vm.assume(bytes4(interfaceId) != type(IERC721Burnable).interfaceId);
        vm.assume(bytes4(interfaceId) != type(IERC721MetaTx).interfaceId);
        vm.assume(bytes4(interfaceId) != type(IERC721Metadata).interfaceId);

        assertFalse(_LensERC721().supportsInterface(bytes4(interfaceId)));
    }

    // getDomainSeparator
    // which is different if the address calling is lensHub or not

    function testCannot_getBalanceOfAddressZero() public {
        vm.expectRevert(Errors.InvalidParameter.selector);
        _LensERC721().balanceOf(address(0));
    }

    // mintTimestampOf(uint256 tokenId)
    function testMintTimestampIsTheExpectedOne(uint32 blockTimestamp, address nftRecipient) public {
        vm.assume(nftRecipient != address(0));
        vm.assume(blockTimestamp > 0);
        vm.warp(blockTimestamp);

        uint256 tokenId = _mintERC721(nftRecipient);

        assertEq(_LensERC721().mintTimestampOf(tokenId), blockTimestamp);
    }

    function testCannotGetMintTimestampOf_UnexistentToken(uint256 unexistentTokenId) public {
        vm.assume(!_LensERC721().exists(unexistentTokenId));

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        _LensERC721().mintTimestampOf(unexistentTokenId);
    }

    function testCannot_GetTokenDataOf_NonexistingToken(uint256 tokenId) public {
        vm.assume(!_LensERC721().exists(tokenId));

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        _LensERC721().tokenDataOf(tokenId);
    }

    function testTotalSupply(address to) public {
        vm.assume(to != address(0));
        uint256 currentTotalSupply = _LensERC721().totalSupply();

        uint256 tokenId = _mintERC721(to);
        uint256 totalSupplyAfterMint = _LensERC721().totalSupply();
        assertEq(totalSupplyAfterMint, currentTotalSupply + 1);

        vm.prank(to);
        _burnERC721(tokenId);

        uint256 totalSupplyAfterBurn = _LensERC721().totalSupply();
        assertEq(totalSupplyAfterBurn, totalSupplyAfterMint - 1);
    }

    // approve
    // - to owner reverts Errors.InvalidParameter();
    // - not owner or approvedforall reverts Errors.NotOwnerOrApproved();

    // getApprove
    // - reverts if token doesn't exist

    // setApprovalForAll (reverts if given to msg.sender)

    // transferFrom fails for not approved or not owner
    // safeTransferFrom fails for not approved or not owner

    // _checkOnERC721Received fails with Errors.NonERC721ReceiverImplementer();

    // transfers fail if not owner or to zero address

    // sending to a contract with IERC721Receiver isn't tested
}
