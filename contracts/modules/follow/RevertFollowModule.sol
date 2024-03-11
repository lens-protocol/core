// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Errors} from '../constants/Errors.sol';
import {IFollowModule} from '../../interfaces/IFollowModule.sol';

import {LensModuleMetadata} from '../LensModuleMetadata.sol';

/**
 * @title RevertFollowModule
 * @author Lens Protocol
 *
 * @notice This follow module rejects all follow attempts.
 */
contract RevertFollowModule is LensModuleMetadata, IFollowModule {
    constructor(address moduleOwner) LensModuleMetadata(moduleOwner) {}

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == type(IFollowModule).interfaceId || super.supportsInterface(interfaceID);
    }

    /// @inheritdoc IFollowModule
    function initializeFollowModule(
        uint256 /* profileId */,
        address /* transactionExecutor */,
        bytes calldata /* data */
    ) external pure override returns (bytes memory) {
        return '';
    }

    /**
     * @inheritdoc IFollowModule
     * @notice Processes a follow by rejecting it, reverting the transaction. Parameters are ignored.
     */
    function processFollow(
        uint256 /* followerProfileId */,
        uint256 /* followTokenId */,
        address /* transactionExecutor */,
        uint256 /* profileId */,
        bytes calldata /* data */
    ) external pure override returns (bytes memory) {
        revert Errors.FollowInvalid();
    }
}
