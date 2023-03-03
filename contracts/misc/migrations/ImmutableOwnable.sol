// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract ImmutableOwnable {
    address immutable OWNER;
    address immutable LENS_HUB;
    address immutable MIGRATOR;

    error OnlyOwner();
    error OnlyOwnerOrHub();
    error OnlyOwnerOrHubOrMigrator();

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

    modifier onlyOwnerOrHubOrMigrator() {
        if (msg.sender != OWNER && msg.sender != LENS_HUB && msg.sender != MIGRATOR) {
            revert OnlyOwnerOrHubOrMigrator();
        }
        _;
    }

    constructor(address owner, address lensHub, address migrator) {
        OWNER = owner;
        LENS_HUB = lensHub;
        MIGRATOR = migrator;
    }
}
