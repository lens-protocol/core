// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import 'forge-std/Test.sol';

import {BaseTest} from './BaseTest.t.sol';
import {DataTypes} from '../../contracts/libraries/DataTypes.sol';
import {Errors} from '../../contracts/libraries/Errors.sol';

contract FreeCollectModule is BaseTest {
    function setUp() public override {
        super.setUp();
        vm.startPrank(user);
        contracts.lensHub.createProfile(DataTypes.CreateProfileData({
            to: user,
            handle: MOCK_PROFILE_HANDLE,
            imageURI: MOCK_PROFILE_URI,
            followModule: address(0),
            followModuleInitData: "",
            followNFTURI: MOCK_FOLLOW_NFT_URI
        }));
        vm.stopPrank();
    }

    function testCannotCollectWithoutFollowing() public {
        vm.prank(user);
        contracts.lensHub.post(DataTypes.PostData({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: address(contracts.freeCollectModule),
            collectModuleInitData: abi.encode(true),
            referenceModule: address(0),
            referenceModuleInitData: ""
        }));

        vm.prank(userTwo);
        vm.expectRevert(Errors.FollowInvalid.selector);
        contracts.lensHub.collect(FIRST_PROFILE_ID, 1, "");
    }

    function testCanCollectWithoutFollowing() public {
        vm.prank(user);
        contracts.lensHub.post(DataTypes.PostData({
            profileId: FIRST_PROFILE_ID,
            contentURI: MOCK_URI,
            collectModule: address(contracts.freeCollectModule),
            collectModuleInitData: abi.encode(false),
            referenceModule: address(0),
            referenceModuleInitData: ""
        }));

        vm.prank(userTwo);
        contracts.lensHub.collect(FIRST_PROFILE_ID, 1, "");
    }
}
