// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWMATIC is IERC20 {
    function withdraw(uint256 amountToUnwrap) external;

    function deposit() external payable;
}
