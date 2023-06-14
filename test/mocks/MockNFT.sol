// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {LensBaseERC721} from 'contracts/base/LensBaseERC721.sol';

contract MockNFT is LensBaseERC721 {
    function testMockNFT() public {
        // Prevents being counted in Foundry Coverage
    }

    function name() public pure override returns (string memory) {
        return 'Mock NFT';
    }

    function symbol() public pure override returns (string memory) {
        return 'NFT';
    }

    function tokenURI(uint256 /* tokenId */) external pure override returns (string memory) {
        return 'https://ipfs.io/ipfs/QmNZiPk974vDsPmQii3YbrMKfi12KTSNM7XMiYyiea4VYZ';
    }

    function mint(address to, uint256 nftId) external {
        _mint(to, nftId);
    }
}
