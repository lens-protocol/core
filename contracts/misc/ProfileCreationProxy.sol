// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ILensHub} from '../interfaces/ILensHub.sol';
import {DataTypes} from '../libraries/constants/DataTypes.sol';
import {Errors} from '../libraries/constants/Errors.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title ProfileCreationProxy
 * @author Lens Protocol
 *
 * @notice This is an ownable proxy contract that enforces ".lens" handle suffixes at profile creation.
 * Only the owner can create profiles.
 */
contract ProfileCreationProxy is Ownable {
    ILensHub immutable LENS_HUB;

    constructor(address owner, ILensHub hub) {
        _transferOwnership(owner);
        LENS_HUB = hub;
    }

    function proxyCreateProfile(DataTypes.CreateProfileData memory vars) external onlyOwner {
        LENS_HUB.createProfile(vars);
    }
}
