// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {IReferenceModule} from '../interfaces/IReferenceModule.sol';

contract MockReferenceModule is IReferenceModule {
    function initializeReferenceModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        uint256 number = abi.decode(data, (uint256));
        require(number == 1, 'MockReferenceModule: invalid');
        return new bytes(0);
    }

    function processComment(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed
    ) external override {}

    function processMirror(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed
    ) external override {}
}
