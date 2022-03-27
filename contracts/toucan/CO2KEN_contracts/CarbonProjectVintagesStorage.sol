// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth

// Storage contract for CarbonProjects
pragma solidity >=0.8.4 <0.9.0;

import './CarbonProjectVintageTypes.sol';

/// @dev Separate storage contract to improve upgrade safety
contract CarbonProjectVintagesStorage {
    uint128 public projectVintageTokenCounter;
    uint128 public totalSupply;
    address public contractRegistry;
    string public baseURI;

    mapping(uint256 => VintageData) public vintageData;

    /// @dev mapping to identify invalid projectVintageIds
    /// Examples: projectVintageIds that have been removed or non-existent ones
    mapping(uint256 => bool) public validProjectVintageIds;

    /// @dev Maps: projectTokenId => vintage startTime => projectVintageTokenId
    ///
    /// This is the rough reverse of VintageData.projectTokenId, i.e. it's the
    /// way that a caller with a projectTokenId and a vintage startTime can
    /// obtain the corresponding projectVintageTokenId.  This is particularly
    /// important during the batch NFT approval phase, since prior to
    /// confirmation, there is no direct association between the batch and the
    /// project/vintage; only a long serial number containing info which allows
    /// that association.
    mapping(uint256 => mapping(uint64 => uint256)) public pvToTokenId;

    /// @dev All roles related to Access Control
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
}
