// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '../../../contracts/libraries/DataTypes.sol';

contract SigSetup {
    uint256 nonce;
    uint256 deadline;

    function setUp() public virtual {
        nonce = 0;
        deadline = type(uint256).max;
    }
}

contract SignatureHelpers {
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
    ) internal pure returns (DataTypes.PostWithSigData memory) {
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

    function _buildPostWithSigData(
        address delegatedSigner,
        DataTypes.PostParams memory postParams,
        DataTypes.EIP712Signature memory sig
    ) internal pure returns (DataTypes.PostWithSigData memory) {
        return
            _buildPostWithSigData(
                delegatedSigner,
                postParams.profileId,
                postParams.contentURI,
                postParams.collectModule,
                postParams.collectModuleInitData,
                postParams.referenceModule,
                postParams.referenceModuleInitData,
                sig
            );
    }

    function _buildCommentWithSigData(
        address delegatedSigner,
        uint256 profileId,
        string memory contentURI,
        uint256 pointedProfileId,
        uint256 pointedPubId,
        bytes memory referenceModuleData,
        address collectModule,
        bytes memory collectModuleInitData,
        address referenceModule,
        bytes memory referenceModuleInitData,
        DataTypes.EIP712Signature memory sig
    ) internal pure returns (DataTypes.CommentWithSigData memory) {
        return
            DataTypes.CommentWithSigData(
                delegatedSigner,
                profileId,
                contentURI,
                pointedProfileId,
                pointedPubId,
                referenceModuleData,
                collectModule,
                collectModuleInitData,
                referenceModule,
                referenceModuleInitData,
                sig
            );
    }

    function _buildCommentWithSigData(
        address delegatedSigner,
        DataTypes.CommentParams memory commentParams,
        DataTypes.EIP712Signature memory sig
    ) internal pure returns (DataTypes.CommentWithSigData memory) {
        return
            _buildCommentWithSigData({
                delegatedSigner: delegatedSigner,
                profileId: commentParams.profileId,
                contentURI: commentParams.contentURI,
                pointedProfileId: commentParams.pointedProfileId,
                pointedPubId: commentParams.pointedPubId,
                referenceModuleData: commentParams.referenceModuleData,
                collectModule: commentParams.collectModule,
                collectModuleInitData: commentParams.collectModuleInitData,
                referenceModule: commentParams.referenceModule,
                referenceModuleInitData: commentParams.referenceModuleInitData,
                sig: sig
            });
    }

    function _buildMirrorWithSigData(
        address delegatedSigner,
        uint256 profileId,
        uint256 pointedProfileId,
        uint256 pointedPubId,
        bytes memory referenceModuleData,
        DataTypes.EIP712Signature memory sig
    ) internal pure returns (DataTypes.MirrorWithSigData memory) {
        return
            DataTypes.MirrorWithSigData(
                delegatedSigner,
                profileId,
                pointedProfileId,
                pointedPubId,
                referenceModuleData,
                sig
            );
    }

    function _buildMirrorWithSigData(
        address delegatedSigner,
        DataTypes.MirrorParams memory mirrorParams,
        DataTypes.EIP712Signature memory sig
    ) internal pure returns (DataTypes.MirrorWithSigData memory) {
        return
            _buildMirrorWithSigData({
                delegatedSigner: delegatedSigner,
                profileId: mirrorParams.profileId,
                pointedProfileId: mirrorParams.pointedProfileId,
                pointedPubId: mirrorParams.pointedPubId,
                referenceModuleData: mirrorParams.referenceModuleData,
                sig: sig
            });
    }

    function _buildCollectWithSigData(
        address delegatedSigner,
        DataTypes.CollectData memory collectData,
        DataTypes.EIP712Signature memory sig
    ) internal pure returns (DataTypes.CollectWithSigData memory) {
        return
            DataTypes.CollectWithSigData({
                delegatedSigner: delegatedSigner,
                publicationCollectedProfileId: collectData.publisherProfileId,
                publicationCollectedId: collectData.pubId,
                collectorProfileId: collectData.collectorProfileId,
                referrerProfileId: 0,
                referrerPubId: 0,
                collectModuleData: collectData.data,
                sig: sig
            });
    }
}
