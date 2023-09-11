// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Errors} from 'contracts/modules/constants/Errors.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {IModuleRegistry} from 'contracts/interfaces/IModuleRegistry.sol';

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

    constructor(address hub) {
        HUB = ILensHub(hub);
        MODULE_REGISTRY = IModuleRegistry(ILensHub(hub).getModuleRegistry());
    }

    // TODO: Rename this to _currencyRegistered or smth
    function _currencyWhitelisted(address currency) internal returns (bool) {
        MODULE_REGISTRY.registerErc20Currency(currency);
        return true;
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
