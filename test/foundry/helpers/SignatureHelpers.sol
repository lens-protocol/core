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
        DataTypes.PostData memory postData,
        DataTypes.EIP712Signature memory sig
    ) internal pure returns (DataTypes.PostWithSigData memory) {
        return
            _buildPostWithSigData(
                delegatedSigner,
                postData.profileId,
                postData.contentURI,
                postData.collectModule,
                postData.collectModuleInitData,
                postData.referenceModule,
                postData.referenceModuleInitData,
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
    ) internal pure returns (DataTypes.CommentWithSigData memory) {
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

    function _buildCommentWithSigData(
        address delegatedSigner,
        DataTypes.CommentData memory commentData,
        DataTypes.EIP712Signature memory sig
    ) internal pure returns (DataTypes.CommentWithSigData memory) {
        return
            _buildCommentWithSigData({
                delegatedSigner: delegatedSigner,
                profileId: commentData.profileId,
                contentURI: commentData.contentURI,
                profileIdPointed: commentData.profileIdPointed,
                pubIdPointed: commentData.pubIdPointed,
                referenceModuleData: commentData.referenceModuleData,
                collectModule: commentData.collectModule,
                collectModuleInitData: commentData.collectModuleInitData,
                referenceModule: commentData.referenceModule,
                referenceModuleInitData: commentData.referenceModuleInitData,
                sig: sig
            });
    }

    function _buildMirrorWithSigData(
        address delegatedSigner,
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes memory referenceModuleData,
        DataTypes.EIP712Signature memory sig
    ) internal pure returns (DataTypes.MirrorWithSigData memory) {
        return
            DataTypes.MirrorWithSigData(
                delegatedSigner,
                profileId,
                profileIdPointed,
                pubIdPointed,
                referenceModuleData,
                sig
            );
    }

    function _buildMirrorWithSigData(
        address delegatedSigner,
        DataTypes.MirrorData memory mirrorData,
        DataTypes.EIP712Signature memory sig
    ) internal pure returns (DataTypes.MirrorWithSigData memory) {
        return
            _buildMirrorWithSigData({
                delegatedSigner: delegatedSigner,
                profileId: mirrorData.profileId,
                profileIdPointed: mirrorData.profileIdPointed,
                pubIdPointed: mirrorData.pubIdPointed,
                referenceModuleData: mirrorData.referenceModuleData,
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
                collectorProfileId: collectData.collectorProfileId,
                publisherProfileId: collectData.publisherProfileId,
                pubId: collectData.pubId,
                data: collectData.data,
                sig: sig
            });
    }

    function _buildSetDefaultProfileWithSigData(
        address delegatedSigner,
        address wallet,
        uint256 profileId,
        DataTypes.EIP712Signature memory sig
    ) internal pure returns (DataTypes.SetDefaultProfileWithSigData memory) {
        return DataTypes.SetDefaultProfileWithSigData(delegatedSigner, wallet, profileId, sig);
    }
}
