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
        address signer,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.SET_PROFILE_METADATA_URI,
                profileId,
                _encodeUsingEip712Rules(metadataURI),
                signer,
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
        address signer,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.SET_FOLLOW_MODULE,
                profileId,
                followModule,
                _encodeUsingEip712Rules(followModuleInitData),
                signer,
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
        address signer,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.CHANGE_DELEGATED_EXECUTORS_CONFIG,
                delegatorProfileId,
                _encodeUsingEip712Rules(delegatedExecutors),
                _encodeUsingEip712Rules(approvals),
                configNumber,
                switchToGivenConfig,
                signer,
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
        address signer,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.POST,
                profileId,
                _encodeUsingEip712Rules(contentURI),
                _encodeUsingEip712Rules(actionModules),
                _encodeUsingEip712Rules(actionModulesInitDatas),
                referenceModule,
                _encodeUsingEip712Rules(referenceModuleInitData),
                signer,
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getPostTypedDataHash(
        Types.PostParams memory postParams,
        address signer,
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
                signer: signer,
                nonce: nonce,
                deadline: deadline
            });
    }

    function _getCommentTypedDataHash(
        Types.CommentParams memory commentParams,
        address signer,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes memory encodedAbi1;
        bytes memory encodedAbi2;
        encodedAbi1 = abi.encode(
            Typehash.COMMENT,
            commentParams.profileId,
            _encodeUsingEip712Rules(commentParams.contentURI),
            commentParams.pointedProfileId,
            commentParams.pointedPubId,
            _encodeUsingEip712Rules(commentParams.referrerProfileIds)
        );
        encodedAbi2 = abi.encode(
            _encodeUsingEip712Rules(commentParams.referrerPubIds),
            _encodeUsingEip712Rules(commentParams.referenceModuleData),
            _encodeUsingEip712Rules(commentParams.actionModules),
            _encodeUsingEip712Rules(commentParams.actionModulesInitDatas),
            commentParams.referenceModule,
            _encodeUsingEip712Rules(commentParams.referenceModuleInitData),
            signer,
            nonce,
            deadline
        );
        bytes32 structHash = keccak256(abi.encodePacked(encodedAbi1, encodedAbi2));
        return _calculateDigest(structHash);
    }

    function _getQuoteTypedDataHash(
        Types.QuoteParams memory quoteParams,
        address signer,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes memory encodedAbi1;
        bytes memory encodedAbi2;
        encodedAbi1 = abi.encode(
            Typehash.QUOTE,
            quoteParams.profileId,
            _encodeUsingEip712Rules(quoteParams.contentURI),
            quoteParams.pointedProfileId,
            quoteParams.pointedPubId,
            _encodeUsingEip712Rules(quoteParams.referrerProfileIds),
            _encodeUsingEip712Rules(quoteParams.referrerPubIds)
        );
        encodedAbi2 = abi.encode(
            _encodeUsingEip712Rules(quoteParams.referenceModuleData),
            _encodeUsingEip712Rules(quoteParams.actionModules),
            _encodeUsingEip712Rules(quoteParams.actionModulesInitDatas),
            quoteParams.referenceModule,
            _encodeUsingEip712Rules(quoteParams.referenceModuleInitData),
            signer,
            nonce,
            deadline
        );
        bytes32 structHash = keccak256(abi.encodePacked(encodedAbi1, encodedAbi2));
        return _calculateDigest(structHash);
    }

    function _getMirrorTypedDataHash(
        Types.MirrorParams memory mirrorParams,
        address signer,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.MIRROR,
                mirrorParams.profileId,
                _encodeUsingEip712Rules(mirrorParams.metadataURI),
                mirrorParams.pointedProfileId,
                mirrorParams.pointedPubId,
                _encodeUsingEip712Rules(mirrorParams.referrerProfileIds),
                _encodeUsingEip712Rules(mirrorParams.referrerPubIds),
                _encodeUsingEip712Rules(mirrorParams.referenceModuleData),
                signer,
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getFollowTypedDataHash(
        uint256 followerProfileId,
        uint256[] memory idsOfProfilesToFollow,
        uint256[] memory followTokenIds,
        bytes[] memory datas,
        address signer,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.FOLLOW,
                followerProfileId,
                _encodeUsingEip712Rules(idsOfProfilesToFollow),
                _encodeUsingEip712Rules(followTokenIds),
                _encodeUsingEip712Rules(datas),
                signer,
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _getActTypedDataHash(
        Types.PublicationActionParams memory publicationActionParams,
        address signer,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.ACT,
                publicationActionParams.publicationActedProfileId,
                publicationActionParams.publicationActedId,
                publicationActionParams.actorProfileId,
                _encodeUsingEip712Rules(publicationActionParams.referrerProfileIds),
                _encodeUsingEip712Rules(publicationActionParams.referrerPubIds),
                publicationActionParams.actionModuleAddress,
                _encodeUsingEip712Rules(publicationActionParams.actionModuleData),
                signer,
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
        uint256 PUBLICATIONS_MAPPING_SLOT = 20;
        uint256 publicationSlot;

        {
            // NOTE: Quotes are converted into V1 comments.
            Types.PublicationType pubType = hub.getPublicationType(profileId, pubId);
            if (pubType == Types.PublicationType.Nonexistent) {
                revert('Cannot convert unexistent or already V1 publications.');
            } else if (pubType == Types.PublicationType.Mirror && collectModule != address(0)) {
                revert('Legacy V1 mirrors cannot have collect module.');
            } else if (pubType != Types.PublicationType.Mirror && collectModule == address(0)) {
                revert('Legacy V1 non-mirror publications requires a non-zero collect module.');
            }

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

        {
            uint256 ACTION_MODULES_OFFSET = 8;
            uint256 ACTION_MODULES_MAPPING_SLOT = publicationSlot + ACTION_MODULES_OFFSET;

            _setActionModuleInPublicationStorage(
                ACTION_MODULES_MAPPING_SLOT,
                _getDefaultPostParams().actionModules[0],
                false
            );
            _setActionModuleInPublicationStorage(
                ACTION_MODULES_MAPPING_SLOT,
                _getDefaultCommentParams().actionModules[0],
                false
            );
            _setActionModuleInPublicationStorage(
                ACTION_MODULES_MAPPING_SLOT,
                _getDefaultQuoteParams().actionModules[0],
                false
            );
        }
    }

    function _setActionModuleInPublicationStorage(
        uint256 actionModuleMappingSlot,
        address module,
        bool isEnabled
    ) internal {
        bytes32 slot;
        assembly {
            mstore(0, module)
            mstore(32, actionModuleMappingSlot)
            slot := keccak256(0, 64)
        }
        vm.store({target: address(hub), slot: slot, value: bytes32(uint256(isEnabled ? 1 : 0))});
    }

    function _isV1LegacyPub(Types.PublicationMemory memory pub) internal pure returns (bool) {
        return uint8(pub.pubType) == 0;
    }

    function _encodeUsingEip712Rules(bytes[] memory bytesArray) internal pure returns (bytes32) {
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
        return _encodeUsingEip712Rules(bytesArrayEncodedElements);
    }

    function _encodeUsingEip712Rules(bool[] memory boolArray) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(boolArray));
    }

    function _encodeUsingEip712Rules(address[] memory addressArray) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addressArray));
    }

    function _encodeUsingEip712Rules(uint256[] memory uint256Array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(uint256Array));
    }

    function _encodeUsingEip712Rules(bytes32[] memory bytes32Array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes32Array));
    }

    function _encodeUsingEip712Rules(string memory stringValue) internal pure returns (bytes32) {
        return keccak256(bytes(stringValue));
    }

    function _encodeUsingEip712Rules(bytes memory bytesValue) internal pure returns (bytes32) {
        return keccak256(bytesValue);
    }
}
