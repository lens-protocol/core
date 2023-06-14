// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract MockNonERC721Recipient {
    function testMockNonERC721Recipient() public {
        // Prevents being counted in Foundry Coverage
    }

    // This contract should never have an onERC721Received function
}
