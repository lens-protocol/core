// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.0;

interface IOffsetHelper {
    function autoOffset(
        address _depositedToken,
        address _poolToken,
        uint256 _amountToOffset
    ) external;

    function autoOffsetUsingPoolToken(address _poolToken, uint256 _amountToOffset) external;

    function isSwapable(address _erc20Address) external view returns (bool);

    function isRedeemable(address _erc20Address) external view returns (bool);
}
