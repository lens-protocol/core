// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'test/foundry/base/BaseTest.t.sol';
import {RevertFollowModule} from 'contracts/modules/follow/RevertFollowModule.sol';
import {Errors as ModuleErrors} from 'contracts/modules/constants/Errors.sol';

contract RevertFollowModuleTest is BaseTest {
    using stdJson for string;
    RevertFollowModule revertFollowModule;

    // Deploy & Whitelist RevertFollowModule
    constructor() TestSetup() {
        if (fork && keyExists(string(abi.encodePacked('.', forkEnv, '.RevertFollowModule')))) {
            revertFollowModule = RevertFollowModule(
                json.readAddress(string(abi.encodePacked('.', forkEnv, '.RevertFollowModule')))
            );
            console.log('Testing against already deployed module at:', address(revertFollowModule));
        } else {
            vm.prank(deployer);
            revertFollowModule = new RevertFollowModule();
        }
    }

    // RevertFollowModule doesn't need initialization, so this always returns an empty bytes array and is
    // callable by anyone
    function testInitialize(address from, uint256 profileId) public {
        vm.prank(from);
        revertFollowModule.initializeFollowModule(profileId, address(0), '');
    }

    // Negatives
    function testCannotProcessFollow(
        address from,
        uint256 followerProfileId,
        uint256 followerTokenId,
        address transactionExecutor,
        uint256 profileId
    ) public {
        vm.assume(from != address(0));
        vm.assume(followerProfileId != 0);
        vm.assume(followerTokenId != 0);
        vm.assume(profileId != 0);

        vm.expectRevert(ModuleErrors.FollowInvalid.selector);

        vm.prank(from);
        revertFollowModule.processFollow(followerProfileId, followerTokenId, transactionExecutor, profileId, '');
    }
}
