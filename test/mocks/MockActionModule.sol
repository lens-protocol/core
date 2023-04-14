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

    function initializePublicationAction(
        uint256 /** profileId*/,
        uint256 /** pubId*/,
        address /** transactionExecutor*/,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        return data;
    }

    // In the actionModuleData: Pass "True" for success, "False" for revert
    function processPublicationAction(
        Types.ProcessActionParams calldata processActionParams
    ) external pure override returns (bytes memory) {
        bool shouldItSucceed = abi.decode(processActionParams.actionModuleData, (bool));
        if (!shouldItSucceed) {
            revert MockActionModuleReverted();
        }
        return processActionParams.actionModuleData;
    }
}
