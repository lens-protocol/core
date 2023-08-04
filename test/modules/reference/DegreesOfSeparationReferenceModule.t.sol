// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'test/base/BaseTest.t.sol';
import {DegreesOfSeparationReferenceModule, ModuleConfig} from 'contracts/modules/reference/DegreesOfSeparationReferenceModule.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';

contract DegreesOfSeparationReferenceModuleTest is BaseTest {
    // The one that performed the original publication that is being commented/quoted/mirrored.
    TestAccount originalPublisher;
    // The one performing the comment/mirror/quote.
    TestAccount currentPublisher;
    // Expected to be used mostly as 1st degree profile in the path, when needed.
    TestAccount firstAccount;
    // Expected to be used mostly as 2nd degree profile in the path, when needed.
    TestAccount secondAccount;
    // Expected to be used mostly as 3rd degree profile in the path, when needed.
    TestAccount thirdAccount;

    address hubAddress;

    uint8 MAX_DEGREES_OF_SEPARATION;

    DegreesOfSeparationReferenceModule module;

    function testDegreesOfSeparationReferenceModule() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override {
        super.setUp();

        originalPublisher = _loadAccountAs('PUBLISHER');
        currentPublisher = _loadAccountAs('ANOTHER_PUBLISHER');
        firstAccount = _loadAccountAs('FIRST_ACCOUNT');
        secondAccount = _loadAccountAs('SECOND_ACCOUNT');
        thirdAccount = _loadAccountAs('THIRD_ACCOUNT');

        hubAddress = address(hub);

        module = loadOrDeploy_DegreesOfSeparationReferenceModule();

        MAX_DEGREES_OF_SEPARATION = module.MAX_DEGREES_OF_SEPARATION();
    }

    function _getInitData(
        bool commentsRestricted,
        bool quotesRestricted,
        bool mirrorsRestricted,
        uint8 degreesOfSeparation,
        uint128 sourceProfile
    ) private pure returns (bytes memory) {
        return abi.encode(commentsRestricted, quotesRestricted, mirrorsRestricted, degreesOfSeparation, sourceProfile);
    }

    function testCannotInitialize_IfSenderIsNotTheLensHub(address notHub) public {
        vm.assume(notHub != address(0));
        vm.assume(notHub != hubAddress);

        vm.expectRevert(Errors.NotHub.selector);

        vm.prank(notHub);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: MAX_DEGREES_OF_SEPARATION,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );
    }

    function testCannotInitialize_IfDegreesExceedsMaxAllowedValue(uint8 unallowedDegreesValue) public {
        vm.assume(unallowedDegreesValue > MAX_DEGREES_OF_SEPARATION);

        vm.expectRevert(DegreesOfSeparationReferenceModule.InvalidDegreesOfSeparation.selector);

        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: unallowedDegreesValue,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );
    }

    function testCannotInitialize_IfDataHasWrongFormat() public {
        bytes memory wrongData = abi.encode(true, 69);

        vm.expectRevert();

        vm.prank(hubAddress);
        module.initializeReferenceModule(originalPublisher.profileId, 1, originalPublisher.owner, wrongData);
    }

    function testCannotInitialize_IfSourceProfileDoesNotExist(uint128 unexistentProfileId) public {
        vm.assume(!hub.exists(unexistentProfileId));

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: MAX_DEGREES_OF_SEPARATION,
                sourceProfile: unexistentProfileId
            })
        );
    }

    function testInitialize(
        bool commentsRestricted,
        bool quotesRestricted,
        bool mirrorsRestricted,
        uint8 degrees
    ) public {
        degrees = uint8(bound(degrees, 0, MAX_DEGREES_OF_SEPARATION));

        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: commentsRestricted,
                quotesRestricted: quotesRestricted,
                mirrorsRestricted: mirrorsRestricted,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        ModuleConfig memory config = module.getModuleConfig(originalPublisher.profileId, 1);

        assertTrue(config.setUp);
        assertEq(config.commentsRestricted, commentsRestricted);
        assertEq(config.quotesRestricted, quotesRestricted);
        assertEq(config.mirrorsRestricted, mirrorsRestricted);
        assertEq(config.degreesOfSeparation, degrees);
        assertEq(config.sourceProfile, uint128(originalPublisher.profileId));
    }

    function testCannotProcessComment_IfDegreesOfSeparationRestrictionIsNotMet_PathLength(uint8 degrees) public {
        // Degrees 0 is a special case that will be tested separetly.
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: false,
                mirrorsRestricted: false,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = _buildWrongPathLengthPath();

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(DegreesOfSeparationReferenceModule.ProfilePathExceedsDegreesOfSeparation.selector);
        vm.prank(hubAddress);
        module.processComment(
            Types.ProcessCommentParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessMirror_IfDegreesOfSeparationRestrictionIsNotMet_PathLength(uint8 degrees) public {
        // Degrees 0 is a special case that will be tested separetly.
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: false,
                quotesRestricted: false,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = _buildWrongPathLengthPath();

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: false,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(DegreesOfSeparationReferenceModule.ProfilePathExceedsDegreesOfSeparation.selector);
        vm.prank(hubAddress);
        module.processMirror(
            Types.ProcessMirrorParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessQuote_IfDegreesOfSeparationRestrictionIsNotMet_PathLength(uint8 degrees) public {
        // Degrees 0 is a special case that will be tested separetly.
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: false,
                quotesRestricted: true,
                mirrorsRestricted: false,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = _buildWrongPathLengthPath();

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: false,
                quotesRestricted: false,
                mirrorsRestricted: false,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(DegreesOfSeparationReferenceModule.ProfilePathExceedsDegreesOfSeparation.selector);
        vm.prank(hubAddress);
        module.processQuote(
            Types.ProcessQuoteParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessComment_IfDegreesOfSeparationRestrictionIsNotMet_OriginalPublisherDoesNotFollowFirstPathNode(
        uint8 degrees
    ) public {
        // Degrees 0 is a special case that will be tested separetly.
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = _buildPathWhereOriginalPublisherDoesNotFollowFirstNode(degrees);

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(Errors.NotFollowing.selector);
        vm.prank(hubAddress);
        module.processComment(
            Types.ProcessCommentParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessMirror_IfDegreesOfSeparationRestrictionIsNotMet_OriginalPublisherDoesNotFollowFirstPathNode(
        uint8 degrees
    ) public {
        // Degrees 0 is a special case that will be tested separetly.
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = _buildPathWhereOriginalPublisherDoesNotFollowFirstNode(degrees);

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(Errors.NotFollowing.selector);
        vm.prank(hubAddress);
        module.processMirror(
            Types.ProcessMirrorParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessQuote_IfDegreesOfSeparationRestrictionIsNotMet_OriginalPublisherDoesNotFollowFirstPathNode(
        uint8 degrees
    ) public {
        // Degrees 0 is a special case that will be tested separetly.
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = _buildPathWhereOriginalPublisherDoesNotFollowFirstNode(degrees);

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(Errors.NotFollowing.selector);
        vm.prank(hubAddress);
        module.processQuote(
            Types.ProcessQuoteParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessComment_IfDegreesOfSeparationRestrictionIsNotMet_LastPathNodeDoesNotFollowCurrentPublisher(
        uint8 degrees
    ) public {
        // Degrees 0 is a special case that will be tested separetly.
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = _buildPathWhereLastPathNodeDoesNotFollowCurrentPublisher(degrees);

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(Errors.NotFollowing.selector);
        vm.prank(hubAddress);
        module.processComment(
            Types.ProcessCommentParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessMirror_IfDegreesOfSeparationRestrictionIsNotMet_LastPathNodeDoesNotFollowCurrentPublisher(
        uint8 degrees
    ) public {
        // Degrees 0 is a special case that will be tested separetly.
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = _buildPathWhereLastPathNodeDoesNotFollowCurrentPublisher(degrees);

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(Errors.NotFollowing.selector);
        vm.prank(hubAddress);
        module.processMirror(
            Types.ProcessMirrorParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessQuote_IfDegreesOfSeparationRestrictionIsNotMet_LastPathNodeDoesNotFollowCurrentPublisher(
        uint8 degrees
    ) public {
        // Degrees 0 is a special case that will be tested separetly.
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = _buildPathWhereLastPathNodeDoesNotFollowCurrentPublisher(degrees);

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(Errors.NotFollowing.selector);
        vm.prank(hubAddress);
        module.processQuote(
            Types.ProcessQuoteParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessComment_IfDegreesOfSeparationRestrictionIsNotMet_MissingFollowLinkInThePath() public {
        // Note: This test just makes sense for degrees = 3, the rest of the cases are already covered by other tests.

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: MAX_DEGREES_OF_SEPARATION,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = new uint256[](MAX_DEGREES_OF_SEPARATION - 1);
        _follow({follower: originalPublisher, target: firstAccount});
        path[0] = firstAccount.profileId;
        // Intentonally missing _follow(firstAccount, secondAccount) linkage.
        _follow({follower: secondAccount, target: currentPublisher});
        path[1] = secondAccount.profileId;

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: MAX_DEGREES_OF_SEPARATION,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(Errors.NotFollowing.selector);
        vm.prank(hubAddress);
        module.processComment(
            Types.ProcessCommentParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessMirror_IfDegreesOfSeparationRestrictionIsNotMet_MissingFollowLinkInThePath() public {
        // Note: This test just makes sense for degrees = 3, the rest of the cases are already covered by other tests.

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: MAX_DEGREES_OF_SEPARATION,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = new uint256[](MAX_DEGREES_OF_SEPARATION - 1);
        _follow({follower: originalPublisher, target: firstAccount});
        path[0] = firstAccount.profileId;
        // Intentonally missing _follow(firstAccount, secondAccount) linkage.
        _follow({follower: secondAccount, target: currentPublisher});
        path[1] = secondAccount.profileId;

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: MAX_DEGREES_OF_SEPARATION,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(Errors.NotFollowing.selector);
        vm.prank(hubAddress);
        module.processMirror(
            Types.ProcessMirrorParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessQuote_IfDegreesOfSeparationRestrictionIsNotMet_MissingFollowLinkInThePath() public {
        // Note: This test just makes sense for degrees = 3, the rest of the cases are already covered by other tests.

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: MAX_DEGREES_OF_SEPARATION,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Performs follows and builds path.
        uint256[] memory path = new uint256[](MAX_DEGREES_OF_SEPARATION - 1);
        _follow({follower: originalPublisher, target: firstAccount});
        path[0] = firstAccount.profileId;
        // Intentonally missing _follow(firstAccount, secondAccount) linkage.
        _follow({follower: secondAccount, target: currentPublisher});
        path[1] = secondAccount.profileId;

        // Initializes module for config inheritance (profile: currentPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: MAX_DEGREES_OF_SEPARATION,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(Errors.NotFollowing.selector);
        vm.prank(hubAddress);
        module.processQuote(
            Types.ProcessQuoteParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(path)
            })
        );
    }

    function testCannotProcessComment_IfNotInheritingConfig_NotUsingSameReferenceModule(uint8 degrees) public {
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(DegreesOfSeparationReferenceModule.NotInheritingPointedPubConfig.selector);
        vm.prank(hubAddress);
        module.processComment(
            Types.ProcessCommentParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testCannotProcessComment_IfNotInheritingConfig_NotRestrictingComments(uint8 degrees) public {
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: false,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(DegreesOfSeparationReferenceModule.NotInheritingPointedPubConfig.selector);
        vm.prank(hubAddress);
        module.processComment(
            Types.ProcessCommentParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testCannotProcessComment_IfNotInheritingConfig_WrongSourceProfile(
        uint8 degrees,
        uint128 wrongSourceProfile
    ) public {
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));
        vm.assume(hub.exists(wrongSourceProfile));
        vm.assume(wrongSourceProfile != uint128(originalPublisher.profileId));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: wrongSourceProfile
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(DegreesOfSeparationReferenceModule.NotInheritingPointedPubConfig.selector);
        vm.prank(hubAddress);
        module.processComment(
            Types.ProcessCommentParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testCannotProcessComment_IfNotInheritingConfig_WrongDegrees(uint8 degrees, uint8 wrongDegrees) public {
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));
        wrongDegrees = uint8(bound(wrongDegrees, 0, MAX_DEGREES_OF_SEPARATION));
        vm.assume(degrees != wrongDegrees);

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            currentPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: wrongDegrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(DegreesOfSeparationReferenceModule.NotInheritingPointedPubConfig.selector);
        vm.prank(hubAddress);
        module.processComment(
            Types.ProcessCommentParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testProcessQuote_EvenWhenNotInheritingConfig(uint8 degrees) public {
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        // NOTE: Quote is not even using the reference same module!
        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.prank(hubAddress);
        module.processQuote(
            Types.ProcessQuoteParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testProcessMirror_EvenWhenNotInheritingConfig(uint8 degrees) public {
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        // NOTE: Mirror is not even using the reference same module!
        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.prank(hubAddress);
        module.processMirror(
            Types.ProcessMirrorParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testProcessComment_IfCommentNotRestricted(uint8 degrees) public {
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: false,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        // NOTE: Comment is not using the reference same module.
        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.prank(hubAddress);
        module.processComment(
            Types.ProcessCommentParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testProcessMirror_IfMirrorNotRestricted(uint8 degrees) public {
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: false,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        // NOTE: Mirror is not using the reference same module.
        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.prank(hubAddress);
        module.processMirror(
            Types.ProcessMirrorParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testProcessQuote_IfQuoteNotRestricted(uint8 degrees) public {
        degrees = uint8(bound(degrees, 1, MAX_DEGREES_OF_SEPARATION));

        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: false,
                mirrorsRestricted: true,
                degreesOfSeparation: degrees,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        // NOTE: Quote is not using the reference same module.
        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.prank(hubAddress);
        module.processQuote(
            Types.ProcessQuoteParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: currentPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testProcessComment_WhenRestrictedWithZeroDegrees_ButCurrentPublisherIsSourceProfile() public {
        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Initializes module for (profile: originalPublisher.profileId, pubId: 2)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            2,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: originalPublisher, pubCount: 2});

        vm.prank(hubAddress);
        module.processComment(
            Types.ProcessCommentParams({
                profileId: originalPublisher.profileId,
                transactionExecutor: originalPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testProcessMirror_WhenRestrictedWithZeroDegrees_ButCurrentPublisherIsSourceProfile() public {
        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Initializes module for (profile: originalPublisher.profileId, pubId: 2)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            2,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: originalPublisher, pubCount: 2});

        vm.prank(hubAddress);
        module.processMirror(
            Types.ProcessMirrorParams({
                profileId: originalPublisher.profileId,
                transactionExecutor: originalPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testProcessQuote_WhenRestrictedWithZeroDegrees_ButCurrentPublisherIsSourceProfile() public {
        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Initializes module for (profile: originalPublisher.profileId, pubId: 2)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            2,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: originalPublisher, pubCount: 2});

        vm.prank(hubAddress);
        module.processQuote(
            Types.ProcessQuoteParams({
                profileId: originalPublisher.profileId,
                transactionExecutor: originalPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testCannotProcessComment_WhenRestrictedWithZeroDegrees_AndCurrentPublisherIsNotSourceProfile() public {
        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        // Initializes module for (profile: originalPublisher.profileId, pubId: 2)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(DegreesOfSeparationReferenceModule.OperationDisabled.selector);
        vm.prank(hubAddress);
        module.processComment(
            Types.ProcessCommentParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: originalPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testCannotProcessMirror_WhenRestrictedWithZeroDegrees_AndCurrentPublisherIsNotSourceProfile() public {
        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        // Initializes module for (profile: originalPublisher.profileId, pubId: 2)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(DegreesOfSeparationReferenceModule.OperationDisabled.selector);
        vm.prank(hubAddress);
        module.processMirror(
            Types.ProcessMirrorParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: originalPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    function testCannotProcessQuote_WhenRestrictedWithZeroDegrees_AndCurrentPublisherIsNotSourceProfile() public {
        // Initializes module for (profile: originalPublisher.profileId, pubId: 1)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            originalPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        // Makes current publisher to be one degree of separation from original publisher.
        _follow({follower: originalPublisher, target: currentPublisher});

        // Initializes module for (profile: originalPublisher.profileId, pubId: 2)
        vm.prank(hubAddress);
        module.initializeReferenceModule(
            currentPublisher.profileId,
            1,
            originalPublisher.owner,
            _getInitData({
                commentsRestricted: true,
                quotesRestricted: true,
                mirrorsRestricted: true,
                degreesOfSeparation: 0,
                sourceProfile: uint128(originalPublisher.profileId)
            })
        );

        _mockLensHubPubCountResponse({account: currentPublisher, pubCount: 1});

        vm.expectRevert(DegreesOfSeparationReferenceModule.OperationDisabled.selector);
        vm.prank(hubAddress);
        module.processQuote(
            Types.ProcessQuoteParams({
                profileId: currentPublisher.profileId,
                transactionExecutor: originalPublisher.owner,
                pointedProfileId: originalPublisher.profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(_emptyUint256Array())
            })
        );
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function _mockLensHubPubCountResponse(TestAccount memory account, uint256 pubCount) internal {
        uint256 profileId = account.profileId;
        uint256 profilesMappingSlot = StorageLib.PROFILES_MAPPING_SLOT;
        uint256 pubCountSlot;
        assembly {
            mstore(0, profileId)
            mstore(32, profilesMappingSlot)
            pubCountSlot := keccak256(0, 64)
        }
        vm.store(hubAddress, bytes32(pubCountSlot), bytes32(pubCount));
    }

    function _buildWrongPathLengthPath() internal returns (uint256[] memory) {
        uint256[] memory path = new uint256[](MAX_DEGREES_OF_SEPARATION);
        _follow({follower: originalPublisher, target: firstAccount});
        path[0] = firstAccount.profileId;
        _follow({follower: firstAccount, target: secondAccount});
        path[1] = secondAccount.profileId;
        _follow({follower: secondAccount, target: thirdAccount});
        path[2] = thirdAccount.profileId;
        _follow({follower: thirdAccount, target: currentPublisher});
        return path;
    }

    function _buildPathWhereOriginalPublisherDoesNotFollowFirstNode(uint256 degrees)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory path = new uint256[](degrees - 1);
        if (degrees == 1) {
            return path;
        }
        if (degrees == 2) {
            _follow({follower: firstAccount, target: currentPublisher});
            path[0] = firstAccount.profileId;
        }
        if (degrees == 3) {
            _follow({follower: firstAccount, target: secondAccount});
            path[0] = firstAccount.profileId;
            _follow({follower: secondAccount, target: currentPublisher});
            path[1] = secondAccount.profileId;
        }
        return path;
    }

    function _buildPathWhereLastPathNodeDoesNotFollowCurrentPublisher(uint256 degrees)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory path = new uint256[](degrees - 1);
        if (degrees == 1) {
            return path;
        }
        if (degrees == 2) {
            _follow({follower: originalPublisher, target: firstAccount});
            path[0] = firstAccount.profileId;
        }
        if (degrees == 3) {
            _follow({follower: originalPublisher, target: firstAccount});
            path[0] = firstAccount.profileId;
            _follow({follower: firstAccount, target: secondAccount});
            path[1] = secondAccount.profileId;
        }
        return path;
    }

    function _follow(TestAccount memory follower, TestAccount memory target) internal {
        vm.prank(follower.owner);
        hub.follow(follower.profileId, _toUint256Array(target.profileId), _toUint256Array(0), _toBytesArray(''));
    }
}
