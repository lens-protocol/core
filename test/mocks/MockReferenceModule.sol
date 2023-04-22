// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IReferenceModule} from 'contracts/interfaces/IReferenceModule.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {MockModule} from 'test/mocks/MockModule.sol';

/**
 * @dev This is a simple mock follow module to be used for testing.
 */
contract MockReferenceModule is MockModule, IReferenceModule {
    function testMockReferenceModule() public {
        // Prevents being counted in Foundry Coverage
    }

    function initializeReferenceModule(
        uint256,
        uint256,
        address,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        return _decodeFlagAndRevertIfFalse(data);
    }

    function processComment(
        Types.ProcessCommentParams calldata processCommentParams
    ) external override returns (bytes memory) {
        return _decodeFlagAndRevertIfFalse(processCommentParams.data);
    }

    function processQuote(
        Types.ProcessQuoteParams calldata processQuoteParams
    ) external override returns (bytes memory) {
        return _decodeFlagAndRevertIfFalse(processQuoteParams.data);
    }

    function processMirror(
        Types.ProcessMirrorParams calldata processMirrorParams
    ) external override returns (bytes memory) {
        return _decodeFlagAndRevertIfFalse(processMirrorParams.data);
    }
}
