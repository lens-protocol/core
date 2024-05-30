// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/**
 * @dev A simple mock currency to be used for testnet mocks.
 */
contract MockCurrency is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
