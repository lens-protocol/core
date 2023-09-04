// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IFollowModule} from 'contracts/interfaces/IFollowModule.sol';
import {Errors} from 'contracts/modules/constants/Errors.sol';
import {FeeModuleBase} from 'contracts/modules/FeeModuleBase.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {HubRestricted} from 'contracts/base/HubRestricted.sol';

/**
 * @notice A struct containing the necessary data to execute follow actions on a given profile.
 *
 * @param currency The currency associated with this profile.
 * @param amount The following cost associated with this profile.
 * @param recipient The recipient address associated with this profile.
 */
struct FeeConfig {
    address currency;
    uint256 amount;
    address recipient;
}

/**
 * @title FeeFollowModule
 * @author Lens Protocol
 *
 * @notice This follow module charges a fee for every follow.
 */
contract FeeFollowModule is FeeModuleBase, HubRestricted, IFollowModule {
    using SafeERC20 for IERC20;

    mapping(uint256 profileId => FeeConfig config) internal _feeConfig;

    constructor(address hub, address moduleGlobals) FeeModuleBase(moduleGlobals) HubRestricted(hub) {}

    /**
     * @inheritdoc IFollowModule
     * @param data The arbitrary data parameter, decoded into:
     *  - address currency: The currency address, must be internally whitelisted.
     *  - uint256 amount: The currency total amount to charge.
     *  - address recipient: The custom recipient address to direct earnings to.
     */
    function initializeFollowModule(
        uint256 profileId,
        address /* transactionExecutor */,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        FeeConfig memory feeConfig = abi.decode(data, (FeeConfig));
        // We allow address(0) to allow burning the currency. But the token has to support transfers to address(0).
        //
        // We don't introduce the upper limit to the amount, even though it might overflow if the amount * treasuryFee
        // during processFollow. But this is a safe behavior, and a case that should never happen, because amounts close
        // to type(uint256).max don't make any sense from the economic standpoint.
        if (feeConfig.amount == 0) {
            if (feeConfig.currency != address(0)) {
                revert Errors.InitParamsInvalid();
            }
        } else {
            if (!_currencyWhitelisted(feeConfig.currency)) {
                revert Errors.InitParamsInvalid();
            }
        }
        _feeConfig[profileId] = feeConfig;
        return data;
    }

    /**
     * @inheritdoc IFollowModule
     * @notice Processes a follow by charging a fee.
     */
    function processFollow(
        uint256 /* followerProfileId */,
        uint256 followTokenId,
        address transactionExecutor,
        uint256 targetProfileId,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        // We charge only when performing a fresh follow.
        if (followTokenId == 0) {
            uint256 amount = _feeConfig[targetProfileId].amount;
            address currency = _feeConfig[targetProfileId].currency;
            _validateDataIsExpected(data, currency, amount);

            (address treasury, uint16 treasuryFee) = _treasuryData();
            address recipient = _feeConfig[targetProfileId].recipient;
            uint256 treasuryAmount = (amount * treasuryFee) / BPS_MAX;
            uint256 adjustedAmount = amount - treasuryAmount;

            IERC20(currency).safeTransferFrom(transactionExecutor, recipient, adjustedAmount);
            if (treasuryAmount > 0) {
                IERC20(currency).safeTransferFrom(transactionExecutor, treasury, treasuryAmount);
            }
        } else {
            // If following with a follow token, we validate the amount is zero.
            (, uint256 decodedAmount) = abi.decode(data, (address, uint256));
            if (decodedAmount != 0) {
                revert Errors.InvalidParams();
            }
        }
        return data;
    }

    /**
     * @notice Returns fee configuration for a given profile.
     *
     * @param profileId The token ID of the profile to query.
     *
     * @return FeeConfig The FeeConfig struct mapped to that profile.
     */
    function getFeeConfig(uint256 profileId) external view returns (FeeConfig memory) {
        return _feeConfig[profileId];
    }
}
