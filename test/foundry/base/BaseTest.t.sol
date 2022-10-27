// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './TestSetup.t.sol';
import '../../../contracts/libraries/DataTypes.sol';

contract BaseTest is TestSetup {
    function _getSetDefaultProfileTypedDataHash(
        address wallet,
        uint256 profileId,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(SET_DEFAULT_PROFILE_WITH_SIG_TYPEHASH, wallet, profileId, nonce, deadline)
        );
        return _calculateDigest(structHash);
    }

    function _getSetProfileMetadataURITypedDataHash(
        uint256 profileId,
        string memory metadataURI,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                SET_PROFILE_METADATA_URI_WITH_SIG_TYPEHASH,
                profileId,
                keccak256(bytes(metadataURI)),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getSetFollowModuleTypedDataHash(
        uint256 profileId,
        address followModule,
        bytes memory followModuleInitData,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                SET_FOLLOW_MODULE_WITH_SIG_TYPEHASH,
                profileId,
                followModule,
                keccak256(followModuleInitData),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getSetDelegatedExecutorApprovalTypedDataHash(
        address onBehalfOf,
        address executor,
        bool approved,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                SET_DELEGATED_EXECUTOR_APPROVAL_WITH_SIG_TYPEHASH,
                onBehalfOf,
                executor,
                approved,
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getSetProfileImageURITypedDataHash(
        uint256 profileId,
        string memory imageURI,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                SET_PROFILE_IMAGE_URI_WITH_SIG_TYPEHASH,
                profileId,
                keccak256(bytes(imageURI)),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getSetFollowNFTURITypedDatahash(
        uint256 profileId,
        string memory followNFTURI,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                SET_FOLLOW_NFT_URI_WITH_SIG_TYPEHASH,
                profileId,
                keccak256(bytes(followNFTURI)),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getPostTypedDataHash(
        uint256 profileId,
        string memory contentURI,
        address collectModule,
        bytes memory collectModuleInitData,
        address referenceModule,
        bytes memory referenceModuleInitData,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                POST_WITH_SIG_TYPEHASH,
                profileId,
                keccak256(bytes(contentURI)),
                collectModule,
                keccak256(collectModuleInitData),
                referenceModule,
                keccak256(referenceModuleInitData),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getPostTypedDataHash(
        DataTypes.PostData memory postData,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        return
            _getPostTypedDataHash({
                profileId: postData.profileId,
                contentURI: postData.contentURI,
                collectModule: postData.collectModule,
                collectModuleInitData: postData.collectModuleInitData,
                referenceModule: postData.referenceModule,
                referenceModuleInitData: postData.referenceModuleInitData,
                nonce: nonce,
                deadline: deadline
            });
    }

    function _getCommentTypedDataHash(
        uint256 profileId,
        string memory contentURI,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes memory referenceModuleData,
        address collectModule,
        bytes memory collectModuleInitData,
        address referenceModule,
        bytes memory referenceModuleInitData,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                COMMENT_WITH_SIG_TYPEHASH,
                profileId,
                keccak256(bytes(contentURI)),
                profileIdPointed,
                pubIdPointed,
                keccak256(referenceModuleData),
                collectModule,
                keccak256(collectModuleInitData),
                referenceModule,
                keccak256(referenceModuleInitData),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getCommentTypedDataHash(
        DataTypes.CommentData memory commentData,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        return
            _getCommentTypedDataHash({
                profileId: commentData.profileId,
                contentURI: commentData.contentURI,
                profileIdPointed: commentData.profileIdPointed,
                pubIdPointed: commentData.pubIdPointed,
                referenceModuleData: commentData.referenceModuleData,
                collectModule: commentData.collectModule,
                collectModuleInitData: commentData.collectModuleInitData,
                referenceModule: commentData.referenceModule,
                referenceModuleInitData: commentData.referenceModuleInitData,
                nonce: nonce,
                deadline: deadline
            });
    }

    function _getMirrorTypedDataHash(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes memory referenceModuleData,
        address referenceModule,
        bytes memory referenceModuleInitData,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                MIRROR_WITH_SIG_TYPEHASH,
                profileId,
                profileIdPointed,
                pubIdPointed,
                keccak256(referenceModuleData),
                referenceModule,
                keccak256(referenceModuleInitData),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getMirrorTypedDataHash(
        DataTypes.MirrorData memory mirrorData,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        return
            _getMirrorTypedDataHash({
                profileId: mirrorData.profileId,
                profileIdPointed: mirrorData.profileIdPointed,
                pubIdPointed: mirrorData.pubIdPointed,
                referenceModuleData: mirrorData.referenceModuleData,
                referenceModule: mirrorData.referenceModule,
                referenceModuleInitData: mirrorData.referenceModuleInitData,
                nonce: nonce,
                deadline: deadline
            });
    }

    function _getFollowTypedDataHash(
        uint256[] memory profileIds,
        bytes[] memory datas,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        uint256 dataLength = datas.length;
        bytes32[] memory dataHashes = new bytes32[](dataLength);
        for (uint256 i = 0; i < dataLength; ) {
            dataHashes[i] = keccak256(datas[i]);
            unchecked {
                ++i;
            }
        }

        bytes32 structHash = keccak256(
            abi.encode(
                FOLLOW_WITH_SIG_TYPEHASH,
                keccak256(abi.encodePacked(profileIds)),
                keccak256(abi.encodePacked(dataHashes)),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getCollectTypedDataHash(
        uint256 profileId,
        uint256 pubId,
        bytes memory data,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                COLLECT_WITH_SIG_TYPEHASH,
                profileId,
                pubId,
                keccak256(data),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _calculateDigest(bytes32 structHash) internal view returns (bytes32) {
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        return digest;
    }

    function _getSigStruct(
        uint256 pKey,
        bytes32 digest,
        uint256 deadline
    ) internal returns (DataTypes.EIP712Signature memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pKey, digest);
        return DataTypes.EIP712Signature(v, r, s, deadline);
    }

    function _toUint256Array(uint256 n) internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](1);
        ret[0] = n;
        return ret;
    }

    function _toBytesArray(bytes memory n) internal pure returns (bytes[] memory) {
        bytes[] memory ret = new bytes[](1);
        ret[0] = n;
        return ret;
    }

    function _post(DataTypes.PostData memory postData) internal returns (uint256) {
        return hub.post(postData);
    }

    function _comment(DataTypes.CommentData memory commentData) internal returns (uint256) {
        return hub.comment(commentData);
    }

    function _mirror(DataTypes.MirrorData memory mirrorData) internal returns (uint256) {
        return hub.mirror(mirrorData);
    }

    function _postWithSig(DataTypes.PostWithSigData memory postWithSigData)
        internal
        returns (uint256)
    {
        return hub.postWithSig(postWithSigData);
    }

    function _commentWithSig(DataTypes.CommentWithSigData memory commentWithSigData)
        internal
        returns (uint256)
    {
        return hub.commentWithSig(commentWithSigData);
    }

    function _mirrorWithSig(DataTypes.MirrorWithSigData memory mirrorWithSigData)
        internal
        returns (uint256)
    {
        return hub.mirrorWithSig(mirrorWithSigData);
    }

    function _setDelegatedExecutorApproval(address executor, bool approved) internal {
        hub.setDelegatedExecutorApproval(executor, approved);
    }

    function _getPub(uint256 profileId, uint256 pubId)
        internal
        view
        returns (DataTypes.PublicationStruct memory)
    {
        return hub.getPub(profileId, pubId);
    }

    function _getSigNonce(address signer) internal view returns (uint256) {
        return hub.sigNonces(signer);
    }

    function _getPubCount(uint256 profileId) internal view returns (uint256) {
        return hub.getPubCount(profileId);
    }
}
