// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

import {Events} from 'contracts/libraries/Events.sol';
import {MockFollowModule} from 'contracts/mocks/MockFollowModule.sol';

contract EventTest is BaseTest {
    address profileOwnerTwo = address(0x2222);
    address mockFollowModule;

    // Non-Lens Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Upgraded(address indexed implementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    function setUp() public override {
        TestSetup.setUp();
        mockFollowModule = address(new MockFollowModule());
        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);
    }

    function predictContractAddress(address user, uint256 distanceFromCurrentNonce)
        internal
        returns (address)
    {
        return computeCreateAddress(user, vm.getNonce(user) + distanceFromCurrentNonce);
    }

    // MISC

    function testProxyInitEmitsExpectedEvents() public {
        string memory expectedNFTName = 'Lens Protocol Profiles';
        string memory expectedNFTSymbol = 'LPP';

        vm.startPrank(deployer);

        address followNFTAddr = predictContractAddress(deployer, 1);
        address collectNFTAddr = predictContractAddress(deployer, 2);
        hubProxyAddr = predictContractAddress(deployer, 3);

        // Deploy implementation contracts.
        hubImpl = new LensHub(followNFTAddr, collectNFTAddr);
        followNFT = new FollowNFT(hubProxyAddr);
        collectNFT = new CollectNFT(hubProxyAddr);

        // Deploy and initialize proxy.
        bytes memory initData = abi.encodeCall(
            hubImpl.initialize,
            (expectedNFTName, expectedNFTSymbol, governance)
        );

        // Event tests
        // Upgraded
        vm.expectEmit(true, false, false, true, hubProxyAddr);
        emit Upgraded(address(hubImpl));

        // BaseInitialized
        vm.expectEmit(false, false, false, true, hubProxyAddr);
        emit Events.BaseInitialized(expectedNFTName, expectedNFTSymbol, block.timestamp);

        // StateSet
        vm.expectEmit(true, true, true, true, hubProxyAddr);
        emit Events.StateSet(
            deployer,
            DataTypes.ProtocolState.Unpaused,
            DataTypes.ProtocolState.Paused,
            block.timestamp
        );

        // GovernanceSet
        vm.expectEmit(true, true, true, true, hubProxyAddr);
        emit Events.GovernanceSet(deployer, address(0), governance, block.timestamp);

        // AdminChanged
        vm.expectEmit(false, false, false, true, hubProxyAddr);
        emit AdminChanged(address(0), deployer);

        hubAsProxy = new TransparentUpgradeableProxy(address(hubImpl), deployer, initData);
        vm.stopPrank();
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
        uint256 expectedProfileId = 2;
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
        emit Events.MirrorCreated({
            profileId: newProfileId,
            pubId: 2,
            profileIdPointed: newProfileId,
            pubIdPointed: 1,
            referenceModuleData: '',
            timestamp: block.timestamp
        });
        hub.mirror(mockMirrorData);
        vm.stopPrank();
    }

    function testCollectingEmitsExpectedEvents() public {
        vm.startPrank(profileOwner);
        hub.post(mockPostData);

        uint256 expectedPubId = 1;
        address expectedCollectNFTAddress = predictContractAddress(address(hub), 0);
        string memory expectedNFTName = '1-Collect-1';
        string memory expectedNFTSymbol = '1-Cl-1';

        // BaseInitialized
        vm.expectEmit(true, true, true, true, expectedCollectNFTAddress);
        emit Events.BaseInitialized(expectedNFTName, expectedNFTSymbol, block.timestamp);

        // CollectNFTInitialized
        vm.expectEmit(true, true, true, true, expectedCollectNFTAddress);
        emit Events.CollectNFTInitialized(newProfileId, expectedPubId, block.timestamp);

        // CollectNFTDeployed
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.CollectNFTDeployed(
            newProfileId,
            expectedPubId,
            expectedCollectNFTAddress,
            block.timestamp
        );

        // CollectNFTTransferred
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.CollectNFTTransferred(
            newProfileId,
            expectedPubId,
            1, // collect nft id
            address(0),
            profileOwner,
            block.timestamp
        );

        // Transfer
        vm.expectEmit(true, true, true, true, expectedCollectNFTAddress);
        emit Transfer(address(0), profileOwner, 1);

        // Collected
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.Collected(
            newProfileId, // TODO: Replace with proper ProfileID
            newProfileId,
            expectedPubId,
            newProfileId,
            expectedPubId,
            '',
            block.timestamp
        );

        // TODO: Replace with proper ProfileID
        hub.collect(newProfileId, newProfileId, expectedPubId, '');
        vm.stopPrank();
    }

    function testCollectingFromMirrorEmitsExpectedEvents() public {
        uint256[] memory followTargetIds = new uint256[](1);
        followTargetIds[0] = 1;
        bytes[] memory followDatas = new bytes[](1);
        followDatas[0] = '';
        uint256 expectedPubId = 1;
        address expectedCollectNFTAddress = predictContractAddress(address(hub), 0);
        string memory expectedNFTName = '1-Collect-1';
        string memory expectedNFTSymbol = '1-Cl-1';

        vm.startPrank(profileOwner);
        hub.post(mockPostData);
        hub.mirror(mockMirrorData);

        // BaseInitialized
        vm.expectEmit(false, false, false, true, expectedCollectNFTAddress);
        emit Events.BaseInitialized(expectedNFTName, expectedNFTSymbol, block.timestamp);

        // CollectNFTInitialized
        vm.expectEmit(true, true, true, true, expectedCollectNFTAddress);
        emit Events.CollectNFTInitialized(newProfileId, expectedPubId, block.timestamp);

        // CollectNFTDeployed
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.CollectNFTDeployed(
            newProfileId,
            expectedPubId,
            expectedCollectNFTAddress,
            block.timestamp
        );

        // CollectNFTTransferred
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.CollectNFTTransferred(
            newProfileId,
            expectedPubId,
            1, // collect nft id
            address(0),
            profileOwner,
            block.timestamp
        );

        // Transfer
        vm.expectEmit(true, true, true, true, expectedCollectNFTAddress);
        emit Transfer(address(0), profileOwner, 1);

        // Collected
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.Collected(
            newProfileId, // TODO: Replace with proper ProfileID
            newProfileId,
            expectedPubId,
            newProfileId,
            expectedPubId,
            '',
            block.timestamp
        );

        // TODO: Replace with proper ProfileID
        hub.collect(newProfileId, 1, expectedPubId, '');
        vm.stopPrank();
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
