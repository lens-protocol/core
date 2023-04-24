// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'test/base/BaseTest.t.sol';
import {FollowerOnlyReferenceModule} from 'contracts/modules/reference/FollowerOnlyReferenceModule.sol';
import {FollowValidationLib} from 'contracts/modules/libraries/FollowValidationLib.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';

contract FollowerOnlyReferenceModuleTest is BaseTest {
    using stdJson for string;
    FollowerOnlyReferenceModule followerOnlyReferenceModule;

    uint256 profileId;

    uint256 followerProfileId;
    address followerProfileOwner = address(0xF01108E4);
    uint256 notFollowerProfileId;
    address notFollowerProfileOwner = address(0x707F01108E4);

    function setUp() public virtual override {
        super.setUp();
        profileId = _createProfile(profileOwner);

        followerProfileId = _createProfile(followerProfileOwner);
        notFollowerProfileId = _createProfile(notFollowerProfileOwner);

        vm.prank(followerProfileOwner);
        hub.follow(followerProfileId, _toUint256Array(profileId), _toUint256Array(0), _toBytesArray(''));
        assertTrue(hub.isFollowing(followerProfileId, profileId));
        assertFalse(hub.isFollowing(notFollowerProfileId, profileId));
    }

    // Deploy & Whitelist FollowerOnlyReferenceModule
    constructor() TestSetup() {
        if (fork && keyExists(string(abi.encodePacked('.', forkEnv, '.FollowerOnlyReferenceModule')))) {
            followerOnlyReferenceModule = FollowerOnlyReferenceModule(
                json.readAddress(string(abi.encodePacked('.', forkEnv, '.FollowerOnlyReferenceModule')))
            );
            console.log('Testing against already deployed module at:', address(followerOnlyReferenceModule));
        } else {
            vm.prank(deployer);
            followerOnlyReferenceModule = new FollowerOnlyReferenceModule(hubProxyAddr);
        }
    }

    // FollowerOnlyReferenceModule doesn't need initialization, so this always returns an empty bytes array and is
    // callable by anyone
    function testInitialize(address from, uint256 fuzzProfileId, uint256 fuzzPubId) public {
        vm.prank(from);
        followerOnlyReferenceModule.initializeReferenceModule(fuzzProfileId, fuzzPubId, address(0), '');
    }

    // Negatives
    function testCannotProcessComment_IfNotFollowing(uint256 pubId) public {
        vm.expectRevert(Errors.NotFollowing.selector);

        vm.prank(address(hub));
        followerOnlyReferenceModule.processComment(
            Types.ProcessCommentParams({
                profileId: notFollowerProfileId,
                transactionExecutor: profileOwner,
                pointedProfileId: profileId,
                pointedPubId: pubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testCannotProcessMirror_IfNotFollowing(uint256 pubId) public {
        vm.expectRevert(Errors.NotFollowing.selector);

        vm.prank(address(hub));
        followerOnlyReferenceModule.processMirror(
            Types.ProcessMirrorParams({
                profileId: notFollowerProfileId,
                transactionExecutor: profileOwner,
                pointedProfileId: profileId,
                pointedPubId: pubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testCannotProcessQuote_IfNotFollowing(uint256 pubId) public {
        vm.expectRevert(Errors.NotFollowing.selector);

        vm.prank(address(hub));
        followerOnlyReferenceModule.processQuote(
            Types.ProcessQuoteParams({
                profileId: notFollowerProfileId,
                transactionExecutor: profileOwner,
                pointedProfileId: profileId,
                pointedPubId: pubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testProcessComment_IfFollowing(uint256 pubId) public {
        vm.prank(address(hub));
        followerOnlyReferenceModule.processComment(
            Types.ProcessCommentParams({
                profileId: followerProfileId,
                transactionExecutor: profileOwner,
                pointedProfileId: profileId,
                pointedPubId: pubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testProcessMirror_IfFollowing(uint256 pubId) public {
        vm.prank(address(hub));
        followerOnlyReferenceModule.processMirror(
            Types.ProcessMirrorParams({
                profileId: followerProfileId,
                transactionExecutor: profileOwner,
                pointedProfileId: profileId,
                pointedPubId: pubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }

    function testProcessQuote_IfFollowing(uint256 pubId) public {
        vm.prank(address(hub));
        followerOnlyReferenceModule.processQuote(
            Types.ProcessQuoteParams({
                profileId: followerProfileId,
                transactionExecutor: profileOwner,
                pointedProfileId: profileId,
                pointedPubId: pubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
        );
    }
}
