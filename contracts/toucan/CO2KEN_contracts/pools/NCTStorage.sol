// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

/// @dev Storage for the UUPS Proxy upgradable NCT contract
contract NatureCarbonTonneStorage {
    uint256 public supplyCap;
    mapping(address => uint256) public tokenBalances;
    address public contractRegistry;

    /// @dev !! When bringing this change into the BCT contract, keep in mind that this var cannot be in this place as it would render the storage layout incompatible !!
    address[] public scoredTCO2s;

    /// @dev Mappings for attributes that can be included or excluded
    /// if set to `false`, attribute-values are blacklisted/rejected
    /// if set to `true`, attribute-values are whitelisted/accepted
    mapping(string => bool) public regions;
    mapping(string => bool) public standards;
    mapping(string => bool) public methodologies;

    /// @dev mapping to whitelist external non-TCO2 contracts by address
    mapping(address => bool) public externalWhiteList;

    /// @dev mapping to include certain TCO2 contracts by address,
    /// overriding attribute matching checks
    mapping(address => bool) public internalWhiteList;

    /// @dev mapping to exclude certain TCO2 contracts by address,
    /// even if the attribute matching would pass
    mapping(address => bool) public internalBlackList;

    /// @dev fees redeem receiver address
    address public feeRedeemReceiver;

    uint256 public feeRedeemPercentageInBase;

    /// @dev fees redeem burn address
    address public feeRedeemBurnAddress;

    /// @dev fees redeem burn percentage with 2 fixed decimals precision
    uint256 public feeRedeemBurnPercentageInBase;

    /// @dev repacked smaller variables here so new bools can be added below
    uint64 public minimumVintageStartTime;
    bool public seedMode;
    bool public regionsIsAcceptedMapping;
    bool public standardsIsAcceptedMapping;
    bool public methodologiesIsAcceptedMapping;
}
