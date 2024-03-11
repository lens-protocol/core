// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Errors} from './constants/Errors.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';
import {IModuleRegistry} from '../interfaces/IModuleRegistry.sol';

/**
 * @title FeeModuleBase
 * @author Lens Protocol
 *
 * @notice This is an abstract contract to be inherited from by modules that require basic fee functionality.
 * It contains getters for module globals parameters as well as a validation function to check expected data.
 */
abstract contract FeeModuleBase {
    uint16 internal constant BPS_MAX = 10000;

    ILensHub private immutable HUB;
    IModuleRegistry public immutable MODULE_REGISTRY;

    constructor(address hub, address moduleRegistry) {
        HUB = ILensHub(hub);
        MODULE_REGISTRY = IModuleRegistry(moduleRegistry);
    }

    function _verifyErc20Currency(address currency) internal {
        if (currency != address(0)) {
            MODULE_REGISTRY.verifyErc20Currency(currency);
        }
    }

    function _treasuryData() internal view returns (address, uint16) {
        return HUB.getTreasuryData();
    }

    function _validateDataIsExpected(bytes calldata data, address currency, uint256 amount) internal pure {
        (address decodedCurrency, uint256 decodedAmount) = abi.decode(data, (address, uint256));
        if (decodedAmount != amount || decodedCurrency != currency) {
            revert Errors.ModuleDataMismatch();
        }
    }
}
