// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
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
            if (keyExists(json, string(abi.encodePacked('.', forkEnv, '.UIDataProvider')))) {
                uiDataProvider = UIDataProvider(
                    json.readAddress(string(abi.encodePacked('.', forkEnv, '.UIDataProvider')))
                );
            } else {
                console.log('UIDataProvider key does not exist');
                if (forkVersion == 1) {
                    console.log('No UIDataProvider address found - deploying new one');
                    uiDataProvider = new UIDataProvider(ILensHub(address(hub)));
                } else {
                    console.log('No UIDataProvider address found in addressBook, which is required for V2');
                    revert('No UIDataProvider address found in addressBook, which is required for V2');
                }
            }
        } else {
            uiDataProvider = new UIDataProvider(ILensHub(address(hub)));
        }
    }

    function testGetLatestDataByProfile() public {
        Types.Profile memory profile = hub.getProfile(defaultAccount.profileId);
        uint256 pubCount1 = profile.pubCount;
        Types.Publication memory pub1 = hub.getPublication(defaultAccount.profileId, pubCount1);

        vm.expectCall(address(hub), abi.encodeCall(hub.getProfile, (defaultAccount.profileId)), 3);
        vm.expectCall(address(hub), abi.encodeCall(hub.getPublication, (defaultAccount.profileId, pubCount1)), 1);

        LatestData memory latestData1 = uiDataProvider.getLatestDataByProfile(defaultAccount.profileId);

        assertEq(latestData1.profile.pubCount, profile.pubCount);
        assertEq(latestData1.profile.followModule, profile.followModule);
        assertEq(latestData1.profile.followNFT, profile.followNFT);
        assertEq(latestData1.profile.__DEPRECATED__handle, profile.__DEPRECATED__handle);
        assertEq(latestData1.profile.__DEPRECATED__imageURI, profile.__DEPRECATED__imageURI);
        assertEq(latestData1.profile.metadataURI, profile.metadataURI);

        assertEq(latestData1.publication.pointedProfileId, pub1.pointedProfileId);
        assertEq(latestData1.publication.pointedPubId, pub1.pointedPubId);
        assertEq(latestData1.publication.contentURI, pub1.contentURI);
        assertEq(latestData1.publication.referenceModule, pub1.referenceModule);
        assertEq(latestData1.publication.__DEPRECATED__collectModule, pub1.__DEPRECATED__collectModule);
        assertEq(latestData1.publication.__DEPRECATED__collectNFT, pub1.__DEPRECATED__collectNFT);
        assertTrue(latestData1.publication.pubType == pub1.pubType);
        assertEq(latestData1.publication.rootProfileId, pub1.rootProfileId);
        assertEq(latestData1.publication.rootPubId, pub1.rootPubId);
        assertEq(latestData1.publication.enabledActionModulesBitmap, pub1.enabledActionModulesBitmap);

        Types.PostParams memory postParams = Types.PostParams({
            profileId: defaultAccount.profileId,
            contentURI: 'newPost',
            actionModules: _toAddressArray(address(mockActionModule)),
            actionModulesInitDatas: _toBytesArray(abi.encode(true)),
            referenceModule: address(0),
            referenceModuleInitData: ''
        });

        vm.prank(defaultAccount.owner);
        hub.post(postParams);

        profile = hub.getProfile(defaultAccount.profileId);
        uint256 pubCount2 = profile.pubCount;

        assertEq(pubCount2, pubCount1 + 1);

        Types.Publication memory pub2 = hub.getPublication(defaultAccount.profileId, pubCount2);

        vm.expectCall(address(hub), abi.encodeCall(hub.getPublication, (defaultAccount.profileId, pubCount2)), 1);

        LatestData memory latestData2 = uiDataProvider.getLatestDataByProfile(defaultAccount.profileId);

        assertEq(latestData2.profile.pubCount, profile.pubCount);

        assertEq(latestData2.publication.pointedProfileId, pub2.pointedProfileId);
        assertEq(latestData2.publication.pointedPubId, pub2.pointedPubId);
        assertEq(latestData2.publication.contentURI, pub2.contentURI);
        assertEq(latestData2.publication.referenceModule, pub2.referenceModule);
        assertEq(latestData2.publication.__DEPRECATED__collectModule, pub2.__DEPRECATED__collectModule);
        assertEq(latestData2.publication.__DEPRECATED__collectNFT, pub2.__DEPRECATED__collectNFT);
        assertTrue(latestData2.publication.pubType == pub2.pubType);
        assertEq(latestData2.publication.rootProfileId, pub2.rootProfileId);
        assertEq(latestData2.publication.rootPubId, pub2.rootPubId);
        assertEq(latestData2.publication.enabledActionModulesBitmap, pub2.enabledActionModulesBitmap);

        assertEq(latestData2.publication.contentURI, postParams.contentURI);
    }
}
