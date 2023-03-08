// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {ImmutableOwnable} from 'contracts/misc/ImmutableOwnable.sol';

import {ILensHandles} from 'contracts/interfaces/ILensHandles.sol';
import {ITokenHandleRegistry} from 'contracts/interfaces/ITokenHandleRegistry.sol';

/**
 * @title ModuleWhitelistProxy
 * @author Lens Protocol
 *
 * @notice This is an ownable proxy contract that enforces ".lens" handle suffixes at profile creation.
 * Only the owner can create profiles.
 */
contract ModuleWhitelistProxy is ImmutableOwnable {
    uint256 latestId;

    constructor(address owner, address hub) ImmutableOwnable(owner, hub) {}

    function proxyWhitelistActionModule(address actionModule) external onlyOwner returns (uint256) {
        ++latestId;
        ILensHub(LENS_HUB).whitelistActionModuleId(actionModule, latestId);
        return latestId;
    }
}
