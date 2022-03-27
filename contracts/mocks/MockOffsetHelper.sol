//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract MockOffsetHelper {
    using SafeERC20 for IERC20;

    mapping(string => address) public eligibleTokenAddresses;

    constructor(string[] memory _eligibleTokenSymbols, address[] memory _eligibleTokenAddresses) {
        uint256 i = 0;
        uint256 eligibleTokenSymbolsLen = _eligibleTokenSymbols.length;
        while (i < eligibleTokenSymbolsLen) {
            eligibleTokenAddresses[_eligibleTokenSymbols[i]] = _eligibleTokenAddresses[i];
            i += 1;
        }
    }

    // @description this is the autoOffset method for when the user wants to input tokens like USDC, WETH, WMATIC
    // @param _depositedToken the address of the token that the user sends (could be USDC, WETH, WMATIC)
    // @param _poolToken the pool that the user wants to use (could be NCT or BCT)
    // @param _amountToOffset the amount of TCO2 to offset
    function autoOffset(
        address _depositedToken,
        address _poolToken,
        uint256 _amountToOffset
    ) public {
        IERC20(_depositedToken).safeTransferFrom(msg.sender, address(this), _amountToOffset);
    }

    // @description this is the autoOffset method for when the user already has and wants to input BCT / NCT
    // @param _poolToken the pool token that the user wants to use (could be NCT or BCT)
    // @param _amountToOffset the amount of TCO2 to offset
    function autoOffsetUsingPoolToken(address _poolToken, uint256 _amountToOffset) public {
        IERC20(_poolToken).safeTransferFrom(msg.sender, address(this), _amountToOffset);
    }

    // checks address and returns if can be used at all by the contract
    // @param _erc20Address address of token to be checked
    function isEligible(address _erc20Address) public view returns (bool) {
        if (_erc20Address == eligibleTokenAddresses['BCT']) return true;
        if (_erc20Address == eligibleTokenAddresses['NCT']) return true;
        if (_erc20Address == eligibleTokenAddresses['USDC']) return true;
        if (_erc20Address == eligibleTokenAddresses['WETH']) return true;
        if (_erc20Address == eligibleTokenAddresses['WMATIC']) return true;
        return false;
    }

    // checks address and returns if it can be used in a swap
    // @param _erc20Address address of token to be checked
    function isSwapable(address _erc20Address) public view returns (bool) {
        if (_erc20Address == eligibleTokenAddresses['USDC']) return true;
        if (_erc20Address == eligibleTokenAddresses['WETH']) return true;
        if (_erc20Address == eligibleTokenAddresses['WMATIC']) return true;
        return false;
    }

    // checks address and returns if can it's a pool token and can be redeemed
    // @param _erc20Address address of token to be checked
    function isRedeemable(address _erc20Address) public view returns (bool) {
        if (_erc20Address == eligibleTokenAddresses['BCT']) return true;
        if (_erc20Address == eligibleTokenAddresses['NCT']) return true;
        return false;
    }
}
