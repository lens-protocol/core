// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import {ForkManagement} from 'test/helpers/ForkManagement.sol';
import {LegacyCollectNFT} from 'contracts/misc/LegacyCollectNFT.sol';
import {LensHub} from 'contracts/LensHub.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {ModuleGlobals} from 'contracts/misc/ModuleGlobals.sol';
import {LensHandles} from 'contracts/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/namespaces/TokenHandleRegistry.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import {LensHubInitializable} from 'contracts/misc/LensHubInitializable.sol';
import 'test/base/BaseTest.t.sol';

contract MigrationsTest is BaseTest {
    TestAccount firstAccount;

    TestAccount secondAccount;

    uint256 followTokenIdV1;

    function beforeUpgrade() internal override {
        firstAccount = _loadAccountAs('FIRST_ACCOUNT');

        secondAccount = _loadAccountAs('SECOND_ACCOUNT');

        vm.prank(firstAccount.owner);
        followTokenIdV1 = IOldHub(address(hub)).follow(_toUint256Array(secondAccount.profileId), _toBytesArray(''))[0];
    }

    function setUp() public override {
        super.setUp();

        vm.prank(governance);
        hub.setMigrationAdmins(_toAddressArray(migrationAdmin), true);
    }

    function testCannotMigrateFollowIfAlreadyFollowing_byPublic() public onlyFork {
        vm.prank(firstAccount.owner);
        uint256 followTokenIdV2 = hub.follow(
            firstAccount.profileId,
            _toUint256Array(secondAccount.profileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];

        assertTrue(hub.isFollowing(firstAccount.profileId, secondAccount.profileId));

        FollowNFT followNFT = FollowNFT(hub.getProfile(secondAccount.profileId).followNFT);

        uint256 followTokenV1FollowerProfileId = followNFT.getFollowerProfileId(followTokenIdV1);
        uint256 followTokenV2FollowerProfileId = followNFT.getFollowerProfileId(followTokenIdV2);
        uint256 followTokenIdUsedByFirstAccount = followNFT.getFollowTokenId(firstAccount.profileId);
        uint256 originalFollowTimestampTokenV1 = followNFT.getOriginalFollowTimestamp(followTokenIdV1);
        uint256 originalFollowTimestampTokenV2 = followNFT.getOriginalFollowTimestamp(followTokenIdV2);

        assertEq(followTokenV1FollowerProfileId, 0);
        assertEq(followTokenV2FollowerProfileId, firstAccount.profileId);
        assertEq(followTokenIdUsedByFirstAccount, followTokenIdV2);
        assertEq(originalFollowTimestampTokenV1, 0);
        assertEq(originalFollowTimestampTokenV2, block.timestamp);

        vm.prank(firstAccount.owner);
        hub.batchMigrateFollows({
            followerProfileId: firstAccount.profileId,
            idsOfProfileFollowed: _toUint256Array(secondAccount.profileId),
            followTokenIds: _toUint256Array(followTokenIdV1)
        });

        // Migration did not take effect as it was already following, values are the same as before.
        assertEq(followNFT.getFollowerProfileId(followTokenIdV1), followTokenV1FollowerProfileId);
        assertEq(followNFT.getFollowerProfileId(followTokenIdV2), followTokenV2FollowerProfileId);
        assertEq(followNFT.getFollowTokenId(firstAccount.profileId), followTokenIdUsedByFirstAccount);
        assertEq(followNFT.getOriginalFollowTimestamp(followTokenIdV1), originalFollowTimestampTokenV1);
        assertEq(followNFT.getOriginalFollowTimestamp(followTokenIdV2), originalFollowTimestampTokenV2);
    }

    function testCannotMigrateFollowIfAlreadyFollowing_byAdmin() public onlyFork {
        vm.prank(firstAccount.owner);
        uint256 followTokenIdV2 = hub.follow(
            firstAccount.profileId,
            _toUint256Array(secondAccount.profileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];

        assertTrue(hub.isFollowing(firstAccount.profileId, secondAccount.profileId));

        FollowNFT followNFT = FollowNFT(hub.getProfile(secondAccount.profileId).followNFT);

        uint256 followTokenV1FollowerProfileId = followNFT.getFollowerProfileId(followTokenIdV1);
        uint256 followTokenV2FollowerProfileId = followNFT.getFollowerProfileId(followTokenIdV2);
        uint256 followTokenIdUsedByFirstAccount = followNFT.getFollowTokenId(firstAccount.profileId);
        uint256 originalFollowTimestampTokenV1 = followNFT.getOriginalFollowTimestamp(followTokenIdV1);
        uint256 originalFollowTimestampTokenV2 = followNFT.getOriginalFollowTimestamp(followTokenIdV2);

        assertEq(followTokenV1FollowerProfileId, 0);
        assertEq(followTokenV2FollowerProfileId, firstAccount.profileId);
        assertEq(followTokenIdUsedByFirstAccount, followTokenIdV2);
        assertEq(originalFollowTimestampTokenV1, 0);
        assertEq(originalFollowTimestampTokenV2, block.timestamp);

        vm.prank(migrationAdmin);
        hub.batchMigrateFollowers({
            followerProfileIds: _toUint256Array(firstAccount.profileId),
            idOfProfileFollowed: secondAccount.profileId,
            followTokenIds: _toUint256Array(followTokenIdV1)
        });

        // Migration did not take effect as it was already following, values are the same as before.
        assertEq(followNFT.getFollowerProfileId(followTokenIdV1), followTokenV1FollowerProfileId);
        assertEq(followNFT.getFollowerProfileId(followTokenIdV2), followTokenV2FollowerProfileId);
        assertEq(followNFT.getFollowTokenId(firstAccount.profileId), followTokenIdUsedByFirstAccount);
        assertEq(followNFT.getOriginalFollowTimestamp(followTokenIdV1), originalFollowTimestampTokenV1);
        assertEq(followNFT.getOriginalFollowTimestamp(followTokenIdV2), originalFollowTimestampTokenV2);
    }

    function testCannotMigrateFollowIfBlocked_byPublic() public onlyFork {
        vm.prank(secondAccount.owner);
        hub.setBlockStatus(secondAccount.profileId, _toUint256Array(firstAccount.profileId), _toBoolArray(true));

        FollowNFT followNFT = FollowNFT(hub.getProfile(secondAccount.profileId).followNFT);

        uint256 followTokenV1FollowerProfileId = followNFT.getFollowerProfileId(followTokenIdV1);
        uint256 followTokenIdUsedByFirstAccount = followNFT.getFollowTokenId(firstAccount.profileId);
        uint256 originalFollowTimestampTokenV1 = followNFT.getOriginalFollowTimestamp(followTokenIdV1);

        assertEq(followTokenV1FollowerProfileId, 0);
        assertEq(followTokenIdUsedByFirstAccount, 0);
        assertEq(originalFollowTimestampTokenV1, 0);

        vm.prank(firstAccount.owner);
        hub.batchMigrateFollows({
            followerProfileId: firstAccount.profileId,
            idsOfProfileFollowed: _toUint256Array(secondAccount.profileId),
            followTokenIds: _toUint256Array(followTokenIdV1)
        });

        // Migration did not take effect as it was blocked, values are the same as before.
        assertEq(followNFT.getFollowerProfileId(followTokenIdV1), followTokenV1FollowerProfileId);
        assertEq(followNFT.getFollowTokenId(firstAccount.profileId), followTokenIdUsedByFirstAccount);
        assertEq(followNFT.getOriginalFollowTimestamp(followTokenIdV1), originalFollowTimestampTokenV1);
    }

    function testCannotMigrateFollowIfBlocked_byAdmin() public onlyFork {
        vm.prank(secondAccount.owner);
        hub.setBlockStatus(secondAccount.profileId, _toUint256Array(firstAccount.profileId), _toBoolArray(true));

        FollowNFT followNFT = FollowNFT(hub.getProfile(secondAccount.profileId).followNFT);

        uint256 followTokenV1FollowerProfileId = followNFT.getFollowerProfileId(followTokenIdV1);
        uint256 followTokenIdUsedByFirstAccount = followNFT.getFollowTokenId(firstAccount.profileId);
        uint256 originalFollowTimestampTokenV1 = followNFT.getOriginalFollowTimestamp(followTokenIdV1);

        assertEq(followTokenV1FollowerProfileId, 0);
        assertEq(followTokenIdUsedByFirstAccount, 0);
        assertEq(originalFollowTimestampTokenV1, 0);

        vm.prank(migrationAdmin);
        hub.batchMigrateFollowers({
            followerProfileIds: _toUint256Array(firstAccount.profileId),
            idOfProfileFollowed: secondAccount.profileId,
            followTokenIds: _toUint256Array(followTokenIdV1)
        });

        // Migration did not take effect as it was blocked, values are the same as before.
        assertEq(followNFT.getFollowerProfileId(followTokenIdV1), followTokenV1FollowerProfileId);
        assertEq(followNFT.getFollowTokenId(firstAccount.profileId), followTokenIdUsedByFirstAccount);
        assertEq(followNFT.getOriginalFollowTimestamp(followTokenIdV1), originalFollowTimestampTokenV1);
    }

    function testCannotMigrateFollowIfSelfFollow_byPublic() public onlyFork {
        FollowNFT followNFT = FollowNFT(hub.getProfile(secondAccount.profileId).followNFT);
        vm.prank(firstAccount.owner);
        followNFT.transferFrom(firstAccount.owner, secondAccount.owner, followTokenIdV1);
        assertEq(followNFT.ownerOf(followTokenIdV1), secondAccount.owner);

        uint256 followTokenV1FollowerProfileId = followNFT.getFollowerProfileId(followTokenIdV1);
        uint256 followTokenIdUsedByFirstAccount = followNFT.getFollowTokenId(firstAccount.profileId);
        uint256 originalFollowTimestampTokenV1 = followNFT.getOriginalFollowTimestamp(followTokenIdV1);

        assertEq(followTokenV1FollowerProfileId, 0);
        assertEq(followTokenIdUsedByFirstAccount, 0);
        assertEq(originalFollowTimestampTokenV1, 0);

        vm.prank(secondAccount.owner);
        hub.batchMigrateFollows({
            followerProfileId: secondAccount.profileId,
            idsOfProfileFollowed: _toUint256Array(secondAccount.profileId),
            followTokenIds: _toUint256Array(followTokenIdV1)
        });

        // Migration did not take effect as self-follows are no longer valid, values are the same as before.
        assertEq(followNFT.getFollowerProfileId(followTokenIdV1), followTokenV1FollowerProfileId);
        assertEq(followNFT.getFollowTokenId(firstAccount.profileId), followTokenIdUsedByFirstAccount);
        assertEq(followNFT.getOriginalFollowTimestamp(followTokenIdV1), originalFollowTimestampTokenV1);
    }

    function testCannotMigrateFollowIfSelfFollow_byAdmin() public onlyFork {
        FollowNFT followNFT = FollowNFT(hub.getProfile(secondAccount.profileId).followNFT);
        vm.prank(firstAccount.owner);
        followNFT.transferFrom(firstAccount.owner, secondAccount.owner, followTokenIdV1);
        assertEq(followNFT.ownerOf(followTokenIdV1), secondAccount.owner);

        uint256 followTokenV1FollowerProfileId = followNFT.getFollowerProfileId(followTokenIdV1);
        uint256 followTokenIdUsedByFirstAccount = followNFT.getFollowTokenId(firstAccount.profileId);
        uint256 originalFollowTimestampTokenV1 = followNFT.getOriginalFollowTimestamp(followTokenIdV1);

        assertEq(followTokenV1FollowerProfileId, 0);
        assertEq(followTokenIdUsedByFirstAccount, 0);
        assertEq(originalFollowTimestampTokenV1, 0);

        vm.prank(migrationAdmin);
        hub.batchMigrateFollowers({
            followerProfileIds: _toUint256Array(secondAccount.profileId),
            idOfProfileFollowed: secondAccount.profileId,
            followTokenIds: _toUint256Array(followTokenIdV1)
        });

        // Migration did not take effect as self-follows are no longer valid, values are the same as before.
        assertEq(followNFT.getFollowerProfileId(followTokenIdV1), followTokenV1FollowerProfileId);
        assertEq(followNFT.getFollowTokenId(firstAccount.profileId), followTokenIdUsedByFirstAccount);
        assertEq(followNFT.getOriginalFollowTimestamp(followTokenIdV1), originalFollowTimestampTokenV1);
    }

    function testCannotMigrateFollowsIfNotProfileOwner(address sender) public onlyFork {
        vm.assume(sender != address(0));
        vm.assume(sender != proxyAdmin);
        vm.assume(sender != firstAccount.owner);

        FollowNFT followNFT = FollowNFT(hub.getProfile(secondAccount.profileId).followNFT);

        uint256 followTokenV1FollowerProfileId = followNFT.getFollowerProfileId(followTokenIdV1);
        uint256 followTokenIdUsedByFirstAccount = followNFT.getFollowTokenId(firstAccount.profileId);
        uint256 originalFollowTimestampTokenV1 = followNFT.getOriginalFollowTimestamp(followTokenIdV1);

        assertEq(followTokenV1FollowerProfileId, 0);
        assertEq(followTokenIdUsedByFirstAccount, 0);
        assertEq(originalFollowTimestampTokenV1, 0);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        vm.prank(sender);
        hub.batchMigrateFollows({
            followerProfileId: firstAccount.profileId,
            idsOfProfileFollowed: _toUint256Array(secondAccount.profileId),
            followTokenIds: _toUint256Array(followTokenIdV1)
        });
    }

    function testCannotMigrateFollowersIfNotMigrationAdmin(address sender) public onlyFork {
        vm.assume(sender != address(0));
        vm.assume(sender != proxyAdmin);
        vm.assume(sender != migrationAdmin);

        FollowNFT followNFT = FollowNFT(hub.getProfile(secondAccount.profileId).followNFT);

        uint256 followTokenV1FollowerProfileId = followNFT.getFollowerProfileId(followTokenIdV1);
        uint256 followTokenIdUsedByFirstAccount = followNFT.getFollowTokenId(firstAccount.profileId);
        uint256 originalFollowTimestampTokenV1 = followNFT.getOriginalFollowTimestamp(followTokenIdV1);

        assertEq(followTokenV1FollowerProfileId, 0);
        assertEq(followTokenIdUsedByFirstAccount, 0);
        assertEq(originalFollowTimestampTokenV1, 0);

        vm.expectRevert(Errors.NotMigrationAdmin.selector);
        vm.prank(sender);
        hub.batchMigrateFollowers({
            followerProfileIds: _toUint256Array(firstAccount.profileId),
            idOfProfileFollowed: secondAccount.profileId,
            followTokenIds: _toUint256Array(followTokenIdV1)
        });
    }
}

contract MigrationsTestHardcoded is BaseTest {
    using stdJson for string;

    uint256 internal constant LENS_PROTOCOL_PROFILE_ID = 1;
    uint256 internal constant ENUMERABLE_GET_FIRST_PROFILE = 0;

    address owner = address(0x087E4);

    uint256[] followerProfileIds = new uint256[](10);

    function beforeUpgrade() internal override {
        // TODO: This can be moved and split
        uint256 idOfProfileFollowed = 8;
        address followNFTAddress = IOldHub(address(hub)).getProfile(idOfProfileFollowed).followNFT;
        for (uint256 i = 0; i < 10; i++) {
            uint256 followTokenId = i + 1;
            address followerOwner = IERC721(followNFTAddress).ownerOf(followTokenId);
            uint256 followerProfileId = IERC721Enumerable(address(hub)).tokenOfOwnerByIndex(
                followerOwner,
                ENUMERABLE_GET_FIRST_PROFILE
            );
            followerProfileIds[i] = followerProfileId;
        }
    }

    function setUp() public override {
        super.setUp();

        // This should be tested only on Fork
        if (!fork) return;

        vm.prank(governance);
        hub.setMigrationAdmins(_toAddressArray(migrationAdmin), true);
    }

    function testProfileMigration() public onlyFork {
        uint256[] memory profileIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            profileIds[i] = i + 1;
        }
        hub.batchMigrateProfiles(profileIds);
    }

    function testFollowMigration() public onlyFork {
        uint256 idOfProfileFollowed = 8;

        uint256[] memory followTokenIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            uint256 followTokenId = i + 1;

            followTokenIds[i] = followTokenId;
        }

        vm.prank(migrationAdmin);
        hub.batchMigrateFollowers(followerProfileIds, idOfProfileFollowed, followTokenIds);
    }

    function testFollowMigration_byHubFollow() public onlyFork {
        uint256 followerProfileId = 8;

        uint256[] memory idsOfProfilesToFollow = new uint256[](1);
        idsOfProfilesToFollow[0] = 92973;

        bytes[] memory datas = new bytes[](1);
        datas[0] = '';

        uint256[] memory followTokenIds = new uint256[](1);
        followTokenIds[0] = 1;

        vm.prank(hub.ownerOf(followerProfileId));
        hub.follow(followerProfileId, idsOfProfilesToFollow, followTokenIds, datas);

        address targetFollowNFT = hub.getProfile(idsOfProfilesToFollow[0]).followNFT;

        vm.prank(hub.ownerOf(followerProfileId));
        FollowNFT(targetFollowNFT).unwrap(followTokenIds[0]);
    }
}
