// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IPublicationActionModule} from 'contracts/interfaces/IPublicationActionModule.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @dev This is a simple mock Action module to be used for testing revert cases on processAction.
 */
contract MockActionModule is IPublicationActionModule {
    error MockActionModuleReverted();

    function testMockActionModule() public {
        // Prevents being counted in Foundry Coverage
    }

    // Reverts if `data` does not decode as `true`.
    function initializePublicationAction(
        uint256 /** profileId*/,
        uint256 /** pubId*/,
        address /** transactionExecutor*/,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        return _decodeFlagAndRevertIfFalse(data);
    }

    // Reverts if `processActionParams.actionModuleData` does not decode as `true`.
    function processPublicationAction(
        Types.ProcessActionParams calldata processActionParams
    ) external pure override returns (bytes memory) {
        return _decodeFlagAndRevertIfFalse(processActionParams.actionModuleData);
    }

    // Reverts if the flag decoded from the data is not `true`.
    function _decodeFlagAndRevertIfFalse(bytes memory data) internal pure returns (bytes memory) {
        bool shouldItSucceed = abi.decode(data, (bool));
        if (!shouldItSucceed) {
            revert MockActionModuleReverted();
        }
        return data;
    }
}
