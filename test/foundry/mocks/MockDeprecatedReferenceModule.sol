// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILegacyReferenceModule} from 'contracts/interfaces/ILegacyReferenceModule.sol';

/**
 * @dev This is a simple mock follow module to be used for testing.
 */
contract MockDeprecatedReferenceModule is ILegacyReferenceModule {
    function testMockDeprecatedReferenceModule() public {
        // Prevents being counted in Foundry Coverage
    }

    function initializeReferenceModule(
        uint256,
        uint256,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        uint256 number = abi.decode(data, (uint256));
        require(number == 1, 'MockDeprecatedReferenceModule: invalid');
        return new bytes(0);
    }

    function processComment(
        uint256 profileId,
        uint256 pointedProfileId,
        uint256 pointedPubId,
        bytes calldata data
    ) external override {}

    function processMirror(
        uint256 profileId,
        uint256 pointedProfileId,
        uint256 pointedPubId,
        bytes calldata data
    ) external override {}
}
