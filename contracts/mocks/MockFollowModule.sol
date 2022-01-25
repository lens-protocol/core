// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {IFollowModule} from '../interfaces/IFollowModule.sol';

contract MockFollowModule is IFollowModule {
    function initializeFollowModule(uint256 profileId, bytes calldata data)
        external
        pure
        override
        returns (bytes memory)
    {
        uint256 number = abi.decode(data, (uint256));
        require(number == 1, 'MockFollowModule: invalid');
        return new bytes(0);
    }

    function processFollow(
        address follower,
        uint256 profileId,
        bytes calldata data
    ) external override {}

    function validateFollow(
        uint256 profileId,
        address follower,
        uint256 followNFTTokenId
    ) external view override {}

    function followModuleTransferHook(
        uint256 profileId,
        address from,
        address to,
        uint256 followNFTTokenId
    ) external override {}
}
