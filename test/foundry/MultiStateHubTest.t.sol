// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'test/foundry/base/BaseTest.t.sol';
import 'test/foundry/helpers/SignatureHelpers.sol';

contract MultiStateHubTest_Common is BaseTest {
    // Negatives
    function testCannotSetStateAsRegularUser() public {
        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(Types.ProtocolState.Paused);

        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(Types.ProtocolState.PublishingPaused);

        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(Types.ProtocolState.Unpaused);
    }

    function testCannotSetEmergencyAdminAsRegularUser() public {
        vm.expectRevert(Errors.NotGovernance.selector);
        _setEmergencyAdmin(address(this));
    }

    function testCannotUnpauseAsEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        vm.expectRevert(Errors.EmergencyAdminCanOnlyPauseFurther.selector);
        _setState(Types.ProtocolState.Unpaused);
    }

    function testCannotSetLowerStateAsEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        _setState(Types.ProtocolState.Paused);

        vm.expectRevert(Errors.EmergencyAdminCanOnlyPauseFurther.selector);
        _setState(Types.ProtocolState.PublishingPaused);

        vm.expectRevert(Errors.EmergencyAdminCanOnlyPauseFurther.selector);
        _setState(Types.ProtocolState.Paused);
    }

    function testCannotSetEmergencyAdminAsEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        vm.expectRevert(Errors.NotGovernance.selector);
        _setEmergencyAdmin(address(0));
    }

    // Scenarios
    function testSetProtocolStateAsEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        Types.ProtocolState[2] memory states = [Types.ProtocolState.PublishingPaused, Types.ProtocolState.Paused];

        for (uint256 i = 0; i < states.length; i++) {
            Types.ProtocolState newState = states[i];
            Types.ProtocolState prevState = _getState();
            _setState(newState);
            Types.ProtocolState curState = _getState();
            assertTrue(newState == curState);
            assertTrue(curState != prevState);
        }
    }

    function testSetProtocolStateAsGovernance() public {
        vm.startPrank(governance);

        Types.ProtocolState[6] memory states = [
            Types.ProtocolState.PublishingPaused,
            Types.ProtocolState.Paused,
            Types.ProtocolState.Unpaused,
            Types.ProtocolState.Paused,
            Types.ProtocolState.PublishingPaused,
            Types.ProtocolState.Unpaused
        ];

        for (uint256 i = 0; i < states.length; i++) {
            Types.ProtocolState newState = states[i];
            Types.ProtocolState prevState = _getState();
            _setState(newState);
            Types.ProtocolState curState = _getState();
            assertTrue(newState == curState);
            assertTrue(curState != prevState);
        }
        vm.stopPrank();
    }

    function testGovernanceCanRevokeEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        _setState(Types.ProtocolState.PublishingPaused);

        vm.prank(governance);
        _setEmergencyAdmin(address(0));

        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(Types.ProtocolState.Paused);
    }
}

