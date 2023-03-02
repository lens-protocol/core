// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IReferenceModule} from 'contracts/interfaces/IReferenceModule.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @dev This is a simple mock follow module to be used for testing.
 */
contract MockReferenceModule is IReferenceModule {
    function initializeReferenceModule(
        uint256,
        address,
        uint256,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        uint256 number = abi.decode(data, (uint256));
        require(number == 1, 'MockReferenceModule: invalid');
        return new bytes(0);
    }

    function processComment(Types.ProcessCommentParams calldata processCommentParams) external override {}

    function processQuote(Types.ProcessQuoteParams calldata processQuoteParams) external override {}

    function processMirror(Types.ProcessMirrorParams calldata processMirrorParams) external override {}
}
