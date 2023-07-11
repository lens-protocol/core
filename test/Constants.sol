// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

uint256 constant ISSECP256K1_CURVE_ORDER = 115792089237316195423570985008687907852837564279074904382605163141518161494337;
bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
bytes32 constant PROXY_IMPLEMENTATION_STORAGE_SLOT = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);

uint256 constant PROFILE_GUARDIAN_COOLDOWN = 7 days;
uint256 constant HANDLE_GUARDIAN_COOLDOWN = 7 days;
