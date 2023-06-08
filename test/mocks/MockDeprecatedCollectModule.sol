// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILegacyCollectModule} from 'contracts/interfaces/ILegacyCollectModule.sol';
import {MockModule} from 'test/mocks/MockModule.sol';

/**
 * @title FreeCollectModule
 * @author Lens Protocol
 *
 * @notice This is a simple Lens CollectModule implementation, inheriting from the ICollectModule interface.
 *
 * This module works by allowing all collects.
 */
contract MockDeprecatedCollectModule is MockModule, ILegacyCollectModule {
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
        _decodeFlagAndRevertIfFalse(data);
        return '';
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
        bytes calldata data
    ) external view override {
        _decodeFlagAndRevertIfFalse(data);
    }
}
