// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IPermissionlessCreator {
    function increaseCredits(address account, uint256 amount) external;

    function decreaseCredits(address account, uint256 amount) external;
}

contract CreditsFaucet {
    IPermissionlessCreator permissionlessCreator;

    constructor(address permissionlessCreator_) {
        permissionlessCreator = IPermissionlessCreator(permissionlessCreator_);
    }

    function getCredits(address account, uint256 amount) external {
        return permissionlessCreator.increaseCredits(account, amount);
    }

    function burnCredits(uint256 amount) external {
        return permissionlessCreator.decreaseCredits(msg.sender, amount);
    }
}
