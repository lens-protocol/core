// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {HubRestricted} from 'contracts/core/base/HubRestricted.sol';

/**
 * @title ModuleBase
 * @author Lens Protocol
 *
 * @notice This contract fires an event at construction, to be inherited by other modules, in addition to the
 * HubRestricted contract features.
 */
abstract contract ModuleBase is HubRestricted {
    constructor(address hub) HubRestricted(hub) {
        emit Events.ModuleBaseConstructed(hub, block.timestamp);
    }
}
