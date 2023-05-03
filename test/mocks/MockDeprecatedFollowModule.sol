// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILegacyFollowModule} from 'contracts/interfaces/ILegacyFollowModule.sol';

/**
 * @dev This is a simple mock follow module to be used for testing.
 */
contract MockDeprecatedFollowModule is ILegacyFollowModule {
    function testMockDeprecatedFollowModule() public {
        // Prevents being counted in Foundry Coverage
    }

    function initializeFollowModule(uint256, bytes calldata data) external pure override returns (bytes memory) {
        uint256 number = abi.decode(data, (uint256));
        require(number == 1, 'MockFollowModule: invalid');
        return new bytes(0);
    }

    function processFollow(address follower, uint256 profileId, bytes calldata data) external override {}

    function isFollowing(uint256, address, uint256) external pure override returns (bool) {
        return true;
    }

    function followModuleTransferHook(
        uint256 profileId,
        address from,
        address to,
        uint256 followNFTTokenId
    ) external override {}
}
