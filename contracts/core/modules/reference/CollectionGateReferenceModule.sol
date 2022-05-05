// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {IReferenceModule} from '../../../interfaces/IReferenceModule.sol';
import {Errors} from '../../../libraries/Errors.sol';
import {ModuleBase} from '../ModuleBase.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

/**
 * @title CollectionGatedReferenceModule
 * @author Lens Protocol/Sébastien Bellanger (Share CEO)
 *
 * @notice A simple reference module that validates that comments or mirrors originate is the owner of a given collection.
 */
contract CollectionGatedReferenceModule is ModuleBase, IReferenceModule {
    using EnumerableSet for EnumerableSet.UintSet;

    struct ProfileData {
        address collection;
        EnumerableSet.UintSet tokenIdSet;
    }

    mapping(uint256 => ProfileData) internal _dataByProfile;

    constructor(address hub) ModuleBase(hub) {}

    /**
     * @dev There is nothing needed at initialization.
     */
    function initializeReferenceModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external override returns (bytes memory) {
        // decode
        (address collection, uint256[] memory tokenIdSet) = abi.decode(data, (address, uint256[]));
        if (collection == address(0)) revert Errors.InitParamsInvalid();
        ProfileData storage profileData = _dataByProfile[profileId];
        profileData.collection = collection;

        if (tokenIdSet.length > 0) {
            for (uint256 i = 0; i < tokenIdSet.length; ++i) {
                profileData.tokenIdSet.add(tokenIdSet[i]);
            }
        }
        return new bytes(0);
    }

    /**
     * @notice Validates that the commenting profile's owner is a collection owner.
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
        _checkCollectionValidity(
            commentCreator,
            _dataByProfile[profileId].collection,
            _dataByProfile[profileId].tokenIdSet
        );
    }

    /**
     * @notice Validates that the commenting profile's owner is a collection owner.
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

        _checkCollectionValidity(
            mirrorCreator,
            _dataByProfile[profileId].collection,
            _dataByProfile[profileId].tokenIdSet
        );
    }

    function _checkCollectionValidity(
        address user,
        address collection,
        EnumerableSet.UintSet storage tokenIdSet
    ) internal view{
        bool isErc721 = IERC721(collection).supportsInterface(type(IERC721).interfaceId);
        if (!isErc721) {
            if (!IERC1155(collection).supportsInterface(type(IERC1155).interfaceId))
                revert Errors.InvalidCollection();
            else {
                uint256 totalBalance = 0;
                for (uint256 i = 0; i < tokenIdSet.length(); i++) {
                    totalBalance += IERC1155(collection).balanceOf(user, tokenIdSet.at(i));
                }
                if (totalBalance == 0) revert Errors.NotCollectionOwner();
            }
        } else {
            if (IERC721(collection).balanceOf(user) == 0) {
                revert Errors.NotCollectionOwner();
            }
        }
    }
}
