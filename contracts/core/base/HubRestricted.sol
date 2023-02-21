// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {Errors} from '../../libraries/constants/Errors.sol';
import {Events} from '../../libraries/constants/Events.sol';

/**
 * @title HubRestricted
 * @author Lens Protocol
 *
 * @notice This abstract contract adds a public `HUB` immutable field, validations when setting it, as well
 * as an `onlyHub` modifier, to inherit from contracts that have functions restricted to be only called by the Lens hub.
 */
abstract contract HubRestricted {
    address public immutable HUB;

    modifier onlyHub() {
        if (msg.sender != HUB) {
            revert Errors.NotHub();
        }
        _;
    }

    constructor(address hub) {
        if (hub == address(0)) {
            revert Errors.InitParamsInvalid();
        }
        HUB = hub;
    }
}
