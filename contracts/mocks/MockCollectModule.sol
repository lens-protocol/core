// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ICollectModule} from 'contracts/interfaces/ICollectModule.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

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
        uint256,
        address,
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
        uint256 publicationCollectedProfileId,
        uint256 publicationCollectedId,
        uint256 collectorProfileId,
        address collectorProfileOwner,
        address executor,
        uint256 referrerProfileId,
        uint256 referrerPubId,
        Types.PublicationType referrerPubType,
        bytes calldata data
    ) external view override {}
}
