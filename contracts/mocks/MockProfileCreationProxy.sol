// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {ILensHub} from '../interfaces/ILensHub.sol';
import {DataTypes} from '../libraries/DataTypes.sol';

/**
 * @title MockProfileCreationProxy
 * @author Lens Protocol
 *
 * @dev This is a proxy to allow profiles to be created from any address.
 */
contract MockProfileCreationProxy {
    ILensHub immutable LENS_HUB;

    constructor(address hub) {
        LENS_HUB = ILensHub(hub);
    }

    function proxyCreateProfile(DataTypes.CreateProfileData calldata vars) external {
        LENS_HUB.createProfile(vars);
    }
}
