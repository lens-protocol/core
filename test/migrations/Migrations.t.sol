// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import {ForkManagement} from 'test/helpers/ForkManagement.sol';
import {LegacyCollectNFT} from 'contracts/misc/LegacyCollectNFT.sol';
import {LensHub} from 'contracts/LensHub.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {LensHandles} from 'contracts/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/namespaces/TokenHandleRegistry.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import {LensHubInitializable} from 'contracts/misc/LensHubInitializable.sol';
import {MigrationLib} from 'contracts/libraries/MigrationLib.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import 'test/base/BaseTest.t.sol';

contract MigrationsTest is BaseTest {
    TestAccount firstAccount;

    TestAccount secondAccount;

    uint256 followTokenIdV1;

    function beforeUpgrade() internal override {
        console.log('beforeUpgrade setup');
        firstAccount = _loadAccountAs('FIRST_ACCOUNT');

        secondAccount = _loadAccountAs('SECOND_ACCOUNT');

        vm.prank(firstAccount.owner);
        // TODO: What if already following...?
        followTokenIdV1 = IOldHub(address(hub)).follow(_toUint256Array(secondAccount.profileId), _toBytesArray(''))[0];
    }

    function setUp() public override {
        super.setUp();

        if (!fork) {
            return;
        }

        if (firstAccount.profileId == 0) {
            firstAccount = _loadAccountAs('FIRST_ACCOUNT');
        }

        if (secondAccount.profileId == 0) {
            secondAccount = _loadAccountAs('SECOND_ACCOUNT');
        }

        if (forkVersion == 2) {
            followTokenIdV1 = vm.envOr({name: 'FORK_TEST__FIRST_ACCOUNT__FOLLOW_TOKEN_ID', defaultValue: uint256(0)});
        }
        assertTrue(followTokenIdV1 != 0, 'Follow token id v1 is still zero, after everything we tried........');

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

        address followNFTOwner = followNFT.ownerOf(followTokenIdV1);
        vm.prank(followNFTOwner);
        followNFT.transferFrom(followNFTOwner, secondAccount.owner, followTokenIdV1);
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
        address followNFTOwner = followNFT.ownerOf(followTokenIdV1);
        vm.prank(followNFTOwner);
        followNFT.transferFrom(followNFTOwner, secondAccount.owner, followTokenIdV1);
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
        if (forkVersion == 2 || block.chainid != 137) {
            return;
        }

        uint256[] memory profileIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            profileIds[i] = i + 1;
        }
        hub.batchMigrateProfiles(profileIds);
    }

    function testFollowMigration() public onlyFork {
        if (forkVersion == 2 || block.chainid != 137) {
            return;
        }

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
        if (forkVersion == 2 || block.chainid != 137) {
            return;
        }

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

contract MigrationsTestNonFork is BaseTest {
    address followerProfileOwner;
    uint256 followerProfileId;

    address ownerOfProfileFollowed;
    uint256 idOfProfileFollowed;

    uint256 followTokenId;

    FollowNFT mockFollowNFT;

    function setUp() public override {
        super.setUp();

        followerProfileOwner = makeAddr('followerProfileOwner');
        followerProfileId = _createProfile(followerProfileOwner);

        ownerOfProfileFollowed = makeAddr('ownerOfProfileFollowed');
        idOfProfileFollowed = _createProfile(ownerOfProfileFollowed);

        followTokenId = 69;

        mockFollowNFT = FollowNFT(makeAddr('mockFollowNFT'));

        vm.prank(governance);
        hub.setMigrationAdmins(_toAddressArray(migrationAdmin), true);
    }

    function testCannotSetMigrationAdmins_IfNotGovernance() public notFork {
        address otherAddress = makeAddr('otherAddress');

        vm.expectRevert(Errors.NotGovernance.selector);

        vm.prank(otherAddress);
        hub.setMigrationAdmins(_toAddressArray(otherAddress), true);
    }

    function testSetMigrationAdmins() public notFork {
        address newAdmin = makeAddr('newAdmin');
        vm.prank(governance);
        hub.setMigrationAdmins(_toAddressArray(newAdmin), true);
    }

    function _mockTokenOwner(uint256 profileId, address owner) internal {
        bytes32 profileOwnerSlot = keccak256(abi.encode(profileId, StorageLib.TOKEN_DATA_MAPPING_SLOT));
        vm.store(address(hub), profileOwnerSlot, bytes32(uint256(uint160(owner))));
    }

    function _mockProfileDeprecatedHandle(uint256 profileId, string memory handle) internal {
        bytes32 profileSlot = keccak256(abi.encode(profileId, StorageLib.PROFILES_MAPPING_SLOT));

        uint256 handleOffset = 3;
        bytes32 handleSlot = bytes32(uint256(profileSlot) + handleOffset);
        bytes32 bytes32Handle = _shortStringToBytes32Storage(handle);

        vm.store(address(hub), handleSlot, bytes32Handle);
    }

    function _mockProfileFollowNFT(uint256 profileId, address followNFTAddress) internal {
        bytes32 profileSlot = keccak256(abi.encode(profileId, StorageLib.PROFILES_MAPPING_SLOT));

        uint256 followNFTOffset = 2;
        bytes32 followNFTSlot = bytes32(uint256(profileSlot) + followNFTOffset);

        vm.store(address(hub), followNFTSlot, bytes32(uint256(uint160(followNFTAddress))));
    }

    function _shortStringToBytes32Storage(string memory str) internal returns (bytes32) {
        uint256 length = bytes(str).length;
        require(length < 32, 'Storing storage strings supported up to 31 bytes');
        return bytes32(abi.encodePacked(str)) | bytes32(length * 2);
    }
}
