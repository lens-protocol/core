// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './helpers/SignatureHelpers.sol';

contract MultiStateHubTest_Common is BaseTest {
    // Negatives
    function testCannotSetStateAsRegularUser() public {
        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(DataTypes.ProtocolState.Paused);

        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(DataTypes.ProtocolState.PublishingPaused);

        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(DataTypes.ProtocolState.Unpaused);
    }

    function testCannotSetEmergencyAdminAsRegularUser() public {
        vm.expectRevert(Errors.NotGovernance.selector);
        _setEmergencyAdmin(address(this));
    }

    function testCannotUnpauseAsEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        vm.expectRevert(Errors.EmergencyAdminCanOnlyPauseFurther.selector);
        _setState(DataTypes.ProtocolState.Unpaused);
    }

    function testCannotSetLowerStateAsEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        _setState(DataTypes.ProtocolState.Paused);

        vm.expectRevert(Errors.EmergencyAdminCanOnlyPauseFurther.selector);
        _setState(DataTypes.ProtocolState.PublishingPaused);

        vm.expectRevert(Errors.EmergencyAdminCanOnlyPauseFurther.selector);
        _setState(DataTypes.ProtocolState.Paused);
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

        DataTypes.ProtocolState[2] memory states = [
            DataTypes.ProtocolState.PublishingPaused,
            DataTypes.ProtocolState.Paused
        ];

        for (uint256 i = 0; i < states.length; i++) {
            DataTypes.ProtocolState newState = states[i];
            DataTypes.ProtocolState prevState = _getState();
            _setState(newState);
            DataTypes.ProtocolState curState = _getState();
            assertTrue(newState == curState);
            assertTrue(curState != prevState);
        }
    }

    function testSetProtocolStateAsGovernance() public {
        vm.startPrank(governance);

        DataTypes.ProtocolState[6] memory states = [
            DataTypes.ProtocolState.PublishingPaused,
            DataTypes.ProtocolState.Paused,
            DataTypes.ProtocolState.Unpaused,
            DataTypes.ProtocolState.Paused,
            DataTypes.ProtocolState.PublishingPaused,
            DataTypes.ProtocolState.Unpaused
        ];

        for (uint256 i = 0; i < states.length; i++) {
            DataTypes.ProtocolState newState = states[i];
            DataTypes.ProtocolState prevState = _getState();
            _setState(newState);
            DataTypes.ProtocolState curState = _getState();
            assertTrue(newState == curState);
            assertTrue(curState != prevState);
        }
        vm.stopPrank();
    }

    function testGovernanceCanRevokeEmergencyAdmin() public {
        vm.prank(governance);
        _setEmergencyAdmin(address(this));

        _setState(DataTypes.ProtocolState.PublishingPaused);

        vm.prank(governance);
        _setEmergencyAdmin(address(0));

        vm.expectRevert(Errors.NotGovernanceOrEmergencyAdmin.selector);
        _setState(DataTypes.ProtocolState.Paused);
    }
}

contract MultiStateHubTest_PausedState_Direct is BaseTest {
    uint256 postId;

    function setUp() public virtual override {
        super.setUp();

        vm.prank(profileOwner);
        postId = _post(mockPostData);

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Paused);
    }

    function _mockSetFollowModule() internal virtual {
        _setFollowModule(profileOwner, newProfileId, address(0), '');
    }

    function _mockSetDelegatedExecutorApproval() internal virtual {
        address executor = otherSigner;
        bool approved = true;
        _setDelegatedExecutorApproval(profileOwner, executor, approved);
    }

    function _mockSetProfileImageURI() internal virtual {
        _setProfileImageURI(profileOwner, newProfileId, MOCK_URI);
    }

    function _mockSetFollowNFTURI() internal virtual {
        _setFollowNFTURI(profileOwner, newProfileId, MOCK_URI);
    }

    function _mockPost() internal virtual {
        vm.prank(profileOwner);
        _post(mockPostData);
    }

    function _mockComment() internal virtual {
        mockCommentData.pubIdPointed = postId;
        vm.prank(profileOwner);
        _comment(mockCommentData);
    }

    function _mockMirror() internal virtual {
        mockMirrorData.pubIdPointed = postId;
        vm.prank(profileOwner);
        _mirror(mockMirrorData);
    }

    function _mockBurn() internal virtual {
        _burn(profileOwner, newProfileId);
    }

    function _mockFollow() internal virtual {
        _follow({msgSender: me, onBehalfOf: me, profileId: newProfileId, data: ''});
    }

    // TODO: The following two functions were copy-pasted from CollectingTest.t.sol
    // TODO: Consider extracting them somewhere else to be used by both of tests
    function _mockCollect() internal virtual {
        vm.prank(profileOwner);
        _collect(
            mockCollectData.collector,
            mockCollectData.profileId,
            mockCollectData.pubId,
            mockCollectData.data
        );
    }

    // Negatives
    function testCannotTransferProfileWhilePaused() public virtual {
        vm.expectRevert(Errors.Paused.selector);
        _transferProfile({
            msgSender: profileOwner,
            from: profileOwner,
            to: address(111),
            tokenId: newProfileId
        });
    }

    function testCannotCreateProfileWhilePaused() public virtual {
        vm.expectRevert(Errors.Paused.selector);
        _createProfile(address(this));

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _createProfile(address(this));
    }

    function testCannotSetFollowModuleWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockSetFollowModule();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockSetFollowModule();
    }

    function testCannotSetDelegatedExecutorWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockSetDelegatedExecutorApproval();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockSetDelegatedExecutorApproval();
    }

    function testCannotSetProfileImageURIWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockSetProfileImageURI();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockSetProfileImageURI();
    }

    function testCannotSetFollowNFTURIWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockSetFollowNFTURI();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockSetFollowNFTURI();
    }

    function testCannotPostWhilePaused() public {
        vm.expectRevert(Errors.PublishingPaused.selector);
        _mockPost();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockPost();
    }

    function testCannotCommentWhilePaused() public {
        vm.expectRevert(Errors.PublishingPaused.selector);
        _mockComment();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockComment();
    }

    function testCannotMirrorWhilePaused() public {
        vm.expectRevert(Errors.PublishingPaused.selector);
        _mockMirror();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockMirror();
    }

    function testCannotBurnWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockBurn();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockBurn();
    }

    function testCannotFollowWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockFollow();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockFollow();
    }

    function testCannotCollectWhilePaused() public {
        vm.expectRevert(Errors.Paused.selector);
        _mockCollect();

        vm.prank(governance);
        _setState(DataTypes.ProtocolState.Unpaused);

        _mockCollect();
    }
}

