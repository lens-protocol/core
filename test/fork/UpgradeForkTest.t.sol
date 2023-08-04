// This test should upgrade the forked Polygon deployment, and run a series of tests.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import 'forge-std/console2.sol';
import 'test/base/BaseTest.t.sol';
import 'test/mocks/MockReferenceModule.sol';
import 'test/mocks/MockDeprecatedReferenceModule.sol';
import 'test/mocks/MockDeprecatedCollectModule.sol';
import 'test/mocks/MockFollowModule.sol';
import 'test/mocks/MockDeprecatedFollowModule.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';
import {LensV2UpgradeContract} from 'contracts/misc/LensV2UpgradeContract.sol';

contract UpgradeForkTest is BaseTest {
    using stdJson for string;

    address mockFollowModuleAddr;
    address mockReferenceModuleAddr;

    IOldHub legacyHub;

    address freeCollectModule;
    address lensV2UpgradeContract;

    uint256 follow1;
    uint256 follow2;
    uint256 post1;
    uint256 post2;
    uint256 comment1;
    uint256 comment2;
    uint256 comment3;
    uint256 comment4;
    uint256 mirror1;
    uint256 mirror2;
    uint256 mirror3;
    uint256 mirror4;
    uint256 collect1;

    uint256 follow3;
    uint256 post3;
    uint256 post4;
    uint256 comment5;
    uint256 comment6;
    uint256 comment7;
    uint256 comment8;
    uint256 quote1;
    uint256 quote2;
    uint256 quote3;
    uint256 quote4;
    uint256 mirror5;
    uint256 mirror6;
    uint256 mirror7;
    uint256 mirror8;
    uint256 collect2;

    uint256 post5;
    uint256 quote5;
    uint256 comment9;
    uint256 comment10;

    uint256 follow4;
    uint256 follow5;
    uint256 follow6;

    TestAccount profileOne;
    TestAccount profileTwo;
    TestAccount profileThree;
    TestAccount profileFour;

    uint256 profile1PubCount;
    uint256 profile2PubCount;

    uint256 profile1NewPubs;
    uint256 profile2NewPubs;

    function setUp() public override {
        super.setUp();
        legacyHub = IOldHub(address(hub));
        freeCollectModule = json.readAddress(string(abi.encodePacked('.', forkEnv, '.Modules.v1.FreeCollectModule')));
    }

    function upgradeToV2() internal override {
        // We override the upgrade function to upgrade manually within the test
    }

    function _prepareV1State() internal {
        // Create two profiles
        // TODO: fetch existing profiles from ENV

        // Profile1 - this we migrate
        profileOne = _loadAccountAs('UPGRADE_PROFILE_1');
        // Profile2 - this we don't migrate
        profileTwo = _loadAccountAs('UPGRADE_PROFILE_2');

        profile1PubCount = legacyHub.getProfile(profileOne.profileId).pubCount;
        profile2PubCount = legacyHub.getProfile(profileTwo.profileId).pubCount;

        // Profile1: Follows Profile2 creating Follow#1
        vm.prank(profileOne.owner);
        follow1 = legacyHub.follow(_toUint256Array(profileTwo.profileId), _toBytesArray(''))[0];

        // Profile2: Follows Profile1 creating Follow#2
        vm.prank(profileTwo.owner);
        follow2 = legacyHub.follow(_toUint256Array(profileOne.profileId), _toBytesArray(''))[0];

        // Post, comment, mirror - from each of the profile (mixing it up with each other):
        // Profile1 clean publications:
        vm.startPrank(profileOne.owner);
        // Profile1: Post#1
        post1 = legacyHub.post(
            OldPostData({
                profileId: profileOne.profileId,
                contentURI: 'https://post1',
                collectModule: freeCollectModule,
                collectModuleInitData: abi.encode(false),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile1NewPubs++;

        // Profile1: Comment#1 on Profile1.Post#1
        comment1 = legacyHub.comment(
            OldCommentData({
                profileId: profileOne.profileId,
                contentURI: 'https://comment1',
                profileIdPointed: profileOne.profileId,
                pubIdPointed: post1,
                referenceModuleData: '',
                collectModule: freeCollectModule,
                collectModuleInitData: abi.encode(false),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile1NewPubs++;

        // Profile1: Mirror#1 on Profile1.Post#1
        mirror1 = legacyHub.mirror(
            OldMirrorData({
                profileId: profileOne.profileId,
                pointedProfileId: profileOne.profileId,
                pointedPubId: post1,
                referenceModuleData: '',
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile1NewPubs++;

        vm.stopPrank();

        // Profile2 clean publications:
        vm.startPrank(profileTwo.owner);
        // Profile2: Post#2
        post2 = legacyHub.post(
            OldPostData({
                profileId: profileTwo.profileId,
                contentURI: 'https://post2',
                collectModule: freeCollectModule,
                collectModuleInitData: abi.encode(false),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile2NewPubs++;

        // Profile2: Comment#2 on Profile2.Post#2
        comment2 = legacyHub.comment(
            OldCommentData({
                profileId: profileTwo.profileId,
                contentURI: 'https://comment2',
                profileIdPointed: profileTwo.profileId,
                pubIdPointed: post2,
                referenceModuleData: '',
                collectModule: freeCollectModule,
                collectModuleInitData: abi.encode(false),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile2NewPubs++;

        // Profile2: Mirror#2 on Profile2.Post#2
        mirror2 = legacyHub.mirror(
            OldMirrorData({
                profileId: profileTwo.profileId,
                pointedProfileId: profileTwo.profileId,
                pointedPubId: post2,
                referenceModuleData: '',
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile2NewPubs++;

        vm.stopPrank();

        // Mixed publications between profiles:
        vm.startPrank(profileOne.owner);
        // Profile1: Comment#3 on Profile2.Post#2
        comment3 = legacyHub.comment(
            OldCommentData({
                profileId: profileOne.profileId,
                contentURI: 'https://comment3',
                profileIdPointed: profileTwo.profileId,
                pubIdPointed: post2,
                referenceModuleData: '',
                collectModule: freeCollectModule,
                collectModuleInitData: abi.encode(false),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile1NewPubs++;

        // Profile1: Mirror#3 on Profile2.Comment#2
        mirror3 = legacyHub.mirror(
            OldMirrorData({
                profileId: profileOne.profileId,
                pointedProfileId: profileTwo.profileId,
                pointedPubId: comment2,
                referenceModuleData: '',
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile1NewPubs++;

        vm.stopPrank();

        vm.startPrank(profileTwo.owner);
        // Profile2: Comment#4 on Profile1.Post#1
        comment4 = legacyHub.comment(
            OldCommentData({
                profileId: profileTwo.profileId,
                contentURI: 'https://comment4',
                profileIdPointed: profileOne.profileId,
                pubIdPointed: post1,
                referenceModuleData: '',
                collectModule: freeCollectModule,
                collectModuleInitData: abi.encode(false),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile2NewPubs++;

        // Profile2: Mirror#4 on Profile1.Comment#1
        mirror4 = legacyHub.mirror(
            OldMirrorData({
                profileId: profileTwo.profileId,
                pointedProfileId: profileOne.profileId,
                pointedPubId: comment1,
                referenceModuleData: '',
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile2NewPubs++;
        vm.stopPrank();

        // In total we have:
        // - 2 Posts
        // - 4 Comments
        // - 4 Mirrors

        // One profile collects from other
        // Profile1: Collect#1 on Profile2.Post#2
        vm.prank(profileOne.owner);
        collect1 = legacyHub.collect({profileId: profileTwo.profileId, pubId: post2, data: ''});
    }

    function _prepareUpgradeContract() internal {
        // Load V1 modules addresses

        Module[] memory collectModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', forkEnv, '.Modules.v1.collect'))),
            (Module[])
        );
        address[] memory oldCollectModulesToUnwhitelist = new address[](collectModules.length);
        for (uint i = 0; i < collectModules.length; i++) {
            oldCollectModulesToUnwhitelist[i] = collectModules[i].addy;
        }

        Module[] memory referenceModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', forkEnv, '.Modules.v1.reference'))),
            (Module[])
        );
        address[] memory oldReferenceModulesToUnwhitelist = new address[](referenceModules.length);
        for (uint i = 0; i < referenceModules.length; i++) {
            oldReferenceModulesToUnwhitelist[i] = referenceModules[i].addy;
        }

        Module[] memory followModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', forkEnv, '.Modules.v1.follow'))),
            (Module[])
        );
        address[] memory oldFollowModulesToUnwhitelist = new address[](followModules.length);
        for (uint i = 0; i < followModules.length; i++) {
            oldFollowModulesToUnwhitelist[i] = followModules[i].addy;
        }

        // Load V2 modules addresses

        // Module[] memory actionModules = abi.decode(
        //     vm.parseJson(json, string(abi.encodePacked('.', forkEnv, '.Modules.v2.action'))),
        //     (Module[])
        // );
        // address[] memory newActionModulesToWhitelist = new address[](actionModules.length);
        // for (uint i = 0; i < actionModules.length; i++) {
        //     newActionModulesToWhitelist[i] = actionModules[i].addy;
        // }

        // Module[] memory referenceModulesV2 = abi.decode(
        //     vm.parseJson(json, string(abi.encodePacked('.', forkEnv, '.Modules.v2.reference'))),
        //     (Module[])
        // );
        // address[] memory newReferenceModulesToWhitelist = new address[](referenceModulesV2.length);
        // for (uint i = 0; i < referenceModulesV2.length; i++) {
        //     newReferenceModulesToWhitelist[i] = referenceModulesV2[i].addy;
        // }

        // Module[] memory followModulesV2 = abi.decode(
        //     vm.parseJson(json, string(abi.encodePacked('.', forkEnv, '.Modules.v2.follow'))),
        //     (Module[])
        // );
        // address[] memory newFollowModulesToWhitelist = new address[](followModulesV2.length);
        // for (uint i = 0; i < followModulesV2.length; i++) {
        //     newFollowModulesToWhitelist[i] = followModulesV2[i].addy;
        // }

        lensV2UpgradeContract = address(
            new LensV2UpgradeContract({
                proxyAdminAddress: address(0), // TODO!
                governanceAddress: address(0), // TODO!
                owner: governance,
                lensHub: address(hub),
                newImplementationAddress: address(0), // TODO!
                oldFollowModulesToUnwhitelist_: oldFollowModulesToUnwhitelist,
                newFollowModulesToWhitelist_: _emptyAddressArray(),
                oldReferenceModulesToUnwhitelist_: oldReferenceModulesToUnwhitelist,
                newReferenceModulesToWhitelist_: _emptyAddressArray(),
                oldCollectModulesToUnwhitelist_: oldCollectModulesToUnwhitelist,
                newActionModulesToWhitelist_: _emptyAddressArray()
            })
        );
    }

    function _doSomeStuffOnV2() internal {
        // Same stuff as we done on V1, but with the new interface
        // Create two profiles

        // Profile3
        profileThree = _loadAccountAs('UPGRADE_PROFILE_3');
        // Profile4
        profileFour = _loadAccountAs('UPGRADE_PROFILE_4');

        // Profile3: Follows Profile4 creating Follow#3
        vm.prank(profileThree.owner);
        follow3 = hub.follow(
            profileThree.profileId,
            _toUint256Array(profileFour.profileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];

        // Profile4: Follows Profile1 creating Follow#4
        vm.prank(profileFour.owner);
        follow4 = hub.follow(
            profileFour.profileId,
            _toUint256Array(profileOne.profileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];

        // Profile1: Follows Profile3 creating Follow#5
        vm.prank(profileOne.owner);
        follow5 = hub.follow(
            profileOne.profileId,
            _toUint256Array(profileThree.profileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];

        // Profile2: Follows Profile4 creating Follow#6
        vm.prank(profileTwo.owner);
        follow6 = hub.follow(
            profileTwo.profileId,
            _toUint256Array(profileFour.profileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];

        // Post, comment, mirror - from each of the profile (mixing it up with each other):
        // Profile3 clean publications:
        vm.startPrank(profileThree.owner);
        // Profile3: Post#3
        post3 = hub.post(
            Types.PostParams({
                profileId: profileThree.profileId,
                contentURI: 'https://post3',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // Profile3: Comment#5 on Profile3.Post#3
        comment5 = hub.comment(
            Types.CommentParams({
                profileId: profileThree.profileId,
                contentURI: 'https://comment5',
                pointedProfileId: profileThree.profileId,
                pointedPubId: post3,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // Profile3: Quote#1 on Profile3.Post#3
        quote1 = hub.quote(
            Types.QuoteParams({
                profileId: profileThree.profileId,
                contentURI: 'https://quote1',
                pointedProfileId: profileThree.profileId,
                pointedPubId: post3,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // Profile3: Mirror#5 on Profile3.Post#3
        mirror5 = hub.mirror(
            Types.MirrorParams({
                profileId: profileThree.profileId,
                pointedProfileId: profileThree.profileId,
                pointedPubId: post3,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: ''
            })
        );

        vm.stopPrank();

        // Profile4 clean publications:
        vm.startPrank(profileFour.owner);
        // Profile4: Post#4
        post4 = hub.post(
            Types.PostParams({
                profileId: profileFour.profileId,
                contentURI: 'https://post4',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // Profile4: Comment#6 on Profile4.Post#4
        comment6 = hub.comment(
            Types.CommentParams({
                profileId: profileFour.profileId,
                contentURI: 'https://comment6',
                pointedProfileId: profileFour.profileId,
                pointedPubId: post4,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // Profile4: Quote#2 on Profile4.Post#4
        quote2 = hub.quote(
            Types.QuoteParams({
                profileId: profileFour.profileId,
                contentURI: 'https://quote2',
                pointedProfileId: profileFour.profileId,
                pointedPubId: post4,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // Profile4: Mirror#6 on Profile4.Post#4
        mirror6 = hub.mirror(
            Types.MirrorParams({
                profileId: profileFour.profileId,
                pointedProfileId: profileFour.profileId,
                pointedPubId: post4,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: ''
            })
        );

        vm.stopPrank();

        // Mixed publications between profiles:
        vm.startPrank(profileThree.owner);
        // Profile3: Comment#7 on Profile4.Post#4
        comment7 = hub.comment(
            Types.CommentParams({
                profileId: profileThree.profileId,
                contentURI: 'https://comment7',
                pointedProfileId: profileFour.profileId,
                pointedPubId: post4,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // Profile3: Quote#3 on Profile4.Comment#6
        quote3 = hub.quote(
            Types.QuoteParams({
                profileId: profileThree.profileId,
                contentURI: 'https://quote3',
                pointedProfileId: profileFour.profileId,
                pointedPubId: comment6,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // Profile3: Mirror#7 on Profile4.Quote#2
        mirror7 = hub.mirror(
            Types.MirrorParams({
                profileId: profileThree.profileId,
                pointedProfileId: profileFour.profileId,
                pointedPubId: quote2,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: ''
            })
        );

        // Profile3: Comment#8 on Profile1.Post#1
        comment8 = hub.comment(
            Types.CommentParams({
                profileId: profileThree.profileId,
                contentURI: 'https://comment8',
                pointedProfileId: profileOne.profileId,
                pointedPubId: post1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // Profile3: Quote#4 on Profile1.Comment#1
        quote4 = hub.quote(
            Types.QuoteParams({
                profileId: profileThree.profileId,
                contentURI: 'https://quote4',
                pointedProfileId: profileOne.profileId,
                pointedPubId: comment1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // Profile3: Mirror#8 on Profile1.Post#1
        mirror8 = hub.mirror(
            Types.MirrorParams({
                profileId: profileThree.profileId,
                pointedProfileId: profileOne.profileId,
                pointedPubId: post1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: ''
            })
        );

        vm.stopPrank();

        // Mixed publications between Profile4 and Profile2:
        vm.startPrank(profileFour.owner);
        // Profile4: Comment#9 on Profile2.Post#2
        comment9 = hub.comment(
            Types.CommentParams({
                profileId: profileFour.profileId,
                contentURI: 'https://comment9',
                pointedProfileId: profileTwo.profileId,
                pointedPubId: post2,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // Profile1: Quote#5 on Profile2.Comment#2
        quote5 = hub.quote(
            Types.QuoteParams({
                profileId: profileFour.profileId,
                contentURI: 'https://quote5',
                pointedProfileId: profileTwo.profileId,
                pointedPubId: comment2,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile1NewPubs++;

        // Profile2: Post#5
        post5 = hub.post(
            Types.PostParams({
                profileId: profileTwo.profileId,
                contentURI: 'https://post5',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile2NewPubs++;

        // Profile2: Comment#10 on Profile3.Post#3
        comment10 = hub.comment(
            Types.CommentParams({
                profileId: profileTwo.profileId,
                contentURI: 'https://comment10',
                pointedProfileId: profileThree.profileId,
                pointedPubId: post3,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );
        profile2NewPubs++;

        // V2 profile collects from V1 profile
        // Profile3: Collect#2 on Profile2.Post#2
        vm.prank(profileThree.owner);
        collect2 = hub.collect(
            Types.CollectParams({
                publicationCollectedProfileId: profileTwo.profileId,
                publicationCollectedId: post2,
                collectorProfileId: profileThree.profileId,
                referrerProfileId: 0,
                referrerPubId: 0,
                collectModuleData: ''
            })
        );

        // TODO: We should also test the Act
    }

    function _verifyDataAfterUpgrade() internal {
        // Using V2 interface, verify that the data is the same as before for:
        // V1 Profile1 was migrated, so has to conform to new after-migration data:
        Types.Profile memory profile1 = hub.getProfile(profileOne.profileId);
        assertEq(profile1.pubCount, profile1PubCount + profile1NewPubs);
        assertEq(profile1.followModule, address(0));
        assertEq(profile1.__DEPRECATED__handle, '');
        assertEq(profile1.imageURI, string.concat(MOCK_URI, '/imageURI/', LibString.lower('UPGRADE_PROFILE_1')));
        assertEq(profile1.__DEPRECATED__followNFTURI, '');

        // V1 Profile2 was not migrated, so still has to have the old data:
        Types.Profile memory profile2 = hub.getProfile(profileTwo.profileId);
        assertEq(profile2.pubCount, profile2PubCount + profile2NewPubs);
        assertEq(profile2.followModule, address(0));
        assertEq(profile2.__DEPRECATED__handle, LibString.lower('UPGRADE_PROFILE_2'));
        assertEq(profile2.imageURI, string.concat(MOCK_URI, '/imageURI/', LibString.lower('UPGRADE_PROFILE_2')));
        assertEq(
            profile2.__DEPRECATED__followNFTURI,
            string.concat(MOCK_URI, '/followNFTURI/', LibString.lower('UPGRADE_PROFILE_2'))
        );

        // - 2 Posts V1
        Types.Publication memory post1Pub = hub.getPublication(profileOne.profileId, post1);
        assertEq(post1Pub.pointedProfileId, 0);
        assertEq(post1Pub.pointedPubId, 0);
        assertEq(post1Pub.contentURI, 'https://post1');
        assertEq(post1Pub.referenceModule, address(0));
        assertEq(post1Pub.__DEPRECATED__collectModule, freeCollectModule);
        assertEq(uint256(post1Pub.pubType), uint256(Types.PublicationType.Post));
        assertEq(post1Pub.rootProfileId, 0); // V1 posts don't have root
        assertEq(post1Pub.rootPubId, 0); // V1 posts don't have root
        assertEq(post1Pub.enabledActionModulesBitmap, 0); // V1 posts don't have action modules

        Types.Publication memory post2Pub = hub.getPublication(profileTwo.profileId, post2);
        assertEq(post2Pub.pointedProfileId, 0);
        assertEq(post2Pub.pointedPubId, 0);
        assertEq(post2Pub.contentURI, 'https://post2');
        assertEq(post2Pub.referenceModule, address(0));
        assertEq(post2Pub.__DEPRECATED__collectModule, freeCollectModule);
        assertEq(uint256(post2Pub.pubType), uint256(Types.PublicationType.Post));
        assertEq(post2Pub.rootProfileId, 0); // V1 posts don't have root
        assertEq(post2Pub.rootPubId, 0); // V1 posts don't have root
        assertEq(post2Pub.enabledActionModulesBitmap, 0); // V1 posts don't have action modules

        // - 2 Posts V2
        Types.Publication memory post3Pub = hub.getPublication(profileThree.profileId, post3);
        assertEq(post3Pub.pointedProfileId, 0);
        assertEq(post3Pub.pointedPubId, 0);
        assertEq(post3Pub.contentURI, 'https://post3');
        assertEq(post3Pub.referenceModule, address(0));
        assertEq(post3Pub.__DEPRECATED__collectModule, address(0)); // V2 posts don't have collect module
        assertEq(uint256(post3Pub.pubType), uint256(Types.PublicationType.Post));
        assertEq(post3Pub.rootProfileId, 0); // V2 posts don't have root
        assertEq(post3Pub.rootPubId, 0); // V2 posts don't have root
        assertEq(post3Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 post

        Types.Publication memory post4Pub = hub.getPublication(profileFour.profileId, post4);
        assertEq(post4Pub.pointedProfileId, 0);
        assertEq(post4Pub.pointedPubId, 0);
        assertEq(post4Pub.contentURI, 'https://post4');
        assertEq(post4Pub.referenceModule, address(0));
        assertEq(post4Pub.__DEPRECATED__collectModule, address(0)); // V2 posts don't have collect module
        assertEq(uint256(post4Pub.pubType), uint256(Types.PublicationType.Post));
        assertEq(post4Pub.rootProfileId, 0); // V2 posts don't have root
        assertEq(post4Pub.rootPubId, 0); // V2 posts don't have root
        assertEq(post4Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 post

        // - 1 V2 Post from V1 non-migrated Profile 2:
        Types.Publication memory post5Pub = hub.getPublication(profileTwo.profileId, post5);
        assertEq(post5Pub.pointedProfileId, 0);
        assertEq(post5Pub.pointedPubId, 0);
        assertEq(post5Pub.contentURI, 'https://post5');
        assertEq(post5Pub.referenceModule, address(0));
        assertEq(post5Pub.__DEPRECATED__collectModule, address(0)); // V2 posts don't have collect module
        assertEq(uint256(post5Pub.pubType), uint256(Types.PublicationType.Post));
        assertEq(post5Pub.rootProfileId, 0); // V2 posts don't have root
        assertEq(post5Pub.rootPubId, 0); // V2 posts don't have root
        assertEq(post5Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 post

        // - 4 Comments V1
        Types.Publication memory comment1Pub = hub.getPublication(profileOne.profileId, comment1);
        assertEq(comment1Pub.pointedProfileId, profileOne.profileId);
        assertEq(comment1Pub.pointedPubId, post1);
        assertEq(comment1Pub.contentURI, 'https://comment1');
        assertEq(comment1Pub.referenceModule, address(0));
        assertEq(comment1Pub.__DEPRECATED__collectModule, freeCollectModule);
        assertEq(uint256(comment1Pub.pubType), uint256(Types.PublicationType.Comment));
        assertEq(comment1Pub.rootProfileId, 0); // V1 comments don't have root
        assertEq(comment1Pub.rootPubId, 0); // V1 comments don't have root
        assertEq(comment1Pub.enabledActionModulesBitmap, 0); // V1 comments don't have action modules

        Types.Publication memory comment2Pub = hub.getPublication(profileTwo.profileId, comment2);
        assertEq(comment2Pub.pointedProfileId, profileTwo.profileId);
        assertEq(comment2Pub.pointedPubId, post2);
        assertEq(comment2Pub.contentURI, 'https://comment2');
        assertEq(comment2Pub.referenceModule, address(0));
        assertEq(comment2Pub.__DEPRECATED__collectModule, freeCollectModule);
        assertEq(uint256(comment2Pub.pubType), uint256(Types.PublicationType.Comment));
        assertEq(comment2Pub.rootProfileId, 0); // V1 comments don't have root
        assertEq(comment2Pub.rootPubId, 0); // V1 comments don't have root
        assertEq(comment2Pub.enabledActionModulesBitmap, 0); // V1 comments don't have action modules

        Types.Publication memory comment3Pub = hub.getPublication(profileOne.profileId, comment3);
        assertEq(comment3Pub.pointedProfileId, profileTwo.profileId);
        assertEq(comment3Pub.pointedPubId, post2);
        assertEq(comment3Pub.contentURI, 'https://comment3');
        assertEq(comment3Pub.referenceModule, address(0));
        assertEq(comment3Pub.__DEPRECATED__collectModule, freeCollectModule);
        assertEq(uint256(comment3Pub.pubType), uint256(Types.PublicationType.Comment));
        assertEq(comment3Pub.rootProfileId, 0); // V1 comments don't have root
        assertEq(comment3Pub.rootPubId, 0); // V1 comments don't have root
        assertEq(comment3Pub.enabledActionModulesBitmap, 0); // V1 comments don't have action modules

        Types.Publication memory comment4Pub = hub.getPublication(profileTwo.profileId, comment4);
        assertEq(comment4Pub.pointedProfileId, profileOne.profileId);
        assertEq(comment4Pub.pointedPubId, post1);
        assertEq(comment4Pub.contentURI, 'https://comment4');
        assertEq(comment4Pub.referenceModule, address(0));
        assertEq(comment4Pub.__DEPRECATED__collectModule, freeCollectModule);
        assertEq(uint256(comment4Pub.pubType), uint256(Types.PublicationType.Comment));
        assertEq(comment4Pub.rootProfileId, 0); // V1 comments don't have root
        assertEq(comment4Pub.rootPubId, 0); // V1 comments don't have root
        assertEq(comment4Pub.enabledActionModulesBitmap, 0); // V1 comments don't have action modules

        // - 4 Mirrors V1
        Types.Publication memory mirror1Pub = hub.getPublication(profileOne.profileId, mirror1);
        assertEq(mirror1Pub.pointedProfileId, profileOne.profileId);
        assertEq(mirror1Pub.pointedPubId, post1);
        assertEq(mirror1Pub.contentURI, '');
        assertEq(mirror1Pub.referenceModule, address(0));
        assertEq(mirror1Pub.__DEPRECATED__collectModule, address(0)); // V1 mirrors don't have collect module
        assertEq(uint256(mirror1Pub.pubType), uint256(Types.PublicationType.Mirror));
        assertEq(mirror1Pub.rootProfileId, 0); // V1 mirrors don't have root
        assertEq(mirror1Pub.rootPubId, 0); // V1 mirrors don't have root
        assertEq(mirror1Pub.enabledActionModulesBitmap, 0); // V1 mirrors don't have action modules

        Types.Publication memory mirror2Pub = hub.getPublication(profileTwo.profileId, mirror2);
        assertEq(mirror2Pub.pointedProfileId, profileTwo.profileId);
        assertEq(mirror2Pub.pointedPubId, post2);
        assertEq(mirror2Pub.contentURI, '');
        assertEq(mirror2Pub.referenceModule, address(0));
        assertEq(mirror2Pub.__DEPRECATED__collectModule, address(0)); // V1 mirrors don't have collect module
        assertEq(uint256(mirror2Pub.pubType), uint256(Types.PublicationType.Mirror));
        assertEq(mirror2Pub.rootProfileId, 0); // V1 mirrors don't have root
        assertEq(mirror2Pub.rootPubId, 0); // V1 mirrors don't have root
        assertEq(mirror2Pub.enabledActionModulesBitmap, 0); // V1 mirrors don't have action modules

        Types.Publication memory mirror3Pub = hub.getPublication(profileOne.profileId, mirror3);
        assertEq(mirror3Pub.pointedProfileId, profileTwo.profileId);
        assertEq(mirror3Pub.pointedPubId, comment2);
        assertEq(mirror3Pub.contentURI, '');
        assertEq(mirror3Pub.referenceModule, address(0));
        assertEq(mirror3Pub.__DEPRECATED__collectModule, address(0)); // V1 mirrors don't have collect module
        assertEq(uint256(mirror3Pub.pubType), uint256(Types.PublicationType.Mirror));
        assertEq(mirror3Pub.rootProfileId, 0); // V1 mirrors don't have root
        assertEq(mirror3Pub.rootPubId, 0); // V1 mirrors don't have root
        assertEq(mirror3Pub.enabledActionModulesBitmap, 0); // V1 mirrors don't have action modules

        Types.Publication memory mirror4Pub = hub.getPublication(profileTwo.profileId, mirror4);
        assertEq(mirror4Pub.pointedProfileId, profileOne.profileId);
        assertEq(mirror4Pub.pointedPubId, comment1);
        assertEq(mirror4Pub.contentURI, '');
        assertEq(mirror4Pub.referenceModule, address(0));
        assertEq(mirror4Pub.__DEPRECATED__collectModule, address(0)); // V1 mirrors don't have collect module
        assertEq(uint256(mirror4Pub.pubType), uint256(Types.PublicationType.Mirror));
        assertEq(mirror4Pub.rootProfileId, 0); // V1 mirrors don't have root
        assertEq(mirror4Pub.rootPubId, 0); // V1 mirrors don't have root
        assertEq(mirror4Pub.enabledActionModulesBitmap, 0); // V1 mirrors don't have action modules

        // - 4 Comments V2
        Types.Publication memory comment5Pub = hub.getPublication(profileThree.profileId, comment5);
        assertEq(comment5Pub.pointedProfileId, profileThree.profileId);
        assertEq(comment5Pub.pointedPubId, post3);
        assertEq(comment5Pub.contentURI, 'https://comment5');
        assertEq(comment5Pub.referenceModule, address(0));
        assertEq(comment5Pub.__DEPRECATED__collectModule, address(0)); // V2 comments don't have collect module
        assertEq(uint256(comment5Pub.pubType), uint256(Types.PublicationType.Comment));
        assertEq(comment5Pub.rootProfileId, profileThree.profileId);
        assertEq(comment5Pub.rootPubId, post3);
        assertEq(comment5Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 comment

        Types.Publication memory comment6Pub = hub.getPublication(profileFour.profileId, comment6);
        assertEq(comment6Pub.pointedProfileId, profileFour.profileId);
        assertEq(comment6Pub.pointedPubId, post4);
        assertEq(comment6Pub.contentURI, 'https://comment6');
        assertEq(comment6Pub.referenceModule, address(0));
        assertEq(comment6Pub.__DEPRECATED__collectModule, address(0)); // V2 comments don't have collect module
        assertEq(uint256(comment6Pub.pubType), uint256(Types.PublicationType.Comment));
        assertEq(comment6Pub.rootProfileId, profileFour.profileId);
        assertEq(comment6Pub.rootPubId, post4);
        assertEq(comment6Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 comment

        Types.Publication memory comment7Pub = hub.getPublication(profileThree.profileId, comment7);
        assertEq(comment7Pub.pointedProfileId, profileFour.profileId);
        assertEq(comment7Pub.pointedPubId, post4);
        assertEq(comment7Pub.contentURI, 'https://comment7');
        assertEq(comment7Pub.referenceModule, address(0));
        assertEq(comment7Pub.__DEPRECATED__collectModule, address(0)); // V2 comments don't have collect module
        assertEq(uint256(comment7Pub.pubType), uint256(Types.PublicationType.Comment));
        assertEq(comment7Pub.rootProfileId, profileFour.profileId);
        assertEq(comment7Pub.rootPubId, post4);
        assertEq(comment7Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 comment

        Types.Publication memory comment8Pub = hub.getPublication(profileThree.profileId, comment8);
        assertEq(comment8Pub.pointedProfileId, profileOne.profileId);
        assertEq(comment8Pub.pointedPubId, post1);
        assertEq(comment8Pub.contentURI, 'https://comment8');
        assertEq(comment8Pub.referenceModule, address(0));
        assertEq(comment8Pub.__DEPRECATED__collectModule, address(0)); // V2 comments don't have collect module
        assertEq(uint256(comment8Pub.pubType), uint256(Types.PublicationType.Comment));
        assertEq(comment8Pub.rootProfileId, 0); // V2 comments on V1 posts don't have a root
        assertEq(comment8Pub.rootPubId, 0); // V2 comments on V1 posts don't have a root
        assertEq(comment8Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 comment

        Types.Publication memory comment9Pub = hub.getPublication(profileFour.profileId, comment9);
        assertEq(comment9Pub.pointedProfileId, profileTwo.profileId);
        assertEq(comment9Pub.pointedPubId, post2);
        assertEq(comment9Pub.contentURI, 'https://comment9');
        assertEq(comment9Pub.referenceModule, address(0));
        assertEq(comment9Pub.__DEPRECATED__collectModule, address(0)); // V2 comments don't have collect module
        assertEq(uint256(comment9Pub.pubType), uint256(Types.PublicationType.Comment));
        assertEq(comment9Pub.rootProfileId, 0); // V2 comments on V1 posts don't have a root
        assertEq(comment9Pub.rootPubId, 0); // V2 comments on V1 posts don't have a root
        assertEq(comment9Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 comment

        Types.Publication memory comment10Pub = hub.getPublication(profileTwo.profileId, comment10);
        assertEq(comment10Pub.pointedProfileId, profileThree.profileId);
        assertEq(comment10Pub.pointedPubId, post3);
        assertEq(comment10Pub.contentURI, 'https://comment10');
        assertEq(comment10Pub.referenceModule, address(0));
        assertEq(comment10Pub.__DEPRECATED__collectModule, address(0)); // V2 comments don't have collect module
        assertEq(uint256(comment10Pub.pubType), uint256(Types.PublicationType.Comment));
        assertEq(comment10Pub.rootProfileId, profileThree.profileId);
        assertEq(comment10Pub.rootPubId, post3);
        assertEq(comment10Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 comment

        // - 4 Mirrors V2
        Types.Publication memory mirror5Pub = hub.getPublication(profileThree.profileId, mirror5);
        assertEq(mirror5Pub.pointedProfileId, profileThree.profileId);
        assertEq(mirror5Pub.pointedPubId, post3);
        assertEq(mirror5Pub.contentURI, '');
        assertEq(mirror5Pub.referenceModule, address(0));
        assertEq(mirror5Pub.__DEPRECATED__collectModule, address(0)); // V2 mirrors don't have collect module
        assertEq(uint256(mirror5Pub.pubType), uint256(Types.PublicationType.Mirror));
        assertEq(mirror5Pub.rootProfileId, profileThree.profileId);
        assertEq(mirror5Pub.rootPubId, post3);
        assertEq(mirror5Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 mirror

        Types.Publication memory mirror6Pub = hub.getPublication(profileFour.profileId, mirror6);
        assertEq(mirror6Pub.pointedProfileId, profileFour.profileId);
        assertEq(mirror6Pub.pointedPubId, post4);
        assertEq(mirror6Pub.contentURI, '');
        assertEq(mirror6Pub.referenceModule, address(0));
        assertEq(mirror6Pub.__DEPRECATED__collectModule, address(0)); // V2 mirrors don't have collect module
        assertEq(uint256(mirror6Pub.pubType), uint256(Types.PublicationType.Mirror));
        assertEq(mirror6Pub.rootProfileId, profileFour.profileId);
        assertEq(mirror6Pub.rootPubId, post4);
        assertEq(mirror6Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 mirror

        Types.Publication memory mirror7Pub = hub.getPublication(profileThree.profileId, mirror7);
        assertEq(mirror7Pub.pointedProfileId, profileFour.profileId);
        assertEq(mirror7Pub.pointedPubId, quote2);
        assertEq(mirror7Pub.contentURI, '');
        assertEq(mirror7Pub.referenceModule, address(0));
        assertEq(mirror7Pub.__DEPRECATED__collectModule, address(0)); // V2 mirrors don't have collect module
        assertEq(uint256(mirror7Pub.pubType), uint256(Types.PublicationType.Mirror));
        assertEq(mirror7Pub.rootProfileId, profileFour.profileId);
        assertEq(mirror7Pub.rootPubId, quote2);
        assertEq(mirror7Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 mirror

        Types.Publication memory mirror8Pub = hub.getPublication(profileThree.profileId, mirror8);
        assertEq(mirror8Pub.pointedProfileId, profileOne.profileId);
        assertEq(mirror8Pub.pointedPubId, post1);
        assertEq(mirror8Pub.contentURI, '');
        assertEq(mirror8Pub.referenceModule, address(0));
        assertEq(mirror8Pub.__DEPRECATED__collectModule, address(0)); // V2 mirrors don't have collect module
        assertEq(uint256(mirror8Pub.pubType), uint256(Types.PublicationType.Mirror));
        assertEq(mirror8Pub.rootProfileId, 0); // V2 mirrors on V1 posts don't have a root
        assertEq(mirror8Pub.rootPubId, 0); // V2 mirrors on V1 posts don't have a root
        assertEq(mirror8Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 mirror

        // - 2 Quotes V2
        Types.Publication memory quote1Pub = hub.getPublication(profileThree.profileId, quote1);
        assertEq(quote1Pub.pointedProfileId, profileThree.profileId);
        assertEq(quote1Pub.pointedPubId, post3);
        assertEq(quote1Pub.contentURI, 'https://quote1');
        assertEq(quote1Pub.referenceModule, address(0));
        assertEq(quote1Pub.__DEPRECATED__collectModule, address(0)); // V2 quotes don't have collect module
        assertEq(uint256(quote1Pub.pubType), uint256(Types.PublicationType.Quote));
        assertEq(quote1Pub.rootProfileId, profileThree.profileId);
        assertEq(quote1Pub.rootPubId, post3);
        assertEq(quote1Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 quote

        Types.Publication memory quote2Pub = hub.getPublication(profileFour.profileId, quote2);
        assertEq(quote2Pub.pointedProfileId, profileFour.profileId);
        assertEq(quote2Pub.pointedPubId, post4);
        assertEq(quote2Pub.contentURI, 'https://quote2');
        assertEq(quote2Pub.referenceModule, address(0));
        assertEq(quote2Pub.__DEPRECATED__collectModule, address(0)); // V2 quotes don't have collect module
        assertEq(uint256(quote2Pub.pubType), uint256(Types.PublicationType.Quote));
        assertEq(quote2Pub.rootProfileId, profileFour.profileId);
        assertEq(quote2Pub.rootPubId, post4);
        assertEq(quote2Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 quote

        Types.Publication memory quote3Pub = hub.getPublication(profileThree.profileId, quote3);
        assertEq(quote3Pub.pointedProfileId, profileFour.profileId);
        assertEq(quote3Pub.pointedPubId, comment6);
        assertEq(quote3Pub.contentURI, 'https://quote3');
        assertEq(quote3Pub.referenceModule, address(0));
        assertEq(quote3Pub.__DEPRECATED__collectModule, address(0)); // V2 quotes don't have collect module
        assertEq(uint256(quote3Pub.pubType), uint256(Types.PublicationType.Quote));
        assertEq(quote3Pub.rootProfileId, profileFour.profileId);
        assertEq(quote3Pub.rootPubId, post4);
        assertEq(quote3Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 quote

        Types.Publication memory quote4Pub = hub.getPublication(profileThree.profileId, quote4);
        assertEq(quote4Pub.pointedProfileId, profileOne.profileId);
        assertEq(quote4Pub.pointedPubId, comment1);
        assertEq(quote4Pub.contentURI, 'https://quote4');
        assertEq(quote4Pub.referenceModule, address(0));
        assertEq(quote4Pub.__DEPRECATED__collectModule, address(0)); // V2 quotes don't have collect module
        assertEq(uint256(quote4Pub.pubType), uint256(Types.PublicationType.Quote));
        assertEq(quote4Pub.rootProfileId, 0); // V2 quotes on V1 posts don't have a root
        assertEq(quote4Pub.rootPubId, 0); // V2 quotes on V1 posts don't have a root
        assertEq(quote4Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 quote

        Types.Publication memory quote5Pub = hub.getPublication(profileFour.profileId, quote5);
        assertEq(quote5Pub.pointedProfileId, profileTwo.profileId);
        assertEq(quote5Pub.pointedPubId, comment2);
        assertEq(quote5Pub.contentURI, 'https://quote5');
        assertEq(quote5Pub.referenceModule, address(0));
        assertEq(quote5Pub.__DEPRECATED__collectModule, address(0)); // V2 quotes don't have collect module
        assertEq(uint256(quote5Pub.pubType), uint256(Types.PublicationType.Quote));
        assertEq(quote5Pub.rootProfileId, 0); // V2 quotes on V1 posts don't have a root
        assertEq(quote5Pub.rootPubId, 0); // V2 quotes on V1 posts don't have a root
        assertEq(quote5Pub.enabledActionModulesBitmap, 0); // We didn't set action modules in this V2 quote

        // - 1 Collect V1
        // - 1 Collect V2
    }

    function testUpgradeV1toV2() public onlyFork {
        _prepareV1State();
        _prepareUpgradeContract();
        // _upgradeV1toV2();
        // _migrateProfile1();
        _doSomeStuffOnV2();
        _verifyDataAfterUpgrade();
    }

    function testUpgrade() public onlyFork {
        ILensHub hub = ILensHub(hubProxyAddr);
        address proxyAdmin = address(uint160(uint256(vm.load(hubProxyAddr, ADMIN_SLOT))));
        address gov = hub.getGovernance();

        // Set up the new deployment and helper memory structs.
        _forkSetup(hubProxyAddr, gov);

        // Create a profile on the old hub, set the default profile.
        uint256 profileId = _fullCreateProfileSequence(gov, hub);

        // Post, comment, mirror.
        _fullPublishSequence(profileId, gov, hub);

        // Follow, Collect.
        _fullFollowCollectSequence(profileId, gov, hub);

        // Get the profile.
        Types.Profile memory Profile = hub.getProfile(profileId);
        bytes memory encodedProfile = abi.encode(Profile);

        // Upgrade the hub.
        TransparentUpgradeableProxy oldHubAsProxy = TransparentUpgradeableProxy(payable(hubProxyAddr));
        vm.prank(proxyAdmin);
        oldHubAsProxy.upgradeTo(address(hubImpl));

        // Ensure governance is the same.
        assertEq(hub.getGovernance(), gov);

        // Ensure profile is the same.
        Profile = hub.getProfile(profileId);
        bytes memory postUpgradeEncodedProfile = abi.encode(Profile);
        assertEq(postUpgradeEncodedProfile, encodedProfile);

        // Create a profile on the new hub, set the default profile.
        profileId = _fullCreateProfileSequence(gov, hub);

        // Post, comment, mirror.
        _fullPublishSequence(profileId, gov, hub);

        // Follow, Collect.
        _fullFollowCollectSequence(profileId, gov, hub);

        // Fourth, set new data and ensure getters return the new data (proper slots set).
        vm.prank(gov);
        hub.setGovernance(address(this));
        assertEq(hub.getGovernance(), address(this));
    }

    function _fullCreateProfileSequence(address gov, ILensHub hub) private returns (uint256) {
        // To make this test suite evergreen, we must try setting a modern follow module since we don't know
        // which version of the hub we're working with, if this fails, then we should use a deprecated one.

        Types.CreateProfileParams memory createProfileParams = _getDefaultCreateProfileParams();
        createProfileParams.followModule = mockFollowModuleAddr;

        uint256 profileId;
        try hub.createProfile(createProfileParams) returns (uint256 retProfileId) {
            profileId = retProfileId;
            console2.log('Profile created with modern follow module.');
        } catch {
            console2.log('Profile creation with modern follow module failed. Attempting with deprecated module.');

            address mockDeprecatedFollowModule = address(new MockDeprecatedFollowModule());

            vm.prank(gov);
            hub.whitelistFollowModule(mockDeprecatedFollowModule, true);

            // precompute basic profile creaton data.
            createProfileParams = Types.CreateProfileParams({
                to: address(this),
                imageURI: MOCK_URI,
                followModule: address(0),
                followModuleInitData: abi.encode(true)
            });

            OldCreateProfileParams memory oldCreateProfileParams = OldCreateProfileParams(
                createProfileParams.to,
                vm.toString((IERC721Enumerable(address(hub)).totalSupply())),
                createProfileParams.imageURI,
                mockDeprecatedFollowModule,
                createProfileParams.followModuleInitData,
                MOCK_URI
            );

            oldCreateProfileParams.followModule = mockDeprecatedFollowModule;
            profileId = IOldHub(address(hub)).createProfile(oldCreateProfileParams);
        }
        return profileId;
    }

    function _fullPublishSequence(uint256 profileId, address gov, ILensHub hub) private {
        // First check if the new interface works, if not, use the old interface.

        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.profileId = profileId;
        postParams.referenceModule = mockReferenceModuleAddr;

        Types.CommentParams memory commentParams = _getDefaultCommentParams();
        commentParams.profileId = profileId;
        commentParams.pointedProfileId = profileId;

        Types.MirrorParams memory mirrorParams = _getDefaultMirrorParams();
        mirrorParams.profileId = profileId;
        mirrorParams.pointedProfileId = profileId;

        // Set the modern reference module, the modern collect module is already set by default.
        postParams.referenceModule = mockReferenceModuleAddr;

        try hub.post(postParams) returns (uint256 retPubId) {
            console2.log('Post published with modern collect and reference module, continuing with modern modules.');
            uint256 postId = retPubId;
            assertEq(postId, 1);

            commentParams.referenceModule = mockReferenceModuleAddr;

            // Validate post.
            assertEq(postId, 1);
            Types.Publication memory pub = hub.getPublication(profileId, postId);
            assertEq(pub.pointedProfileId, 0);
            assertEq(pub.pointedPubId, 0);
            assertEq(pub.contentURI, postParams.contentURI);
            assertEq(pub.referenceModule, postParams.referenceModule);
            // assertEq(pub.collectModule, postParams.collectModule); // TODO: Proper test
            // assertEq(pub.collectNFT, address(0));

            // Comment.
            uint256 commentId = hub.comment(commentParams);

            // Validate comment.
            assertEq(commentId, 2);
            pub = hub.getPublication(profileId, commentId);
            assertEq(pub.pointedProfileId, commentParams.pointedProfileId);
            assertEq(pub.pointedPubId, commentParams.pointedPubId);
            assertEq(pub.contentURI, commentParams.contentURI);
            assertEq(pub.referenceModule, commentParams.referenceModule);
            // assertEq(pub.collectModule, commentParams.collectModule); // TODO: Proper test
            // assertEq(pub.collectNFT, address(0));

            // Mirror.
            uint256 mirrorId = hub.mirror(mirrorParams);

            // Validate mirror.
            assertEq(mirrorId, 3);
            pub = hub.getPublication(profileId, mirrorId);
            assertEq(pub.pointedProfileId, mirrorParams.pointedProfileId);
            assertEq(pub.pointedPubId, mirrorParams.pointedPubId);
            assertEq(pub.contentURI, '');
            assertEq(pub.referenceModule, address(0));
            // assertEq(pub.collectModule, address(0)); // TODO: Proper tests
            // assertEq(pub.collectNFT, address(0));
        } catch {
            console2.log('Post with modern collect and reference module failed, Attempting with deprecated modules');

            // address mockDeprecatedCollectModule = address(new MockDeprecatedCollectModule()); // TODO: Proper test
            address mockDeprecatedReferenceModule = address(new MockDeprecatedReferenceModule());

            vm.startPrank(gov);
            // hub.whitelistCollectModule(mockDeprecatedCollectModule, true); // TODO: Proper test
            hub.whitelistReferenceModule(mockDeprecatedReferenceModule, true);
            vm.stopPrank();

            // Post.
            // postParams.collectModule = mockDeprecatedCollectModule; // TODO: Proper test
            postParams.referenceModule = mockDeprecatedReferenceModule;
            uint256 postId = hub.post(postParams);

            // Validate post.
            assertEq(postId, 1);
            Types.Publication memory pub = hub.getPublication(profileId, postId);
            assertEq(pub.pointedProfileId, 0);
            assertEq(pub.pointedPubId, 0);
            assertEq(pub.contentURI, postParams.contentURI);
            assertEq(pub.referenceModule, postParams.referenceModule);
            // assertEq(pub.collectModule, postParams.collectModule); // TODO: Proper test
            // assertEq(pub.collectNFT, address(0));

            // Comment.
            // commentParams.collectModule = mockDeprecatedCollectModule; // TODO: Proper test
            commentParams.referenceModule = mockDeprecatedReferenceModule;
            uint256 commentId = hub.comment(commentParams);

            // Validate comment.
            assertEq(commentId, 2);
            pub = hub.getPublication(profileId, commentId);
            assertEq(pub.pointedProfileId, commentParams.pointedProfileId);
            assertEq(pub.pointedPubId, commentParams.pointedPubId);
            assertEq(pub.contentURI, commentParams.contentURI);
            assertEq(pub.referenceModule, commentParams.referenceModule);
            // assertEq(pub.collectModule, commentParams.collectModule); // TODO: Proper test
            // assertEq(pub.collectNFT, address(0));

            // Mirror.
            OldMirrorData memory oldMirrorData = OldMirrorData({
                profileId: mirrorParams.profileId,
                pointedProfileId: mirrorParams.pointedProfileId,
                pointedPubId: mirrorParams.pointedPubId,
                referenceModuleData: mirrorParams.referenceModuleData,
                referenceModule: mockDeprecatedReferenceModule,
                referenceModuleInitData: commentParams.referenceModuleInitData
            });

            uint256 mirrorId = IOldHub(address(hub)).mirror(oldMirrorData);

            // Validate mirror.
            assertEq(mirrorId, 3);
            pub = hub.getPublication(profileId, mirrorId);
            assertEq(pub.pointedProfileId, mirrorParams.pointedProfileId);
            assertEq(pub.pointedPubId, mirrorParams.pointedPubId);
            assertEq(pub.contentURI, '');
            assertEq(pub.referenceModule, mockDeprecatedReferenceModule);
            // assertEq(pub.collectModule, address(0)); // TODO: Proper test
            // assertEq(pub.collectNFT, address(0));
        }
    }

    function _fullFollowCollectSequence(uint256 profileId, address gov, ILensHub hub) private {
        // First check if the new interface works, if not, use the old interface.
        uint256[] memory profileIds = new uint256[](1);
        profileIds[0] = profileId;
        uint256[] memory followTokenIds = new uint256[](1);
        followTokenIds[0] = 0;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';

        uint256 secondProfileId = _fullCreateProfileSequence(gov, hub);

        try hub.follow(secondProfileId, profileIds, followTokenIds, datas) {
            console2.log('Follow with modern interface succeeded, continuing with modern interface.');
            hub.collect(
                Types.CollectParams({
                    publicationCollectedProfileId: profileId,
                    publicationCollectedId: 1,
                    collectorProfileId: profileId,
                    referrerProfileId: 0,
                    referrerPubId: 0,
                    collectModuleData: ''
                })
            );
            hub.collect(
                Types.CollectParams({
                    publicationCollectedProfileId: profileId,
                    publicationCollectedId: 2,
                    collectorProfileId: profileId,
                    referrerProfileId: 0,
                    referrerPubId: 0,
                    collectModuleData: ''
                })
            );
            hub.collect(
                Types.CollectParams({
                    publicationCollectedProfileId: profileId,
                    publicationCollectedId: 3,
                    collectorProfileId: profileId,
                    referrerProfileId: 0,
                    referrerPubId: 0,
                    collectModuleData: ''
                })
            );
        } catch {
            console2.log('Follow with modern interface failed, proceeding with deprecated interface.');
            IOldHub(address(hub)).follow(profileIds, datas);
            IOldHub(address(hub)).collect(profileId, 1, '');
            IOldHub(address(hub)).collect(profileId, 2, '');
            IOldHub(address(hub)).collect(profileId, 3, '');
        }
    }

    function _forkSetup(address hubProxyAddr, address gov) private {
        // Start deployments.
        vm.startPrank(deployer);

        // Precompute needed addresss.
        address followNFTAddr = computeCreateAddress(deployer, 1);
        address legacyCollectNFTAddr = computeCreateAddress(deployer, 2);

        // Deploy implementation contracts.
        // TODO: Last 3 addresses are for the follow modules for migration purposes.
        hubImpl = new LensHubInitializable({
            moduleGlobals: address(0),
            followNFTImpl: followNFTAddr,
            collectNFTImpl: legacyCollectNFTAddr,
            lensHandlesAddress: address(0),
            tokenHandleRegistryAddress: address(0),
            legacyFeeFollowModule: address(0),
            legacyProfileFollowModule: address(0),
            newFeeFollowModule: address(0),
            tokenGuardianCooldown: PROFILE_GUARDIAN_COOLDOWN
        });
        followNFT = new FollowNFT(hubProxyAddr);
        legacyCollectNFT = new LegacyCollectNFT(hubProxyAddr);

        // Deploy the mock modules.
        mockReferenceModuleAddr = address(new MockReferenceModule());
        mockFollowModuleAddr = address(new MockFollowModule());

        // End deployments.
        vm.stopPrank();

        hub = LensHub(hubProxyAddr);
        // Start gov actions.
        vm.startPrank(gov);
        hub.whitelistProfileCreator(address(this), true);
        hub.whitelistFollowModule(mockFollowModuleAddr, true);
        hub.whitelistReferenceModule(mockReferenceModuleAddr, true);

        // End gov actions.
        vm.stopPrank();

        // Compute the domain separator.
        domainSeparator = keccak256(
            abi.encode(
                Typehash.EIP712_DOMAIN,
                keccak256('Lens Protocol Profiles'),
                MetaTxLib.EIP712_DOMAIN_VERSION_HASH,
                block.chainid,
                hubProxyAddr
            )
        );
    }
}
