// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract MockNFT is ERC721('Mock NFT', 'NFT') {
    function testMockNFT() public {
        // Prevents being counted in Foundry Coverage
    }

    function mint(address to, uint256 nftId) external {
        _mint(to, nftId);
    }
}
