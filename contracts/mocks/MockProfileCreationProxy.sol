// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ILensHub} from '../interfaces/ILensHub.sol';
import {DataTypes} from '../libraries/constants/DataTypes.sol';
import {Errors} from '../libraries/constants/Errors.sol';

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

    function proxyCreateProfile(DataTypes.CreateProfileData memory vars) external {
        LENS_HUB.createProfile(vars);
    }
}
