// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

import {Events} from 'contracts/libraries/Events.sol';
import {MockFollowModule} from 'contracts/mocks/MockFollowModule.sol';

contract EventTest is BaseTest {
    address profileOwnerTwo = address(0x2222);
    address mockFollowModule;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

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
        uint256 expectedTokenId = 2;
        mockCreateProfileData.to = profileOwnerTwo;
        vm.prank(governance);
        hub.whitelistProfileCreator(profileOwnerTwo, true);
        vm.prank(profileOwnerTwo);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Transfer(address(0), profileOwnerTwo, expectedTokenId);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ProfileCreated(
            expectedTokenId,
            profileOwnerTwo,
            profileOwnerTwo,
            mockCreateProfileData.imageURI,
            mockCreateProfileData.followModule,
            '',
            mockCreateProfileData.followNFTURI,
            block.timestamp
        );
        hub.createProfile(mockCreateProfileData);
    }

    function testProfileCreationForOtherUserEmitsExpectedEvents() public {
        uint256 expectedTokenId = 2;
        mockCreateProfileData.to = profileOwnerTwo;
        vm.expectEmit(true, true, true, true, address(hub));
        emit Transfer(address(0), profileOwnerTwo, expectedTokenId);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ProfileCreated(
            expectedTokenId,
            me,
            profileOwnerTwo,
            mockCreateProfileData.imageURI,
            mockCreateProfileData.followModule,
            '',
            mockCreateProfileData.followNFTURI,
            block.timestamp
        );
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
        emit Events.DispatcherSet(expectedProfileId, me, block.timestamp);
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
            '',
            mockPostData.referenceModule,
            '',
            block.timestamp
        );
        hub.post(mockPostData);
    }

    function testCommentingEmitsExpectedEvents() public {
        vm.startPrank(profileOwner);
        hub.post(mockPostData);
        vm.expectEmit(true, true, false, true, address(hub));
        emit Events.CommentCreated(
            newProfileId,
            2,
            mockCommentData.contentURI,
            newProfileId,
            1,
            '',
            mockCommentData.collectModule,
            '',
            mockCommentData.referenceModule,
            '',
            block.timestamp
        );
        hub.comment(mockCommentData);
        vm.stopPrank();
    }

    function testMirroringEmitsExpectedEvents() public {
        vm.startPrank(profileOwner);
        hub.post(mockPostData);
        vm.expectEmit(true, true, false, true, address(hub));
        emit Events.MirrorCreated(
            newProfileId,
            2,
            newProfileId,
            1,
            '',
            mockMirrorData.referenceModule,
            '',
            block.timestamp
        );
        hub.mirror(mockMirrorData);
        vm.stopPrank();
    }

    function testFollowingEmitsExpectedEvents() public {
        uint256[] memory followTargetIds = new uint256[](1);
        followTargetIds[0] = 1;
        bytes[] memory followDatas = new bytes[](1);
        followDatas[0] = '';
        address expectedFollowNFTAddress = utils.predictContractAddress(address(hub), 0);

        vm.prank(profileOwner);
        vm.expectEmit(true, true, false, true, address(hub));
        emit Events.FollowNFTDeployed(
            newProfileId,
            expectedFollowNFTAddress,
            block.timestamp
        );

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.FollowNFTTransferred(1, 1, address(0), profileOwner, block.timestamp);

        vm.expectEmit(true, true, true, true, expectedFollowNFTAddress);
        emit Transfer(address(0), profileOwner, 1);

        vm.expectEmit(true, true, false, true, address(hub));
        emit Events.Followed(profileOwner, followTargetIds, followDatas, block.timestamp);
        
        hub.follow(profileOwner, followTargetIds, followDatas);
    }

    function testCollectingEmitsExpectedEvents() public {
        // TODO
    }

    function testCollectingFromMirrorEmitsExpectedEvents() public {
        // TODO
    }

    // MODULE GLOBALS GOVERNANCE

    function testGovernanceChangeEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(moduleGlobals));
        emit Events.ModuleGlobalsGovernanceSet(governance, me, block.timestamp);
        moduleGlobals.setGovernance(me);
    }

    function testTreasuryChangeEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, false, true, address(moduleGlobals));
        emit Events.ModuleGlobalsTreasurySet(treasury, me, block.timestamp);
        moduleGlobals.setTreasury(me);
    }

    function testTreasuryFeeChangeEmitsExpectedEvents() public {
        uint16 newFee = 1;
        vm.prank(governance);
        vm.expectEmit(true, true, false, true, address(moduleGlobals));
        emit Events.ModuleGlobalsTreasuryFeeSet(TREASURY_FEE_BPS, newFee, block.timestamp);
        moduleGlobals.setTreasuryFee(newFee);
    }

    function testCurrencyWhitelistEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(moduleGlobals));
        emit Events.ModuleGlobalsCurrencyWhitelisted(me, false, true, block.timestamp);
        moduleGlobals.whitelistCurrency(me, true);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(moduleGlobals));
        emit Events.ModuleGlobalsCurrencyWhitelisted(me, true, false, block.timestamp);
        moduleGlobals.whitelistCurrency(me, false);
    }
}
