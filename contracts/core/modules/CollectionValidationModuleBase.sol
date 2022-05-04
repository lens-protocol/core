// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {IFollowModule} from '../../interfaces/IFollowModule.sol';
import {ILensHub} from '../../interfaces/ILensHub.sol';
import {Errors} from '../../libraries/Errors.sol';
import {Events} from '../../libraries/Events.sol';
import {ModuleBase} from './ModuleBase.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

abstract contract CollectionValidationModuleBase is ModuleBase {

    function _checkCollectionValidity(address user, address collection) returns(bool){
        bool isErc721 = IERC721(collection).supportsInterface(type(IERC721).interfaceId);
        if(!isErc721){
            revert Errors.NotCollection();
        }
        if( IERC721(collection).balanceOf(user) == 0){
            revert Errors.NotCollectionOwner();
        }
    }
}