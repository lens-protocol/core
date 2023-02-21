// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ICollectModule} from 'contracts/interfaces/ICollectModule.sol';
import {ModuleBase} from 'contracts/core/modules/ModuleBase.sol';
import {FollowValidationModuleBase} from 'contracts/core/modules/FollowValidationModuleBase.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title FreeCollectModule
 * @author Lens Protocol
 *
 * @notice This is a simple Lens CollectModule implementation, inheriting from the ICollectModule interface.
 *
 * This module works by allowing all collects.
 */
contract FreeCollectModule is FollowValidationModuleBase, ICollectModule {
    constructor(address hub) ModuleBase(hub) {}

    mapping(uint256 => mapping(uint256 => bool)) internal _followerOnlyByPublicationByProfile;

    /**
     * @dev There is nothing needed at initialization.
     */
    function initializePublicationCollectModule(
        uint256 profileId,
        uint256 pubId,
        address,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        bool followerOnly = abi.decode(data, (bool));
        if (followerOnly) _followerOnlyByPublicationByProfile[profileId][pubId] = true;
        return data;
    }

    /**
     * @dev Processes a collect by:
     *  1. Ensuring the collector is a follower, if needed
     */
    function processCollect(
        uint256 publicationCollectedProfileId,
        uint256 publicationCollectedId,
        uint256,
        address collectorProfileOwner,
        address,
        uint256,
        uint256,
        Types.PublicationType,
        bytes calldata
    ) external view override {
        if (_followerOnlyByPublicationByProfile[publicationCollectedProfileId][publicationCollectedId])
            _checkFollowValidity(publicationCollectedProfileId, collectorProfileOwner);
    }
}
