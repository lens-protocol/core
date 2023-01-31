// SPDX-License-Identifier: AGPL-3.0-only
// File modified from https://github.com/transmissions11/solmate/blob/main/src/test/ERC721.t.sol
pragma solidity 0.8.15;

import 'forge-std/Test.sol';

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract ERC721Recipient is IERC721Receiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        revert(string(abi.encodePacked(IERC721Receiver.onERC721Received.selector)));
    }
}

contract WrongReturnDataERC721Recipient is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient {}

abstract contract ERC721Test is Test {
    function _getERC721TokenAddress() internal view virtual returns (address);

    function _mintERC721(address to) internal virtual returns (uint256);

    function _burnERC721(uint256 tokenId) internal virtual;

    // function _getExpectedName() internal virtual returns (string memory);

    // function _getExpectedSymbol() internal virtual returns (string memory);

    function _getUnexistentTokenId() internal view virtual returns (uint256) {
        return type(uint256).max;
    }

    function _token() internal view virtual returns (IERC721) {
        return IERC721(_getERC721TokenAddress());
    }

    // function invariantMetadata() public {
    //     assertEq(_token().name(), _getExpectedName(''));
    //     assertEq(_token().symbol(), _getExpectedSymbol(''));
    // }

    function testMint() public {
        uint256 tokenId = _mintERC721(address(0xBEEF));

        assertEq(_token().balanceOf(address(0xBEEF)), 1);
        assertEq(_token().ownerOf(tokenId), address(0xBEEF));
    }

    function testBurn() public {
        uint256 tokenId = _mintERC721(address(this));
        assertEq(_token().balanceOf(address(this)), 1);
        _burnERC721(tokenId);
        assertEq(_token().balanceOf(address(this)), 0);

        vm.expectRevert();
        _token().ownerOf(tokenId);
    }

    function testApprove() public {
        uint256 tokenId = _mintERC721(address(this));

        _token().approve(address(0xBEEF), tokenId);

        assertEq(_token().getApproved(tokenId), address(0xBEEF));
    }

    function testApproveAll() public {
        _token().setApprovalForAll(address(0xBEEF), true);

        assertTrue(_token().isApprovedForAll(address(this), address(0xBEEF)));
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        uint256 tokenId = _mintERC721(from);

        vm.prank(from);
        _token().approve(address(this), tokenId);

        _token().transferFrom(from, address(0xBEEF), tokenId);

        assertEq(_token().getApproved(tokenId), address(0));
        assertEq(_token().ownerOf(tokenId), address(0xBEEF));
        assertEq(_token().balanceOf(address(0xBEEF)), 1);
        assertEq(_token().balanceOf(from), 0);
    }

    function testTransferFromSelf() public {
        uint256 tokenId = _mintERC721(address(this));

        _token().transferFrom(address(this), address(0xBEEF), tokenId);

        assertEq(_token().getApproved(tokenId), address(0));
        assertEq(_token().ownerOf(tokenId), address(0xBEEF));
        assertEq(_token().balanceOf(address(0xBEEF)), 1);
        assertEq(_token().balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll() public {
        address from = address(0xABCD);

        uint256 tokenId = _mintERC721(from);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().transferFrom(from, address(0xBEEF), tokenId);

        assertEq(_token().getApproved(tokenId), address(0));
        assertEq(_token().ownerOf(tokenId), address(0xBEEF));
        assertEq(_token().balanceOf(address(0xBEEF)), 1);
        assertEq(_token().balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        uint256 tokenId = _mintERC721(from);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().safeTransferFrom(from, address(0xBEEF), tokenId);

        assertEq(_token().getApproved(tokenId), address(0));
        assertEq(_token().ownerOf(tokenId), address(0xBEEF));
        assertEq(_token().balanceOf(address(0xBEEF)), 1);
        assertEq(_token().balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        uint256 tokenId = _mintERC721(from);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().safeTransferFrom(from, address(recipient), tokenId);

        assertEq(_token().getApproved(tokenId), address(0));
        assertEq(_token().ownerOf(tokenId), address(recipient));
        assertEq(_token().balanceOf(address(recipient)), 1);
        assertEq(_token().balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), tokenId);
        assertEq(recipient.data(), '');
    }

    function testSafeTransferFromToERC721RecipientWithData() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        uint256 tokenId = _mintERC721(from);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().safeTransferFrom(from, address(recipient), tokenId, 'testing 123');

        assertEq(_token().getApproved(tokenId), address(0));
        assertEq(_token().ownerOf(tokenId), address(recipient));
        assertEq(_token().balanceOf(address(recipient)), 1);
        assertEq(_token().balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), tokenId);
        assertEq(recipient.data(), 'testing 123');
    }

    function testFailMintToZero() public {
        _mintERC721(address(0));
    }

    function testFailBurnUnMinted() public {
        _burnERC721(_getUnexistentTokenId());
    }

    function testFailDoubleBurn() public {
        uint256 tokenId = _mintERC721(address(0xBEEF));

        _burnERC721(tokenId);
        _burnERC721(tokenId);
    }

    function testFailApproveUnMinted() public {
        _token().approve(address(0xBEEF), _getUnexistentTokenId());
    }

    function testFailApproveUnAuthorized() public {
        uint256 tokenId = _mintERC721(address(0xCAFE));

        _token().approve(address(0xBEEF), tokenId);
    }

    function testFailTransferFromUnOwned() public {
        _token().transferFrom(address(0xFEED), address(0xBEEF), _getUnexistentTokenId());
    }

    function testFailTransferFromWrongFrom() public {
        uint256 tokenId = _mintERC721(address(0xCAFE));

        _token().transferFrom(address(0xFEED), address(0xBEEF), tokenId);
    }

    function testFailTransferFromToZero() public {
        uint256 tokenId = _mintERC721(address(this));

        _token().transferFrom(address(this), address(0), tokenId);
    }

    function testFailTransferFromNotOwner() public {
        uint256 tokenId = _mintERC721(address(0xFEED));

        _token().transferFrom(address(0xFEED), address(0xBEEF), tokenId);
    }

    function testFailSafeTransferFromToNonERC721Recipient() public {
        uint256 tokenId = _mintERC721(address(this));

        _token().safeTransferFrom(address(this), address(new NonERC721Recipient()), tokenId);
    }

    function testFailSafeTransferFromToNonERC721RecipientWithData() public {
        uint256 tokenId = _mintERC721(address(this));

        _token().safeTransferFrom(
            address(this),
            address(new NonERC721Recipient()),
            tokenId,
            'testing 123'
        );
    }

    function testFailSafeTransferFromToRevertingERC721Recipient() public {
        uint256 tokenId = _mintERC721(address(this));

        _token().safeTransferFrom(address(this), address(new RevertingERC721Recipient()), tokenId);
    }

    function testFailSafeTransferFromToRevertingERC721RecipientWithData() public {
        uint256 tokenId = _mintERC721(address(this));

        _token().safeTransferFrom(
            address(this),
            address(new RevertingERC721Recipient()),
            tokenId,
            'testing 123'
        );
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnData() public {
        uint256 tokenId = _mintERC721(address(this));

        _token().safeTransferFrom(
            address(this),
            address(new WrongReturnDataERC721Recipient()),
            tokenId
        );
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData() public {
        uint256 tokenId = _mintERC721(address(this));

        _token().safeTransferFrom(
            address(this),
            address(new WrongReturnDataERC721Recipient()),
            tokenId,
            'testing 123'
        );
    }

    function testFailBalanceOfZeroAddress() public view {
        _token().balanceOf(address(0));
    }

    function testFailOwnerOfUnminted() public view {
        _token().ownerOf(_getUnexistentTokenId());
    }
}
