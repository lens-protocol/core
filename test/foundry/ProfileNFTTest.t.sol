// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './ERC721Test.t.sol';

contract ProfileNFTTest is BaseTest, ERC721Test {
    function _mintERC721(address to) internal virtual override returns (uint256) {
        return _createProfile(to);
    }

    function _burnERC721(uint256 tokenId) internal virtual override {
        return hub.burn(tokenId);
    }

    function _getERC721TokenAddress() internal view virtual override returns (address) {
        return address(hub);
    }
}
