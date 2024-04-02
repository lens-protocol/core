// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {PermissionlessCreator} from 'contracts/misc/PermissionlessCreator.sol';
import {FreeCreditsProvider} from 'contracts/misc/FreeCreditsProvider.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

contract FreeCreditsProviderTest is BaseTest {
    error OnlyOwner();

    using stdJson for string;

    PermissionlessCreator permissionlessCreator;
    address permissionlessCreatorOwner = makeAddr('PERMISSIONLESS_CREATOR_OWNER');

    FreeCreditsProvider freeCreditsProvider;

    function setUp() public virtual override {
        super.setUp();

        if (fork) {
            if (keyExists(json, string(abi.encodePacked('.', forkEnv, '.PermissionlessCreator')))) {
                permissionlessCreator = PermissionlessCreator(
                    json.readAddress(string(abi.encodePacked('.', forkEnv, '.PermissionlessCreator')))
                );
                permissionlessCreatorOwner = permissionlessCreator.OWNER();
            } else {
                console.log('PermissionlessCreator key does not exist');
                if (forkVersion == 1) {
                    console.log('No PermissionlessCreator address found - deploying new one');
                    permissionlessCreator = new PermissionlessCreator(
                        permissionlessCreatorOwner,
                        address(hub),
                        address(lensHandles),
                        address(tokenHandleRegistry)
                    );
                } else {
                    console.log('No PermissionlessCreator address found in addressBook, which is required for V2');
                    revert('No PermissionlessCreator address found in addressBook, which is required for V2');
                }
            }
        } else {
            permissionlessCreator = new PermissionlessCreator(
                permissionlessCreatorOwner,
                address(hub),
                address(lensHandles),
                address(tokenHandleRegistry)
            );
            vm.startPrank(permissionlessCreatorOwner);
            permissionlessCreator.setHandleCreationPrice(5 ether);
            permissionlessCreator.setProfileCreationPrice(5 ether);
            permissionlessCreator.setHandleLengthMin(5);
            vm.stopPrank();
        }

        vm.prank(governance);
        hub.whitelistProfileCreator(address(permissionlessCreator), true);

        freeCreditsProvider = new FreeCreditsProvider(address(permissionlessCreator));

        vm.prank(permissionlessCreatorOwner);
        permissionlessCreator.addCreditProvider(address(freeCreditsProvider));
    }

    // Scenarios
    function testIncreaseCredit(address profileCreator, address txSender) public {
        vm.assume(profileCreator != address(0));
        vm.assume(profileCreator != address(permissionlessCreator));
        vm.assume(profileCreator != address(freeCreditsProvider));
        vm.assume(txSender != address(0));
        vm.assume(txSender != address(permissionlessCreator));
        vm.assume(txSender != address(freeCreditsProvider));

        uint256 creditsBefore = permissionlessCreator.getCreditBalance(profileCreator);

        vm.prank(txSender);
        freeCreditsProvider.getFreeCredit(profileCreator, 123);

        uint256 creditsAfter = permissionlessCreator.getCreditBalance(profileCreator);

        assertEq(creditsBefore + 123, creditsAfter);
    }

    function testDecreaseCredit(address profileCreator) public {
        vm.assume(profileCreator != address(0));
        vm.assume(profileCreator != address(permissionlessCreator));
        vm.assume(profileCreator != address(freeCreditsProvider));

        freeCreditsProvider.getFreeCredit(profileCreator, 123456);

        uint256 creditsBefore = permissionlessCreator.getCreditBalance(profileCreator);

        vm.prank(profileCreator);
        freeCreditsProvider.burnCredits(123);

        uint256 creditsAfter = permissionlessCreator.getCreditBalance(profileCreator);

        assertEq(creditsBefore - 123, creditsAfter);
    }
}