contract MultiStateHubTest_PausedState_Direct is BaseTest {
    uint256 postId;
    uint256 followerProfileId;

    function setUp() public virtual override {
        super.setUp();

        followerProfileId = _createProfile(me);

        vm.prank(profileOwner);
        postId = _post(mockPostParams);

        vm.prank(governance);
        _setState(Types.ProtocolState.Paused);
    }

    // TODO: Consider extracting these mock actions functions somewhere because they're used in several places
    function _mockSetFollowModule() internal virtual {
        _setFollowModule(profileOwner, newProfileId, address(0), '');
    }

    function _mockChangeDelegatedExecutorsConfig() internal virtual {
        address executor = otherSigner;
        bool approved = true;
        _changeDelegatedExecutorsConfig(profileOwner, newProfileId, executor, approved);
    }

    function _mockSetProfileImageURI() internal virtual {
        _setProfileImageURI(profileOwner, newProfileId, MOCK_URI);
    }

    function _mockSetFollowNFTURI() internal virtual {
        _setFollowNFTURI(profileOwner, newProfileId, MOCK_URI);
    }

    function _mockPost() internal virtual {
        vm.prank(profileOwner);
        _post(mockPostParams);
    }

    function _mockComment() internal virtual {
        mockCommentParams.pointedPubId = postId;
        vm.prank(profileOwner);
        _comment(mockCommentParams);
    }

    function _mockMirror() internal virtual {
        mockMirrorParams.pointedPubId = postId;
        vm.prank(profileOwner);
        _mirror(mockMirrorParams);
    }

    function _mockBurn() internal virtual {
        _burn(profileOwner, newProfileId);
    }

    function _mockFollow() internal virtual {
        _follow({
            msgSender: me,
            followerProfileId: followerProfileId,
            idOfProfileToFollow: newProfileId,
            followTokenId: 0,
            data: ''
        });
    }

    // TODO: The following two functions were copy-pasted from CollectingTest.t.sol
    // TODO: Consider extracting them somewhere else to be used by both of tests
    function _mockCollect() internal virtual {
        vm.prank(profileOwner);
        _collect(
            mockCollectParams.collectorProfileId,
            mockCollectParams.publicationCollectedProfileId,
            mockCollectParams.publicationCollectedId,
            mockCollectParams.collectModuleData
        );
    }

    // Negatives
    function testCannotTransferProfileWhilePaused() public virtual {
        vm.expectRevert(Errors.Paused.selector);
        _transferProfile({msgSender: profileOwner, from: profileOwner, to: address(111), tokenId: newProfileId});
    }

    function testCannotCreateProfileWhilePaused() public virtual {
        vm.expectRevert(Errors.Paused.selector);
        _createProfile(address(this));

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _createProfile(address(this));
    }

    function testCannotSetFollowModuleWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockSetFollowModule();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockSetFollowModule();
    }

    function testCannotSetDelegatedExecutorWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockChangeDelegatedExecutorsConfig();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockChangeDelegatedExecutorsConfig();
    }

    function testCannotSetProfileImageURIWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockSetProfileImageURI();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockSetProfileImageURI();
    }

    function testCannotSetFollowNFTURIWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockSetFollowNFTURI();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockSetFollowNFTURI();
    }

    function testCannotPostWhilePaused() public {
        vm.expectRevert(Errors.PublishingPaused.selector);
        _mockPost();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockPost();
    }

    function testCannotCommentWhilePaused() public {
        vm.expectRevert(Errors.PublishingPaused.selector);
        _mockComment();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockComment();
    }

    function testCannotMirrorWhilePaused() public {
        vm.expectRevert(Errors.PublishingPaused.selector);
        _mockMirror();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockMirror();
    }

    function testCannotBurnWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockBurn();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockBurn();
    }

    function testCannotFollowWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockFollow();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockFollow();
    }

    function testCannotCollectWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockCollect();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockCollect();
    }
}

contract MultiStateHubTest_PausedState_WithSig is MultiStateHubTest_PausedState_Direct, SigSetup {
    function setUp() public override(MultiStateHubTest_PausedState_Direct, SigSetup) {
        MultiStateHubTest_PausedState_Direct.setUp();
        SigSetup.setUp();
        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);
        followerProfileId = _createProfile(otherSigner);
        vm.prank(governance);
        _setState(Types.ProtocolState.Paused);
    }

    function _mockSetFollowModule() internal override {
        bytes32 digest = _getSetFollowModuleTypedDataHash(newProfileId, address(0), '', nonce, deadline);

        _setFollowModuleWithSig({
            profileId: newProfileId,
            followModule: address(0),
            followModuleInitData: '',
            signature: _getSigStruct(profileOwner, profileOwnerKey, digest, deadline)
        });
    }

    // Positives
    function _mockChangeDelegatedExecutorsConfig() internal override {
        address executor = otherSigner;

        bytes32 digest = _getChangeDelegatedExecutorsConfigTypedDataHash({
            delegatorProfileId: newProfileId,
            executors: _toAddressArray(executor),
            approvals: _toBoolArray(true),
            configNumber: 0,
            switchToGivenConfig: true,
            nonce: nonce,
            deadline: deadline
        });
        hub.changeDelegatedExecutorsConfigWithSig({
            delegatorProfileId: newProfileId,
            executors: _toAddressArray(executor),
            approvals: _toBoolArray(true),
            configNumber: 0,
            switchToGivenConfig: true,
            signature: _getSigStruct(profileOwner, profileOwnerKey, digest, deadline)
        });
    }

    function _mockSetProfileImageURI() internal override {
        bytes32 digest = _getSetProfileImageURITypedDataHash(newProfileId, MOCK_URI, nonce, deadline);

        _setProfileImageURIWithSig({
            profileId: newProfileId,
            imageURI: MOCK_URI,
            signature: _getSigStruct(profileOwner, profileOwnerKey, digest, deadline)
        });
    }

    function _mockSetFollowNFTURI() internal override {
        bytes32 digest = _getSetFollowNFTURITypedDataHash(newProfileId, MOCK_URI, nonce, deadline);

        _setFollowNFTURIWithSig({
            profileId: newProfileId,
            followNFTURI: MOCK_URI,
            signature: _getSigStruct(profileOwner, profileOwnerKey, digest, deadline)
        });
    }

    function _mockPost() internal override {
        bytes32 digest = _getPostTypedDataHash(mockPostParams, nonce, deadline);

        _postWithSig(mockPostParams, _getSigStruct(profileOwner, profileOwnerKey, digest, deadline));
    }

    function _mockComment() internal override {
        mockCommentParams.pointedPubId = postId;
        bytes32 digest = _getCommentTypedDataHash(mockCommentParams, nonce, deadline);

        _commentWithSig(mockCommentParams, _getSigStruct(profileOwner, profileOwnerKey, digest, deadline));
    }

    function _mockMirror() internal override {
        mockMirrorParams.pointedPubId = postId;
        bytes32 digest = _getMirrorTypedDataHash(mockMirrorParams, nonce, deadline);

        _mirrorWithSig(mockMirrorParams, _getSigStruct(profileOwner, profileOwnerKey, digest, deadline));
    }

    function _mockFollow() internal override {
        bytes32 digest = _getFollowTypedDataHash(
            followerProfileId,
            _toUint256Array(newProfileId),
            _toUint256Array(0),
            _toBytesArray(''),
            nonce,
            deadline
        );

        _followWithSig({
            followerProfileId: followerProfileId,
            idOfProfileToFollow: newProfileId,
            followTokenId: 0,
            data: '',
            signature: _getSigStruct(otherSigner, otherSignerKey, digest, deadline)
        });
    }

    function _mockCollect() internal override {
        bytes32 digest = _getCollectTypedDataHash(mockCollectParams, nonce, deadline);

        _collectWithSig(mockCollectParams, _getSigStruct(profileOwner, profileOwnerKey, digest, deadline));
    }

    // Methods that cannot be called with signature
    function testCannotTransferProfileWhilePaused() public override {}

    function testCannotCreateProfileWhilePaused() public override {}
}

