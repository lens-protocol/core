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
        mockPostData.collectModule = address(0xC0FFEE);
        replicateInitData();
        vm.prank(profileOwner);
        vm.expectRevert(Errors.CollectModuleNotWhitelisted.selector);
        _publish();
    }

    function testCannotPublishNotWhitelistedReferenceModule() public {
        mockPostData.referenceModule = address(0xC0FFEE);
        replicateInitData();
        vm.prank(profileOwner);
        vm.expectRevert(Errors.ReferenceModuleNotWhitelisted.selector);
        _publish();
    }

    function testCannotPublishWithSigNotWhitelistedCollectModule() public virtual {
        mockPostData.collectModule = address(0xC0FFEE);
        replicateInitData();
        vm.expectRevert(Errors.CollectModuleNotWhitelisted.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotPublishWithSigNotWhitelistedReferenceModule() public {
        mockPostData.referenceModule = address(0xC0FFEE);
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
        mockPostData.referenceModule = address(mockReferenceModule);
        mockPostData.referenceModuleInitData = abi.encode(1);
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
        _setDelegatedExecutorApproval(profileOwner, otherSigner, true);

        uint256 expectedPubId = _getPubCount(newProfileId) + 1;

        vm.prank(otherSigner);
        uint256 pubId = _publish();
        assertEq(pubId, expectedPubId);

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testExecutorPublishWithSig() public {
        _setDelegatedExecutorApproval(profileOwner, otherSigner, true);

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
        return _post(mockPostData);
    }

    function _publishWithSig(
        address delegatedSigner,
        uint256 signerPrivKey,
        uint256 digestDeadline,
        uint256 sigDeadline
    ) internal virtual override returns (uint256) {
        bytes32 digest = _getPostTypedDataHash(mockPostData, nonce, digestDeadline);

        return
            _postWithSig(
                _buildPostWithSigData(
                    delegatedSigner,
                    mockPostData,
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
        return _expectedPubFromInitData(mockPostData);
    }
}

contract CommentTest is PublishingTest {
    uint256 postId;

    function replicateInitData() internal override {
        mockCommentData.profileId = mockPostData.profileId;
        mockCommentData.contentURI = mockPostData.contentURI;
        mockCommentData.collectModule = mockPostData.collectModule;
        mockCommentData.collectModuleInitData = mockPostData.collectModuleInitData;
        mockCommentData.referenceModule = mockPostData.referenceModule;
        mockCommentData.referenceModuleInitData = mockPostData.referenceModuleInitData;
    }

    function _publish() internal override returns (uint256) {
        return _comment(mockCommentData);
    }

    function _publishWithSig(
        address delegatedSigner,
        uint256 signerPrivKey,
        uint256 digestDeadline,
        uint256 sigDeadline
    ) internal override returns (uint256) {
        bytes32 digest = _getCommentTypedDataHash(mockCommentData, nonce, digestDeadline);

        return
            _commentWithSig(
                _buildCommentWithSigData(
                    delegatedSigner,
                    mockCommentData,
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
        return _expectedPubFromInitData(mockCommentData);
    }

    function setUp() public override {
        PublishingTest.setUp();

        vm.prank(profileOwner);
        postId = _post(mockPostData);
    }

    // negatives
    function testCannotCommentOnNonExistentPublication() public {
        uint256 nonExistentPubId = _getPubCount(newProfileId) + 10;

        replicateInitData();
        mockCommentData.pubIdPointed = nonExistentPubId;

        vm.prank(profileOwner);
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _publish();
    }

    function testCannotCommentWithSigOnNonExistentPublication() public {
        uint256 nonExistentPubId = _getPubCount(newProfileId) + 10;

        replicateInitData();
        mockCommentData.pubIdPointed = nonExistentPubId;

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotCommentOnTheSamePublicationBeingCreated() public {
        uint256 nextPubId = _getPubCount(newProfileId) + 1;

        replicateInitData();
        mockCommentData.pubIdPointed = nextPubId;

        vm.prank(profileOwner);
        vm.expectRevert(Errors.CannotCommentOnSelf.selector);
        _publish();
    }

    function testCannotCommentWithSigOnTheSamePublicationBeingCreated() public {
        uint256 nextPubId = _getPubCount(newProfileId) + 1;

        replicateInitData();
        mockCommentData.pubIdPointed = nextPubId;

        vm.expectRevert(Errors.CannotCommentOnSelf.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    // scenarios
    function testPostWithReferenceModuleAndComment() public {
        mockPostData.referenceModule = address(mockReferenceModule);
        mockPostData.referenceModuleInitData = abi.encode(1);
        vm.prank(profileOwner);
        postId = _post(mockPostData);

        mockCommentData.pubIdPointed = postId;
        vm.prank(profileOwner);
        uint256 commentPubId = _publish();

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, commentPubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }
}

contract MirrorTest is PublishingTest {
    uint256 postId;

    function replicateInitData() internal override {
        mockMirrorData.profileId = mockPostData.profileId;
        mockMirrorData.referenceModule = mockPostData.referenceModule;
        mockMirrorData.referenceModuleInitData = mockPostData.referenceModuleInitData;
    }

    function _publish() internal override returns (uint256) {
        return _mirror(mockMirrorData);
    }

    function _publishWithSig(
        address delegatedSigner,
        uint256 signerPrivKey,
        uint256 digestDeadline,
        uint256 sigDeadline
    ) internal override returns (uint256) {
        bytes32 digest = _getMirrorTypedDataHash(mockMirrorData, nonce, digestDeadline);

        return
            _mirrorWithSig(
                _buildMirrorWithSigData(
                    delegatedSigner,
                    mockMirrorData,
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
        return _expectedPubFromInitData(mockMirrorData);
    }

    function setUp() public override {
        PublishingTest.setUp();

        vm.prank(profileOwner);
        postId = _post(mockPostData);
    }

    // ignored - these tests don't apply to mirrors
    function testCannotPublishNotWhitelistedCollectModule() public override {}

    function testCannotPublishWithSigNotWhitelistedCollectModule() public override {}

    // negatives

    function testCannotMirrorNonExistentPublication() public {
        uint256 nonExistentPubId = _getPubCount(newProfileId) + 10;

        replicateInitData();
        mockMirrorData.pubIdPointed = nonExistentPubId;

        vm.prank(profileOwner);
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _publish();
    }

    function testCannotMirrorWithSigNonExistentPublication() public {
        uint256 nonExistentPubId = _getPubCount(newProfileId) + 10;

        replicateInitData();
        mockMirrorData.pubIdPointed = nonExistentPubId;

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    // scenarios
    function testMirrorAnotherMirrorShouldPointToOriginalPost() public {
        mockMirrorData.pubIdPointed = postId;
        vm.prank(profileOwner);
        uint256 firstMirrorId = _publish();

        mockMirrorData.pubIdPointed = firstMirrorId;
        vm.prank(profileOwner);
        uint256 secondMirrorId = _publish();

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, secondMirrorId);
        mockMirrorData.pubIdPointed = postId; // We're expecting a mirror to point at the original post ID
        _verifyPublication(pub, _expectedPubFromInitData(mockMirrorData));
    }

    function testMirrorAnotherMirrorWithSigShouldPointToOriginalPost() public {
        mockMirrorData.pubIdPointed = postId;
        vm.prank(profileOwner);
        uint256 firstMirrorId = _publish();

        mockMirrorData.pubIdPointed = firstMirrorId;
        uint256 secondMirrorId = _publishWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey
        });

        DataTypes.PublicationStruct memory pub = _getPub(newProfileId, secondMirrorId);
        mockMirrorData.pubIdPointed = postId; // We're expecting a mirror to point at the original post ID
        _verifyPublication(pub, _expectedPubFromInitData(mockMirrorData));
    }
}
