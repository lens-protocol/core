// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ICollectModule} from 'contracts/interfaces/ICollectModule.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {MockModule} from 'test/mocks/MockModule.sol';

/**
 * @title FreeCollectModule
 * @author Lens Protocol
 *
 * @notice This is a simple Lens CollectModule implementation, inheriting from the ICollectModule interface.
 *
 * This module works by allowing all collects.
 */
contract MockCollectModule is MockModule, ICollectModule {
    function testMockCollectModule() public {
        // Prevents being counted in Foundry Coverage
    }

    /**
     * @dev There is nothing needed at initialization.
     */
    function initializePublicationCollectModule(
        uint256,
        uint256,
        address,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        return _decodeFlagAndRevertIfFalse(data);
    }

    /**
     * @dev Processes a collect by:
     *  1. Ensuring the collector is a follower, if needed
     */
    function processCollect(
        Types.ProcessCollectParams calldata processCollectParams
    ) external pure override returns (bytes memory) {
        return _decodeFlagAndRevertIfFalse(processCollectParams.data);
    }
}
