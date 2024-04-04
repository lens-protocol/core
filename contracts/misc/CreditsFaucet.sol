// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {PermissionlessCreator} from 'contracts/misc/PermissionlessCreator.sol';

contract CreditsFaucet {
    PermissionlessCreator permissionlessCreator;

    constructor(address permissionlessCreator_) {
        permissionlessCreator = PermissionlessCreator(permissionlessCreator_);
    }

    function getCredits(address account, uint256 amount) external {
        return permissionlessCreator.increaseCredits(account, amount);
    }

    function burnCredits(uint256 amount) external {
        return permissionlessCreator.decreaseCredits(msg.sender, amount);
    }
}
