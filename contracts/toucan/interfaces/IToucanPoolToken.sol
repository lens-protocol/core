// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IToucanPoolToken is IERC20Upgradeable {
    function version() external pure returns (string memory);

    function deposit(address erc20Addr, uint256 amount) external;

    function checkEligible(address erc20Addr) external view returns (bool);

    function checkAttributeMatching(address erc20Addr)
        external
        view
        returns (bool);

    function calculateRedeemFees(
        address[] memory tco2s,
        uint256[] memory amounts
    ) external view returns (uint256);

    function redeemMany(address[] memory tco2s, uint256[] memory amounts)
        external;

    function redeemAuto(uint256 amount) external;

    function redeemAuto2(uint256 amount)
        external
        returns (address[] memory tco2s, uint256[] memory amounts);

    function getRemaining() external view returns (uint256);

    function getScoredTCO2s() external view returns (address[] memory);
}
