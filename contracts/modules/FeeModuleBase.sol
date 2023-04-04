// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Errors} from 'contracts/modules/constants/Errors.sol';
import {IModuleGlobals} from 'contracts/interfaces/IModuleGlobals.sol';

/**
 * @title FeeModuleBase
 * @author Lens Protocol
 *
 * @notice This is an abstract contract to be inherited from by modules that require basic fee functionality.
 * It contains getters for module globals parameters as well as a validation function to check expected data.
 */
abstract contract FeeModuleBase {
    uint16 internal constant BPS_MAX = 10000;

    IModuleGlobals public immutable MODULE_GLOBALS;

    constructor(address moduleGlobals) {
        MODULE_GLOBALS = IModuleGlobals(moduleGlobals);
    }

    function _currencyWhitelisted(address currency) internal view returns (bool) {
        return MODULE_GLOBALS.isCurrencyWhitelisted(currency);
    }

    function _treasuryData() internal view returns (address, uint16) {
        return MODULE_GLOBALS.getTreasuryData();
    }

    function _validateDataIsExpected(bytes calldata data, address currency, uint256 amount) internal pure {
        (address decodedCurrency, uint256 decodedAmount) = abi.decode(data, (address, uint256));
        if (decodedAmount != amount || decodedCurrency != currency) {
            revert Errors.ModuleDataMismatch();
        }
    }
}
