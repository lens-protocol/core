// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'contracts/libraries/constants/Types.sol';

contract SigSetup {
    function testSigSetup() public {
        // Prevents being counted in Foundry Coverage
    }

    uint256 nonce;
    uint256 deadline;

    function setUp() public virtual {
        nonce = 0;
        deadline = type(uint256).max;
    }
}
