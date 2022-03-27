// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface ICarbonProjectVintages is IERC721Upgradeable {
    function addNewVintage(
        address to,
        uint256 projectTokenId,
        string memory name,
        uint64 startTime,
        uint64 endTime,
        uint64 totalVintageQuantity,
        bool isCorsiaCompliant,
        bool isCCPcompliant,
        string memory coBenefits,
        string memory correspAdjustment,
        string memory additionalCertification,
        string memory uri
    ) external returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);
}
