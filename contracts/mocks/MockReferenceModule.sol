// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IReferenceModule} from '../interfaces/IReferenceModule.sol';

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

    function processComment(
        uint256 profileId,
        address executor,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        uint256 referrerProfileId,
        bytes calldata data
    ) external override {}

    function processMirror(
        uint256 profileId,
        address executor,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes calldata data
    ) external override {}
}
