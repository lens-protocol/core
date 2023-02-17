// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './helpers/SignatureHelpers.sol';
import {PublishingHelpers} from './helpers/PublishingHelpers.sol';

abstract contract PublishingTest is BaseTest, SignatureHelpers, PublishingHelpers, SigSetup {
    function replicateInitData() internal virtual {
        // Default implementation does nothing.
    }

    function _publish() internal virtual returns (uint256);

    function _publishWithSig(
        address delegatedSigner,
        uint256 signerPrivKey,
        uint256 digestDeadline,
        uint256 sigDeadline
    ) internal virtual returns (uint256);

    function _publishWithSig(address delegatedSigner, uint256 signerPrivKey)
        internal
        virtual
        returns (uint256)
    {
        return _publishWithSig(delegatedSigner, signerPrivKey, deadline, deadline);
    }

    function _expectedPubFromInitData()
        internal
        view
        virtual
        returns (DataTypes.PublicationStruct memory);

    function setUp() public virtual override(SigSetup, TestSetup) {
        TestSetup.setUp();
        SigSetup.setUp();
    }

    // negatives
    function testCannotPublishIfNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _publish();
    }

    function testCannotPublishNotWhitelistedCollectModule() public virtual {
        mockPostParams.collectModule = address(0xC0FFEE);
        replicateInitData();
        vm.prank(profileOwner);
        vm.expectRevert(Errors.CollectModuleNotWhitelisted.selector);
        _publish();
    }

    function testCannotPublishNotWhitelistedReferenceModule() public virtual {
        mockPostParams.referenceModule = address(0xC0FFEE);
        replicateInitData();
        vm.prank(profileOwner);
        vm.expectRevert(Errors.ReferenceModuleNotWhitelisted.selector);
        _publish();
    }

    function testCannotPublishWithSigNotWhitelistedCollectModule() public virtual {
        mockPostParams.collectModule = address(0xC0FFEE);
        replicateInitData();
        vm.expectRevert(Errors.CollectModuleNotWhitelisted.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotPublishWithSigNotWhitelistedReferenceModule() public virtual {
        mockPostParams.referenceModule = address(0xC0FFEE);
        replicateInitData();
        vm.expectRevert(Errors.ReferenceModuleNotWhitelisted.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotPublishWithSigInvalidSigner() public {
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: otherSignerKey});
    }

    function testCannotPublishWithSigInvalidNonce() public {
        nonce = _getSigNonce(otherSigner) + 1;
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: otherSignerKey});
    }

    function testCannotPublishWithSigInvalidDeadline() public {
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _publishWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey,
            digestDeadline: type(uint256).max,
            sigDeadline: block.timestamp + 10
        });
    }

    function testCannotPublishIfNonceWasIncrementedWithAnotherAction() public {
        assertEq(_getSigNonce(profileOwner), nonce, 'Wrong nonce before posting');

        uint256 expectedPubId = _getPubCount(newProfileId) + 1;

        uint256 pubId = _publishWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey
        });
        assertEq(pubId, expectedPubId, 'Wrong pubId');

        assertTrue(_getSigNonce(profileOwner) != nonce, 'Wrong nonce after posting');

        vm.expectRevert(Errors.SignatureInvalid.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotPublishWithSigExpiredDeadline() public {
        deadline = 10;
        vm.warp(20);

        vm.expectRevert(Errors.SignatureExpired.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: otherSignerKey});
    }

    function testCannotPublishWithSigNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _publishWithSig({delegatedSigner: otherSigner, signerPrivKey: otherSignerKey});
    }

    // positives
    function testPublish() public {
        uint256 expectedPubId = _getPubCount(newProfileId) + 1;

        vm.prank(profileOwner);
        uint256 pubId = _publish();

        assertEq(pubId, expectedPubId);

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testPublishWithAWhitelistedReferenceModule() public {
        mockPostParams.referenceModule = address(mockReferenceModule);
        mockPostParams.referenceModuleInitData = abi.encode(1);
        replicateInitData();

        uint256 expectedPubId = _getPubCount(newProfileId) + 1;

        vm.prank(profileOwner);
        uint256 pubId = _publish();

        assertEq(pubId, expectedPubId);

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testPublishWithSig() public {
        uint256 expectedPubId = _getPubCount(newProfileId) + 1;

        uint256 pubId = _publishWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey
        });
        assertEq(pubId, expectedPubId);

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testExecutorPublish() public {
        _changeDelegatedExecutorsConfig(profileOwner, newProfileId, otherSigner, true);

        uint256 expectedPubId = _getPubCount(newProfileId) + 1;

        vm.prank(otherSigner);
        uint256 pubId = _publish();
        assertEq(pubId, expectedPubId);

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testExecutorPublishWithSig() public {
        _changeDelegatedExecutorsConfig(profileOwner, newProfileId, otherSigner, true);

        uint256 expectedPubId = _getPubCount(newProfileId) + 1;
        uint256 pubId = _publishWithSig({
            delegatedSigner: otherSigner,
            signerPrivKey: otherSignerKey
        });
        assertEq(pubId, expectedPubId);

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }
}

contract PostTest is PublishingTest {
    function _publish() internal virtual override returns (uint256) {
        return _post(mockPostParams);
    }

    function _publishWithSig(
        address delegatedSigner,
        uint256 signerPrivKey,
        uint256 digestDeadline,
        uint256 sigDeadline
    ) internal virtual override returns (uint256) {
        bytes32 digest = _getPostTypedDataHash(mockPostParams, nonce, digestDeadline);

        return
            _postWithSig(
                _buildPostWithSigData(
                    delegatedSigner,
                    mockPostParams,
                    _getSigStruct(signerPrivKey, digest, sigDeadline)
                )
            );
    }

    function _expectedPubFromInitData()
        internal
        view
        virtual
        override
        returns (DataTypes.PublicationStruct memory)
    {
        return _expectedPubFromInitData(mockPostParams);
    }
}

contract CommentTest is PublishingTest {
    uint256 postId;

    function replicateInitData() internal override {
        mockCommentParams.profileId = mockPostParams.profileId;
        mockCommentParams.contentURI = mockPostParams.contentURI;
        mockCommentParams.collectModule = mockPostParams.collectModule;
        mockCommentParams.collectModuleInitData = mockPostParams.collectModuleInitData;
        mockCommentParams.referenceModule = mockPostParams.referenceModule;
        mockCommentParams.referenceModuleInitData = mockPostParams.referenceModuleInitData;
    }

    function _publish() internal override returns (uint256) {
        return _comment(mockCommentParams);
    }

    function _publishWithSig(
        address delegatedSigner,
        uint256 signerPrivKey,
        uint256 digestDeadline,
        uint256 sigDeadline
    ) internal override returns (uint256) {
        bytes32 digest = _getCommentTypedDataHash(mockCommentParams, nonce, digestDeadline);

        return
            _commentWithSig(
                _buildCommentWithSigData(
                    delegatedSigner,
                    mockCommentParams,
                    _getSigStruct(signerPrivKey, digest, sigDeadline)
                )
            );
    }

    function _expectedPubFromInitData()
        internal
        view
        override
        returns (DataTypes.PublicationStruct memory)
    {
        return _expectedPubFromInitData(mockCommentParams);
    }

    function setUp() public override {
        PublishingTest.setUp();

        vm.prank(profileOwner);
        postId = _post(mockPostParams);
    }

    // negatives
    function testCannotCommentOnNonExistentPublication() public {
        uint256 nonExistentPubId = _getPubCount(newProfileId) + 10;

        replicateInitData();
        mockCommentParams.pointedPubId = nonExistentPubId;

        vm.prank(profileOwner);
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _publish();
    }

    function testCannotCommentWithSigOnNonExistentPublication() public {
        uint256 nonExistentPubId = _getPubCount(newProfileId) + 10;

        replicateInitData();
        mockCommentParams.pointedPubId = nonExistentPubId;

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotCommentOnTheSamePublicationBeingCreated() public {
        uint256 nextPubId = _getPubCount(newProfileId) + 1;

        replicateInitData();
        mockCommentParams.pointedPubId = nextPubId;

        vm.prank(profileOwner);
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _publish();
    }

    function testCannotCommentWithSigOnTheSamePublicationBeingCreated() public {
        uint256 nextPubId = _getPubCount(newProfileId) + 1;

        replicateInitData();
        mockCommentParams.pointedPubId = nextPubId;

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotCommentIfBlocked() public {
        uint256 commenterProfileId = _createProfile(profileOwner);
        mockCommentParams.profileId = commenterProfileId;
        vm.prank(profileOwner);
        hub.setBlockStatus(
            mockPostParams.profileId,
            _toUint256Array(commenterProfileId),
            _toBoolArray(true)
        );
        vm.expectRevert(Errors.Blocked.selector);
        vm.prank(profileOwner);
        _publish();
    }

    function testCannotCommentWithSigIfBlocked() public {
        uint256 commenterProfileId = _createProfile(profileOwner);
        mockCommentParams.profileId = commenterProfileId;
        vm.prank(profileOwner);
        hub.setBlockStatus(
            mockPostParams.profileId,
            _toUint256Array(commenterProfileId),
            _toBoolArray(true)
        );
        vm.expectRevert(Errors.Blocked.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    // scenarios
    function testPostWithReferenceModuleAndComment() public {
        mockPostParams.referenceModule = address(mockReferenceModule);
        mockPostParams.referenceModuleInitData = abi.encode(1);
        vm.prank(profileOwner);
        postId = _post(mockPostParams);

        mockCommentParams.pointedPubId = postId;
        vm.prank(profileOwner);
        uint256 commentPubId = _publish();

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, commentPubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testCommentOnMirrorShouldPointToOriginalPost() public {
        mockMirrorParams.pointedPubId = postId;
        vm.prank(profileOwner);
        uint256 mirrorId = _mirror(mockMirrorParams);

        mockCommentParams.pointedPubId = mirrorId;
        vm.prank(profileOwner);
        uint256 commentId = _publish();

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, commentId);
        mockCommentParams.pointedPubId = postId; // We're expecting a mirror to point at the original post ID
        _verifyPublication(pub, _expectedPubFromInitData(mockCommentParams));
    }

    function testCommentWithSigOnMirrorShouldPointToOriginalPost() public {
        mockMirrorParams.pointedPubId = postId;
        vm.prank(profileOwner);
        uint256 mirrorId = _mirror(mockMirrorParams);

        mockCommentParams.pointedPubId = mirrorId;
        uint256 commentId = _publishWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey
        });

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, commentId);
        mockCommentParams.pointedPubId = postId; // We're expecting a mirror to point at the original post ID
        _verifyPublication(pub, _expectedPubFromInitData(mockCommentParams));
    }
}

contract MirrorTest is PublishingTest {
    uint256 postId;

    function replicateInitData() internal override {
        mockMirrorParams.profileId = mockPostParams.profileId;
    }

    function _publish() internal override returns (uint256) {
        return _mirror(mockMirrorParams);
    }

    function _publishWithSig(
        address delegatedSigner,
        uint256 signerPrivKey,
        uint256 digestDeadline,
        uint256 sigDeadline
    ) internal override returns (uint256) {
        bytes32 digest = _getMirrorTypedDataHash(mockMirrorParams, nonce, digestDeadline);

        return
            _mirrorWithSig(
                _buildMirrorWithSigData(
                    delegatedSigner,
                    mockMirrorParams,
                    _getSigStruct(signerPrivKey, digest, sigDeadline)
                )
            );
    }

    function _expectedPubFromInitData()
        internal
        view
        override
        returns (DataTypes.PublicationStruct memory)
    {
        return _expectedPubFromInitData(mockMirrorParams);
    }

    function setUp() public override {
        PublishingTest.setUp();

        vm.prank(profileOwner);
        postId = _post(mockPostParams);
    }

    // ignored - these tests don't apply to mirrors
    function testCannotPublishNotWhitelistedCollectModule() public override {}

    function testCannotPublishWithSigNotWhitelistedCollectModule() public override {}

    function testCannotPublishNotWhitelistedReferenceModule() public override {}

    function testCannotPublishWithSigNotWhitelistedReferenceModule() public override {}

    // negatives

    function testCannotMirrorNonExistentPublication() public {
        uint256 nonExistentPubId = _getPubCount(newProfileId) + 10;

        replicateInitData();
        mockMirrorParams.pointedPubId = nonExistentPubId;

        vm.prank(profileOwner);
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _publish();
    }

    function testCannotMirrorWithSigNonExistentPublication() public {
        uint256 nonExistentPubId = _getPubCount(newProfileId) + 10;

        replicateInitData();
        mockMirrorParams.pointedPubId = nonExistentPubId;

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotMirrorIfBlocked() public {
        uint256 mirrorerProfileId = _createProfile(profileOwner);
        mockMirrorParams.profileId = mirrorerProfileId;
        vm.prank(profileOwner);
        hub.setBlockStatus(
            mockPostParams.profileId,
            _toUint256Array(mirrorerProfileId),
            _toBoolArray(true)
        );
        vm.expectRevert(Errors.Blocked.selector);
        vm.prank(profileOwner);
        _publish();
    }

    function testCannotMirrorWithSigIfBlocked() public {
        uint256 mirrorerProfileId = _createProfile(profileOwner);
        mockMirrorParams.profileId = mirrorerProfileId;
        vm.prank(profileOwner);
        hub.setBlockStatus(
            mockPostParams.profileId,
            _toUint256Array(mirrorerProfileId),
            _toBoolArray(true)
        );
        vm.expectRevert(Errors.Blocked.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    // scenarios
    function testMirrorAnotherMirrorShouldPointToOriginalPost() public {
        mockMirrorParams.pointedPubId = postId;
        vm.prank(profileOwner);
        uint256 firstMirrorId = _publish();

        mockMirrorParams.pointedPubId = firstMirrorId;
        vm.prank(profileOwner);
        uint256 secondMirrorId = _publish();

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, secondMirrorId);
        mockMirrorParams.pointedPubId = postId; // We're expecting a mirror to point at the original post ID
        _verifyPublication(pub, _expectedPubFromInitData(mockMirrorParams));
    }

    function testMirrorAnotherMirrorWithSigShouldPointToOriginalPost() public {
        mockMirrorParams.pointedPubId = postId;
        vm.prank(profileOwner);
        uint256 firstMirrorId = _publish();

        mockMirrorParams.pointedPubId = firstMirrorId;
        uint256 secondMirrorId = _publishWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey
        });

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, secondMirrorId);
        mockMirrorParams.pointedPubId = postId; // We're expecting a mirror to point at the original post ID
        _verifyPublication(pub, _expectedPubFromInitData(mockMirrorParams));
    }
}
