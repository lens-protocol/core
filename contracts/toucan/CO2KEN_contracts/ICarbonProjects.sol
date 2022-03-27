// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface ICarbonProjects is IERC721Upgradeable {
    function getProjectId(uint256 tokenId)
        external
        view
        returns (string memory projectId);

    function addNewProject(
        address to,
        string memory projectId,
        string memory standard,
        string memory methodology,
        string memory region,
        string memory storageMethod,
        string memory method,
        string memory emissionType,
        string memory category,
        string memory metaDataHash
    ) external returns (uint256);

    function isValidProjectTokenId(uint256 tokenId) external returns (bool);
}