contract MultiStateHubTest_PausedState_WithSig is
    MultiStateHubTest_PausedState_Direct,
    SignatureHelpers,
    SigSetup
{
    function setUp() public override(MultiStateHubTest_PausedState_Direct, SigSetup) {
        MultiStateHubTest_PausedState_Direct.setUp();
        SigSetup.setUp();
    }

    function _mockSetFollowModule() internal override {
        bytes32 digest = _getSetFollowModuleTypedDataHash(
            newProfileId,
            address(0),
            '',
            nonce,
            deadline
        );

        _setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
                followModule: address(0),
                followModuleInitData: '',
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    // Positives
    function _mockSetDelegatedExecutorApproval() internal override {
        address onBehalfOf = profileOwner;
        address executor = otherSigner;

        bytes32 digest = _getSetDelegatedExecutorApprovalTypedDataHash({
            onBehalfOf: onBehalfOf,
            executor: executor,
            approved: true,
            nonce: nonce,
            deadline: deadline
        });
        hub.setDelegatedExecutorApprovalWithSig(
            _buildSetDelegatedExecutorApprovalWithSigData({
                onBehalfOf: onBehalfOf,
                executor: executor,
                approved: true,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    function _mockSetProfileImageURI() internal override {
        bytes32 digest = _getSetProfileImageURITypedDataHash(
            newProfileId,
            MOCK_URI,
            nonce,
            deadline
        );

        _setProfileImageURIWithSig(
            DataTypes.SetProfileImageURIWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
                imageURI: MOCK_URI,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    function _mockSetFollowNFTURI() internal override {
        bytes32 digest = _getSetFollowNFTURITypedDataHash(newProfileId, MOCK_URI, nonce, deadline);

        _setFollowNFTURIWithSig(
            DataTypes.SetFollowNFTURIWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
                followNFTURI: MOCK_URI,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    function _mockPost() internal override {
        bytes32 digest = _getPostTypedDataHash(mockPostData, nonce, deadline);

        _postWithSig(
            _buildPostWithSigData({
                delegatedSigner: address(0),
                postData: mockPostData,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    function _mockComment() internal override {
        mockCommentData.pubIdPointed = postId;
        bytes32 digest = _getCommentTypedDataHash(mockCommentData, nonce, deadline);

        _commentWithSig(
            _buildCommentWithSigData({
                delegatedSigner: address(0),
                commentData: mockCommentData,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    function _mockMirror() internal override {
        mockMirrorData.pubIdPointed = postId;
        bytes32 digest = _getMirrorTypedDataHash(mockMirrorData, nonce, deadline);

        _mirrorWithSig(
            _buildMirrorWithSigData({
                delegatedSigner: address(0),
                mirrorData: mockMirrorData,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    function _mockBurn() internal override {
        bytes32 digest = _getBurnTypedDataHash(newProfileId, nonce, deadline);

        _burnWithSig({
            profileId: newProfileId,
            sig: _getSigStruct(profileOwnerKey, digest, deadline)
        });
    }

    function _mockFollow() internal override {
        bytes32 digest = _getFollowTypedDataHash(
            _toUint256Array(newProfileId),
            _toBytesArray(''),
            nonce,
            deadline
        );

        uint256[] memory nftIds = _followWithSig(
            _buildFollowWithSigData({
                delegatedSigner: address(0),
                follower: otherSigner,
                profileIds: _toUint256Array(newProfileId),
                datas: _toBytesArray(''),
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function _mockCollect() internal override {
        bytes32 digest = _getCollectTypedDataHash(
            mockCollectData.profileId,
            mockCollectData.pubId,
            mockCollectData.data,
            nonce,
            deadline
        );

        _collectWithSig(
            _buildCollectWithSigData({
                delegatedSigner: address(0),
                collectData: mockCollectData,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    // Methods that cannot be called with sig
    function testCannotTransferProfileWhilePaused() public override {}

    function testCannotCreateProfileWhilePaused() public override {}
}
