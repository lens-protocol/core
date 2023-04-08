// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/foundry/base/BaseTest.t.sol';
import 'test/foundry/helpers/SignatureHelpers.sol';
import {PublishingHelpers} from 'test/foundry/helpers/PublishingHelpers.sol';

abstract contract PublishingTest is BaseTest, PublishingHelpers, SigSetup {
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

    function _publishWithSig(address delegatedSigner, uint256 signerPrivKey) internal virtual returns (uint256) {
        return _publishWithSig(delegatedSigner, signerPrivKey, deadline, deadline);
    }

    function _expectedPubFromInitData() internal view virtual returns (Types.Publication memory);

    function setUp() public virtual override(SigSetup, TestSetup) {
        TestSetup.setUp();
        SigSetup.setUp();
    }

    // negatives
    function testCannotPublishIfNotDelegatedExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _publish();
    }

    // TODO: Proper test
    // function testCannotPublishNotWhitelistedCollectModule() public virtual {
    //     mockPostParams.collectModule = address(0xC0FFEE);
    //     replicateInitData();
    //     vm.prank(profileOwner);
    //     vm.expectRevert(Errors.NotWhitelisted.selector);
    //     _publish();
    // }

    function testCannotPublishNotWhitelistedReferenceModule() public virtual {
        mockPostParams.referenceModule = address(0xC0FFEE);
        replicateInitData();
        vm.prank(profileOwner);
        vm.expectRevert(Errors.NotWhitelisted.selector);
        _publish();
    }

    // TODO: Proper test
    // function testCannotPublishWithSigNotWhitelistedCollectModule() public virtual {
    //     mockPostParams.collectModule = address(0xC0FFEE);
    //     replicateInitData();
    //     vm.expectRevert(Errors.NotWhitelisted.selector);
    //     _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
    // }

    function testCannotPublishWithSigNotWhitelistedReferenceModule() public virtual {
        mockPostParams.referenceModule = address(0xC0FFEE);
        replicateInitData();
        vm.expectRevert(Errors.NotWhitelisted.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
    }

    function testCannotPublishWithSigInvalidSigner() public {
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: otherSignerKey});
    }

    function testCannotPublishWithSigInvalidNonce() public {
        nonce = _getSigNonce(otherSigner) + 1;
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: otherSignerKey});
    }

    function testCannotPublishWithSigInvalidDeadline() public {
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _publishWithSig({
            delegatedSigner: profileOwner,
            signerPrivKey: profileOwnerKey,
            digestDeadline: type(uint256).max,
            sigDeadline: block.timestamp + 10
        });
    }

    function testCannotPublishIfNonceWasIncrementedWithAnotherAction() public {
        assertEq(_getSigNonce(profileOwner), nonce, 'Wrong nonce before posting');

        uint256 expectedPubId = _getPubCount(newProfileId) + 1;

        uint256 pubId = _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
        assertEq(pubId, expectedPubId, 'Wrong pubId');

        assertTrue(_getSigNonce(profileOwner) != nonce, 'Wrong nonce after posting');

        vm.expectRevert(Errors.SignatureInvalid.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
    }

    function testCannotPublishWithSigExpiredDeadline() public {
        deadline = 10;
        vm.warp(20);

        vm.expectRevert(Errors.SignatureExpired.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: otherSignerKey});
    }

    function testCannotPublishWithSigNotDelegatedExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _publishWithSig({delegatedSigner: otherSigner, signerPrivKey: otherSignerKey});
    }

    // positives
    function testPublish() public {
        uint256 expectedPubId = _getPubCount(newProfileId) + 1;

        vm.prank(profileOwner);
        uint256 pubId = _publish();

        assertEq(pubId, expectedPubId);

        Types.Publication memory pub = _getPub(newProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    // TODO: Can publish without a collect module
    // TODO: Can publish without a reference module

    function testPublishWithAWhitelistedReferenceModule() public {
        mockPostParams.referenceModule = address(mockReferenceModule);
        mockPostParams.referenceModuleInitData = abi.encode(1);
        replicateInitData();

        uint256 expectedPubId = _getPubCount(newProfileId) + 1;

        vm.prank(profileOwner);
        uint256 pubId = _publish();

        assertEq(pubId, expectedPubId);

        Types.Publication memory pub = _getPub(newProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testPublishWithSig() public {
        uint256 expectedPubId = _getPubCount(newProfileId) + 1;

        uint256 pubId = _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
        assertEq(pubId, expectedPubId);

        Types.Publication memory pub = _getPub(newProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testDelegatedExecutorPublish() public {
        _changeDelegatedExecutorsConfig(profileOwner, newProfileId, otherSigner, true);

        uint256 expectedPubId = _getPubCount(newProfileId) + 1;

        vm.prank(otherSigner);
        uint256 pubId = _publish();
        assertEq(pubId, expectedPubId);

        Types.Publication memory pub = _getPub(newProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testDelegatedExecutorPublishWithSig() public {
        _changeDelegatedExecutorsConfig(profileOwner, newProfileId, otherSigner, true);

        uint256 expectedPubId = _getPubCount(newProfileId) + 1;
        uint256 pubId = _publishWithSig({delegatedSigner: otherSigner, signerPrivKey: otherSignerKey});
        assertEq(pubId, expectedPubId);

        Types.Publication memory pub = _getPub(newProfileId, pubId);
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

        return _postWithSig(mockPostParams, _getSigStruct(delegatedSigner, signerPrivKey, digest, sigDeadline));
    }

    function _expectedPubFromInitData() internal view virtual override returns (Types.Publication memory) {
        return _expectedPubFromInitData(mockPostParams);
    }
}

contract CommentTest is PublishingTest {
    uint256 postId;

    function replicateInitData() internal override {
        mockCommentParams.profileId = mockPostParams.profileId;
        mockCommentParams.contentURI = mockPostParams.contentURI;
        mockCommentParams.actionModules = mockPostParams.actionModules;
        mockCommentParams.actionModulesInitDatas = mockPostParams.actionModulesInitDatas;
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

        return _commentWithSig(mockCommentParams, _getSigStruct(delegatedSigner, signerPrivKey, digest, sigDeadline));
    }

    function _expectedPubFromInitData() internal view override returns (Types.Publication memory) {
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
        vm.expectRevert(Errors.InvalidPointedPub.selector);
        _publish();
    }

    function testCannotCommentWithSigOnNonExistentPublication() public {
        uint256 nonExistentPubId = _getPubCount(newProfileId) + 10;

        replicateInitData();
        mockCommentParams.pointedPubId = nonExistentPubId;

        vm.expectRevert(Errors.InvalidPointedPub.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
    }

    function testCannotCommentOnTheSamePublicationBeingCreated() public {
        uint256 nextPubId = _getPubCount(newProfileId) + 1;

        replicateInitData();
        mockCommentParams.pointedPubId = nextPubId;

        vm.prank(profileOwner);
        vm.expectRevert(Errors.InvalidPointedPub.selector);
        _publish();
    }

    function testCannotCommentWithSigOnTheSamePublicationBeingCreated() public {
        uint256 nextPubId = _getPubCount(newProfileId) + 1;

        replicateInitData();
        mockCommentParams.pointedPubId = nextPubId;

        vm.expectRevert(Errors.InvalidPointedPub.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
    }

    function testCannotCommentIfBlocked() public {
        uint256 commenterProfileId = _createProfile(profileOwner);
        mockCommentParams.profileId = commenterProfileId;
        vm.prank(profileOwner);
        hub.setBlockStatus(mockPostParams.profileId, _toUint256Array(commenterProfileId), _toBoolArray(true));
        vm.expectRevert(Errors.Blocked.selector);
        vm.prank(profileOwner);
        _publish();
    }

    function testCannotCommentWithSigIfBlocked() public {
        uint256 commenterProfileId = _createProfile(profileOwner);
        mockCommentParams.profileId = commenterProfileId;
        vm.prank(profileOwner);
        hub.setBlockStatus(mockPostParams.profileId, _toUint256Array(commenterProfileId), _toBoolArray(true));
        vm.expectRevert(Errors.Blocked.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
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

        Types.Publication memory pub = _getPub(newProfileId, commentPubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testCannotCommentOnMirror() public {
        mockMirrorParams.pointedPubId = postId;
        vm.prank(profileOwner);
        uint256 mirrorId = _mirror(mockMirrorParams);

        mockCommentParams.pointedPubId = mirrorId;
        vm.expectRevert(Errors.InvalidPointedPub.selector);
        vm.prank(profileOwner);
        _publish();
    }

    function testCannotCommentOnMirrorWithSig() public {
        mockMirrorParams.pointedPubId = postId;
        vm.prank(profileOwner);
        uint256 mirrorId = _mirror(mockMirrorParams);

        mockCommentParams.pointedPubId = mirrorId;
        vm.expectRevert(Errors.InvalidPointedPub.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
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

        return _mirrorWithSig(mockMirrorParams, _getSigStruct(delegatedSigner, signerPrivKey, digest, sigDeadline));
    }

    function _expectedPubFromInitData() internal view override returns (Types.Publication memory) {
        return _expectedPubFromInitData(mockMirrorParams);
    }

    function setUp() public override {
        PublishingTest.setUp();

        vm.prank(profileOwner);
        postId = _post(mockPostParams);
    }

    // ignored - these tests don't apply to mirrors
    // TODO: Proper tests
    // function testCannotPublishNotWhitelistedCollectModule() public override {}
    // function testCannotPublishWithSigNotWhitelistedCollectModule() public override {}

    function testCannotPublishNotWhitelistedReferenceModule() public override {}

    function testCannotPublishWithSigNotWhitelistedReferenceModule() public override {}

    // negatives

    function testCannotMirrorNonExistentPublication() public {
        uint256 nonExistentPubId = _getPubCount(newProfileId) + 10;

        replicateInitData();
        mockMirrorParams.pointedPubId = nonExistentPubId;

        vm.prank(profileOwner);
        vm.expectRevert(Errors.InvalidPointedPub.selector);
        _publish();
    }

    function testCannotMirrorWithSigNonExistentPublication() public {
        uint256 nonExistentPubId = _getPubCount(newProfileId) + 10;

        replicateInitData();
        mockMirrorParams.pointedPubId = nonExistentPubId;

        vm.expectRevert(Errors.InvalidPointedPub.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
    }

    function testCannotMirrorIfBlocked() public {
        uint256 mirrorerProfileId = _createProfile(profileOwner);
        mockMirrorParams.profileId = mirrorerProfileId;
        vm.prank(profileOwner);
        hub.setBlockStatus(mockPostParams.profileId, _toUint256Array(mirrorerProfileId), _toBoolArray(true));
        vm.expectRevert(Errors.Blocked.selector);
        vm.prank(profileOwner);
        _publish();
    }

    function testCannotMirrorWithSigIfBlocked() public {
        uint256 mirrorerProfileId = _createProfile(profileOwner);
        mockMirrorParams.profileId = mirrorerProfileId;
        vm.prank(profileOwner);
        hub.setBlockStatus(mockPostParams.profileId, _toUint256Array(mirrorerProfileId), _toBoolArray(true));
        vm.expectRevert(Errors.Blocked.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
    }

    // scenarios
    function testCannotMirrorAMirror() public {
        mockMirrorParams.pointedPubId = postId;
        vm.prank(profileOwner);
        uint256 firstMirrorId = _publish();

        mockMirrorParams.pointedPubId = firstMirrorId;
        vm.prank(profileOwner);
        vm.expectRevert(Errors.InvalidPointedPub.selector);
        _publish();
    }

    function testCannotMirrorAMirrorWithSig() public {
        mockMirrorParams.pointedPubId = postId;
        vm.prank(profileOwner);
        uint256 firstMirrorId = _publish();

        mockMirrorParams.pointedPubId = firstMirrorId;
        vm.expectRevert(Errors.InvalidPointedPub.selector);
        _publishWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
    }
}
