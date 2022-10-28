// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './helpers/SignatureHelpers.sol';
import './helpers/CollectingHelpers.sol';

contract SigSetup {
    uint256 nonce;
    uint256 deadline;

    function setUp() public virtual {
        nonce = 0;
        deadline = type(uint256).max;
    }
}

contract CollectingTest_Post is BaseTest, SignatureHelpers, CollectingHelpers, SigSetup {
    function replicateInitData() internal virtual {}

    function _collect() internal virtual returns (uint256) {
        return
            _collect(
                mockCollectData.collector,
                mockCollectData.profileId,
                mockCollectData.pubId,
                mockCollectData.data
            );
    }

    function _publishWithSig(address delegatedSigner, uint256 signerPrivKey)
        internal
        virtual
        returns (uint256)
    {
        bytes32 digest = _getPostTypedDataHash(mockPostData, nonce, deadline);

        return
            _postWithSig(
                _buildPostWithSigData(
                    delegatedSigner,
                    mockPostData,
                    _getSigStruct(signerPrivKey, digest, deadline)
                )
            );
    }

    function _expectedPubFromInitData()
        internal
        view
        virtual
        returns (DataTypes.PublicationStruct memory)
    {
        return _expectedPubFromInitData(mockPostData);
    }

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

    function testCannotPublishWithSigInvalidSigner() public {
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: otherSignerKey});
    }

    function testCannotPublishWithSigInvalidNonce() public {
        nonce = _getSigNonce(otherSigner) + 1;
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _publishWithSig({delegatedSigner: address(0), signerPrivKey: otherSignerKey});
    }

    function testCannotPublishIfNonceWasIncrementedWithAnotherAction() public {
        assertEq(_getSigNonce(profileOwner), nonce, 'Wrong nonce before posting');

        uint256 expectedPubId = _getPubCount(firstProfileId) + 1;

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
        uint256 expectedPubId = _getPubCount(firstProfileId) + 1;

        vm.prank(profileOwner);
        uint256 pubId = _publish();

        assertEq(pubId, expectedPubId);

        DataTypes.PublicationStruct memory pub = _getPub(firstProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testPublishWithAWhitelistedReferenceModule() public {
        mockPostData.referenceModule = address(mockReferenceModule);
        mockPostData.referenceModuleInitData = abi.encode(1);
        replicateInitData();

        uint256 expectedPubId = _getPubCount(firstProfileId) + 1;

        vm.prank(profileOwner);
        uint256 pubId = _publish();

        assertEq(pubId, expectedPubId);

        DataTypes.PublicationStruct memory pub = _getPub(firstProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testPublishWithSig() public {
        uint256 expectedPubId = _getPubCount(firstProfileId) + 1;

        uint256 pubId = _publishWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey
        });
        assertEq(pubId, expectedPubId);

        DataTypes.PublicationStruct memory pub = _getPub(firstProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testExecutorPublish() public {
        vm.prank(profileOwner);
        _setDelegatedExecutorApproval(otherSigner, true);

        uint256 expectedPubId = _getPubCount(firstProfileId) + 1;

        vm.prank(otherSigner);
        uint256 pubId = _publish();
        assertEq(pubId, expectedPubId);

        DataTypes.PublicationStruct memory pub = _getPub(firstProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }

    function testExecutorPublishWithSig() public {
        vm.prank(profileOwner);
        _setDelegatedExecutorApproval(otherSigner, true);

        uint256 expectedPubId = _getPubCount(firstProfileId) + 1;
        uint256 pubId = _publishWithSig({
            delegatedSigner: otherSigner,
            signerPrivKey: otherSignerKey
        });
        assertEq(pubId, expectedPubId);

        DataTypes.PublicationStruct memory pub = _getPub(firstProfileId, pubId);
        _verifyPublication(pub, _expectedPubFromInitData());
    }
}

contract PublishingTest_Comment is PublishingTest_Post {
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

    function _publishWithSig(address delegatedSigner, uint256 signerPrivKey)
        internal
        override
        returns (uint256)
    {
        bytes32 digest = _getCommentTypedDataHash(mockCommentData, nonce, deadline);

        return
            _commentWithSig(
                _buildCommentWithSigData(
                    delegatedSigner,
                    mockCommentData,
                    _getSigStruct(signerPrivKey, digest, deadline)
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
        PublishingTest_Post.setUp();

        vm.prank(profileOwner);
        _post(mockPostData);
    }
}

contract PublishingTest_Mirror is PublishingTest_Post {
    function replicateInitData() internal override {
        mockMirrorData.profileId = mockPostData.profileId;
        mockMirrorData.referenceModule = mockPostData.referenceModule;
        mockMirrorData.referenceModuleInitData = mockPostData.referenceModuleInitData;
    }

    function _publish() internal override returns (uint256) {
        return _mirror(mockMirrorData);
    }

    function _publishWithSig(address delegatedSigner, uint256 signerPrivKey)
        internal
        override
        returns (uint256)
    {
        bytes32 digest = _getMirrorTypedDataHash(mockMirrorData, nonce, deadline);

        return
            _mirrorWithSig(
                _buildMirrorWithSigData(
                    delegatedSigner,
                    mockMirrorData,
                    _getSigStruct(signerPrivKey, digest, deadline)
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
        PublishingTest_Post.setUp();

        vm.prank(profileOwner);
        _post(mockPostData);
    }

    function testCannotPublishNotWhitelistedCollectModule() public override {}
}
