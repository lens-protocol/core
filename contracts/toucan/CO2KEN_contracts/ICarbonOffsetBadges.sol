// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

interface ICarbonOffsetBadges {
    function mintBadge(
        address to,
        uint256 projectVintageTokenId,
        uint256 amount
    ) external;
}
