// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILegacyCollectModule} from 'contracts/interfaces/ILegacyCollectModule.sol';

/**
 * @title FreeCollectModule
 * @author Lens Protocol
 *
 * @notice This is a simple Lens CollectModule implementation, inheriting from the ICollectModule interface.
 *
 * This module works by allowing all collects.
 */
contract MockDeprecatedCollectModule is ILegacyCollectModule {
    function testMockDeprecatedCollectModule() public {
        // Prevents being counted in Foundry Coverage
    }

    /**
     * @dev There is nothing needed at initialization.
     */
    function initializePublicationCollectModule(
        uint256,
        uint256,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        uint256 number = abi.decode(data, (uint256));
        require(number == 1, 'MockReferenceModule: invalid');
        return new bytes(0);
    }

    /**
     * @dev Processes a collect by:
     *  1. Ensuring the collector is a follower, if needed
     */
    function processCollect(
        uint256,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata
    ) external view override {}
}
