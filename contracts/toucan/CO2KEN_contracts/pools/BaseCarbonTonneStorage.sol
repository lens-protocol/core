// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

/// @dev Storage for UUPS Proxy upgradable BaseCarbonTonne
abstract contract BaseCarbonTonneStorageV1 {
    uint256 public supplyCap;
    mapping(address => uint256) public tokenBalances;
    address public contractRegistry;

    uint64 public minimumVintageStartTime;

    /// @dev Mappings for attributes that can be included or excluded
    /// if set to `false`, attribute-values are blacklisted/rejected
    /// if set to `true`, attribute-values are whitelisted/accepted
    bool public regionsIsAcceptedMapping;
    mapping(string => bool) public regions;

    bool public standardsIsAcceptedMapping;
    mapping(string => bool) public standards;

    bool public methodologiesIsAcceptedMapping;
    mapping(string => bool) public methodologies;

    /// @dev mapping to whitelist external non-TCO2 contracts by address
    mapping(address => bool) public externalWhiteList;

    /// @dev mapping to include certain TCO2 contracts by address,
    /// overriding attribute matching checks
    mapping(address => bool) public internalWhiteList;

    /// @dev mapping to exclude certain TCO2 contracts by address,
    /// even if the attribute matching would pass
    mapping(address => bool) public internalBlackList;
}

abstract contract BaseCarbonTonneStorageV1_1 {
    /// @dev fees redeem receiver address
    address public feeRedeemReceiver;

    uint256 public feeRedeemPercentageInBase;

    /// @dev fees redeem burn address
    address public feeRedeemBurnAddress;

    /// @dev fees redeem burn percentage with 2 fixed decimals precision
    uint256 public feeRedeemBurnPercentageInBase;
}

abstract contract BaseCarbonTonneStorageV1_2 {
    mapping(address => bool) public redeemFeeExemptedAddresses;

    /// @notice array used to read from when redeeming TCO2s automatically
    address[] public scoredTCO2s;
}

abstract contract BaseCarbonTonneStorage is
    BaseCarbonTonneStorageV1,
    BaseCarbonTonneStorageV1_1,
    BaseCarbonTonneStorageV1_2
{}
