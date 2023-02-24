// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IDeprecatedReferenceModule} from 'contracts/interfaces/IDeprecatedReferenceModule.sol';
import {ModuleBase} from 'contracts/core/modules/ModuleBase.sol';
import {FollowValidationModuleBase} from 'contracts/core/modules/FollowValidationModuleBase.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @title FollowerOnlyReferenceModule
 * @author Lens Protocol
 *
 * @notice A simple reference module that validates that comments or mirrors originate from a profile owned
 * by a follower.
 */
contract DeprecatedFollowerOnlyReferenceModule is FollowValidationModuleBase, IDeprecatedReferenceModule {
    constructor(address hub) ModuleBase(hub) {}

    /**
     * @dev There is nothing needed at initialization.
     */
    function initializeReferenceModule(
        uint256,
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
        uint256 pointedProfileId,
        uint256,
        bytes calldata
    ) external view override {
        address commentCreator = IERC721(HUB).ownerOf(profileId);
        _checkFollowValidity(pointedProfileId, commentCreator);
    }

    /**
     * @notice Validates that the mirroring profile's owner is a follower.
     *
     * NOTE: We don't need to care what the pointed publication is in this context.
     */
    function processMirror(
        uint256 profileId,
        uint256 pointedProfileId,
        uint256,
        bytes calldata
    ) external view override {
        address mirrorCreator = IERC721(HUB).ownerOf(profileId);
        _checkFollowValidity(pointedProfileId, mirrorCreator);
    }
}
