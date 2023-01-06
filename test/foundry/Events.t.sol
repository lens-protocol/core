// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

import {Events} from 'contracts/libraries/Events.sol';
import {MockFollowModule} from 'contracts/mocks/MockFollowModule.sol';
import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

contract EventTest is BaseTest {
    address profileOwnerTwo = address(0x2222);
    address mockFollowModule;

    function setUp() public override {
        TestSetup.setUp();
        mockFollowModule = address(new MockFollowModule());
        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);
    }

    // MISC

    function testProxyInitEmitsExpectedEvents() public {
        // Events to detect on proxy init:
        // Upgraded
        // AdminChanged
        // GovernanceSet
        // StateSet
        // BaseInitialized
    }

    // HUB GOVERNANCE

    function testGovernanceEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.GovernanceSet(governance, governance, me, block.timestamp);
        hub.setGovernance(me);
    }

    function testEmergencyAdminChangeEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.EmergencyAdminSet(governance, address(0), me, block.timestamp);
        hub.setEmergencyAdmin(me);
    }

    function testProtocolStateChangeByGovEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(
            governance,
            DataTypes.ProtocolState.Unpaused,
            DataTypes.ProtocolState.Paused,
            block.timestamp
        );
        hub.setState(DataTypes.ProtocolState.Paused);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(
            governance,
            DataTypes.ProtocolState.Paused,
            DataTypes.ProtocolState.PublishingPaused,
            block.timestamp
        );
        hub.setState(DataTypes.ProtocolState.PublishingPaused);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(
            governance,
            DataTypes.ProtocolState.PublishingPaused,
            DataTypes.ProtocolState.Unpaused,
            block.timestamp
        );
        hub.setState(DataTypes.ProtocolState.Unpaused);
    }

    function testProtocolStateChangeByEmergencyAdminEmitsExpectedEvents() public {
        vm.prank(governance);
        hub.setEmergencyAdmin(profileOwner);

        vm.prank(profileOwner);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(
            profileOwner,
            DataTypes.ProtocolState.Unpaused,
            DataTypes.ProtocolState.PublishingPaused,
            block.timestamp
        );
        hub.setState(DataTypes.ProtocolState.PublishingPaused);

        vm.prank(profileOwner);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(
            profileOwner,
            DataTypes.ProtocolState.PublishingPaused,
            DataTypes.ProtocolState.Paused,
            block.timestamp
        );
        hub.setState(DataTypes.ProtocolState.Paused);
    }

    function testFollowModuleWhitelistEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.FollowModuleWhitelisted(me, true, block.timestamp);
        hub.whitelistFollowModule(me, true);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.FollowModuleWhitelisted(me, false, block.timestamp);
        hub.whitelistFollowModule(me, false);
    }

    function testReferenceModuleWhitelistEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ReferenceModuleWhitelisted(me, true, block.timestamp);
        hub.whitelistReferenceModule(me, true);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ReferenceModuleWhitelisted(me, false, block.timestamp);
        hub.whitelistReferenceModule(me, false);
    }

    function testCollectModuleWhitelistEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.CollectModuleWhitelisted(me, true, block.timestamp);
        hub.whitelistCollectModule(me, true);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.CollectModuleWhitelisted(me, false, block.timestamp);
        hub.whitelistCollectModule(me, false);
    }

    // HUB INTERACTION

    function testProfileCreationEmitsExpectedEvents() public {
        mockCreateProfileData.to = profileOwnerTwo;
        vm.prank(governance);
        hub.whitelistProfileCreator(profileOwnerTwo, true);
        vm.prank(profileOwnerTwo);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ProfileCreated(
            2,
            profileOwnerTwo,
            profileOwnerTwo,
            mockCreateProfileData.imageURI,
            mockCreateProfileData.followModule,
            '',
            mockCreateProfileData.followNFTURI,
            block.timestamp
        );
        // TODO also check transfer event - not finding on OZ interfaces
        // vm.expectEmit(true, true, true, true, address(hub));
        // emit IERC721Enumerable.Transfer(address(0), profileOwnerTwo, 2);
        hub.createProfile(mockCreateProfileData);
    }

    function testProfileCreationForOtherUserEmitsExpectedEvents() public {
        mockCreateProfileData.to = profileOwnerTwo;
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ProfileCreated(
            2,
            me,
            profileOwnerTwo,
            mockCreateProfileData.imageURI,
            mockCreateProfileData.followModule,
            '',
            mockCreateProfileData.followNFTURI,
            block.timestamp
        );
        // TODO also check transfer event - not finding on OZ interfaces
        // vm.expectEmit(true, true, true, true, address(hub));
        // emit IERC721Enumerable.Transfer(address(0), profileOwnerTwo, 2);
        hub.createProfile(mockCreateProfileData);
    }

    function testSettingFollowModuleEmitsExpectedEvents() public {
        mockCreateProfileData.to = profileOwnerTwo;
        uint expectedProfileId = 2;
        hub.createProfile(mockCreateProfileData);
        vm.prank(profileOwnerTwo);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.FollowModuleSet(
            expectedProfileId,
            address(mockFollowModule),
            '',
            block.timestamp
        );
        hub.setFollowModule(expectedProfileId, address(mockFollowModule), abi.encode(1));
    }

    function testSettingDispatcherEmitsExpectedEvents() public {
        mockCreateProfileData.to = profileOwnerTwo;
        uint expectedProfileId = 2;
        hub.createProfile(mockCreateProfileData);
        vm.prank(profileOwnerTwo);
        vm.expectEmit(true, true, false, true, address(hub));
        emit Events.DispatcherSet(
            expectedProfileId,
            me,
            block.timestamp
        );
        hub.setDispatcher(expectedProfileId, me);
    }

    function testPostingEmitsExpectedEvents() public {
        vm.prank(profileOwner);
        vm.expectEmit(true, true, false, true, address(hub));
        emit Events.PostCreated(
            newProfileId,
            1,
            mockPostData.contentURI,
            mockPostData.collectModule,
            "",
            mockPostData.referenceModule,
            "",
            block.timestamp
        );
        hub.post(mockPostData);
    }

    function testCommentingEmitsExpectedEvents() public {}

    function testMirroringEmitsExpectedEvents() public {}

    function testFollowingEmitsExpectedEvents() public {}

    function testCollectingEmitsExpectedEvents() public {}

    function testCollectingFromMirrorEmitsExpectedEvents() public {}

    // MODULE GLOBALS GOVERNANCE

    function testGovernanceChangeEmitsExpectedEvents() public {}

    function testTreasuryChangeEmitsExpectedEvents() public {}

    function testTreasuryFeeChangeEmitsExpectedEvents() public {}

    function testCurrencyWhitelistEmitsExpectedEvents() public {}
}
