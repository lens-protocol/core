// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth

// Storage contract for CarbonProjects
pragma solidity >=0.8.4 <0.9.0;

import './CarbonProjectTypes.sol';

/// @dev Separate storage contract to improve upgrade safety
contract CarbonProjectsStorage {
    uint128 public projectTokenCounter;
    uint128 public totalSupply;
    address public contractRegistry;
    string public baseURI;

    /// @dev maps `tokenId` to `ProjectData` struct
    mapping(uint256 => ProjectData) public projectData;

    /// @dev uniqueness check for globalUniqueIdentifier strings
    /// Example: `'VCS-01468' -> true`
    /// Todo: assess if can be deprecated
    mapping(string => bool) public projectIds;

    /// @dev mapping to identify invalid projectTokenIds
    /// Examples: projectokenIds that have been removed or non-existent ones
    mapping(uint256 => bool) public validProjectTokenIds;

    /// @dev Maps a universal/global project-id like 'VCS-1234' to its `tokenId`
    mapping(string => uint256) public pidToTokenId;

    /// @dev All roles related to Access Control
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
}