contract MultiStateHubTest_PublishingPausedState_Direct is BaseTest {
    uint256 postId;

    function setUp() public virtual override {
        super.setUp();

        vm.prank(profileOwner);
        postId = _post(mockPostParams);

        vm.prank(governance);
        _setState(Types.ProtocolState.PublishingPaused);
    }

    // TODO: Consider extracting these mock actions functions somewhere because they're used in several places
    function _mockSetFollowModule() internal virtual {
        _setFollowModule(profileOwner, newProfileId, address(0), '');
    }

    function _mockChangeDelegatedExecutorsConfig() internal virtual {
        address executor = otherSigner;
        bool approved = true;
        _changeDelegatedExecutorsConfig(profileOwner, newProfileId, executor, approved);
    }

    function _mockSetProfileImageURI() internal virtual {
        _setProfileImageURI(profileOwner, newProfileId, MOCK_URI);
    }

    function _mockSetFollowNFTURI() internal virtual {
        _setFollowNFTURI(profileOwner, newProfileId, MOCK_URI);
    }

    function _mockPost() internal virtual {
        vm.prank(profileOwner);
        _post(mockPostParams);
    }

    function _mockComment() internal virtual {
        mockCommentParams.pointedPubId = postId;
        vm.prank(profileOwner);
        _comment(mockCommentParams);
    }

    function _mockMirror() internal virtual {
        mockMirrorParams.pointedPubId = postId;
        vm.prank(profileOwner);
        _mirror(mockMirrorParams);
    }

    function _mockBurn() internal virtual {
        _burn(profileOwner, newProfileId);
    }

    function _mockFollow() internal virtual {
        _follow({
            msgSender: me,
            followerProfileId: _createProfile(me),
            idOfProfileToFollow: newProfileId,
            followTokenId: 0,
            data: ''
        });
    }

    // TODO: The following two functions were copy-pasted from CollectingTest.t.sol
    // TODO: Consider extracting them somewhere else to be used by both of tests
    function _mockCollect() internal virtual {
        vm.prank(profileOwner);
        _collect(
            mockCollectParams.collectorProfileId,
            mockCollectParams.publicationCollectedProfileId,
            mockCollectParams.publicationCollectedId,
            mockCollectParams.collectModuleData
        );
    }

    // Negatives
    function testCanTransferProfileWhilePublishingPaused() public virtual {
        _transferProfile({msgSender: profileOwner, from: profileOwner, to: address(111), tokenId: newProfileId});
    }

    function testCanCreateProfileWhilePublishingPaused() public virtual {
        _createProfile(address(this));
    }

    function testCanSetFollowModuleWhilePublishingPaused() public {
        _mockSetFollowModule();
    }

    function testCanSetDelegatedExecutorWhilePublishingPaused() public {
        _mockChangeDelegatedExecutorsConfig();
    }

    function testCanSetProfileImageURIWhilePublishingPaused() public {
        _mockSetProfileImageURI();
    }

    function testCanSetFollowNFTURIWhilePublishingPaused() public {
        _mockSetFollowNFTURI();
    }

    function testCanBurnWhilePublishingPaused() public {
        _mockBurn();
    }

    function testCanFollowWhilePublishingPaused() public {
        _mockFollow();
    }

    function testCanCollectWhilePublishingPaused() public {
        _mockCollect();
    }

    function testCannotPostWhilePublishingPaused() public {
        vm.expectRevert(Errors.PublishingPaused.selector);
        _mockPost();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockPost();
    }

    function testCannotCommentWhilePublishingPaused() public {
        vm.expectRevert(Errors.PublishingPaused.selector);
        _mockComment();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockComment();
    }

    function testCannotMirrorWhilePublishingPaused() public {
        vm.expectRevert(Errors.PublishingPaused.selector);
        _mockMirror();

        vm.prank(governance);
        _setState(Types.ProtocolState.Unpaused);

        _mockMirror();
    }
}

