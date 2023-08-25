// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {ProfileCreationProxy} from 'contracts/misc/ProfileCreationProxy.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

contract ProfileCreationProxyTest is BaseTest {
    using stdJson for string;

    error OnlyOwner();

    ProfileCreationProxy profileCreationProxy;
    address profileCreationProxyOwner = makeAddr('PROFILE_CREATION_PROXY_OWNER');

    function setUp() public override {
        super.setUp();

        if (fork) {
            if (keyExists(json, string(abi.encodePacked('.', forkEnv, '.ProfileCreationProxy')))) {
                profileCreationProxy = ProfileCreationProxy(
                    json.readAddress(string(abi.encodePacked('.', forkEnv, '.ProfileCreationProxy')))
                );
                profileCreationProxyOwner = profileCreationProxy.OWNER();
            } else {
                console.log('ProfileCreationProxy key does not exist');
                if (forkVersion == 1) {
                    console.log('No ProfileCreationProxy address found - deploying new one');
                    profileCreationProxy = new ProfileCreationProxy(
                        profileCreationProxyOwner,
                        address(hub),
                        address(lensHandles),
                        address(tokenHandleRegistry)
                    );
                } else {
                    console.log('No ProfileCreationProxy address found in addressBook, which is required for V2');
                    revert('No ProfileCreationProxy address found in addressBook, which is required for V2');
                }
            }
        } else {
            profileCreationProxy = new ProfileCreationProxy(
                profileCreationProxyOwner,
                address(hub),
                address(lensHandles),
                address(tokenHandleRegistry)
            );
        }

        vm.prank(governance);
        hub.whitelistProfileCreator(address(profileCreationProxy), true);
    }

    // NEGATIVES

    function testCannot_ProxyCreateProfile_IfNotOwner(address otherAddress) public {
        vm.assume(otherAddress != profileCreationProxyOwner);

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: otherAddress,
            followModule: address(0),
            followModuleInitData: ''
        });

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(otherAddress);
        profileCreationProxy.proxyCreateProfile(createProfileParams);
    }

    function testCannot_ProxyCreateHandle_IfNotOwner(address otherAddress) public {
        vm.assume(otherAddress != profileCreationProxyOwner);

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(otherAddress);
        profileCreationProxy.proxyCreateHandle(otherAddress, 'handle');
    }

    function testCannot_ProxyCreateProfileWithHandle_IfNotOwner(address otherAddress) public {
        vm.assume(otherAddress != profileCreationProxyOwner);

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: otherAddress,
            followModule: address(0),
            followModuleInitData: ''
        });

        vm.expectRevert(OnlyOwner.selector);
        vm.prank(otherAddress);
        profileCreationProxy.proxyCreateProfileWithHandle(createProfileParams, 'handle');
    }

    // SCENARIOS

    function testProxyCreateProfile(address profileOwner) public {
        vm.assume(profileOwner != address(0));

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: profileOwner,
            followModule: address(0),
            followModuleInitData: ''
        });

        vm.expectCall(address(hub), abi.encodeCall(hub.createProfile, (createProfileParams)));

        vm.prank(profileCreationProxyOwner);
        uint256 profileId = profileCreationProxy.proxyCreateProfile(createProfileParams);

        assertEq(hub.ownerOf(profileId), profileOwner);
    }

    function testProxyCreateHandle(address handleOwner) public {
        vm.assume(handleOwner != address(0));

        string memory handle = 'handle';

        vm.expectCall(address(lensHandles), abi.encodeCall(lensHandles.mintHandle, (handleOwner, handle)));

        vm.prank(profileCreationProxyOwner);
        uint256 handleId = profileCreationProxy.proxyCreateHandle(handleOwner, handle);

        assertEq(lensHandles.ownerOf(handleId), handleOwner);
    }

    function testProxyCreateProfileWithHandle(address profileOwner) public {
        vm.assume(profileOwner != address(0));

        Types.CreateProfileParams memory createProfileParams = Types.CreateProfileParams({
            to: profileOwner,
            followModule: address(0),
            followModuleInitData: ''
        });
        string memory handle = 'handle98123791824';

        uint256 predictedProfileId = uint256(vm.load(address(hub), bytes32(StorageLib.PROFILE_COUNTER_SLOT))) + 1;
        uint256 predictedHandleId = lensHandles.getTokenId(handle);

        Types.CreateProfileParams memory calledCreateProfileParams = Types.CreateProfileParams({
            to: address(profileCreationProxy),
            followModule: createProfileParams.followModule,
            followModuleInitData: createProfileParams.followModuleInitData
        });

        vm.expectCall(address(hub), abi.encodeCall(hub.createProfile, (calledCreateProfileParams)), 1);
        vm.expectCall(
            address(lensHandles),
            abi.encodeCall(lensHandles.mintHandle, (address(profileCreationProxy), handle)),
            1
        );
        vm.expectCall(
            address(tokenHandleRegistry),
            abi.encodeCall(tokenHandleRegistry.link, (predictedHandleId, predictedProfileId)),
            1
        );

        vm.prank(profileCreationProxyOwner);
        (uint256 profileId, uint256 handleId) = profileCreationProxy.proxyCreateProfileWithHandle(
            createProfileParams,
            handle
        );

        assertEq(profileId, predictedProfileId, 'Profile id mismatch');
        assertEq(handleId, predictedHandleId, 'Handle id mismatch');

        assertEq(hub.ownerOf(profileId), profileOwner, 'Profile owner mismatch');
        assertEq(lensHandles.ownerOf(handleId), profileOwner, 'Handle owner mismatch');
        assertEq(tokenHandleRegistry.resolve(handleId), profileId, 'Handle not linked to profile');
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId, 'Profile not linked to handle');
    }
}
