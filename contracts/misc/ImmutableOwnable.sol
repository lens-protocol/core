// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract ImmutableOwnable {
    address immutable OWNER;
    address immutable LENS_HUB;

    error OnlyOwner();
    error OnlyOwnerOrHub();

    // TODO: Should we rename this to ADMIN? Cause Owner is usually Profile Owner
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
