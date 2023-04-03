// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';

/**
 * @title FollowValidationLib
 * @author Lens Protocol
 *
 * @notice A library contract that verifies that a user is following another user and reverts if not.
 */
library FollowValidationLib {
    function validateIsFollowing(ILensHub hub, uint256 followerProfileId, uint256 followedProfileId) internal view {
        if (!hub.isFollowing(followerProfileId, followedProfileId)) {
            revert Errors.NotFollowing();
        }
    }
}
