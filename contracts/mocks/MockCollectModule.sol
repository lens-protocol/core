// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ICollectModule} from '../interfaces/ICollectModule.sol';

/**
 * @title FreeCollectModule
 * @author Lens Protocol
 *
 * @notice This is a simple Lens CollectModule implementation, inheriting from the ICollectModule interface.
 *
 * This module works by allowing all collects.
 */
contract MockCollectModule is ICollectModule {
    /**
     * @dev There is nothing needed at initialization.
     */
    function initializePublicationCollectModule(
        uint256,
        address,
        uint256,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        uint256 number = abi.decode(data, (uint256));
        require(number == 1, 'MockCollectModule: invalid');
        return new bytes(0);
    }

    /**
     * @dev Processes a collect by:
     *  1. Ensuring the collector is a follower, if needed
     */
    function processCollect(
        uint256,
        uint256,
        address collector,
        address,
        uint256 profileId,
        uint256 pubId,
        bytes calldata
    ) external view override {}
}
