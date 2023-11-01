// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {LensModuleMetadata} from 'contracts/modules/LensModuleMetadata.sol';

abstract contract MockModule is LensModuleMetadata {
    error MockModuleReverted();

    function testMockModule() public {
        // Prevents being counted in Foundry Coverage
    }

    constructor(address moduleOwner) LensModuleMetadata(moduleOwner) {}

    // Reverts if the flag decoded from the data is not `true`.
    function _decodeFlagAndRevertIfFalse(bytes memory data) internal pure returns (bytes memory) {
        bool shouldItSucceed = abi.decode(data, (bool));
        if (!shouldItSucceed) {
            revert MockModuleReverted();
        }
        return data;
    }
}
