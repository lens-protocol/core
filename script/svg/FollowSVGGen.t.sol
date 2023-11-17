// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

import {FollowSVG} from 'contracts/libraries/svgs/Follow/FollowSVG.sol';

contract FollowNFT {
    function tryWithTokenId(uint256 tokenId) external pure returns (string memory) {
        return FollowSVG.getFollowSVG(tokenId);
    }
}

contract FollowSVGGen is Test {
    FollowNFT followNFT;
    string constant dir = 'svgs/';

    function setUp() public {
        followNFT = new FollowNFT();
    }

    function testFollowSVGGen() external {
        vm.writeFile(string.concat(dir, 'follows/follow_1_gold.svg'), followNFT.tryWithTokenId(1));
        vm.writeFile(string.concat(dir, 'follows/follow_11_normal.svg'), followNFT.tryWithTokenId(11));
    }
}
