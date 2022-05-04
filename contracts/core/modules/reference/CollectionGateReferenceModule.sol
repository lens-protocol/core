// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {CollectionValidationModuleBase} from '../CollectionValidationModuleBase.sol';
import {IReferenceModule} from '../../../interfaces/IReferenceModule.sol';
import {Errors} from '../../../libraries/Errors.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @title CollectionGatedReferenceModule
 * @author Lens Protocol/Sébastien Bellanger (Share CEO)
 *
 * @notice A simple reference module that validates that comments or mirrors originate is the owner of a given collection.
 */
contract CollectionGatedReferenceModule is CollectionValidationModuleBase,IReferenceModule{
    constructor(address hub) ModuleBase(hub) {}

    /**
     * @dev There is nothing needed at initialization.
     */
    function initializeReferenceModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
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
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes calldata data
    ) external view override {
        address commentCreator = IERC721(HUB).ownerOf(profileId);
        address collection = bytesToAddress(data);
        _checkCollectionValidity(commentCreator,collection);
    }

    /**
     * @notice Validates that the commenting profile's owner is a follower.
     *
     * NOTE: We don't need to care what the pointed publication is in this context.
     */
    function processMirror(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes calldata data
    ) external view override {
        address mirrorCreator = IERC721(HUB).ownerOf(profileId);
        address collection = bytesToAddress(data);

        _checkCollectionValidity(mirrorCreator, collection);
    }

    function bytesToAddress (bytes b) constant returns (address) {
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 16 + (c - 48);
            }
            if(c >= 65 && c<= 90) {
                result = result * 16 + (c - 55);
            }
            if(c >= 97 && c<= 122) {
                result = result * 16 + (c - 87);
            }
        }
        return address(result);
    }
}