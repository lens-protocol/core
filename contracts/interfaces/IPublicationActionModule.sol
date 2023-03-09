// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title IPublicationAction
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible Publication Actions.
 */
interface IPublicationActionModule {
    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address executor,
        bytes calldata data
    ) external returns (bytes memory);

    function processPublicationAction(
        Types.ProcessActionParams calldata processActionParams
    ) external returns (bytes memory);
}
