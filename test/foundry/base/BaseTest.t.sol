// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/foundry/base/TestSetup.t.sol';
import 'contracts/libraries/constants/Types.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';

contract BaseTest is TestSetup {
    function _getSetProfileMetadataURITypedDataHash(
        uint256 profileId,
        string memory metadataURI,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(Typehash.SET_PROFILE_METADATA_URI, profileId, keccak256(bytes(metadataURI)), nonce, deadline)
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
                Typehash.SET_FOLLOW_MODULE,
                profileId,
                followModule,
                keccak256(followModuleInitData),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getChangeDelegatedExecutorsConfigTypedDataHash(
        uint256 delegatorProfileId,
        uint64 configNumber,
        address[] memory delegatedExecutors,
        bool[] memory approvals,
        bool switchToGivenConfig,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.CHANGE_DELEGATED_EXECUTORS_CONFIG,
                delegatorProfileId,
                abi.encodePacked(delegatedExecutors),
                abi.encodePacked(approvals),
                configNumber,
                switchToGivenConfig,
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
            abi.encode(Typehash.SET_PROFILE_IMAGE_URI, profileId, keccak256(bytes(imageURI)), nonce, deadline)
        );
        return _calculateDigest(structHash);
    }

    function _getBurnTypedDataHash(uint256 profileId, uint256 nonce, uint256 deadline) internal view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(Typehash.BURN, profileId, nonce, deadline));
        return _calculateDigest(structHash);
    }

    function _getPostTypedDataHash(
        uint256 profileId,
        string memory contentURI,
        address[] memory actionModules,
        bytes[] memory actionModulesInitDatas,
        address referenceModule,
        bytes memory referenceModuleInitData,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.POST,
                profileId,
                keccak256(bytes(contentURI)),
                actionModules,
                _hashActionModulesInitDatas(actionModulesInitDatas),
                referenceModule,
                keccak256(referenceModuleInitData),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _hashActionModulesInitDatas(bytes[] memory actionModulesInitDatas) private pure returns (bytes32) {
        bytes32[] memory actionModulesInitDatasHashes = new bytes32[](actionModulesInitDatas.length);
        uint256 i;
        while (i < actionModulesInitDatas.length) {
            actionModulesInitDatasHashes[i] = keccak256(abi.encode(actionModulesInitDatas[i]));
            unchecked {
                ++i;
            }
        }
        return keccak256(abi.encodePacked(actionModulesInitDatasHashes));
    }

    function _getPostTypedDataHash(
        Types.PostParams memory postParams,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        return
            _getPostTypedDataHash({
                profileId: postParams.profileId,
                contentURI: postParams.contentURI,
                actionModules: postParams.actionModules,
                actionModulesInitDatas: postParams.actionModulesInitDatas,
                referenceModule: postParams.referenceModule,
                referenceModuleInitData: postParams.referenceModuleInitData,
                nonce: nonce,
                deadline: deadline
            });
    }

    // We need this to deal with stack too deep:
    struct ReferenceParamsForAbiEncode {
        bytes32 typehash;
        uint256 profileId;
        bytes32 contentURIHash;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        bytes32 referenceModuleDataHash;
        address[] actionModules;
        bytes32 actionModulesInitDataHash;
        address referenceModule;
        bytes32 referenceModuleInitDataHash;
        uint256 nonce;
        uint256 deadline;
    }

    function _abiEncode(
        ReferenceParamsForAbiEncode memory referenceParamsForAbiEncode
    ) private pure returns (bytes memory) {
        bytes memory encodedStruct = abi.encode(referenceParamsForAbiEncode);
        assembly {
            let lengthWithoutOffset := sub(mload(encodedStruct), 32) // Calculates length without offset.
            encodedStruct := add(encodedStruct, 32) // Skips the offset by shifting the memory pointer.
            mstore(encodedStruct, lengthWithoutOffset) // Stores new length, which now excludes the offset.
        }
        return encodedStruct;
    }

    function _getCommentTypedDataHash(
        Types.CommentParams memory commentParams,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            _abiEncode(
                ReferenceParamsForAbiEncode(
                    Typehash.COMMENT,
                    commentParams.profileId,
                    keccak256(bytes(commentParams.contentURI)),
                    commentParams.pointedProfileId,
                    commentParams.pointedPubId,
                    commentParams.referrerProfileIds,
                    commentParams.referrerPubIds,
                    keccak256(commentParams.referenceModuleData),
                    commentParams.actionModules,
                    _hashActionModulesInitDatas(commentParams.actionModulesInitDatas),
                    commentParams.referenceModule,
                    keccak256(commentParams.referenceModuleInitData),
                    nonce,
                    deadline
                )
            )
        );
        return _calculateDigest(structHash);
    }

    function _getMirrorTypedDataHash(
        uint256 profileId,
        uint256 pointedProfileId,
        uint256 pointedPubId,
        uint256[] memory referrerProfileIds,
        uint256[] memory referrerPubIds,
        bytes memory referenceModuleData,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.MIRROR,
                profileId,
                pointedProfileId,
                pointedPubId,
                referrerProfileIds,
                referrerPubIds,
                keccak256(referenceModuleData),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getMirrorTypedDataHash(
        Types.MirrorParams memory mirrorParams,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        return
            _getMirrorTypedDataHash({
                profileId: mirrorParams.profileId,
                pointedProfileId: mirrorParams.pointedProfileId,
                pointedPubId: mirrorParams.pointedPubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: mirrorParams.referenceModuleData,
                nonce: nonce,
                deadline: deadline
            });
    }

    function _getFollowTypedDataHash(
        uint256 followerProfileId,
        uint256[] memory idsOfProfilesToFollow,
        uint256[] memory followTokenIds,
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
                Typehash.FOLLOW,
                followerProfileId,
                keccak256(abi.encodePacked(idsOfProfilesToFollow)),
                keccak256(abi.encodePacked(followTokenIds)),
                keccak256(abi.encodePacked(dataHashes)),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    // function _getCollectTypedDataHash(
    //     Types.CollectParams memory collectParams,
    //     uint256 nonce,
    //     uint256 deadline
    // ) internal view returns (bytes32) {
    //     bytes32 structHash = keccak256(
    //         abi.encode(
    //             Typehash.COLLECT,
    //             collectParams.publicationCollectedProfileId,
    //             collectParams.publicationCollectedId,
    //             collectParams.collectorProfileId,
    //             collectParams.referrerProfileIds,
    //             collectParams.referrerPubIds,
    //             keccak256(collectParams.collectModuleData),
    //             nonce,
    //             deadline
    //         )
    //     );
    //     return _calculateDigest(structHash);
    // }

    function _getActTypedDataHash(
        Types.PublicationActionParams memory publicationActionParams,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.ACT,
                publicationActionParams.publicationActedProfileId,
                publicationActionParams.publicationActedId,
                publicationActionParams.actorProfileId,
                publicationActionParams.referrerProfileIds,
                publicationActionParams.referrerPubIds,
                publicationActionParams.actionModuleAddress,
                keccak256(publicationActionParams.actionModuleData),
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
    ) internal returns (Types.EIP712Signature memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pKey, digest);
        return Types.EIP712Signature(vm.addr(pKey), v, r, s, deadline);
    }

    function _getSigStruct(
        address signer,
        uint256 pKey,
        bytes32 digest,
        uint256 deadline
    ) internal returns (Types.EIP712Signature memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pKey, digest);
        return Types.EIP712Signature(signer, v, r, s, deadline);
    }

    // Internal functions

    function _post(Types.PostParams memory postParams) internal returns (uint256) {
        return hub.post(postParams);
    }

    function _comment(Types.CommentParams memory commentParams) internal returns (uint256) {
        return hub.comment(commentParams);
    }

    function _mirror(Types.MirrorParams memory mirrorParams) internal returns (uint256) {
        return hub.mirror(mirrorParams);
    }

    // function _collect(
    //     uint256 collectorProfileId,
    //     uint256 publisherProfileId,
    //     uint256 pubId,
    //     bytes memory data
    // ) internal returns (uint256) {
    //     return
    //         hub.collect(
    //             Types.CollectParams({
    //                 publicationCollectedProfileId: publisherProfileId,
    //                 publicationCollectedId: pubId,
    //                 collectorProfileId: collectorProfileId,
    //                 referrerProfileIds: _emptyUint256Array(),
    //                 referrerPubIds: _emptyUint256Array(),
    //                 collectModuleData: data
    //             })
    //         );
    // }

    function _act(
        uint256 actorProfileId,
        uint256 publicationActedProfileId,
        uint256 publicationActedId,
        address actionModuleAddress,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            hub.act(
                Types.PublicationActionParams({
                    publicationActedProfileId: publicationActedProfileId,
                    publicationActedId: publicationActedId,
                    actorProfileId: actorProfileId,
                    referrerProfileIds: _emptyUint256Array(),
                    referrerPubIds: _emptyUint256Array(),
                    actionModuleAddress: actionModuleAddress,
                    actionModuleData: data
                })
            );
    }

    function _postWithSig(
        Types.PostParams memory postParams,
        Types.EIP712Signature memory signature
    ) internal returns (uint256) {
        return hub.postWithSig(postParams, signature);
    }

    function _commentWithSig(
        Types.CommentParams memory commentParams,
        Types.EIP712Signature memory signature
    ) internal returns (uint256) {
        return hub.commentWithSig(commentParams, signature);
    }

    function _mirrorWithSig(
        Types.MirrorParams memory mirrorParams,
        Types.EIP712Signature memory signature
    ) internal returns (uint256) {
        return hub.mirrorWithSig(mirrorParams, signature);
    }

    // function _collectWithSig(
    //     Types.CollectParams memory collectParams,
    //     Types.EIP712Signature memory signature
    // ) internal returns (uint256) {
    //     return hub.collectWithSig(collectParams, signature);
    // }

    function _actWithSig(
        Types.PublicationActionParams memory publiactionActionParams,
        Types.EIP712Signature memory signature
    ) internal returns (bytes memory) {
        return hub.actWithSig(publiactionActionParams, signature);
    }

    function _follow(
        address msgSender,
        uint256 followerProfileId,
        uint256 idOfProfileToFollow,
        uint256 followTokenId,
        bytes memory data
    ) internal returns (uint256[] memory) {
        vm.prank(msgSender);
        return
            hub.follow(
                followerProfileId,
                _toUint256Array(idOfProfileToFollow),
                _toUint256Array(followTokenId),
                _toBytesArray(data)
            );
    }

    function _followWithSig(
        uint256 followerProfileId,
        uint256 idOfProfileToFollow,
        uint256 followTokenId,
        bytes memory data,
        Types.EIP712Signature memory signature
    ) internal returns (uint256[] memory) {
        return
            hub.followWithSig(
                followerProfileId,
                _toUint256Array(idOfProfileToFollow),
                _toUint256Array(followTokenId),
                _toBytesArray(data),
                signature
            );
    }

    function _createProfile(address newProfileOwner) internal returns (uint256) {
        Types.CreateProfileParams memory CreateProfileParams = Types.CreateProfileParams({
            to: newProfileOwner,
            imageURI: mockCreateProfileParams.imageURI,
            followModule: mockCreateProfileParams.followModule,
            followModuleInitData: mockCreateProfileParams.followModuleInitData,
            followNFTURI: mockCreateProfileParams.followNFTURI
        });

        return hub.createProfile(CreateProfileParams);
    }

    function _setState(Types.ProtocolState newState) internal {
        hub.setState(newState);
    }

    function _getState() internal view returns (Types.ProtocolState) {
        return hub.getState();
    }

    function _setEmergencyAdmin(address newEmergencyAdmin) internal {
        hub.setEmergencyAdmin(newEmergencyAdmin);
    }

    function _transferProfile(address msgSender, address from, address to, uint256 tokenId) internal {
        vm.prank(msgSender);
        hub.transferFrom(from, to, tokenId);
    }

    function _changeDelegatedExecutorsConfig(
        address msgSender,
        uint256 profileId,
        address delegatedExecutor,
        bool approved
    ) internal {
        vm.prank(msgSender);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: profileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(approved)
        });
    }

    function _setFollowModule(
        address msgSender,
        uint256 profileId,
        address followModule,
        bytes memory followModuleInitData
    ) internal {
        vm.prank(msgSender);
        hub.setFollowModule(profileId, followModule, followModuleInitData);
    }

    function _setFollowModuleWithSig(
        uint256 profileId,
        address followModule,
        bytes memory followModuleInitData,
        Types.EIP712Signature memory signature
    ) internal {
        hub.setFollowModuleWithSig(profileId, followModule, followModuleInitData, signature);
    }

    function _setProfileImageURI(address msgSender, uint256 profileId, string memory imageURI) internal {
        vm.prank(msgSender);
        hub.setProfileImageURI(profileId, imageURI);
    }

    function _setProfileImageURIWithSig(
        uint256 profileId,
        string memory imageURI,
        Types.EIP712Signature memory signature
    ) internal {
        hub.setProfileImageURIWithSig(profileId, imageURI, signature);
    }

    function _burn(address msgSender, uint256 profileId) internal {
        vm.prank(msgSender);
        hub.burn(profileId);
    }

    function _getPub(uint256 profileId, uint256 pubId) internal view returns (Types.Publication memory) {
        return hub.getPub(profileId, pubId);
    }

    function _getSigNonce(address signer) internal view returns (uint256) {
        return hub.nonces(signer);
    }

    function _getPubCount(uint256 profileId) internal view returns (uint256) {
        return hub.getPubCount(profileId);
    }

    // function _getCollectCount(uint256 profileId, uint256 pubId) internal view returns (uint256) {
    //     address collectNft = hub.getCollectNFT(profileId, pubId);
    //     if (collectNft == address(0)) {
    //         return 0;
    //     } else {
    //         return CollectNFT(collectNft).totalSupply();
    //     }
    // }
}
