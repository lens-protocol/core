// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';

/**
 * @title MockProfileCreationProxy
 * @author Lens Protocol
 *
 * @notice This is a proxy contract that enforces ".test" handle suffixes and adds char validations at profile creation.
 */
contract MockProfileCreationProxy {
    ILensHub immutable LENS_HUB;

    constructor(ILensHub hub) {
        LENS_HUB = hub;
    }

    function proxyCreateProfile(Types.CreateProfileParams memory createProfileParams) external {
        LENS_HUB.createProfile(createProfileParams);
    }
}
