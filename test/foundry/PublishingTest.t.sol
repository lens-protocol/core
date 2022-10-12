// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract PublishingTest is BaseTest {
    // negatives
    function testPostNotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.post(mockPostData);
    }

    function testCommentNotExecutorFails() public {
        vm.prank(profileOwner);
        hub.post(mockPostData);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.comment(mockCommentData);
    }

    function testMirrorNotExecutorFails() public {
        vm.prank(profileOwner);
        hub.post(mockPostData);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.mirror(mockMirrorData);
    }

    // positives
    function testExecutorPost() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        uint256 pubId = hub.post(mockPostData);
        assertEq(pubId, 1);

        DataTypes.PublicationStruct memory pub = hub.getPub(firstProfileId, pubId);
        assertEq(pub.profileIdPointed, 0);
        assertEq(pub.pubIdPointed, 0);
        assertEq(pub.contentURI, mockPostData.contentURI);
        assertEq(pub.referenceModule, mockPostData.referenceModule);
        assertEq(pub.collectModule, mockPostData.collectModule);
        assertEq(pub.collectNFT, address(0));
    }

    function testExecutorComment() public {
        vm.startPrank(profileOwner);
        hub.post(mockPostData);
        hub.setDelegatedExecutorApproval(otherSigner, true);
        vm.stopPrank();

        vm.prank(otherSigner);
        uint256 pubId = hub.comment(mockCommentData);
        assertEq(pubId, 2);

        DataTypes.PublicationStruct memory pub = hub.getPub(firstProfileId, pubId);
        assertEq(pub.profileIdPointed, mockCommentData.profileIdPointed);
        assertEq(pub.pubIdPointed, mockCommentData.pubIdPointed);
        assertEq(pub.contentURI, mockCommentData.contentURI);
        assertEq(pub.referenceModule, mockCommentData.referenceModule);
        assertEq(pub.collectModule, mockCommentData.collectModule);
        assertEq(pub.collectNFT, address(0));
    }

    function testExecutorMirror() public {
        vm.startPrank(profileOwner);
        hub.post(mockPostData);
        hub.setDelegatedExecutorApproval(otherSigner, true);
        vm.stopPrank();

        vm.prank(otherSigner);
        uint256 pubId = hub.mirror(mockMirrorData);
        assertEq(pubId, 2);

        DataTypes.PublicationStruct memory pub = hub.getPub(firstProfileId, pubId);
        assertEq(pub.profileIdPointed, mockMirrorData.profileIdPointed);
        assertEq(pub.pubIdPointed, mockMirrorData.pubIdPointed);
        assertEq(pub.contentURI, '');
        assertEq(pub.referenceModule, mockMirrorData.referenceModule);
        assertEq(pub.collectModule, address(0));
        assertEq(pub.collectNFT, address(0));
    }

    // Meta-tx
    // Negatives
    function testPostWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getPostTypedDataHash(
            firstProfileId,
            mockURI,
            address(mockCollectModule),
            abi.encode(1),
            address(0),
            '',
            nonce,
            deadline
        );

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.postWithSig(
            _buildPostWithSigData({
                delegatedSigner: address(0),
                profileId: firstProfileId,
                contentURI: mockURI,
                collectModule: address(mockCollectModule),
                collectModuleInitData: abi.encode(1),
                referenceModule: address(0),
                referenceModuleInitData: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testPostWithSigNotExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getPostTypedDataHash(
            firstProfileId,
            mockURI,
            address(mockCollectModule),
            abi.encode(1),
            address(0),
            '',
            nonce,
            deadline
        );

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.postWithSig(
            _buildPostWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                contentURI: mockURI,
                collectModule: address(mockCollectModule),
                collectModuleInitData: abi.encode(1),
                referenceModule: address(0),
                referenceModuleInitData: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testCommentWithSigInvalidSignerFails() public {
        vm.prank(profileOwner);
        hub.post(mockPostData);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getCommentTypedDataHash(
            firstProfileId,
            mockURI,
            firstProfileId,
            1,
            '',
            address(mockCollectModule),
            abi.encode(1),
            address(0),
            '',
            nonce,
            deadline
        );
        DataTypes.EIP712Signature memory sig = _getSigStruct(otherSignerKey, digest, deadline);

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.commentWithSig(
            _buildCommentWithSigData({
                delegatedSigner: address(0),
                profileId: firstProfileId,
                contentURI: mockURI,
                profileIdPointed: firstProfileId,
                pubIdPointed: 1,
                referenceModuleData: '',
                collectModule: address(mockCollectModule),
                collectModuleInitData: abi.encode(1),
                referenceModule: address(0),
                referenceModuleInitData: '',
                sig: sig
            })
        );
    }

    function testCommentWithSigNotExecutorFails() public {
        vm.prank(profileOwner);
        hub.post(mockPostData);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getCommentTypedDataHash(
            firstProfileId,
            mockURI,
            firstProfileId,
            1,
            '',
            address(mockCollectModule),
            abi.encode(1),
            address(0),
            '',
            nonce,
            deadline
        );
        DataTypes.EIP712Signature memory sig = _getSigStruct(otherSignerKey, digest, deadline);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.commentWithSig(
            _buildCommentWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                contentURI: mockURI,
                profileIdPointed: firstProfileId,
                pubIdPointed: 1,
                referenceModuleData: '',
                collectModule: address(mockCollectModule),
                collectModuleInitData: abi.encode(1),
                referenceModule: address(0),
                referenceModuleInitData: '',
                sig: sig
            })
        );
    }

    function testMirrorWithSigInvalidSignerFails() public {
        vm.prank(profileOwner);
        hub.post(mockPostData);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getMirrorTypedDataHash(
            firstProfileId,
            firstProfileId,
            1,
            '',
            address(0),
            '',
            nonce,
            deadline
        );

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.mirrorWithSig(
            _buildMirrorWithSigData({
                delegatedSigner: address(0),
                profileId: firstProfileId,
                profileIdPointed: firstProfileId,
                pubIdPointed: 1,
                referenceModuleData: '',
                referenceModule: address(0),
                referenceModuleInitData: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testMirrorWithSigNotExecutorFails() public {
        vm.prank(profileOwner);
        hub.post(mockPostData);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getMirrorTypedDataHash(
            firstProfileId,
            firstProfileId,
            1,
            '',
            address(0),
            '',
            nonce,
            deadline
        );

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.mirrorWithSig(
            _buildMirrorWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                profileIdPointed: firstProfileId,
                pubIdPointed: 1,
                referenceModuleData: '',
                referenceModule: address(0),
                referenceModuleInitData: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    // Positives
    function testExecutorPostWithSig() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getPostTypedDataHash(
            firstProfileId,
            mockURI,
            address(mockCollectModule),
            abi.encode(1),
            address(0),
            '',
            nonce,
            deadline
        );

        uint256 pubId = hub.postWithSig(
            _buildPostWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                contentURI: mockURI,
                collectModule: address(mockCollectModule),
                collectModuleInitData: abi.encode(1),
                referenceModule: address(0),
                referenceModuleInitData: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
        assertEq(pubId, 1);

        DataTypes.PublicationStruct memory pub = hub.getPub(firstProfileId, pubId);
        assertEq(pub.profileIdPointed, 0);
        assertEq(pub.pubIdPointed, 0);
        assertEq(pub.contentURI, mockPostData.contentURI);
        assertEq(pub.referenceModule, mockPostData.referenceModule);
        assertEq(pub.collectModule, mockPostData.collectModule);
        assertEq(pub.collectNFT, address(0));
    }

    function testExecutorCommentWithSig() public {
        vm.startPrank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);
        hub.post(mockPostData);
        vm.stopPrank();

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getCommentTypedDataHash(
            firstProfileId,
            mockURI,
            firstProfileId,
            1,
            '',
            address(mockCollectModule),
            abi.encode(1),
            address(0),
            '',
            nonce,
            deadline
        );
        DataTypes.EIP712Signature memory sig = _getSigStruct(otherSignerKey, digest, deadline);

        uint256 pubId = hub.commentWithSig(
            _buildCommentWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                contentURI: mockURI,
                profileIdPointed: firstProfileId,
                pubIdPointed: 1,
                referenceModuleData: '',
                collectModule: address(mockCollectModule),
                collectModuleInitData: abi.encode(1),
                referenceModule: address(0),
                referenceModuleInitData: '',
                sig: sig
            })
        );
        assertEq(pubId, 2);

        DataTypes.PublicationStruct memory pub = hub.getPub(firstProfileId, pubId);
        assertEq(pub.profileIdPointed, mockCommentData.profileIdPointed);
        assertEq(pub.pubIdPointed, mockCommentData.pubIdPointed);
        assertEq(pub.contentURI, mockCommentData.contentURI);
        assertEq(pub.referenceModule, mockCommentData.referenceModule);
        assertEq(pub.collectModule, mockCommentData.collectModule);
        assertEq(pub.collectNFT, address(0));
    }

    function testExecutorMirrorWithSig() public {
        vm.startPrank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);
        hub.post(mockPostData);
        vm.stopPrank();

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getMirrorTypedDataHash(
            firstProfileId,
            firstProfileId,
            1,
            '',
            address(0),
            '',
            nonce,
            deadline
        );

        uint256 pubId = hub.mirrorWithSig(
            _buildMirrorWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                profileIdPointed: firstProfileId,
                pubIdPointed: 1,
                referenceModuleData: '',
                referenceModule: address(0),
                referenceModuleInitData: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
        assertEq(pubId, 2);

        DataTypes.PublicationStruct memory pub = hub.getPub(firstProfileId, pubId);
        assertEq(pub.profileIdPointed, mockMirrorData.profileIdPointed);
        assertEq(pub.pubIdPointed, mockMirrorData.pubIdPointed);
        assertEq(pub.contentURI, '');
        assertEq(pub.referenceModule, mockMirrorData.referenceModule);
        assertEq(pub.collectModule, address(0));
        assertEq(pub.collectNFT, address(0));
    }

    // Private functions
    function _buildPostWithSigData(
        address delegatedSigner,
        uint256 profileId,
        string memory contentURI,
        address collectModule,
        bytes memory collectModuleInitData,
        address referenceModule,
        bytes memory referenceModuleInitData,
        DataTypes.EIP712Signature memory sig
    ) private pure returns (DataTypes.PostWithSigData memory) {
        return
            DataTypes.PostWithSigData(
                delegatedSigner,
                profileId,
                contentURI,
                collectModule,
                collectModuleInitData,
                referenceModule,
                referenceModuleInitData,
                sig
            );
    }

    function _buildCommentWithSigData(
        address delegatedSigner,
        uint256 profileId,
        string memory contentURI,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes memory referenceModuleData,
        address collectModule,
        bytes memory collectModuleInitData,
        address referenceModule,
        bytes memory referenceModuleInitData,
        DataTypes.EIP712Signature memory sig
    ) private pure returns (DataTypes.CommentWithSigData memory) {
        return
            DataTypes.CommentWithSigData(
                delegatedSigner,
                profileId,
                contentURI,
                profileIdPointed,
                pubIdPointed,
                referenceModuleData,
                collectModule,
                collectModuleInitData,
                referenceModule,
                referenceModuleInitData,
                sig
            );
    }

    function _buildMirrorWithSigData(
        address delegatedSigner,
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes memory referenceModuleData,
        address referenceModule,
        bytes memory referenceModuleInitData,
        DataTypes.EIP712Signature memory sig
    ) private pure returns (DataTypes.MirrorWithSigData memory) {
        return
            DataTypes.MirrorWithSigData(
                delegatedSigner,
                profileId,
                profileIdPointed,
                pubIdPointed,
                referenceModuleData,
                referenceModule,
                referenceModuleInitData,
                sig
            );
    }
}
