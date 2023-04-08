// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract ImmutableOwnable {
    address immutable OWNER;
    address immutable LENS_HUB;

    error OnlyOwner();
    error OnlyOwnerOrHub();

    modifier onlyOwner() {
        if (msg.sender != OWNER) {
            revert OnlyOwner();
        }
        _;
    }

    modifier onlyOwnerOrHub() {
        if (msg.sender != OWNER && msg.sender != LENS_HUB) {
            revert OnlyOwnerOrHub();
        }
        _;
    }

    constructor(address owner, address lensHub) {
        OWNER = owner;
        LENS_HUB = lensHub;
    }
}
