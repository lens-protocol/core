// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IEIP1271Implementer} from '../../interfaces/IEIP1271Implementer.sol';
import {DataTypes} from '../DataTypes.sol';
import {Errors} from '../Errors.sol';
import {DataTypes} from '../DataTypes.sol';
import {GeneralHelpers} from './GeneralHelpers.sol';
import '../Constants.sol';

/**
 * @title MetaTxHelpers
 * @author Lens Protocol
 *
 * @notice This is the library used by the GeneralLib that contains the logic for signature
 * validation.
 *
 * NOTE: the baseFunctions in this contract operate under the assumption that the passed signer is already validated
 * to either be the originator or one of their delegated executors.
 *
 * @dev The functions are internal, so they are inlined into the GeneralLib. User nonces
 * are incremented from this library as well.
 */
library MetaTxHelpers {
    /// Permit and PermitForAll emit these ERC721 events here an optimization.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the `permit()`
     * function.
     *
     * @param spender The spender to approve.
     * @param tokenId The token ID to approve the spender for.
     * @param sig the EIP712Signature struct containing the token owner's signature.
     */
    function basePermit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) internal {
        if (spender == address(0)) revert Errors.ZeroSpender();
        address owner = GeneralHelpers.unsafeOwnerOf(tokenId);
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(PERMIT_TYPEHASH, spender, tokenId, _sigNonces(owner), sig.deadline)
                )
            ),
            owner,
            sig
        );
        emit Approval(owner, spender, tokenId);
    }

    function basePermitForAll(
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) internal {
        if (operator == address(0)) revert Errors.ZeroSpender();
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        PERMIT_FOR_ALL_TYPEHASH,
                        owner,
                        operator,
                        approved,
                        _sigNonces(owner),
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        emit ApprovalForAll(owner, operator, approved);
    }

    function validateSetProfileMetadataURISignature(
        DataTypes.EIP712Signature calldata signature,
        uint256 profileId,
        string calldata metadataURI
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        SET_PROFILE_METADATA_URI_WITH_SIG_TYPEHASH,
                        profileId,
                        keccak256(bytes(metadataURI)),
                        _sigNonces(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature.signer,
            signature
        );
    }

    function validateSetFollowModuleSignature(
        DataTypes.EIP712Signature calldata signature,
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        SET_FOLLOW_MODULE_WITH_SIG_TYPEHASH,
                        profileId,
                        followModule,
                        keccak256(followModuleInitData),
                        _sigNonces(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature.signer,
            signature
        );
    }

    function validateChangeDelegatedExecutorsConfigSignature(
        DataTypes.EIP712Signature calldata signature,
        address[] calldata executors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) internal {
        uint256 nonce = _sigNonces(signature.signer);
        uint256 deadline = signature.deadline;
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        CHANGE_DELEGATED_EXECUTORS_CONFIG_WITH_SIG_TYPEHASH,
                        signature.signer,
                        abi.encodePacked(executors),
                        abi.encodePacked(approvals),
                        configNumber,
                        switchToGivenConfig,
                        nonce,
                        deadline
                    )
                )
            ),
            signature.signer,
            signature
        );
    }

    function validateSetProfileImageURISignature(
        DataTypes.EIP712Signature calldata signature,
        uint256 profileId,
        string calldata imageURI
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        SET_PROFILE_IMAGE_URI_WITH_SIG_TYPEHASH,
                        profileId,
                        keccak256(bytes(imageURI)),
                        _sigNonces(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature.signer,
            signature
        );
    }

    function validateSetFollowNFTURISignature(
        DataTypes.EIP712Signature calldata signature,
        uint256 profileId,
        string calldata followNFTURI
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        SET_FOLLOW_NFT_URI_WITH_SIG_TYPEHASH,
                        profileId,
                        keccak256(bytes(followNFTURI)),
                        _sigNonces(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature.signer,
            signature
        );
    }

    function validatePostSignature(
        DataTypes.EIP712Signature calldata sig,
        DataTypes.PostParams calldata postParams
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        POST_WITH_SIG_TYPEHASH,
                        postParams.profileId,
                        keccak256(bytes(postParams.contentURI)),
                        postParams.collectModule,
                        keccak256(postParams.collectModuleInitData),
                        postParams.referenceModule,
                        keccak256(postParams.referenceModuleInitData),
                        _sigNonces(sig.signer),
                        sig.deadline
                    )
                )
            ),
            sig.signer,
            sig
        );
    }

    function validateCommentSignature(
        DataTypes.EIP712Signature calldata sig,
        DataTypes.CommentParams calldata commentParams
    ) internal {
        uint256 nonce = _sigNonces(sig.signer);
        uint256 deadline = sig.deadline;
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        COMMENT_WITH_SIG_TYPEHASH,
                        commentParams.profileId,
                        keccak256(bytes(commentParams.contentURI)),
                        commentParams.pointedProfileId,
                        commentParams.pointedPubId,
                        commentParams.referrerProfileId,
                        commentParams.referrerPubId,
                        keccak256(commentParams.referenceModuleData),
                        commentParams.collectModule,
                        keccak256(commentParams.collectModuleInitData),
                        commentParams.referenceModule,
                        keccak256(commentParams.referenceModuleInitData),
                        nonce,
                        deadline
                    )
                )
            ),
            sig
        );
    }

    function validateQuoteSignature(
        DataTypes.EIP712Signature calldata sig,
        DataTypes.QuoteParams calldata quoteParams
    ) internal {
        uint256 nonce = _sigNonces(sig.signer);
        uint256 deadline = sig.deadline;
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        COMMENT_WITH_SIG_TYPEHASH,
                        quoteParams.profileId,
                        keccak256(bytes(quoteParams.contentURI)),
                        quoteParams.pointedProfileId,
                        quoteParams.pointedPubId,
                        keccak256(quoteParams.referenceModuleData),
                        quoteParams.referrerProfileId,
                        quoteParams.referrerPubId,
                        quoteParams.collectModule,
                        keccak256(quoteParams.collectModuleInitData),
                        quoteParams.referenceModule,
                        keccak256(quoteParams.referenceModuleInitData),
                        nonce,
                        deadline
                    )
                )
            ),
            sig
        );
    }

    function validateMirrorSignature(
        DataTypes.EIP712Signature calldata sig,
        DataTypes.MirrorParams calldata mirrorParams
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        MIRROR_WITH_SIG_TYPEHASH,
                        mirrorParams.profileId,
                        mirrorParams.pointedProfileId,
                        mirrorParams.pointedPubId,
                        mirrorParams.referrerProfileId,
                        mirrorParams.referrerPubId,
                        keccak256(mirrorParams.referenceModuleData),
                        _sigNonces(sig.signer),
                        sig.deadline
                    )
                )
            ),
            sig.signer,
            sig
        );
    }

    function validateBurnSignature(DataTypes.EIP712Signature calldata signature, uint256 tokenId)
        internal
    {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        BURN_WITH_SIG_TYPEHASH,
                        tokenId,
                        _sigNonces(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature.signer,
            signature
        );
    }

    function validateFollowSignature(
        DataTypes.EIP712Signature calldata signature,
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata datas
    ) internal {
        uint256 dataLength = datas.length;
        bytes32[] memory dataHashes = new bytes32[](dataLength);
        for (uint256 i = 0; i < dataLength; ) {
            dataHashes[i] = keccak256(datas[i]);
            unchecked {
                ++i;
            }
        }
        uint256 nonce = _sigNonces(signature.signer);
        uint256 deadline = signature.deadline;

        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        FOLLOW_WITH_SIG_TYPEHASH,
                        followerProfileId,
                        keccak256(abi.encodePacked(idsOfProfilesToFollow)),
                        keccak256(abi.encodePacked(followTokenIds)),
                        keccak256(abi.encodePacked(dataHashes)),
                        nonce,
                        deadline
                    )
                )
            ),
            signature.signer,
            signature
        );
    }

    function validateUnfollowSignature(
        DataTypes.EIP712Signature calldata signature,
        uint256 unfollowerProfileId,
        uint256[] calldata idsOfProfilesToUnfollow
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        UNFOLLOW_WITH_SIG_TYPEHASH,
                        unfollowerProfileId,
                        keccak256(abi.encodePacked(idsOfProfilesToUnfollow)),
                        _sigNonces(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature.signer,
            signature
        );
    }

    function validateSetBlockStatusSignature(
        DataTypes.EIP712Signature calldata signature,
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        SET_BLOCK_STATUS_WITH_SIG_TYPEHASH,
                        byProfileId,
                        keccak256(abi.encodePacked(idsOfProfilesToSetBlockStatus)),
                        keccak256(abi.encodePacked(blockStatus)),
                        _sigNonces(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature.signer,
            signature
        );
    }

    function validateCollectSignature(
        DataTypes.EIP712Signature calldata sig,
        DataTypes.CollectParams calldata collectParams
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        COLLECT_WITH_SIG_TYPEHASH,
                        collectParams.publicationCollectedProfileId,
                        collectParams.publicationCollectedId,
                        collectParams.collectorProfileId,
                        collectParams.referrerProfileId,
                        collectParams.referrerPubId,
                        keccak256(collectParams.collectModuleData),
                        _sigNonces(sig.signer),
                        sig.deadline
                    )
                )
            ),
            sig
        );
    }

    function getDomainSeparator() internal view returns (bytes32) {
        return _calculateDomainSeparator();
    }

    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(bytes32 digest, DataTypes.EIP712Signature calldata sig)
        internal
        view
    {
        if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
        // If the expected address is a contract, check the signature there.
        if (sig.signer.code.length != 0) {
            bytes memory concatenatedSig = abi.encodePacked(sig.r, sig.s, sig.v);
            if (
                IEIP1271Implementer(sig.signer).isValidSignature(digest, concatenatedSig) !=
                EIP1271_MAGIC_VALUE
            ) {
                revert Errors.SignatureInvalid();
            }
        } else {
            address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
            if (recoveredAddress == address(0) || recoveredAddress != sig.signer) {
                revert Errors.SignatureInvalid();
            }
        }
    }

    // TODO: Remove this duplicate when we refactor all functions to use signer inside the sig
    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 digest,
        address signer,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
        // If the expected address is a contract, check the signature there.
        if (signer.code.length != 0) {
            bytes memory concatenatedSig = abi.encodePacked(sig.r, sig.s, sig.v);
            if (
                IEIP1271Implementer(signer).isValidSignature(digest, concatenatedSig) !=
                EIP1271_MAGIC_VALUE
            ) {
                revert Errors.SignatureInvalid();
            }
        } else {
            address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
            if (recoveredAddress == address(0) || recoveredAddress != signer) {
                revert Errors.SignatureInvalid();
            }
        }
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() private view returns (bytes32) {
        if (block.chainid == POLYGON_CHAIN_ID) {
            // Note that this only works on the canonical Polygon mainnet deployment, and should the
            // name change, a contract upgrade would be necessary.
            return POLYGON_DOMAIN_SEPARATOR;
        }
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(_nameBytes()),
                    EIP712_REVISION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest.
     */
    function _calculateDigest(bytes32 hashedMessage) private view returns (bytes32) {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked('\x19\x01', _calculateDomainSeparator(), hashedMessage)
            );
        }
        return digest;
    }

    /**
     * @dev This fetches a user's signing nonce and increments it, akin to `sigNonces++`.
     *
     * @param user The user address to fetch and post-increment the signing nonce for.
     *
     * @return uint256 The signing nonce for the given user prior to being incremented.
     */
    function _sigNonces(address user) private returns (uint256) {
        uint256 previousValue;
        assembly {
            mstore(0, user)
            mstore(32, SIG_NONCES_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            previousValue := sload(slot)
            sstore(slot, add(previousValue, 1))
        }
        return previousValue;
    }

    /**
     * @dev Reads the name storage slot and returns the value as a bytes variable.
     *
     * @return bytes The contract's name.
     */
    function _nameBytes() private view returns (bytes memory) {
        bytes memory ptr;
        assembly {
            // Load the free memory pointer, where we'll return the value
            ptr := mload(64)

            // Load the slot, which either contains the name + 2*length if length < 32 or
            // 2*length+1 if length >= 32, and the actual string starts at slot keccak256(NAME_SLOT)
            let slotLoad := sload(NAME_SLOT)

            let size
            // Determine if the length > 32 by checking the lowest order bit, meaning the string
            // itself is stored at keccak256(NAME_SLOT)
            switch and(slotLoad, 1)
            case 0 {
                // The name is in the same slot
                // Determine the size by dividing the last byte's value by 2
                size := shr(1, and(slotLoad, 255))

                // Store the size in the first slot
                mstore(ptr, size)

                // Store the actual string in the second slot (without the size)
                mstore(add(ptr, 32), and(slotLoad, not(255)))
            }
            case 1 {
                // The name is not in the same slot
                // Determine the size by dividing the value in the whole slot minus 1 by 2
                size := shr(1, sub(slotLoad, 1))

                // Store the size in the first slot
                mstore(ptr, size)

                // Compute the total memory slots we need, this is (size + 31) / 32
                let totalMemorySlots := shr(5, add(size, 31))

                // Iterate through the words in memory and store the string word by word
                // prettier-ignore
                for { let i := 0 } lt(i, totalMemorySlots) { i := add(i, 1) } {
                    mstore(add(add(ptr, 32), mul(32, i)), sload(add(NAME_SLOT_GT_31, i)))
                }
            }
            // Store the new memory pointer in the free memory pointer slot
            mstore(64, add(add(ptr, 32), size))
        }
        return ptr;
    }
}
