// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IPublicationActionModule} from 'contracts/interfaces/IPublicationActionModule.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {MockModule} from 'test/mocks/MockModule.sol';

/**
 * @dev This is a simple mock Action module to be used for testing revert cases on processAction.
 */
contract MockActionModule is MockModule, IPublicationActionModule {
    function testMockActionModule() public {
        // Prevents being counted in Foundry Coverage
    }

    error MockActionModuleReverted();

    constructor(address moduleOwner) MockModule(moduleOwner) {}

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

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == type(IPublicationActionModule).interfaceId || super.supportsInterface(interfaceID);
    }
}
