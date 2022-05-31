// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @title MetaTxLib
 *
 * @author Lens Protocol (Zer0dot)
 *
 * @notice This library includes functions pertaining to meta-transactions to be called
 * specifically from the LensHub.
 *
 * @dev Meta-transaction functions have had their signature validation delegated to this library, but
 * their consequences (e.g: approval, operator approval, profile creation, etc) remain in the hub.
 */
library MetaTxLib {
    // We store constants equal to the storage slots here to later access via inline
    // assembly without needing to pass storage pointers. The NAME_SLOT_GT_31 slot
    // is equivalent to keccak256(NAME_SLOT) and is where the name string is stored
    // if the length is greater than 31 bytes.
    uint256 internal constant NAME_SLOT = 0;
    uint256 internal constant TOKEN_DATA_MAPPING_SLOT = 2;
    uint256 internal constant SIG_NONCES_MAPPING_SLOT = 10;
    uint256 internal constant NAME_SLOT_GT_31 =
        0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;

    // We also store typehashes here
    bytes32 internal constant EIP712_REVISION_HASH = keccak256('1');
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');
    bytes32 internal constant PERMIT_FOR_ALL_TYPEHASH =
        keccak256(
            'PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant BURN_WITH_SIG_TYPEHASH =
        keccak256('BurnWithSig(uint256 tokenId,uint256 nonce,uint256 deadline)');
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        );
    bytes32 internal constant SET_DEFAULT_PROFILE_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDefaultProfileWithSig(address wallet,uint256 profileId,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_FOLLOW_MODULE_WITH_SIG_TYPEHASH =
        keccak256(
            'SetFollowModuleWithSig(uint256 profileId,address followModule,bytes followModuleInitData,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_FOLLOW_NFT_URI_WITH_SIG_TYPEHASH =
        keccak256(
            'SetFollowNFTURIWithSig(uint256 profileId,string followNFTURI,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_DISPATCHER_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDispatcherWithSig(uint256 profileId,address dispatcher,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_PROFILE_IMAGE_URI_WITH_SIG_TYPEHASH =
        keccak256(
            'SetProfileImageURIWithSig(uint256 profileId,string imageURI,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant POST_WITH_SIG_TYPEHASH =
        keccak256(
            'PostWithSig(uint256 profileId,string contentURI,address collectModule,bytes collectModuleInitData,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant COMMENT_WITH_SIG_TYPEHASH =
        keccak256(
            'CommentWithSig(uint256 profileId,string contentURI,uint256 profileIdPointed,uint256 pubIdPointed,bytes referenceModuleData,address collectModule,bytes collectModuleInitData,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant MIRROR_WITH_SIG_TYPEHASH =
        keccak256(
            'MirrorWithSig(uint256 profileId,uint256 profileIdPointed,uint256 pubIdPointed,bytes referenceModuleData,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant FOLLOW_WITH_SIG_TYPEHASH =
        keccak256(
            'FollowWithSig(uint256[] profileIds,bytes[] datas,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant COLLECT_WITH_SIG_TYPEHASH =
        keccak256(
            'CollectWithSig(uint256 profileId,uint256 pubId,bytes data,uint256 nonce,uint256 deadline)'
        );

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
    ) external {
        if (spender == address(0)) revert Errors.ZeroSpender();
        address owner = _ownerOf(tokenId);
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(PERMIT_TYPEHASH, spender, tokenId, _sigNonces(owner), sig.deadline)
                )
            ),
            owner,
            sig
        );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the `permitForAll()`
     * function.
     *
     * @param owner The owner to approve the operator for, this is the signer.
     * @param operator The operator to approve for the owner.
     * @param approved Whether or not the operator should be approved.
     * @param sig the EIP712Signature struct containing the token owner's signature.
     */
    function basePermitForAll(
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external {
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
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `setDefaultProfileWithSig()` function.
     *
     * @param vars the SetDefaultProfileWithSigData struct containing the relevant parameters.
     */
    function baseSetDefaultProfileWithSig(DataTypes.SetDefaultProfileWithSigData calldata vars)
        external
    {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        SET_DEFAULT_PROFILE_WITH_SIG_TYPEHASH,
                        vars.wallet,
                        vars.profileId,
                        _sigNonces(vars.wallet),
                        vars.sig.deadline
                    )
                )
            ),
            vars.wallet,
            vars.sig
        );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `setFollowModuleWithSig()` function.
     *
     * @param vars the SetFollowModuleWithSigData struct containing the relevant parameters.
     */
    function baseSetFollowModuleWithSig(DataTypes.SetFollowModuleWithSigData calldata vars)
        external
    {
        address owner = _ownerOf(vars.profileId);
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        SET_FOLLOW_MODULE_WITH_SIG_TYPEHASH,
                        vars.profileId,
                        vars.followModule,
                        keccak256(vars.followModuleInitData),
                        _sigNonces(owner),
                        vars.sig.deadline
                    )
                )
            ),
            owner,
            vars.sig
        );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `setDispatcherWithSig()` function.
     *
     * @param vars the setDispatcherWithSigData struct containing the relevant parameters.
     */
    function baseSetDispatcherWithSig(DataTypes.SetDispatcherWithSigData calldata vars) external {
        address owner = _ownerOf(vars.profileId);
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        SET_DISPATCHER_WITH_SIG_TYPEHASH,
                        vars.profileId,
                        vars.dispatcher,
                        _sigNonces(owner),
                        vars.sig.deadline
                    )
                )
            ),
            owner,
            vars.sig
        );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `setProfileImageURIWithSig()` function.
     *
     * @param vars the SetProfileImageURIWithSigData struct containing the relevant parameters.
     */
    function baseSetProfileImageURIWithSig(DataTypes.SetProfileImageURIWithSigData calldata vars)
        external
    {
        address owner = _ownerOf(vars.profileId);
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        SET_PROFILE_IMAGE_URI_WITH_SIG_TYPEHASH,
                        vars.profileId,
                        keccak256(bytes(vars.imageURI)),
                        _sigNonces(owner),
                        vars.sig.deadline
                    )
                )
            ),
            owner,
            vars.sig
        );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `setFollowNFTURIWithSig()` function.
     *
     * @param vars the SetFollowNFTURIWithSigData struct containing the relevant parameters.
     */
    function baseSetFollowNFTURIWithSig(DataTypes.SetFollowNFTURIWithSigData calldata vars)
        external
    {
        address owner = _ownerOf(vars.profileId);
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        SET_FOLLOW_NFT_URI_WITH_SIG_TYPEHASH,
                        vars.profileId,
                        keccak256(bytes(vars.followNFTURI)),
                        _sigNonces(owner),
                        vars.sig.deadline
                    )
                )
            ),
            owner,
            vars.sig
        );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `postWithSig()` function.
     *
     * @param vars the PostWithSigData struct containing the relevant parameters.
     */
    function basePostWithSig(DataTypes.PostWithSigData calldata vars) external {
        address owner = _ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            POST_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            keccak256(bytes(vars.contentURI)),
                            vars.collectModule,
                            keccak256(vars.collectModuleInitData),
                            vars.referenceModule,
                            keccak256(vars.referenceModuleInitData),
                            _sigNonces(owner),
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `commentWithSig()` function.
     *
     * @param vars the CommentWithSig struct containing the relevant parameters.
     */
    function baseCommentWithSig(DataTypes.CommentWithSigData calldata vars) external {
        address owner = _ownerOf(vars.profileId);

        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        COMMENT_WITH_SIG_TYPEHASH,
                        vars.profileId,
                        keccak256(bytes(vars.contentURI)),
                        vars.profileIdPointed,
                        vars.pubIdPointed,
                        keccak256(vars.referenceModuleData),
                        vars.collectModule,
                        keccak256(vars.collectModuleInitData),
                        vars.referenceModule,
                        keccak256(vars.referenceModuleInitData),
                        _sigNonces(owner),
                        vars.sig.deadline
                    )
                )
            ),
            owner,
            vars.sig
        );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `mirrorWithSig()` function.
     *
     * @param vars the MirrorWithSigData struct containing the relevant parameters.
     */
    function baseMirrorWithSig(DataTypes.MirrorWithSigData calldata vars) external {
        address owner = _ownerOf(vars.profileId);
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        MIRROR_WITH_SIG_TYPEHASH,
                        vars.profileId,
                        vars.profileIdPointed,
                        vars.pubIdPointed,
                        keccak256(vars.referenceModuleData),
                        vars.referenceModule,
                        keccak256(vars.referenceModuleInitData),
                        _sigNonces(owner),
                        vars.sig.deadline
                    )
                )
            ),
            owner,
            vars.sig
        );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `burnWithSig()` function.
     *
     * @param tokenId The token ID to burn.
     * @param sig the EIP712Signature struct containing the token owner's signature.
     */
    function baseBurnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig) external {
        address owner = _ownerOf(tokenId);
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(BURN_WITH_SIG_TYPEHASH, tokenId, _sigNonces(owner), sig.deadline)
                )
            ),
            owner,
            sig
        );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `followWithSig()` function.
     *
     * @param vars the FollowWithSigData struct containing the relevant parameters.
     */
    function baseFollowWithSig(DataTypes.FollowWithSigData calldata vars) external {
        uint256 dataLength = vars.datas.length;
        bytes32[] memory dataHashes = new bytes32[](dataLength);
        for (uint256 i = 0; i < dataLength; ) {
            dataHashes[i] = keccak256(vars.datas[i]);
            unchecked {
                ++i;
            }
        }
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        FOLLOW_WITH_SIG_TYPEHASH,
                        keccak256(abi.encodePacked(vars.profileIds)),
                        keccak256(abi.encodePacked(dataHashes)),
                        _sigNonces(vars.follower),
                        vars.sig.deadline
                    )
                )
            ),
            vars.follower,
            vars.sig
        );
    }

    /**
     * @notice Validates parameters and increments the nonce for a given owner using the
     * `collectWithSig()` function.
     *
     * @param vars the CollectWithSigData struct containing the relevant parameters.
     */
    function baseCollectWithSig(DataTypes.CollectWithSigData calldata vars) external {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        COLLECT_WITH_SIG_TYPEHASH,
                        vars.profileId,
                        vars.pubId,
                        keccak256(vars.data),
                        _sigNonces(vars.collector),
                        vars.sig.deadline
                    )
                )
            ),
            vars.collector,
            vars.sig
        );
    }

    /**
     * @notice Returns the domain separator.
     * 
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32) {
        return _calculateDomainSeparator();
    }

    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        DataTypes.EIP712Signature calldata sig
    ) private view {
        if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        if (recoveredAddress == address(0) || recoveredAddress != expectedAddress)
            revert Errors.SignatureInvalid();
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() private view returns (bytes32) {
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

            // Determine if the length > 32 by checking the lowest order bit, meaning the string
            // itself is stored at keccak256(NAME_SLOT)
            switch and(slotLoad, 1)
            case 0 {
                // The name is in the same slot
                // Determine the size by dividing the last byte's value by 2
                let size := shr(1, and(slotLoad, 255))

                // Store the size in the first slot
                mstore(ptr, size)

                // Store the actual string in the second slot (without the size)
                mstore(add(ptr, 32), and(slotLoad, not(255)))

                // Store the new memory pointer in the free memory pointer slot
                mstore(64, add(add(ptr, 32), size))
            }
            case 1 {
                // The name is not in the same slot
                // Determine the size by dividing the value in the whole slot minus 1 by 2
                let size := shr(1, sub(slotLoad, 1))

                // Store the size in the first slot
                mstore(ptr, size)

                // Compute the total memory slots we need, this is (size + 31) / 32
                let totalMemorySlots := shr(5, add(size, 31))

                // Iterate through the words in memory and store the string word by word
                for {
                    let i := 0
                } lt(i, totalMemorySlots) {
                    i := add(i, 1)
                } {
                    mstore(add(add(ptr, 32), mul(32, i)), sload(add(NAME_SLOT_GT_31, i)))
                }

                // Store the new memory pointer in the free memory pointer slot
                mstore(64, add(add(ptr, 32), size))
            }
        }
        // Return a memory pointer to the name (which always starts with the size at the first slot)
        return ptr;
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
     * @dev This fetches the owner address for a given token ID. Note that this does not check
     * and revert upon receiving a zero address.
     *
     * However, this function is always followed by a call to `_validateRecoveredAddress()` with
     * the returned address from this function as the signer, and since `_validateRecoveredAddress()`
     * reverts upon recovering the zero address, the execution will always revert if the owner returned
     * is the zero address.
     */
    function _ownerOf(uint256 tokenId) private view returns (address) {
        // Note that this does *not* include a zero address check, but this is acceptable because
        // _validateRecoveredAddress reverts on recovering a zero address.
        address owner;
        assembly {
            mstore(0, tokenId)
            mstore(32, TOKEN_DATA_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            // this weird bit shift is necessary to remove the packing from the variable
            owner := shr(96, shl(96, sload(slot)))
        }
        return owner;
    }
}
