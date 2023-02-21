// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IReferenceModule} from '../../../interfaces/IReferenceModule.sol';
import {ModuleBase} from '../ModuleBase.sol';
import {FollowValidationModuleBase} from '../FollowValidationModuleBase.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {DataTypes} from 'contracts/libraries/DataTypes.sol';

/**
 * @title FollowerOnlyReferenceModule
 * @author Lens Protocol
 *
 * @notice A simple reference module that validates that comments or mirrors originate from a profile owned
 * by a follower.
 */
contract FollowerOnlyReferenceModule is FollowValidationModuleBase, IReferenceModule {
    constructor(address hub) ModuleBase(hub) {}

    /**
     * @dev There is nothing needed at initialization.
     */
    function initializeReferenceModule(
        uint256,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes memory) {
        return new bytes(0);
    }

    /**
     * @notice Validates that the commenting profile's owner is a follower.
     *
     * NOTE: We don't need to care what the pointed publication is in this context.
     */
    function processComment(
        uint256 profileId,
        address,
        uint256 pointedProfileId,
        uint256,
        uint256,
        uint256,
        DataTypes.PublicationType,
        bytes calldata
    ) external view override {
        address commentCreator = IERC721(HUB).ownerOf(profileId);
        _checkFollowValidity(pointedProfileId, commentCreator);
    }

    /**
     * @notice Validates that the quoting profile's owner is a follower.
     *
     * NOTE: We don't need to care what the pointed publication is in this context.
     */
    function processQuote(
        uint256 profileId,
        address,
        uint256 pointedProfileId,
        uint256,
        uint256,
        uint256,
        DataTypes.PublicationType,
        bytes calldata
    ) external view override {
        address quoteCreator = IERC721(HUB).ownerOf(profileId);
        _checkFollowValidity(pointedProfileId, quoteCreator);
    }

    /**
     * @notice Validates that the mirroring profile's owner is a follower.
     *
     * NOTE: We don't need to care what the pointed publication is in this context.
     */
    function processMirror(
        uint256 profileId,
        address,
        uint256 pointedProfileId,
        uint256,
        uint256,
        uint256,
        DataTypes.PublicationType,
        bytes calldata
    ) external view override {
        address mirrorCreator = IERC721(HUB).ownerOf(profileId);
        _checkFollowValidity(pointedProfileId, mirrorCreator);
    }
}
