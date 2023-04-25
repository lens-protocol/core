// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';

import {Events} from 'contracts/libraries/constants/Events.sol';
import {MockFollowModule} from 'test/mocks/MockFollowModule.sol';

contract EventTest is BaseTest {
    address profileOwnerTwo = address(0x2222);
    address mockFollowModule;

    // Non-Lens Events
    // TODO: Replace this with import from test/helpers/Events.sol
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Upgraded(address indexed implementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    function setUp() public override {
        TestSetup.setUp();
        mockFollowModule = address(new MockFollowModule());
        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);
    }

    function predictContractAddress(address user, uint256 distanceFromCurrentNonce) internal view returns (address) {
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
        // TODO: Last 3 addresses are for the follow modules for migration purposes.
        hubImpl = new LensHubInitializable({
            moduleGlobals: address(0),
            followNFTImpl: followNFTAddr,
            collectNFTImpl: collectNFTAddr,
            lensHandlesAddress: address(0),
            tokenHandleRegistryAddress: address(0),
            legacyFeeFollowModule: address(0),
            legacyProfileFollowModule: address(0),
            newFeeFollowModule: address(0)
        });
        followNFT = new FollowNFT(hubProxyAddr);
        collectNFT = new CollectNFT(hubProxyAddr);

        // Deploy and initialize proxy.
        bytes memory initData = abi.encodeCall(hubImpl.initialize, (expectedNFTName, expectedNFTSymbol, governance));

        // Event tests
        // Upgraded
        vm.expectEmit(true, false, false, true, hubProxyAddr);
        emit Upgraded(address(hubImpl));

        // StateSet
        vm.expectEmit(true, true, true, true, hubProxyAddr);
        emit Events.StateSet(deployer, Types.ProtocolState.Unpaused, Types.ProtocolState.Paused, block.timestamp);

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
        emit Events.GovernanceSet(governance, governance, address(this), block.timestamp);
        hub.setGovernance(address(this));
    }

    function testEmergencyAdminChangeEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.EmergencyAdminSet(governance, address(0), address(this), block.timestamp);
        hub.setEmergencyAdmin(address(this));
    }

    function testProtocolStateChangeByGovEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(governance, Types.ProtocolState.Unpaused, Types.ProtocolState.Paused, block.timestamp);
        hub.setState(Types.ProtocolState.Paused);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(
            governance,
            Types.ProtocolState.Paused,
            Types.ProtocolState.PublishingPaused,
            block.timestamp
        );
        hub.setState(Types.ProtocolState.PublishingPaused);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(
            governance,
            Types.ProtocolState.PublishingPaused,
            Types.ProtocolState.Unpaused,
            block.timestamp
        );
        hub.setState(Types.ProtocolState.Unpaused);
    }

    function testProtocolStateChangeByEmergencyAdminEmitsExpectedEvents() public {
        vm.prank(governance);
        hub.setEmergencyAdmin(defaultAccount.owner);

        vm.prank(defaultAccount.owner);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(
            defaultAccount.owner,
            Types.ProtocolState.Unpaused,
            Types.ProtocolState.PublishingPaused,
            block.timestamp
        );
        hub.setState(Types.ProtocolState.PublishingPaused);

        vm.prank(defaultAccount.owner);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.StateSet(
            defaultAccount.owner,
            Types.ProtocolState.PublishingPaused,
            Types.ProtocolState.Paused,
            block.timestamp
        );
        hub.setState(Types.ProtocolState.Paused);
    }

    function testFollowModuleWhitelistEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.FollowModuleWhitelisted(address(this), true, block.timestamp);
        hub.whitelistFollowModule(address(this), true);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.FollowModuleWhitelisted(address(this), false, block.timestamp);
        hub.whitelistFollowModule(address(this), false);
    }

    function testReferenceModuleWhitelistEmitsExpectedEvents() public {
        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ReferenceModuleWhitelisted(address(this), true, block.timestamp);
        hub.whitelistReferenceModule(address(this), true);

        vm.prank(governance);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ReferenceModuleWhitelisted(address(this), false, block.timestamp);
        hub.whitelistReferenceModule(address(this), false);
    }

    function testProfileCreationEmitsExpectedEvents() public {
        Types.CreateProfileParams memory createProfileParams = _getDefaultCreateProfileParams();
        uint256 expectedTokenId = _getNextProfileId();
        vm.expectEmit(true, true, true, true, address(hub));
        emit Transfer(address(0), createProfileParams.to, expectedTokenId);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ProfileCreated(
            expectedTokenId,
            address(this),
            createProfileParams.to,
            createProfileParams.imageURI,
            createProfileParams.followModule,
            '',
            createProfileParams.followNFTURI,
            block.timestamp
        );
        hub.createProfile(createProfileParams);
    }

    function testSettingFollowModuleEmitsExpectedEvents() public {
        uint256 profileId = hub.createProfile(_getDefaultCreateProfileParams());
        vm.prank(defaultAccount.owner);
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.FollowModuleSet(profileId, address(mockFollowModule), '', block.timestamp);
        hub.setFollowModule(profileId, address(mockFollowModule), abi.encode(true));
    }

    function testPostingEmitsExpectedEvents() public {
        uint256 expectedPostId = hub.getPubCount(mockPostParams.profileId) + 1;
        vm.expectEmit(true, true, false, true, address(hub));
        emit Events.PostCreated(mockPostParams, expectedPostId, _toBytesArray(abi.encode(true)), '', block.timestamp);
        vm.prank(defaultAccount.owner);
        hub.post(mockPostParams);
    }

    function testCommentingEmitsExpectedEvents() public {
        uint256 expectedCommentId = hub.getPubCount(mockPostParams.profileId) + 1;
        vm.expectEmit(true, true, false, true, address(hub));
        emit Events.CommentCreated(
            mockCommentParams,
            expectedCommentId,
            '',
            _toBytesArray(abi.encode(true)),
            '',
            block.timestamp
        );
        vm.prank(defaultAccount.owner);
        hub.comment(mockCommentParams);
    }

    function testMirroringEmitsExpectedEvents() public {
        uint256 expectedMirrorId = hub.getPubCount(mockPostParams.profileId) + 1;
        vm.expectEmit(true, true, false, true, address(hub));
        emit Events.MirrorCreated(mockMirrorParams, expectedMirrorId, '', block.timestamp);
        vm.prank(defaultAccount.owner);
        hub.mirror(mockMirrorParams);
    }

    // TODO: Proper tests for Act
    // function testCollectingEmitsExpectedEvents() public {
    //     vm.startPrank(defaultAccount.owner);
    //     hub.post(mockPostParams);

    //     uint256 expectedPubId = 1;
    //     address expectedCollectNFTAddress = predictContractAddress(address(hub), 0);
    //     string memory expectedNFTName = '1-Collect-1';
    //     string memory expectedNFTSymbol = '1-Cl-1';

    //     // BaseInitialized
    //     vm.expectEmit(true, true, true, true, expectedCollectNFTAddress);
    //     emit Events.BaseInitialized(expectedNFTName, expectedNFTSymbol, block.timestamp);

    //     // CollectNFTInitialized
    //     vm.expectEmit(true, true, true, true, expectedCollectNFTAddress);
    //     // emit Events.CollectNFTInitialized(newProfileId, expectedPubId, block.timestamp);

    //     // CollectNFTDeployed
    //     vm.expectEmit(true, true, true, true, address(hub));
    //     emit Events.CollectNFTDeployed(newProfileId, expectedPubId, expectedCollectNFTAddress, block.timestamp);

    //     // CollectNFTTransferred
    //     vm.expectEmit(true, true, true, true, address(hub));
    //     emit Events.CollectNFTTransferred(
    //         newProfileId,
    //         expectedPubId,
    //         1, // collect nft id
    //         address(0),
    //         defaultAccount.owner,
    //         block.timestamp
    //     );

    //     // Transfer
    //     vm.expectEmit(true, true, true, true, expectedCollectNFTAddress);
    //     emit Transfer(address(0), defaultAccount.owner, 1);

    //     // Collected
    //     // TODO: Proper test
    //     // vm.expectEmit(true, true, true, true, address(hub));
    //     // emit Events.Collected({
    //     //     publicationCollectedProfileId: newProfileId, // TODO: Replace with proper ProfileID
    //     //     publicationCollectedId: expectedPubId,
    //     //     collectorProfileId: newProfileId,
    //     //     referrerProfileIds: _emptyUint256Array(),
    //     //     referrerPubIds: _emptyUint256Array(),
    //     //     collectModuleData: '',
    //     //     timestamp: block.timestamp
    //     // });

    //     // TODO: Replace with proper ProfileID
    //     hub.collect(
    //         Types.CollectParams({
    //             publicationCollectedProfileId: newProfileId,
    //             publicationCollectedId: expectedPubId,
    //             collectorProfileId: newProfileId,
    //             referrerProfileIds: _emptyUint256Array(),
    //             referrerPubIds: _emptyUint256Array(),
    //             collectModuleData: ''
    //         })
    //     );
    //     vm.stopPrank();
    // }

    // TODO: Proper tests for Act
    // function testCollectingFromMirrorEmitsExpectedEvents() public {
    //     uint256[] memory followTargetIds = new uint256[](1);
    //     followTargetIds[0] = 1;
    //     bytes[] memory followDatas = new bytes[](1);
    //     followDatas[0] = '';
    //     address expectedCollectNFTAddress = predictContractAddress(address(hub), 0);
    //     string memory expectedNFTName = '1-Collect-1';
    //     string memory expectedNFTSymbol = '1-Cl-1';

    //     vm.startPrank(defaultAccount.owner);
    //     uint256 postId = hub.post(mockPostParams);
    //     uint256 mirrorId = hub.mirror(mockMirrorParams);

    //     // BaseInitialized
    //     vm.expectEmit(false, false, false, true, expectedCollectNFTAddress);
    //     emit Events.BaseInitialized(expectedNFTName, expectedNFTSymbol, block.timestamp);

    //     // CollectNFTInitialized
    //     // TODO: We removed this event
    //     // vm.expectEmit(true, true, true, true, expectedCollectNFTAddress);
    //     // emit Events.CollectNFTInitialized(newProfileId, postId, block.timestamp);

    //     // CollectNFTDeployed
    //     vm.expectEmit(true, true, true, true, address(hub));
    //     emit Events.CollectNFTDeployed(newProfileId, postId, expectedCollectNFTAddress, block.timestamp);

    //     // CollectNFTTransferred
    //     vm.expectEmit(true, true, true, true, address(hub));
    //     emit Events.CollectNFTTransferred(
    //         newProfileId,
    //         postId,
    //         1, // collect nft id
    //         address(0),
    //         defaultAccount.owner,
    //         block.timestamp
    //     );

    //     // Transfer
    //     vm.expectEmit(true, true, true, true, expectedCollectNFTAddress);
    //     emit Transfer(address(0), defaultAccount.owner, 1);

    //     // Collected
    //     // TODO: Proper test
    //     // vm.expectEmit(true, true, true, true, address(hub));
    //     // emit Events.Collected({
    //     //     publicationCollectedProfileId: newProfileId, // TODO: Replace with proper ProfileID
    //     //     publicationCollectedId: postId,
    //     //     collectorProfileId: newProfileId,
    //     //     referrerProfileIds: _toUint256Array(newProfileId),
    //     //     referrerPubIds: _toUint256Array(mirrorId),
    //     //     collectModuleData: '',
    //     //     timestamp: block.timestamp
    //     // });

    //     // TODO: Replace with proper ProfileID
    //     hub.collect(
    //         Types.CollectParams({
    //             publicationCollectedProfileId: newProfileId,
    //             publicationCollectedId: postId,
    //             collectorProfileId: newProfileId,
    //             referrerProfileIds: _toUint256Array(newProfileId),
    //             referrerPubIds: _toUint256Array(mirrorId),
    //             collectModuleData: ''
    //         })
    //     );
    //     vm.stopPrank();
    // }

    // MODULE GLOBALS GOVERNANCE

    function testGovernanceChangeEmitsExpectedEvents() public {
        vm.prank(modulesGovernance);
        vm.expectEmit(true, true, true, true, address(moduleGlobals));
        emit Events.ModuleGlobalsGovernanceSet(modulesGovernance, address(this), block.timestamp);
        moduleGlobals.setGovernance(address(this));
    }

    function testTreasuryChangeEmitsExpectedEvents() public {
        vm.prank(modulesGovernance);
        vm.expectEmit(true, true, false, true, address(moduleGlobals));
        emit Events.ModuleGlobalsTreasurySet(treasury, address(this), block.timestamp);
        moduleGlobals.setTreasury(address(this));
    }

    function testTreasuryFeeChangeEmitsExpectedEvents() public {
        uint16 newFee = 1;
        vm.prank(modulesGovernance);
        vm.expectEmit(true, true, false, true, address(moduleGlobals));
        emit Events.ModuleGlobalsTreasuryFeeSet(TREASURY_FEE_BPS, newFee, block.timestamp);
        moduleGlobals.setTreasuryFee(newFee);
    }

    function testCurrencyWhitelistEmitsExpectedEvents() public {
        vm.prank(modulesGovernance);
        vm.expectEmit(true, true, true, true, address(moduleGlobals));
        emit Events.ModuleGlobalsCurrencyWhitelisted(address(this), false, true, block.timestamp);
        moduleGlobals.whitelistCurrency(address(this), true);

        vm.prank(modulesGovernance);
        vm.expectEmit(true, true, true, true, address(moduleGlobals));
        emit Events.ModuleGlobalsCurrencyWhitelisted(address(this), true, false, block.timestamp);
        moduleGlobals.whitelistCurrency(address(this), false);
    }
}
