// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {MockDeprecatedCollectModule} from 'test/mocks/MockDeprecatedCollectModule.sol';

contract LensHubEventHooksTest is BaseTest {
    TestAccount follower;
    uint256 defaultPubId;

    function setUp() public override {
        super.setUp();

        /// Follow preparation:

        follower = _loadAccountAs('FOLLOWER');

        vm.prank(follower.owner);
        hub.follow(
            follower.profileId,
            _toUint256Array(defaultAccount.profileId),
            _toUint256Array(0),
            _toBytesArray(abi.encode(false))
        );

        assertTrue(hub.isFollowing(follower.profileId, defaultAccount.profileId));

        /// Collect preparation:
        MockDeprecatedCollectModule mockDeprecatedCollectModule = new MockDeprecatedCollectModule();

        // Create a V1 pub
        vm.prank(defaultAccount.owner);
        defaultPubId = hub.post(_getDefaultPostParams());

        _toLegacyV1Pub(defaultAccount.profileId, defaultPubId, address(0), address(mockDeprecatedCollectModule));

        Types.LegacyCollectParams memory defaultCollectParams = Types.LegacyCollectParams({
            publicationCollectedProfileId: defaultAccount.profileId,
            publicationCollectedId: defaultPubId,
            collectorProfileId: defaultAccount.profileId,
            referrerProfileId: 0,
            referrerPubId: 0,
            collectModuleData: abi.encode(true)
        });

        vm.prank(defaultAccount.owner);
        hub.collectLegacy(defaultCollectParams);
    }

    function testCannot_EmitUnfollowedEvent_ifNotFollowNFTOfFollowedProfile(
        address randomAddress,
        address transactionExecutor
    ) public {
        vm.assume(randomAddress != address(0));
        address followNFT = hub.getProfile(defaultAccount.profileId).followNFT;
        vm.assume(randomAddress != followNFT);
        address proxyAdmin = address(uint160(uint256(vm.load(address(hub), ADMIN_SLOT))));
        vm.assume(randomAddress != proxyAdmin);

        vm.expectRevert(Errors.CallerNotFollowNFT.selector);

        vm.prank(randomAddress);
        hub.emitUnfollowedEvent(follower.profileId, defaultAccount.profileId, transactionExecutor);
    }

    function testEmitUnfollowedEvent_ifFollowNFTOfFollowedProfile(address transactionExecutor) public {
        address followNFT = hub.getProfile(defaultAccount.profileId).followNFT;

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.Unfollowed(follower.profileId, defaultAccount.profileId, transactionExecutor, block.timestamp);

        vm.prank(followNFT);
        hub.emitUnfollowedEvent(follower.profileId, defaultAccount.profileId, transactionExecutor);
    }

    function testEmitCollectNFTTransferEvent_ForRealThisTime(uint256 collectNFTId, address from, address to) public {
        address collectNFT = hub.getPublication(defaultAccount.profileId, defaultPubId).__DEPRECATED__collectNFT;

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.CollectNFTTransferred(
            defaultAccount.profileId,
            defaultPubId,
            collectNFTId,
            from,
            to,
            block.timestamp
        );

        vm.prank(collectNFT);
        hub.emitCollectNFTTransferEvent(defaultAccount.profileId, defaultPubId, collectNFTId, from, to);
    }

    function testCannot_EmitCollectNFTTransferEvent_IfNotCollectNFTOfPublication(address randomAddress) public {
        vm.assume(randomAddress != address(0));
        address collectNFT = hub.getPublication(defaultAccount.profileId, defaultPubId).__DEPRECATED__collectNFT;
        vm.assume(randomAddress != collectNFT);
        address proxyAdmin = address(uint160(uint256(vm.load(address(hub), ADMIN_SLOT))));
        vm.assume(randomAddress != proxyAdmin);

        vm.expectRevert(Errors.CallerNotCollectNFT.selector);

        vm.prank(randomAddress);
        hub.emitCollectNFTTransferEvent(defaultAccount.profileId, defaultPubId, 0, address(0), address(0));
    }
}
