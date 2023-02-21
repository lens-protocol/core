// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '../../../contracts/libraries/DataTypes.sol';

contract SigSetup {
    uint256 nonce;
    uint256 deadline;

    function setUp() public virtual {
        nonce = 0;
        deadline = type(uint256).max;
    }
}
