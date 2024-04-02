// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {PermissionlessCreator} from 'contracts/misc/PermissionlessCreator.sol';

contract FreeCreditsProvider {
    PermissionlessCreator permissionlessCreator;

    constructor(address permissionlessCreator_) {
        permissionlessCreator = PermissionlessCreator(permissionlessCreator_);
    }

    function getFreeCredit(address user, uint256 amount) external {
        return permissionlessCreator.increaseCredits(user, amount);
    }

    function burnCredits(uint256 amount) external {
        return permissionlessCreator.decreaseCredits(msg.sender, amount);
    }
}
