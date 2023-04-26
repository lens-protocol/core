// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ITokenHandleRegistry} from 'contracts/interfaces/ITokenHandleRegistry.sol';
import {RegistryTypes} from 'contracts/namespaces/constants/Types.sol';
import {RegistryErrors} from 'contracts/namespaces/constants/Errors.sol';
import {RegistryEvents} from 'contracts/namespaces/constants/Events.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {ILensHandles} from 'contracts/interfaces/ILensHandles.sol';

contract TokenHandleRegistry is ITokenHandleRegistry {
    address immutable LENS_HUB;
    address immutable LENS_HANDLES;

    /// 1to1 mapping for now. Can be replaced to support multiple handles per token if using mappings
    /// NOTE: Using bytes32 _handleHash(Handle) and _tokenHash(Token) as keys because solidity doesn't support structs as keys.
    mapping(bytes32 handle => RegistryTypes.Token token) handleToToken;
    mapping(bytes32 token => RegistryTypes.Handle handle) tokenToHandle;

    modifier onlyHandleOwner(uint256 handleId, address transactionExecutor) {
        if (IERC721(LENS_HANDLES).ownerOf(handleId) != transactionExecutor) {
            revert RegistryErrors.NotHandleOwner();
        }
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId, address transactionExecutor) {
        if (IERC721(LENS_HUB).ownerOf(tokenId) != transactionExecutor) {
            revert RegistryErrors.NotTokenOwner();
        }
        _;
    }

    modifier onlyHandleOrTokenOwner(
        uint256 handleId,
        uint256 tokenId,
        address transactionExecutor
    ) {
        // The transaction executor must be the owner of the handle or the token (or both).
        if (
            !(IERC721(LENS_HANDLES).ownerOf(handleId) == transactionExecutor ||
                IERC721(LENS_HUB).ownerOf(tokenId) == transactionExecutor)
        ) {
            revert RegistryErrors.NotHandleOrTokenOwner();
        }
        _;
    }

    // NOTE: We don't need whitelisting yet as we use immutable constants for the first version.
    constructor(address lensHub, address lensHandles) {
        LENS_HUB = lensHub;
        LENS_HANDLES = lensHandles;
    }

    // V1 --> V2 Migration function
    function migrationLinkHandleWithToken(uint256 handleId, uint256 tokenId) external {
        if (msg.sender != LENS_HUB) {
            revert RegistryErrors.OnlyLensHub();
        }
        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: LENS_HUB, id: tokenId});
        handleToToken[_handleHash(handle)] = token;
        tokenToHandle[_tokenHash(token)] = handle;
        emit RegistryEvents.HandleLinked(handle, token);
    }

    // NOTE: Simplified interfaces for the first iteration - Namespace and LensHub are constants
    /// @inheritdoc ITokenHandleRegistry
    function linkHandleWithToken(
        uint256 handleId,
        uint256 tokenId,
        bytes calldata /* data */
    ) external onlyTokenOwner(tokenId, msg.sender) onlyHandleOwner(handleId, msg.sender) {
        _linkHandleWithToken(
            RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId}),
            RegistryTypes.Token({collection: LENS_HUB, id: tokenId})
        );
    }

    // NOTE: Simplified interfaces for the first iteration - Namespace and LensHub are constants
    /// @inheritdoc ITokenHandleRegistry
    function unlinkHandleFromToken(
        uint256 handleId,
        uint256 tokenId
    ) external onlyHandleOrTokenOwner(handleId, tokenId, msg.sender) {
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: LENS_HUB, id: tokenId});
        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId});

        RegistryTypes.Token memory tokenThatHandlePointsTo = handleToToken[_handleHash(handle)];
        RegistryTypes.Handle memory handleThatTokenPointsTo = tokenToHandle[_tokenHash(token)];

        if (
            // We don't need to check this because we know that the token is from the LENS_HUB in this version
            // tokenThatHandlePointsTo.collection == token.collection &&
            tokenThatHandlePointsTo.id == token.id &&
            // We don't need to check this because we know that the handle is from the LENS_HANDLES in this version
            // handleThatTokenPointsTo.collection == handle.collection &&
            handleThatTokenPointsTo.id == handle.id
        ) {
            // They both point to each other
            _unlinkHandleFromToken(handle, token);
        } else {
            // They don't point to each other
            // So we have to check which one the transaction executor is the owner of (or both)
            if (msg.sender == IERC721(handle.collection).ownerOf(handle.id)) {
                // Handle owner is the transaction executor
                _unlinkHandleFromToken(handle, tokenThatHandlePointsTo);
            }

            if (msg.sender == IERC721(token.collection).ownerOf(token.id)) {
                // Token owner is the transaction executor
                _unlinkHandleFromToken(handleThatTokenPointsTo, token);
            }
        }
    }

    function unlinkIfBurnt(uint256 handleId, uint256 tokenId) external {
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: LENS_HUB, id: tokenId});
        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId});

        RegistryTypes.Token memory tokenThatHandlePointsTo = handleToToken[_handleHash(handle)];
        RegistryTypes.Handle memory handleThatTokenPointsTo = tokenToHandle[_tokenHash(token)];

        // First check that they both point to each other
        if (
            // We don't need to check this because we know that the token is from the LENS_HUB in this version
            // tokenThatHandlePointsTo.collection == token.collection &&
            tokenThatHandlePointsTo.id == token.id &&
            // We don't need to check this because we know that the handle is from the LENS_HANDLES in this version
            // handleThatTokenPointsTo.collection == handle.collection &&
            handleThatTokenPointsTo.id == handle.id &&
            (!ILensHub(LENS_HUB).exists(handleId) || !ILensHandles(LENS_HANDLES).exists(tokenId))
        ) {
            _unlinkHandleFromToken(handle, token);
        }
    }

    // NOTE: Simplified interfaces for the first iteration - Namespace and LensHub are constants
    /// @inheritdoc ITokenHandleRegistry
    function resolveHandle(uint256 handleId) external view returns (uint256) {
        uint256 resolvedHandleId = _resolveHandle(RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId})).id;
        if (!ILensHandles(LENS_HANDLES).exists(resolvedHandleId)) {
            return 0; // Handle doesn't exist (was burned or never existed)
        }
        return resolvedHandleId;
    }

    // NOTE: Simplified interfaces for the first iteration - Namespace and LensHub are constants
    /// @inheritdoc ITokenHandleRegistry
    function resolveToken(uint256 tokenId) external view returns (uint256) {
        uint256 resolvedTokenId = _resolveToken(RegistryTypes.Token({collection: LENS_HUB, id: tokenId})).id;
        if (!ILensHub(LENS_HUB).exists(resolvedTokenId)) {
            return 0; // Token doesn't exist (was burned or never existed)
        }
        return resolvedTokenId;
    }

    //////////////////////////////////////
    ///        INTERNAL FUNCTIONS      ///
    //////////////////////////////////////

    function _resolveHandle(RegistryTypes.Handle memory handle) internal view returns (RegistryTypes.Token storage) {
        return handleToToken[_handleHash(handle)];
    }

    function _resolveToken(RegistryTypes.Token memory token) internal view returns (RegistryTypes.Handle storage) {
        return tokenToHandle[_tokenHash(token)];
    }

    function _linkHandleWithToken(RegistryTypes.Handle memory handle, RegistryTypes.Token memory token) internal {
        _unlinkIfAlreadyLinked(handle, token);
        handleToToken[_handleHash(handle)] = token;
        tokenToHandle[_tokenHash(token)] = handle;
        emit RegistryEvents.HandleLinked(handle, token);
    }

    function _unlinkIfAlreadyLinked(RegistryTypes.Handle memory handle, RegistryTypes.Token memory token) internal {
        RegistryTypes.Token memory tokenThatHandlePointsTo = handleToToken[_handleHash(handle)];
        RegistryTypes.Handle memory handleThatTokenPointsTo = tokenToHandle[_tokenHash(token)];

        if (tokenThatHandlePointsTo.collection != address(0) || tokenThatHandlePointsTo.id != 0) {
            delete tokenToHandle[_tokenHash(tokenThatHandlePointsTo)];
        }
        if (handleThatTokenPointsTo.collection != address(0) || handleThatTokenPointsTo.id != 0) {
            delete handleToToken[_handleHash(handleThatTokenPointsTo)];
        }
    }

    function _unlinkHandleFromToken(RegistryTypes.Handle memory handle, RegistryTypes.Token memory token) internal {
        delete handleToToken[_handleHash(handle)];
        delete tokenToHandle[_tokenHash(token)];
        emit RegistryEvents.HandleUnlinked(handle, token);
    }

    // Utility functions for mappings

    function _handleHash(RegistryTypes.Handle memory handle) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(handle.collection, handle.id));
    }

    function _tokenHash(RegistryTypes.Token memory token) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(token.collection, token.id));
    }
}
