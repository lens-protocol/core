// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {IFollowModule} from '../../interfaces/IFollowModule.sol';
import {ILensHub} from '../../interfaces/ILensHub.sol';
import {Errors} from '../../libraries/Errors.sol';
import {Events} from '../../libraries/Events.sol';
import {ModuleBase} from './ModuleBase.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @title FollowValidationModuleBase
 * @author Lens Protocol
 *
 * @notice This abstract contract adds a simple non-specific follow validation function.
 *
 * NOTE: Both the `HUB` variable and `_checkFollowValidity()` function are exposed to inheriting
 * contracts.
 *
 * NOTE: This is only compatible with COLLECT & REFERENCE MODULES.
 */
abstract contract FollowValidationModuleBase is ModuleBase {
    function _checkFollowValidity(uint256 profileId, address user) internal view {
        address followModule = ILensHub(HUB).getFollowModule(profileId);
        if (followModule != address(0)) {
            IFollowModule(followModule).validateFollow(profileId, user, 0);
        } else {
            address followNFT = ILensHub(HUB).getFollowNFT(profileId);
            if (followNFT == address(0)) revert Errors.FollowInvalid();
            if (IERC721(followNFT).balanceOf(user) == 0) revert Errors.FollowInvalid();
        }
    }
}
