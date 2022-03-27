// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';

import './IToucanContractRegistry.sol';
import './CarbonProjects.sol';

contract CarbonOffsetBadgesStorage {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Data {
        uint256 projectVintageTokenId;
        uint256 retiredAmount;
        string tokenURI;
    }

    string public baseURI;
    address public contractRegistry;
    CountersUpgradeable.Counter internal _tokenIds;

    mapping(uint256 => Data) public badges;
    mapping(bytes32 => bool) internal hashes;
}
