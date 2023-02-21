// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {Errors} from '../../../libraries/constants/Errors.sol';
import {ModuleBase} from '../ModuleBase.sol';
import {FollowValidatorFollowModuleBase} from './FollowValidatorFollowModuleBase.sol';

/**
 * @title RevertFollowModule
 * @author Lens Protocol
 *
 * @notice This follow module rejects all follow attempts.
 */
contract RevertFollowModule is FollowValidatorFollowModuleBase {
    constructor(address hub) ModuleBase(hub) {}

    /**
     * @notice This follow module always reverts.
     *
     * @return bytes Empty bytes.
     */
    function initializeFollowModule(
        uint256,
        address,
        bytes calldata
    ) external view override onlyHub returns (bytes memory) {
        return new bytes(0);
    }

    /**
     * @dev Processes a follow by rejecting it and reverting the transaction.
     */
    function processFollow(
        uint256,
        address,
        address,
        uint256,
        bytes calldata
    ) external view override onlyHub {
        revert Errors.FollowInvalid();
    }

    /**
     * @dev We don't need to execute any additional logic on transfers in this follow module.
     */
    function followModuleTransferHook(
        uint256 profileId,
        address from,
        address to,
        uint256 followNFTTokenId
    ) external override {}
}
