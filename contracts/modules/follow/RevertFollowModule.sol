// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Errors} from 'contracts/modules/constants/Errors.sol';
import {IFollowModule} from 'contracts/interfaces/IFollowModule.sol';

/**
 * @title RevertFollowModule
 * @author Lens Protocol
 *
 * @notice This follow module rejects all follow attempts.
 */
contract RevertFollowModule is IFollowModule {
    /// @inheritdoc IFollowModule
    function initializeFollowModule(
        uint256, /* profileId */
        address, /* transactionExecutor */
        bytes calldata /* data */
    ) external pure override returns (bytes memory) {
        return '';
    }

    /**
     * @inheritdoc IFollowModule
     * @notice Processes a follow by rejecting it, reverting the transaction. Parameters are ignored.
     */
    function processFollow(
        uint256, /* followerProfileId */
        uint256, /* followTokenId */
        address, /* transactionExecutor */
        uint256, /* profileId */
        bytes calldata /* data */
    ) external pure override returns (bytes memory) {
        revert Errors.FollowInvalid();
    }
}
