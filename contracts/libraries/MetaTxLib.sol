// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';
import {ILensERC721} from 'contracts/interfaces/ILensERC721.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';

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

    uint256 constant POLYGON_CHAIN_ID = 137;

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
                        _encodeUsingEip712Rules(metadataURI),
                        signature.signer,
                        _getNonceIncrementAndEmitEvent(signature.signer),
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
                        _encodeUsingEip712Rules(followModuleInitData),
                        signature.signer,
                        _getNonceIncrementAndEmitEvent(signature.signer),
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
        address signer = signature.signer;
        uint256 deadline = signature.deadline;
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.CHANGE_DELEGATED_EXECUTORS_CONFIG,
                        delegatorProfileId,
                        _encodeUsingEip712Rules(delegatedExecutors),
                        _encodeUsingEip712Rules(approvals),
                        configNumber,
                        switchToGivenConfig,
                        signer,
                        _getNonceIncrementAndEmitEvent(signer),
                        deadline
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
                        _encodeUsingEip712Rules(postParams.contentURI),
                        _encodeUsingEip712Rules(postParams.actionModules),
                        _encodeUsingEip712Rules(postParams.actionModulesInitDatas),
                        postParams.referenceModule,
                        _encodeUsingEip712Rules(postParams.referenceModuleInitData),
                        signature.signer,
                        _getNonceIncrementAndEmitEvent(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    function validateCommentSignature(
        Types.EIP712Signature calldata signature,
        Types.CommentParams calldata commentParams
    ) external {
        bytes memory encodedAbi1;
        bytes memory encodedAbi2;
        // I sold my soul to the devil to make this compile without Stack Too Deep
        encodedAbi1 = abi.encode(
            Typehash.COMMENT,
            commentParams.profileId,
            _encodeUsingEip712Rules(commentParams.contentURI),
            commentParams.pointedProfileId,
            commentParams.pointedPubId,
            _encodeUsingEip712Rules(commentParams.referrerProfileIds),
            _encodeUsingEip712Rules(commentParams.referrerPubIds),
            _encodeUsingEip712Rules(commentParams.referenceModuleData)
        );
        encodedAbi2 = abi.encode(
            _encodeUsingEip712Rules(commentParams.actionModules),
            _encodeUsingEip712Rules(commentParams.actionModulesInitDatas),
            commentParams.referenceModule,
            _encodeUsingEip712Rules(commentParams.referenceModuleInitData),
            signature.signer,
            _getNonceIncrementAndEmitEvent(signature.signer),
            signature.deadline
        );
        bytes memory encodedAbi = abi.encodePacked(encodedAbi1, encodedAbi2);
        _validateRecoveredAddress(_calculateDigest(keccak256(encodedAbi)), signature);
    }

    function validateQuoteSignature(
        Types.EIP712Signature calldata signature,
        Types.QuoteParams calldata quoteParams
    ) external {
        bytes memory encodedAbi1;
        bytes memory encodedAbi2;
        encodedAbi1 = abi.encode(
            Typehash.QUOTE,
            quoteParams.profileId,
            _encodeUsingEip712Rules(quoteParams.contentURI),
            quoteParams.pointedProfileId,
            quoteParams.pointedPubId,
            _encodeUsingEip712Rules(quoteParams.referrerProfileIds),
            _encodeUsingEip712Rules(quoteParams.referrerPubIds),
            _encodeUsingEip712Rules(quoteParams.referenceModuleData)
        );
        encodedAbi2 = abi.encode(
            _encodeUsingEip712Rules(quoteParams.actionModules),
            _encodeUsingEip712Rules(quoteParams.actionModulesInitDatas),
            quoteParams.referenceModule,
            _encodeUsingEip712Rules(quoteParams.referenceModuleInitData),
            signature.signer,
            _getNonceIncrementAndEmitEvent(signature.signer),
            signature.deadline
        );
        bytes memory encodedAbi = abi.encodePacked(encodedAbi1, encodedAbi2);
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
                        _encodeUsingEip712Rules(mirrorParams.metadataURI),
                        mirrorParams.pointedProfileId,
                        mirrorParams.pointedPubId,
                        _encodeUsingEip712Rules(mirrorParams.referrerProfileIds),
                        _encodeUsingEip712Rules(mirrorParams.referrerPubIds),
                        _encodeUsingEip712Rules(mirrorParams.referenceModuleData),
                        signature.signer,
                        _getNonceIncrementAndEmitEvent(signature.signer),
                        signature.deadline
                    )
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
        address signer = signature.signer;
        uint256 deadline = signature.deadline;
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.FOLLOW,
                        followerProfileId,
                        _encodeUsingEip712Rules(idsOfProfilesToFollow),
                        _encodeUsingEip712Rules(followTokenIds),
                        _encodeUsingEip712Rules(datas),
                        signer,
                        _getNonceIncrementAndEmitEvent(signer),
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
        address signer = signature.signer;
        uint256 deadline = signature.deadline;
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.UNFOLLOW,
                        unfollowerProfileId,
                        _encodeUsingEip712Rules(idsOfProfilesToUnfollow),
                        signer,
                        _getNonceIncrementAndEmitEvent(signer),
                        deadline
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
                        _encodeUsingEip712Rules(idsOfProfilesToSetBlockStatus),
                        _encodeUsingEip712Rules(blockStatus),
                        signature.signer,
                        _getNonceIncrementAndEmitEvent(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    function validateLegacyCollectSignature(
        Types.EIP712Signature calldata signature,
        Types.LegacyCollectParams calldata collectParams
    ) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.COLLECT_LEGACY,
                        collectParams.publicationCollectedProfileId,
                        collectParams.publicationCollectedId,
                        collectParams.collectorProfileId,
                        collectParams.referrerProfileId,
                        collectParams.referrerPubId,
                        _encodeUsingEip712Rules(collectParams.collectModuleData),
                        signature.signer,
                        _getNonceIncrementAndEmitEvent(signature.signer),
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
                        _encodeUsingEip712Rules(publicationActionParams.referrerProfileIds),
                        _encodeUsingEip712Rules(publicationActionParams.referrerPubIds),
                        publicationActionParams.actionModuleAddress,
                        _encodeUsingEip712Rules(publicationActionParams.actionModuleData),
                        signature.signer,
                        _getNonceIncrementAndEmitEvent(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    /// @dev This function is used to invalidate signatures by incrementing the nonce
    function incrementNonce(uint8 increment) external {
        uint256 currentNonce = StorageLib.nonces()[msg.sender];
        StorageLib.nonces()[msg.sender] = currentNonce + increment;
        emit Events.NonceUpdated(msg.sender, currentNonce + increment, block.timestamp);
    }

    function calculateDomainSeparator() internal view returns (bytes32) {
        if (address(this) == LENS_HUB_ADDRESS && block.chainid == POLYGON_CHAIN_ID) {
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
        if (block.timestamp > signature.deadline) revert Errors.SignatureExpired();
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
     * @dev This fetches a signer's current nonce and increments it so it's ready for the next meta-tx. Also emits
     * the `NonceUpdated` event.
     *
     * @param signer The address to get and increment the nonce for.
     *
     * @return uint256 The current nonce for the given signer prior to being incremented.
     */
    function _getNonceIncrementAndEmitEvent(address signer) private returns (uint256) {
        uint256 currentNonce;
        unchecked {
            currentNonce = StorageLib.nonces()[signer]++;
        }
        emit Events.NonceUpdated(signer, currentNonce + 1, block.timestamp);
        return currentNonce;
    }

    function _encodeUsingEip712Rules(bytes[] memory bytesArray) private pure returns (bytes32) {
        bytes32[] memory bytesArrayEncodedElements = new bytes32[](bytesArray.length);
        uint256 i;
        while (i < bytesArray.length) {
            // A `bytes` type is encoded as its keccak256 hash.
            bytesArrayEncodedElements[i] = _encodeUsingEip712Rules(bytesArray[i]);
            unchecked {
                ++i;
            }
        }
        // An array is encoded as the keccak256 hash of the concatenation of their encoded elements.
        return _encodeUsingEip712Rules(bytesArrayEncodedElements);
    }

    function _encodeUsingEip712Rules(bool[] memory boolArray) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(boolArray));
    }

    function _encodeUsingEip712Rules(address[] memory addressArray) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(addressArray));
    }

    function _encodeUsingEip712Rules(uint256[] memory uint256Array) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(uint256Array));
    }

    function _encodeUsingEip712Rules(bytes32[] memory bytes32Array) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes32Array));
    }

    function _encodeUsingEip712Rules(string memory stringValue) private pure returns (bytes32) {
        return keccak256(bytes(stringValue));
    }

    function _encodeUsingEip712Rules(bytes memory bytesValue) private pure returns (bytes32) {
        return keccak256(bytesValue);
    }
}
