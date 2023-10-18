// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IFollowModule} from 'contracts/interfaces/IFollowModule.sol';
import {LensModule} from 'contracts/modules/LensModule.sol';

/**
 * @dev This is a simple mock follow module to be used for testing.
 */
contract MockFollowModule is LensModule, IFollowModule {
    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == type(IFollowModule).interfaceId || super.supportsInterface(interfaceID);
    }

    function testMockFollowModule() public {
        // Prevents being counted in Foundry Coverage
    }

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

    function getModuleMetadataURI() external pure override returns (string memory) {
        return 'https://docs.lens.xyz/';
    }
}
