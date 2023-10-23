// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {ERC721Burnable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';

interface IGuardedToken is IERC721 {
    function DANGER__disableTokenGuardian() external;

    function enableTokenGuardian() external;

    function burn(uint256 tokenId) external;
}

contract MockTokenHolderContract is IERC721Receiver {
    // add this to be excluded from coverage report
    function testMockTokenHolderContract() public {}

    address _collection;
    uint256 _tokenId;

    ////////////////////// SETTERS & DEPOSIT FUNCTIONS ////////////

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 tokenId,
        bytes calldata /* data */
    ) public virtual override returns (bytes4) {
        _collection = msg.sender;
        _tokenId = tokenId;
        return IERC721Receiver.onERC721Received.selector;
    }

    function depositNft(address collection, address from, uint256 tokenId) external {
        _collection = collection;
        _tokenId = tokenId;
        IERC721(collection).transferFrom(from, address(this), tokenId);
    }

    function setCollection(address collection) external {
        _collection = collection;
    }

    function getTokenId() external view returns (uint256) {
        return _tokenId;
    }

    ////////////////////// LOCKING MECHANISM FUNCTIONS ////////////

    function executeDisableTokenGuardian() external {
        IGuardedToken(_collection).DANGER__disableTokenGuardian();
    }

    function executeEnableTokenGuardian() external {
        IGuardedToken(_collection).enableTokenGuardian();
    }

    ////////////////////// EIP-721 FUNCTIONS //////////////////////

    function executeSafeTransferFrom(address to) external {
        IGuardedToken(_collection).safeTransferFrom(address(this), to, _tokenId);
    }

    function executeTransferFrom(address to) external {
        IGuardedToken(_collection).transferFrom(address(this), to, _tokenId);
    }

    function executeApprove(address to) external {
        IGuardedToken(_collection).approve(to, _tokenId);
    }

    function executeSetApprovalForAll(address operator, bool approved) external {
        IGuardedToken(_collection).setApprovalForAll(operator, approved);
    }

    function executeBurn() external {
        ERC721Burnable(_collection).burn(_tokenId);
    }
}
