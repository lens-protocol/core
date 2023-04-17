// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'test/foundry/modules/base/BaseModuleTest.t.sol';
import {TokenGatedReferenceModule, TokenGatedEvents, GateParams} from 'contracts/modules/reference/TokenGatedReferenceModule.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {ArrayHelpers} from 'test/foundry/helpers/ArrayHelpers.sol';

contract TokenGatedReferenceModuleBase is BaseModuleTest {
    using stdJson for string;
    TokenGatedReferenceModule tokenGatedReferenceModule;

    function setUp() public virtual override {
        super.setUp();
    }

    // Deploy & Whitelist TokenGatedReferenceModule
    constructor() BaseModuleTest() {
        if (fork && keyExists(string(abi.encodePacked('.', forkEnv, '.TokenGatedReferenceModule')))) {
            tokenGatedReferenceModule = TokenGatedReferenceModule(
                json.readAddress(string(abi.encodePacked('.', forkEnv, '.TokenGatedReferenceModule')))
            );
            console.log('Testing against already deployed module at:', address(tokenGatedReferenceModule));
        } else {
            vm.prank(deployer);
            tokenGatedReferenceModule = new TokenGatedReferenceModule(hubProxyAddr);
        }
    }
}

/////////
// Publication Creation with TokenGatedReferenceModule
//
contract TokenGatedReferenceModule_Publication is TokenGatedReferenceModuleBase {
    constructor() TokenGatedReferenceModuleBase() {}

    // Negatives
    function testCannotPostWithZeroTokenAddress() public {
        vm.expectRevert(Errors.InitParamsInvalid.selector);
        vm.prank(address(hub));
        tokenGatedReferenceModule.initializeReferenceModule(
            1,
            2,
            address(3),
            abi.encode(GateParams({tokenAddress: address(0), minThreshold: 1}))
        );
    }

    function testCannotPostWithZeroMinThreshold() public {
        vm.expectRevert(Errors.InitParamsInvalid.selector);
        vm.prank(address(hub));
        tokenGatedReferenceModule.initializeReferenceModule(
            1,
            2,
            address(3),
            abi.encode(GateParams({tokenAddress: address(currency), minThreshold: 0}))
        );
    }

    function testCannotCallInitializeFromNonHub() public {
        vm.expectRevert(Errors.NotHub.selector);
        tokenGatedReferenceModule.initializeReferenceModule(
            profileId,
            1,
            profileOwner,
            abi.encode(GateParams({tokenAddress: address(currency), minThreshold: 1}))
        );
    }

    function testCannotProcessCommentFromNonHub() public {
        vm.expectRevert(Errors.NotHub.selector);
        tokenGatedReferenceModule.processComment(
            Types.ProcessCommentParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testCannotProcessQuoteFromNonHub() public {
        vm.expectRevert(Errors.NotHub.selector);
        tokenGatedReferenceModule.processQuote(
            Types.ProcessQuoteParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testCannotProcessMirrorFromNonHub() public {
        vm.expectRevert(Errors.NotHub.selector);
        tokenGatedReferenceModule.processMirror(
            Types.ProcessMirrorParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: profileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    // Scenarios
    function testCanInitializeTokenGatedReferenceModule() public {
        vm.prank(address(hub));
        tokenGatedReferenceModule.initializeReferenceModule(
            1,
            2,
            address(3),
            abi.encode(GateParams({tokenAddress: address(currency), minThreshold: 1}))
        );
    }

    function testCreatePublicationWithTokenGatedReferenceModule_EmitsExpectedEvents() public {
        vm.expectEmit(true, true, true, true, address(tokenGatedReferenceModule));
        emit TokenGatedEvents.TokenGatedReferencePublicationCreated(1, 2, address(currency), 4);
        vm.prank(address(hub));
        tokenGatedReferenceModule.initializeReferenceModule(
            1,
            2,
            address(3),
            abi.encode(GateParams({tokenAddress: address(currency), minThreshold: 4}))
        );
    }
}

/////////
// ERC20-Gated Reference
//
contract TokenGatedReferenceModule_ERC20_Gated is TokenGatedReferenceModuleBase {
    uint256 immutable publisherProfileId = 42;
    uint256 immutable publisherPubId = 69;
    uint256 constant minThreshold = 10 ether;

    constructor() TokenGatedReferenceModuleBase() {}

    function setUp() public override {
        super.setUp();
        vm.prank(address(hub));
        tokenGatedReferenceModule.initializeReferenceModule(
            publisherProfileId,
            publisherPubId,
            address(0),
            abi.encode(GateParams({tokenAddress: address(currency), minThreshold: minThreshold}))
        );
    }

    // Negatives
    function testCannotProcessComment_IfNotEnoughBalance() public {
        assertEq(currency.balanceOf(address(profileOwner)), 0);
        vm.expectRevert(TokenGatedReferenceModule.NotEnoughBalance.selector);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processComment(
            Types.ProcessCommentParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testCannotProcessMirror_IfNotEnoughBalance() public {
        assertEq(currency.balanceOf(address(profileOwner)), 0);
        vm.expectRevert(TokenGatedReferenceModule.NotEnoughBalance.selector);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processMirror(
            Types.ProcessMirrorParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testCannotProcessQuote_IfNotEnoughBalance() public {
        assertEq(currency.balanceOf(address(profileOwner)), 0);
        vm.expectRevert(TokenGatedReferenceModule.NotEnoughBalance.selector);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processQuote(
            Types.ProcessQuoteParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    // // Scenarios
    function testProcessComment_HoldingEnoughTokens() public {
        currency.mint(profileOwner, minThreshold);
        assertTrue(currency.balanceOf(profileOwner) >= minThreshold);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processComment(
            Types.ProcessCommentParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testProcessMirror_HoldingEnoughTokens() public {
        currency.mint(profileOwner, minThreshold);
        assertTrue(currency.balanceOf(profileOwner) >= minThreshold);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processMirror(
            Types.ProcessMirrorParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testProcessQuote_HoldingEnoughTokens() public {
        currency.mint(profileOwner, minThreshold);
        assertTrue(currency.balanceOf(profileOwner) >= minThreshold);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processQuote(
            Types.ProcessQuoteParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }
}

/////////
// ERC721-Gated Reference
//
contract TokenGatedReferenceModule_ERC721_Gated is TokenGatedReferenceModuleBase {
    uint256 immutable publisherProfileId = 42;
    uint256 immutable publisherPubId = 69;
    uint256 constant minThreshold = 1;

    constructor() TokenGatedReferenceModuleBase() {}

    function setUp() public override {
        super.setUp();
        vm.prank(address(hub));
        tokenGatedReferenceModule.initializeReferenceModule(
            publisherProfileId,
            publisherPubId,
            address(0),
            abi.encode(GateParams({tokenAddress: address(nft), minThreshold: minThreshold}))
        );
    }

    // Negatives
    function testCannotProcessComment_IfNotEnoughBalance() public {
        assertEq(nft.balanceOf(address(profileOwner)), 0);
        vm.expectRevert(TokenGatedReferenceModule.NotEnoughBalance.selector);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processComment(
            Types.ProcessCommentParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testCannotProcessMirror_IfNotEnoughBalance() public {
        assertEq(nft.balanceOf(address(profileOwner)), 0);
        vm.expectRevert(TokenGatedReferenceModule.NotEnoughBalance.selector);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processMirror(
            Types.ProcessMirrorParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testCannotProcessQuote_IfNotEnoughBalance() public {
        assertEq(nft.balanceOf(address(profileOwner)), 0);
        vm.expectRevert(TokenGatedReferenceModule.NotEnoughBalance.selector);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processQuote(
            Types.ProcessQuoteParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    // // Scenarios
    function testProcessComment_HoldingEnoughTokens() public {
        nft.mint(profileOwner, 1);
        assertTrue(nft.balanceOf(profileOwner) >= minThreshold);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processComment(
            Types.ProcessCommentParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testProcessMirror_HoldingEnoughTokens() public {
        nft.mint(profileOwner, 1);
        assertTrue(nft.balanceOf(profileOwner) >= minThreshold);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processMirror(
            Types.ProcessMirrorParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testProcessQuote_HoldingEnoughTokens() public {
        nft.mint(profileOwner, 1);
        assertTrue(nft.balanceOf(profileOwner) >= minThreshold);
        vm.prank(address(hub));
        tokenGatedReferenceModule.processQuote(
            Types.ProcessQuoteParams({
                profileId: profileId,
                transactionExecutor: profileOwner,
                pointedProfileId: publisherProfileId,
                pointedPubId: publisherPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }
}
