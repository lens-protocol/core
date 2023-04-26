// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ITokenHandleRegistry} from 'contracts/interfaces/ITokenHandleRegistry.sol';
import {RegistryTypes} from 'contracts/namespaces/constants/Types.sol';
import {RegistryErrors} from 'contracts/namespaces/constants/Errors.sol';
import {RegistryEvents} from 'contracts/namespaces/constants/Events.sol';

contract TokenHandleRegistry is ITokenHandleRegistry {
    address immutable LENS_HUB;
    address immutable LENS_HANDLES;

    /// 1to1 mapping for now. Can be replaced to support multiple handles per token if using mappings
    /// NOTE: Using bytes32 _handleHash(Handle) and _tokenHash(Token) as keys because solidity doesn't support structs as keys.
    mapping(bytes32 handle => RegistryTypes.Token token) handleToToken;
    mapping(bytes32 token => RegistryTypes.Handle handle) tokenToHandle;

    modifier onlyHandleOwner(RegistryTypes.Handle memory handle, address transactionExecutor) {
        if (IERC721(handle.collection).ownerOf(handle.id) != transactionExecutor) {
            revert RegistryErrors.NotHandleOwner();
        }
        _;
    }

    modifier onlyTokenOwner(RegistryTypes.Token memory token, address transactionExecutor) {
        if (IERC721(token.collection).ownerOf(token.id) != transactionExecutor) {
            revert RegistryErrors.NotTokenOwner();
        }
        _;
    }

    modifier onlyHandleOrTokenOwner(
        RegistryTypes.Handle memory handle,
        RegistryTypes.Token memory token,
        address transactionExecutor
    ) {
        // The transaction executor must be the owner of the handle or the token (or both).
        if (
            !(IERC721(handle.collection).ownerOf(handle.id) == transactionExecutor ||
                IERC721(token.collection).ownerOf(token.id) == transactionExecutor)
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
    function linkHandleWithToken(uint256 handleId, uint256 tokenId, bytes calldata /* data */) external {
        _linkHandleWithToken(
            RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId}),
            RegistryTypes.Token({collection: LENS_HUB, id: tokenId})
        );
    }

    // NOTE: Simplified interfaces for the first iteration - Namespace and LensHub are constants
    /// @inheritdoc ITokenHandleRegistry
    function unlinkHandleFromToken(uint256 handleId, uint256 tokenId) external {
        _unlinkHandleFromToken(
            RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId}),
            RegistryTypes.Token({collection: LENS_HUB, id: tokenId})
        );
    }

    // NOTE: Simplified interfaces for the first iteration - Namespace and LensHub are constants
    /// @inheritdoc ITokenHandleRegistry
    function resolveHandle(uint256 handleId) external view returns (uint256) {
        return _resolveHandle(RegistryTypes.Handle({collection: LENS_HANDLES, id: handleId})).id;
    }

    // NOTE: Simplified interfaces for the first iteration - Namespace and LensHub are constants
    /// @inheritdoc ITokenHandleRegistry
    function resolveToken(uint256 tokenId) external view returns (uint256) {
        return _resolveToken(RegistryTypes.Token({collection: LENS_HUB, id: tokenId})).id;
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

    function _linkHandleWithToken(
        RegistryTypes.Handle memory handle,
        RegistryTypes.Token memory token
    ) internal onlyTokenOwner(token, msg.sender) onlyHandleOwner(handle, msg.sender) {
        _unlinkIfAlreadyLinked(handle, token);
        handleToToken[_handleHash(handle)] = token;
        tokenToHandle[_tokenHash(token)] = handle;
        emit RegistryEvents.HandleLinked(handle, token);
    }

    function _unlinkIfAlreadyLinked(RegistryTypes.Handle memory handle, RegistryTypes.Token memory token) internal {
        RegistryTypes.Token memory currentToken = handleToToken[_handleHash(handle)];
        RegistryTypes.Handle memory currentHandle = tokenToHandle[_tokenHash(token)];
        if (currentToken.collection != address(0) || currentToken.id != 0) {
            delete tokenToHandle[_tokenHash(currentToken)];
        }
        if (currentHandle.collection != address(0) || currentHandle.id != 0) {
            delete handleToToken[_handleHash(currentHandle)];
        }
    }

    function _unlinkHandleFromToken(
        RegistryTypes.Handle memory handle,
        RegistryTypes.Token memory token
    ) internal onlyHandleOrTokenOwner(handle, token, msg.sender) {
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
