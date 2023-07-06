// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';
import {ILensERC721} from 'contracts/interfaces/ILensERC721.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';

/**
 * @title MetaTxLib
 * @author Lens Protocol
 *
 * NOTE: the functions in this contract operate under the assumption that the passed signer is already validated
 * to either be the originator or one of their delegated executors.
 *
 * @dev User nonces are incremented from this library as well.
 */
library MetaTxLib {
    string constant EIP712_DOMAIN_VERSION = '2';
    bytes32 constant EIP712_DOMAIN_VERSION_HASH = keccak256(bytes(EIP712_DOMAIN_VERSION));
    bytes4 constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

    /**
     * @dev We store the domain separator and LensHub Proxy address as constants to save gas.
     *
     * keccak256(
     *     abi.encode(
     *         keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
     *         keccak256('Lens Protocol Profiles'), // Contract Name
     *         keccak256('2'), // Version Hash
     *         137, // Polygon Chain ID
     *         address(0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d) // Verifying Contract Address - LensHub Address
     *     )
     * );
     */
    bytes32 constant LENS_HUB_CACHED_POLYGON_DOMAIN_SEPARATOR =
        0xbf9544cf7d7a0338fc4f071be35409a61e51e9caef559305410ad74e16a05f2d;

    address constant LENS_HUB_ADDRESS = 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;

    function validateSetProfileMetadataURISignature(
        Types.EIP712Signature calldata signature,
        uint256 profileId,
        string calldata metadataURI
    ) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.SET_PROFILE_METADATA_URI,
                        profileId,
                        keccak256(bytes(metadataURI)),
                        _getAndIncrementNonce(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    function validateSetFollowModuleSignature(
        Types.EIP712Signature calldata signature,
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData
    ) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.SET_FOLLOW_MODULE,
                        profileId,
                        followModule,
                        keccak256(followModuleInitData),
                        _getAndIncrementNonce(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    function validateChangeDelegatedExecutorsConfigSignature(
        Types.EIP712Signature calldata signature,
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) external {
        uint256 nonce = _getAndIncrementNonce(signature.signer);
        uint256 deadline = signature.deadline;
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
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
                )
            ),
            signature
        );
    }

    function validateSetProfileImageURISignature(
        Types.EIP712Signature calldata signature,
        uint256 profileId,
        string calldata imageURI
    ) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.SET_PROFILE_IMAGE_URI,
                        profileId,
                        keccak256(bytes(imageURI)),
                        _getAndIncrementNonce(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    function validatePostSignature(
        Types.EIP712Signature calldata signature,
        Types.PostParams calldata postParams
    ) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.POST,
                        postParams.profileId,
                        keccak256(bytes(postParams.contentURI)),
                        postParams.actionModules,
                        _hashActionModulesInitDatas(postParams.actionModulesInitDatas),
                        postParams.referenceModule,
                        keccak256(postParams.referenceModuleInitData),
                        _getAndIncrementNonce(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
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
        // This assembly workaround allows us to avoid Stack Too Deep error when encoding all the params of the struct.
        // We remove the first 32 bytes of the encoded struct, which is the offset of the struct.
        // The rest of the encoding is the same, so we can just return it.
        bytes memory encodedStruct = abi.encode(referenceParamsForAbiEncode);
        assembly {
            let lengthWithoutOffset := sub(mload(encodedStruct), 32) // Calculates length without offset.
            encodedStruct := add(encodedStruct, 32) // Skips the offset by shifting the memory pointer.
            mstore(encodedStruct, lengthWithoutOffset) // Stores new length, which now excludes the offset.
        }
        return encodedStruct;
        // The code above is the equivalent of:
        //
        // return abi.encode(
        //     referenceParamsForAbiEncode.typehash,
        //     referenceParamsForAbiEncode.profileId,
        //     referenceParamsForAbiEncode.contentURIHash,
        //     referenceParamsForAbiEncode.pointedProfileId,
        //     referenceParamsForAbiEncode.pointedPubId,
        //     referenceParamsForAbiEncode.referrerProfileIds,
        //     referenceParamsForAbiEncode.referrerPubIds,
        //     referenceParamsForAbiEncode.referenceModuleDataHash,
        //     referenceParamsForAbiEncode.actionModules,
        //     referenceParamsForAbiEncode.actionModulesInitDataHash,
        //     referenceParamsForAbiEncode.referenceModule,
        //     referenceParamsForAbiEncode.referenceModuleInitDataHash,
        //     referenceParamsForAbiEncode.nonce,
        //     referenceParamsForAbiEncode.deadline
        // );
    }

    function validateCommentSignature(
        Types.EIP712Signature calldata signature,
        Types.CommentParams calldata commentParams
    ) external {
        bytes32 contentURIHash = keccak256(bytes(commentParams.contentURI));
        bytes32 referenceModuleDataHash = keccak256(commentParams.referenceModuleData);
        bytes32 actionModulesInitDataHash = _hashActionModulesInitDatas(commentParams.actionModulesInitDatas);
        bytes32 referenceModuleInitDataHash = keccak256(commentParams.referenceModuleInitData);
        uint256 nonce = _getAndIncrementNonce(signature.signer);
        uint256 deadline = signature.deadline;
        bytes memory encodedAbi = _abiEncode(
            ReferenceParamsForAbiEncode(
                Typehash.COMMENT,
                commentParams.profileId,
                contentURIHash,
                commentParams.pointedProfileId,
                commentParams.pointedPubId,
                commentParams.referrerProfileIds,
                commentParams.referrerPubIds,
                referenceModuleDataHash,
                commentParams.actionModules,
                actionModulesInitDataHash,
                commentParams.referenceModule,
                referenceModuleInitDataHash,
                nonce,
                deadline
            )
        );
        _validateRecoveredAddress(_calculateDigest(keccak256(encodedAbi)), signature);
    }

    function validateQuoteSignature(
        Types.EIP712Signature calldata signature,
        Types.QuoteParams calldata quoteParams
    ) external {
        bytes32 contentURIHash = keccak256(bytes(quoteParams.contentURI));
        bytes32 referenceModuleDataHash = keccak256(quoteParams.referenceModuleData);
        bytes32 actionModulesInitDataHash = _hashActionModulesInitDatas(quoteParams.actionModulesInitDatas);
        bytes32 referenceModuleInitDataHash = keccak256(quoteParams.referenceModuleInitData);
        uint256 nonce = _getAndIncrementNonce(signature.signer);
        uint256 deadline = signature.deadline;
        bytes memory encodedAbi = _abiEncode(
            ReferenceParamsForAbiEncode(
                Typehash.QUOTE,
                quoteParams.profileId,
                contentURIHash,
                quoteParams.pointedProfileId,
                quoteParams.pointedPubId,
                quoteParams.referrerProfileIds,
                quoteParams.referrerPubIds,
                referenceModuleDataHash,
                quoteParams.actionModules,
                actionModulesInitDataHash,
                quoteParams.referenceModule,
                referenceModuleInitDataHash,
                nonce,
                deadline
            )
        );
        _validateRecoveredAddress(_calculateDigest(keccak256(encodedAbi)), signature);
    }

    function validateMirrorSignature(
        Types.EIP712Signature calldata signature,
        Types.MirrorParams calldata mirrorParams
    ) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.MIRROR,
                        mirrorParams.profileId,
                        mirrorParams.pointedProfileId,
                        mirrorParams.pointedPubId,
                        mirrorParams.referrerProfileIds,
                        mirrorParams.referrerPubIds,
                        keccak256(mirrorParams.referenceModuleData),
                        _getAndIncrementNonce(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    function validateBurnSignature(Types.EIP712Signature calldata signature, uint256 tokenId) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(Typehash.BURN, tokenId, _getAndIncrementNonce(signature.signer), signature.deadline)
                )
            ),
            signature
        );
    }

    function validateFollowSignature(
        Types.EIP712Signature calldata signature,
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata datas
    ) external {
        uint256 dataLength = datas.length;
        bytes32[] memory dataHashes = new bytes32[](dataLength);
        uint256 i;
        while (i < dataLength) {
            dataHashes[i] = keccak256(datas[i]);
            unchecked {
                ++i;
            }
        }
        uint256 nonce = _getAndIncrementNonce(signature.signer);
        uint256 deadline = signature.deadline;

        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.FOLLOW,
                        followerProfileId,
                        keccak256(abi.encodePacked(idsOfProfilesToFollow)),
                        keccak256(abi.encodePacked(followTokenIds)),
                        keccak256(abi.encodePacked(dataHashes)),
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
    }

    function validateUnfollowSignature(
        Types.EIP712Signature calldata signature,
        uint256 unfollowerProfileId,
        uint256[] calldata idsOfProfilesToUnfollow
    ) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.UNFOLLOW,
                        unfollowerProfileId,
                        keccak256(abi.encodePacked(idsOfProfilesToUnfollow)),
                        _getAndIncrementNonce(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    function validateSetBlockStatusSignature(
        Types.EIP712Signature calldata signature,
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.SET_BLOCK_STATUS,
                        byProfileId,
                        keccak256(abi.encodePacked(idsOfProfilesToSetBlockStatus)),
                        keccak256(abi.encodePacked(blockStatus)),
                        _getAndIncrementNonce(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    function validateLegacyCollectSignature(
        Types.EIP712Signature calldata signature,
        Types.CollectParams calldata collectParams
    ) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.LEGACY_COLLECT,
                        collectParams.publicationCollectedProfileId,
                        collectParams.publicationCollectedId,
                        collectParams.collectorProfileId,
                        collectParams.referrerProfileId,
                        collectParams.referrerPubId,
                        keccak256(collectParams.collectModuleData),
                        _getAndIncrementNonce(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    function validateActSignature(
        Types.EIP712Signature calldata signature,
        Types.PublicationActionParams calldata publicationActionParams
    ) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.ACT,
                        publicationActionParams.publicationActedProfileId,
                        publicationActionParams.publicationActedId,
                        publicationActionParams.actorProfileId,
                        publicationActionParams.referrerProfileIds,
                        publicationActionParams.referrerPubIds,
                        publicationActionParams.actionModuleAddress,
                        keccak256(publicationActionParams.actionModuleData),
                        _getAndIncrementNonce(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    function calculateDomainSeparator() internal view returns (bytes32) {
        if (address(this) == LENS_HUB_ADDRESS) {
            return LENS_HUB_CACHED_POLYGON_DOMAIN_SEPARATOR;
        }
        return
            keccak256(
                abi.encode(
                    Typehash.EIP712_DOMAIN,
                    keccak256(bytes(ILensERC721(address(this)).name())),
                    EIP712_DOMAIN_VERSION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(bytes32 digest, Types.EIP712Signature calldata signature) private view {
        if (signature.deadline < block.timestamp) revert Errors.SignatureExpired();
        // If the expected address is a contract, check the signature there.
        if (signature.signer.code.length != 0) {
            bytes memory concatenatedSig = abi.encodePacked(signature.r, signature.s, signature.v);
            if (IERC1271(signature.signer).isValidSignature(digest, concatenatedSig) != EIP1271_MAGIC_VALUE) {
                revert Errors.SignatureInvalid();
            }
        } else {
            address recoveredAddress = ecrecover(digest, signature.v, signature.r, signature.s);
            if (recoveredAddress == address(0) || recoveredAddress != signature.signer) {
                revert Errors.SignatureInvalid();
            }
        }
    }

    /**
     * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest.
     */
    function _calculateDigest(bytes32 hashedMessage) private view returns (bytes32) {
        return keccak256(abi.encodePacked('\x19\x01', calculateDomainSeparator(), hashedMessage));
    }

    /**
     * @dev This fetches a user's signing nonce and increments it, akin to `sigNonces++`.
     *
     * @param user The user address to fetch and post-increment the signing nonce for.
     *
     * @return uint256 The signing nonce for the given user prior to being incremented.
     */
    function _getAndIncrementNonce(address user) private returns (uint256) {
        unchecked {
            return StorageLib.nonces()[user]++;
        }
    }
}