contract MultiStateHubTest_PublishingPausedState_WithSig is MultiStateHubTest_PublishingPausedState_Direct, SigSetup {
    // TODO: Consider refactoring this contract somehow cause it's all just pure copy-paste of the PausedState_WithSig
    function setUp() public override(MultiStateHubTest_PublishingPausedState_Direct, SigSetup) {
        MultiStateHubTest_PublishingPausedState_Direct.setUp();
        SigSetup.setUp();
    }

    function _mockSetFollowModule() internal override {
        bytes32 digest = _getSetFollowModuleTypedDataHash(newProfileId, address(0), '', nonce, deadline);

        _setFollowModuleWithSig({
            profileId: newProfileId,
            followModule: address(0),
            followModuleInitData: '',
            signature: _getSigStruct(profileOwner, profileOwnerKey, digest, deadline)
        });
    }

    // Positives
    function _mockChangeDelegatedExecutorsConfig() internal override {
        address executor = otherSigner;

        bytes32 digest = _getChangeDelegatedExecutorsConfigTypedDataHash({
            delegatorProfileId: newProfileId,
            executors: _toAddressArray(executor),
            approvals: _toBoolArray(true),
            configNumber: 0,
            switchToGivenConfig: true,
            nonce: nonce,
            deadline: deadline
        });
        hub.changeDelegatedExecutorsConfigWithSig({
            delegatorProfileId: newProfileId,
            executors: _toAddressArray(executor),
            approvals: _toBoolArray(true),
            configNumber: 0,
            switchToGivenConfig: true,
            signature: _getSigStruct(profileOwner, profileOwnerKey, digest, deadline)
        });
    }

    function _mockSetProfileImageURI() internal override {
        bytes32 digest = _getSetProfileImageURITypedDataHash(newProfileId, MOCK_URI, nonce, deadline);

        _setProfileImageURIWithSig({
            profileId: newProfileId,
            imageURI: MOCK_URI,
            signature: _getSigStruct(profileOwner, profileOwnerKey, digest, deadline)
        });
    }

    function _mockSetFollowNFTURI() internal override {
        bytes32 digest = _getSetFollowNFTURITypedDataHash(newProfileId, MOCK_URI, nonce, deadline);

        _setFollowNFTURIWithSig({
            profileId: newProfileId,
            followNFTURI: MOCK_URI,
            signature: _getSigStruct(profileOwner, profileOwnerKey, digest, deadline)
        });
    }

    function _mockPost() internal override {
        bytes32 digest = _getPostTypedDataHash(mockPostParams, nonce, deadline);

        _postWithSig(mockPostParams, _getSigStruct(profileOwner, profileOwnerKey, digest, deadline));
    }

    function _mockComment() internal override {
        mockCommentParams.pointedPubId = postId;
        bytes32 digest = _getCommentTypedDataHash(mockCommentParams, nonce, deadline);

        _commentWithSig(mockCommentParams, _getSigStruct(profileOwner, profileOwnerKey, digest, deadline));
    }

    function _mockMirror() internal override {
        mockMirrorParams.pointedPubId = postId;
        bytes32 digest = _getMirrorTypedDataHash(mockMirrorParams, nonce, deadline);

        _mirrorWithSig(mockMirrorParams, _getSigStruct(profileOwner, profileOwnerKey, digest, deadline));
    }

    function _mockFollow() internal override {
        uint256 followerProfileId = _createProfile(otherSigner);
        bytes32 digest = _getFollowTypedDataHash(
            followerProfileId,
            _toUint256Array(newProfileId),
            _toUint256Array(0),
            _toBytesArray(''),
            nonce,
            deadline
        );

        _followWithSig({
            followerProfileId: followerProfileId,
            idOfProfileToFollow: newProfileId,
            followTokenId: 0,
            data: '',
            signature: _getSigStruct(otherSigner, otherSignerKey, digest, deadline)
        });
    }

    function _mockCollect() internal override {
        bytes32 digest = _getCollectTypedDataHash(mockCollectParams, nonce, deadline);

        _collectWithSig(mockCollectParams, _getSigStruct(profileOwner, profileOwnerKey, digest, deadline));
    }

    // Methods that cannot be called with signature
    function testCanTransferProfileWhilePublishingPaused() public override {}

    function testCanCreateProfileWhilePublishingPaused() public override {}
}
