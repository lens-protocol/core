// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';
import {ITokenHandleRegistry} from '../interfaces/ITokenHandleRegistry.sol';
import {RegistryTypes} from './constants/Types.sol';
import {Types} from '../libraries/constants/Types.sol';
import {Errors} from '../libraries/constants/Errors.sol';
import {RegistryErrors} from './constants/Errors.sol';
import {RegistryEvents} from './constants/Events.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';
import {ILensHandles} from '../interfaces/ILensHandles.sol';
import {Typehash} from './constants/Typehash.sol';

/**
 * @title TokenHandleRegistry
 * @author Lens Protocol
 * @notice This contract is used to link a token with a handle.
 * @custom:upgradeable Transparent upgradeable proxy without initializer.
 */
contract TokenHandleRegistry is ITokenHandleRegistry {
    string constant EIP712_DOMAIN_VERSION = '1';
    bytes32 constant EIP712_DOMAIN_VERSION_HASH = keccak256(bytes(EIP712_DOMAIN_VERSION));
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

    // First version of TokenHandleRegistry only works with Lens Profiles and .lens namespace.
    address immutable LENS_HUB;
    address immutable LENS_HANDLES;

    // Using _handleHash(Handle) and _tokenHash(Token) as keys given that structs cannot be used as them.
    mapping(bytes32 handle => RegistryTypes.Token token) handleToToken;
    mapping(bytes32 token => RegistryTypes.Handle handle) tokenToHandle;

    mapping(address signer => uint256 nonce) public nonces;

    constructor(address lensHub, address lensHandles) {
        LENS_HUB = lensHub;
        LENS_HANDLES = lensHandles;
    }

    // Lens V1 to Lens V2 migration function
    // WARNING: It is able to link the Token and Handle even if they're not in the same wallet.
    //          But it is designed to be only called from LensHub migration function, which assures that they are.
    function migrationLink(uint256 handleId, uint256 profileId) external {
        if (msg.sender != LENS_HUB) {
            revert RegistryErrors.OnlyLensHub();
        }
        _executeLinkage(
            RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId}),
            RegistryTypes.Token({collection: LENS_HUB, id: profileId}),
            address(0)
        );
    }

    /// @inheritdoc ITokenHandleRegistry
    function link(uint256 handleId, uint256 profileId) external {
        _link(handleId, profileId, msg.sender);
    }

    function linkWithSig(uint256 handleId, uint256 profileId, Types.EIP712Signature calldata signature) external {
        _validateLinkSignature(signature, handleId, profileId);
        _link(handleId, profileId, signature.signer);
    }

    function _link(uint256 handleId, uint256 profileId, address transactionExecutor) private {
        // Handle and profile must be owned by the same address.
        // Caller should be the owner of the profile or one of its approved delegated executors.
        address profileOwner = ILensHub(LENS_HUB).ownerOf(profileId);
        if (profileOwner != ILensHandles(LENS_HANDLES).ownerOf(handleId)) {
            revert RegistryErrors.HandleAndTokenNotInSameWallet();
        }
        if (
            transactionExecutor != profileOwner &&
            !ILensHub(LENS_HUB).isDelegatedExecutorApproved(profileId, transactionExecutor)
        ) {
            revert RegistryErrors.DoesNotHavePermissions();
        }
        _executeLinkage(
            RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId}),
            RegistryTypes.Token({collection: LENS_HUB, id: profileId}),
            transactionExecutor
        );
    }

    /// @notice This function is used to invalidate signatures by incrementing the nonce
    /// @param increment The amount to increment the nonce by
    function incrementNonce(uint8 increment) external {
        uint256 currentNonce = nonces[msg.sender];
        nonces[msg.sender] = currentNonce + increment;
        emit RegistryEvents.NonceUpdated(msg.sender, currentNonce + increment, block.timestamp);
    }

    function _validateLinkSignature(
        Types.EIP712Signature calldata signature,
        uint256 handleId,
        uint256 profileId
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.LINK,
                        handleId,
                        profileId,
                        _getNonceIncrementAndEmitEvent(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    function _validateUnlinkSignature(
        Types.EIP712Signature calldata signature,
        uint256 handleId,
        uint256 profileId
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.UNLINK,
                        handleId,
                        profileId,
                        _getNonceIncrementAndEmitEvent(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
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

    function calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    Typehash.EIP712_DOMAIN,
                    keccak256('TokenHandleRegistry'),
                    EIP712_DOMAIN_VERSION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    /// @inheritdoc ITokenHandleRegistry
    function unlink(uint256 handleId, uint256 profileId) external {
        _unlink(handleId, profileId, msg.sender);
    }

    function unlinkWithSig(uint256 handleId, uint256 profileId, Types.EIP712Signature calldata signature) external {
        _validateUnlinkSignature(signature, handleId, profileId);
        _unlink(handleId, profileId, signature.signer);
    }

    function _unlink(uint256 handleId, uint256 profileId, address transactionExecutor) private {
        if (handleId == 0 || profileId == 0) {
            revert RegistryErrors.DoesNotExist();
        }
        if (
            ILensHandles(LENS_HANDLES).exists(handleId) &&
            ILensHandles(LENS_HANDLES).ownerOf(handleId) != transactionExecutor &&
            ILensHub(LENS_HUB).exists(profileId) &&
            (ILensHub(LENS_HUB).ownerOf(profileId) != transactionExecutor &&
                !ILensHub(LENS_HUB).isDelegatedExecutorApproved(profileId, transactionExecutor))
        ) {
            revert RegistryErrors.NotHandleNorTokenOwner();
        }
        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId});
        RegistryTypes.Token memory tokenPointedByHandle = handleToToken[_handleHash(handle)];
        // We check if the tokens are (were) linked for the case if some of them doesn't exist
        if (tokenPointedByHandle.id != profileId) {
            revert RegistryErrors.NotLinked();
        }
        _executeUnlinkage(handle, tokenPointedByHandle, transactionExecutor);
    }

    /// @inheritdoc ITokenHandleRegistry
    function resolve(uint256 handleId) external view returns (uint256) {
        if (!ILensHandles(LENS_HANDLES).exists(handleId)) {
            revert RegistryErrors.DoesNotExist();
        }
        uint256 resolvedTokenId = _resolveHandleToToken(RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId}))
            .id;
        if (resolvedTokenId == 0 || !ILensHub(LENS_HUB).exists(resolvedTokenId)) {
            return 0;
        }
        return resolvedTokenId;
    }

    /// @inheritdoc ITokenHandleRegistry
    function getDefaultHandle(uint256 profileId) external view returns (uint256) {
        if (!ILensHub(LENS_HUB).exists(profileId)) {
            revert RegistryErrors.DoesNotExist();
        }
        uint256 defaultHandleId = _resolveTokenToHandle(RegistryTypes.Token({collection: LENS_HUB, id: profileId})).id;
        if (defaultHandleId == 0 || !ILensHandles(LENS_HANDLES).exists(defaultHandleId)) {
            return 0;
        }
        return defaultHandleId;
    }

    //////////////////////////////////////
    ///        INTERNAL FUNCTIONS      ///
    //////////////////////////////////////

    function _resolveHandleToToken(
        RegistryTypes.Handle memory handle
    ) internal view returns (RegistryTypes.Token storage) {
        return handleToToken[_handleHash(handle)];
    }

    function _resolveTokenToHandle(
        RegistryTypes.Token memory token
    ) internal view returns (RegistryTypes.Handle storage) {
        return tokenToHandle[_tokenHash(token)];
    }

    function _executeLinkage(
        RegistryTypes.Handle memory handle,
        RegistryTypes.Token memory token,
        address transactionExecutor
    ) internal {
        _deleteTokenToHandleLinkageIfAny(handle, transactionExecutor);
        handleToToken[_handleHash(handle)] = token;

        _deleteHandleToTokenLinkageIfAny(token, transactionExecutor);
        tokenToHandle[_tokenHash(token)] = handle;

        emit RegistryEvents.HandleLinked(handle, token, transactionExecutor, block.timestamp);
    }

    function _deleteTokenToHandleLinkageIfAny(
        RegistryTypes.Handle memory handle,
        address transactionExecutor
    ) internal {
        RegistryTypes.Token memory tokenPointedByHandle = handleToToken[_handleHash(handle)];
        if (tokenPointedByHandle.collection != address(0) || tokenPointedByHandle.id != 0) {
            delete tokenToHandle[_tokenHash(tokenPointedByHandle)];
            emit RegistryEvents.HandleUnlinked(handle, tokenPointedByHandle, transactionExecutor, block.timestamp);
        }
    }

    function _deleteHandleToTokenLinkageIfAny(RegistryTypes.Token memory token, address transactionExecutor) internal {
        RegistryTypes.Handle memory handlePointedByToken = tokenToHandle[_tokenHash(token)];
        if (handlePointedByToken.collection != address(0) || handlePointedByToken.id != 0) {
            delete handleToToken[_handleHash(handlePointedByToken)];
            emit RegistryEvents.HandleUnlinked(handlePointedByToken, token, transactionExecutor, block.timestamp);
        }
    }

    function _executeUnlinkage(
        RegistryTypes.Handle memory handle,
        RegistryTypes.Token memory token,
        address transactionExecutor
    ) internal {
        delete handleToToken[_handleHash(handle)];
        // tokenToHandle is removed too, as the first version linkage is one-to-one.
        delete tokenToHandle[_tokenHash(token)];
        emit RegistryEvents.HandleUnlinked(handle, token, transactionExecutor, block.timestamp);
    }

    function _handleHash(RegistryTypes.Handle memory handle) internal pure returns (bytes32) {
        return keccak256(abi.encode(handle.collection, handle.id));
    }

    function _tokenHash(RegistryTypes.Token memory token) internal pure returns (bytes32) {
        return keccak256(abi.encode(token.collection, token.id));
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
            currentNonce = nonces[signer]++;
        }
        emit RegistryEvents.NonceUpdated(signer, currentNonce + 1, block.timestamp);
        return currentNonce;
    }
}
