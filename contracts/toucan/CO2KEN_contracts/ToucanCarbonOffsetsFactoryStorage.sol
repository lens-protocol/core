// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth

pragma solidity >=0.8.4 <0.9.0;

/// @dev Storage contract for ToucanCarbonOffsetsFactory (UUPS proxy upgradable)
contract ToucanCarbonOffsetsFactoryStorage {
    address public contractRegistry;
    address[] public deployedContracts;
    mapping(uint256 => address) public pvIdtoERC20;
}
