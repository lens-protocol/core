// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IFollowModule} from 'contracts/interfaces/IFollowModule.sol';

/**
 * @dev This is a simple mock follow module to be used for testing.
 */
contract MockFollowModule is IFollowModule {
    function initializeFollowModule(
        uint256 /* profileId */,
        address /* transactionExecutor */,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        uint256 number = abi.decode(data, (uint256));
        require(number == 1, 'MockFollowModule: invalid');
        return new bytes(0);
    }

    function processFollow(
        uint256 followerProfileId,
        uint256 followTokenId,
        address transactionExecutor,
        uint256 profileId,
        bytes calldata data
    ) external pure override returns (bytes memory) {}
}
