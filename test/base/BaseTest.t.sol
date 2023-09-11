// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/TestSetup.t.sol';
import 'contracts/libraries/constants/Types.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

contract BaseTest is TestSetup {
    using Strings for string;
    using Address for address;

    function testBaseTest() public {
        // Prevents being counted in Foundry Coverage
    }

    // Empty setUp for easier overriding in other tests, otherwise you need to override from TestSetup and is confusing.
    function setUp() public virtual override {
        super.setUp();
    }

    function _effectivelyDisableProfileGuardian(address wallet) internal {
        _effectivelyDisableGuardian(address(hub), wallet);
    }

    function _effectivelyDisableGuardian(address nft, address wallet) internal {
        if (_isProfileGuardianEnabled(wallet)) {
            vm.prank(wallet);
            // TODO: Fix this if we move disableTokenGuardian to its own interface
            LensHub(nft).DANGER__disableTokenGuardian();
            vm.warp(LensHub(nft).getTokenGuardianDisablingTimestamp(wallet));
        }
    }

    function _isProfileGuardianEnabled(address wallet) internal view returns (bool) {
        return
            !wallet.isContract() &&
            (hub.getTokenGuardianDisablingTimestamp(wallet) == 0 ||
                block.timestamp < hub.getTokenGuardianDisablingTimestamp(wallet));
    }

    function _boundPk(uint256 fuzzedUint256) internal view returns (uint256 fuzzedPk) {
        return bound(fuzzedUint256, 1, ISSECP256K1_CURVE_ORDER - 1);
    }

    function _isLensHubProxyAdmin(address proxyAdminCandidate) internal view returns (bool) {
        address proxyAdmin = address(uint160(uint256(vm.load(address(hub), ADMIN_SLOT))));
        return proxyAdminCandidate == proxyAdmin;
    }

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
                _encodeUsingEip712Rules(actionModulesInitDatas),
                referenceModule,
                keccak256(referenceModuleInitData),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _encodeUsingEip712Rules(bytes[] memory bytesArray) private pure returns (bytes32) {
        bytes32[] memory bytesArrayEncodedElements = new bytes32[](bytesArray.length);
        uint256 i;
        while (i < bytesArray.length) {
            // A `bytes` type is encoded as its keccak256 hash.
            bytesArrayEncodedElements[i] = keccak256(bytesArray[i]);
            unchecked {
                ++i;
            }
        }
        // An array is encoded as the keccak256 hash of the concatenation of their encoded elements.
        return keccak256(abi.encodePacked(bytesArrayEncodedElements));
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
                    _encodeUsingEip712Rules(commentParams.actionModulesInitDatas),
                    commentParams.referenceModule,
                    keccak256(commentParams.referenceModuleInitData),
                    nonce,
                    deadline
                )
            )
        );
        return _calculateDigest(structHash);
    }

    function _getQuoteTypedDataHash(
        Types.QuoteParams memory quoteParams,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            _abiEncode(
                ReferenceParamsForAbiEncode(
                    Typehash.QUOTE,
                    quoteParams.profileId,
                    keccak256(bytes(quoteParams.contentURI)),
                    quoteParams.pointedProfileId,
                    quoteParams.pointedPubId,
                    quoteParams.referrerProfileIds,
                    quoteParams.referrerPubIds,
                    keccak256(quoteParams.referenceModuleData),
                    quoteParams.actionModules,
                    _encodeUsingEip712Rules(quoteParams.actionModulesInitDatas),
                    quoteParams.referenceModule,
                    keccak256(quoteParams.referenceModuleInitData),
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
                referrerProfileIds: mirrorParams.referrerProfileIds,
                referrerPubIds: mirrorParams.referrerPubIds,
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
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.FOLLOW,
                followerProfileId,
                keccak256(abi.encodePacked(idsOfProfilesToFollow)),
                keccak256(abi.encodePacked(followTokenIds)),
                _encodeUsingEip712Rules(datas),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

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
        return keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
    }

    function _getSigStruct(
        uint256 pKey,
        bytes32 digest,
        uint256 deadline
    ) internal pure returns (Types.EIP712Signature memory) {
        return _getSigStruct(vm.addr(pKey), pKey, digest, deadline);
    }

    function _getSigStruct(
        address signer,
        uint256 pKey,
        bytes32 digest,
        uint256 deadline
    ) internal pure returns (Types.EIP712Signature memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pKey, digest);
        return Types.EIP712Signature(signer, v, r, s, deadline);
    }

    function _toLegacyV1Pub(uint256 profileId, uint256 pubId, address referenceModule, address collectModule) internal {
        // NOTE: Quotes are converted into V1 comments.

        Types.PublicationType pubType = hub.getPublicationType(profileId, pubId);
        if (pubType == Types.PublicationType.Nonexistent) {
            revert('Cannot convert unexistent or already V1 publications.');
        } else if (pubType == Types.PublicationType.Mirror && collectModule != address(0)) {
            revert('Legacy V1 mirrors cannot have collect module.');
        } else if (pubType != Types.PublicationType.Mirror && collectModule == address(0)) {
            revert('Legacy V1 non-mirror publications requires a non-zero collect module.');
        }

        uint256 PUBLICATIONS_MAPPING_SLOT = 20;
        uint256 publicationSlot;
        assembly {
            mstore(0, profileId)
            mstore(32, PUBLICATIONS_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            publicationSlot := keccak256(0, 64)
        }

        uint256 REFERENCE_MODULE_OFFSET = 3;
        uint256 referenceModuleSlot = publicationSlot + REFERENCE_MODULE_OFFSET;
        vm.store({
            target: address(hub),
            slot: bytes32(referenceModuleSlot),
            value: bytes32(uint256(uint160(referenceModule)))
        });

        uint256 COLLECT_MODULE_OFFSET = 4;
        uint256 collectModuleSlot = publicationSlot + COLLECT_MODULE_OFFSET;
        vm.store({
            target: address(hub),
            slot: bytes32(collectModuleSlot),
            value: bytes32(uint256(uint160(collectModule)))
        });

        uint256 firstSlotOffsetToWipe = 5;
        uint256 lastSlotOffsetToWipe = 8;
        for (uint256 offset = firstSlotOffsetToWipe; offset <= lastSlotOffsetToWipe; offset++) {
            vm.store({target: address(hub), slot: bytes32(publicationSlot + offset), value: 0});
        }
    }

    function _isV1LegacyPub(Types.PublicationMemory memory pub) internal pure returns (bool) {
        return uint8(pub.pubType) == 0;
    }
}
