// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library TestEvents {
    // Non-Lens Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Upgraded(address indexed implementation);
    event AdminChanged(address previousAdmin, address newAdmin);
}
