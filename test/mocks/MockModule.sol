// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {LensModule} from 'contracts/modules/LensModule.sol';

abstract contract MockModule is LensModule {
    error MockModuleReverted();

    function testMockModule() public {
        // Prevents being counted in Foundry Coverage
    }

    // Reverts if the flag decoded from the data is not `true`.
    function _decodeFlagAndRevertIfFalse(bytes memory data) internal pure returns (bytes memory) {
        bool shouldItSucceed = abi.decode(data, (bool));
        if (!shouldItSucceed) {
            revert MockModuleReverted();
        }
        return data;
    }

    function getModuleMetadataURI() external pure override returns (string memory) {
        return 'https://docs.lens.xyz/';
    }
}
