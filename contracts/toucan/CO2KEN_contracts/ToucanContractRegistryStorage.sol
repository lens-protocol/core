// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

/// @dev  ToucanContractRegistryStorage is used for separation of data and logic
contract ToucanContractRegistryStorage {
    address internal _carbonOffsetBatchesAddress;
    address internal _carbonProjectsAddress;
    address internal _carbonProjectVintagesAddress;
    address internal _toucanCarbonOffsetsFactoryAddress;
    address internal _carbonOffsetBadgesAddress;

    mapping(address => bool) public projectVintageERC20Registry;

    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
}
