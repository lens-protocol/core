// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Errors} from './constants/Errors.sol';

/**
 * @title ActionRestricted
 * @author Lens Protocol
 *
 * @notice This abstract contract adds a public `ACTION_MODULE` immutable field, and `onlyActionModule` modifier,
 * to inherit from contracts that have functions restricted to be only called by the Action Modules.
 */
abstract contract ActionRestricted {
    address public immutable ACTION_MODULE;

    modifier onlyActionModule() {
        if (msg.sender != ACTION_MODULE) {
            revert Errors.NotActionModule();
        }
        _;
    }

    constructor(address actionModule) {
        ACTION_MODULE = actionModule;
    }
}
