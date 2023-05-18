// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/MetaTxNegatives.t.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {UIDataProvider, LatestData} from 'contracts/misc/UIDataProvider.sol';

contract UIDataProviderTest is BaseTest {
    using stdJson for string;
    UIDataProvider uiDataProvider;

    function setUp() public override {
        super.setUp();
        Types.PostParams memory postParams = _getDefaultPostParams();
        vm.prank(defaultAccount.owner);
        hub.post(postParams);

        if (fork) {
            uiDataProvider = UIDataProvider(
                json.readAddress(string(abi.encodePacked('.', forkEnv, '.UIDataProvider')))
            );
        } else {
            uiDataProvider = new UIDataProvider(ILensHub(address(hub)));
        }
    }

    function testGetLatestDataByProfile() public {
        Types.Profile memory profile = hub.getProfile(defaultAccount.profileId);
        uint256 pubCount = profile.pubCount;
        Types.Publication memory pub = hub.getPub(defaultAccount.profileId, pubCount);

        vm.expectCall(address(hub), abi.encodeCall(hub.getProfile, (defaultAccount.profileId)), 1);
        vm.expectCall(address(hub), abi.encodeCall(hub.getPub, (defaultAccount.profileId, pubCount)), 1);

        LatestData memory latestData = uiDataProvider.getLatestDataByProfile(defaultAccount.profileId);

        assertEq(latestData.profile.pubCount, profile.pubCount);
        assertEq(latestData.profile.followModule, profile.followModule);
        assertEq(latestData.profile.followNFT, profile.followNFT);
        assertEq(latestData.profile.handleDeprecated, profile.handleDeprecated);
        assertEq(latestData.profile.imageURI, profile.imageURI);
        assertEq(latestData.profile.followNFTURI, profile.followNFTURI);
        assertEq(latestData.profile.metadataURI, profile.metadataURI);

        assertEq(latestData.publication.pointedProfileId, pub.pointedProfileId);
        assertEq(latestData.publication.pointedPubId, pub.pointedPubId);
        assertEq(latestData.publication.contentURI, pub.contentURI);
        assertEq(latestData.publication.referenceModule, pub.referenceModule);
        assertEq(latestData.publication.__DEPRECATED__collectModule, pub.__DEPRECATED__collectModule);
        assertEq(latestData.publication.__DEPRECATED__collectNFT, pub.__DEPRECATED__collectNFT);
        assertTrue(latestData.publication.pubType == pub.pubType);
        assertEq(latestData.publication.rootProfileId, pub.rootProfileId);
        assertEq(latestData.publication.rootPubId, pub.rootPubId);
        assertEq(latestData.publication.enabledActionModulesBitmap, pub.enabledActionModulesBitmap);
    }
}
