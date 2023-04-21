// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract NFT is ERC721('NFT', 'NFT') {
    function mint(address to, uint256 nftId) external {
        _mint(to, nftId);
    }
}
