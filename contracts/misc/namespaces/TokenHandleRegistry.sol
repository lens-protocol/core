// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {VersionedInitializable} from 'contracts/base/upgradeability/VersionedInitializable.sol';
import {ITokenHandleRegistry} from 'contracts/interfaces/ITokenHandleRegistry.sol';

// TODO: Move to the Errors file
library RegistryErrors {
    error NotHandleOwner();
    error NotTokenOwner();
    error NotHandleOrTokenOwner();
    error OnlyLensHub();
}

// TODO: Move to the Types file
struct Token {
    uint256 id; // SLOT 0
    address collection; // SLOT 1 - end
    // uint96 _gap; // SLOT 1 - start
}

struct Handle {
    uint256 id; // SLOT 0
    address collection; // SLOT 1 - end
    // uint96 _gap; // SLOT 1 - start
}

// TODO: Move to the Events file
library RegistryEvents {
    event HandleLinked(Handle handle, Token token);
    event HandleUnlinked(Handle handle, Token token);
}

contract TokenHandleRegistry is ITokenHandleRegistry, VersionedInitializable {
    // Constant for upgradeability purposes, see VersionedInitializable. Do not confuse it with the EIP-712 revision number.
    uint256 internal constant REVISION = 1;

    address immutable LENS_HUB;
    address immutable LENS_HANDLES;

    /// 1to1 mapping for now. Can be replaced to support multiple handles per token if using mappings
    /// NOTE: Using bytes32 _handleHash(Handle) and _tokenHash(Token) as keys because solidity doesn't support structs as keys.
    mapping(bytes32 handle => Token token) handleToToken;
    mapping(bytes32 token => Handle handle) tokenToHandle;

    modifier onlyHandleOwner(Handle memory handle, address transactionExecutor) {
        if (IERC721(handle.collection).ownerOf(handle.id) != transactionExecutor) {
            revert RegistryErrors.NotHandleOwner();
        }
        _;
    }

    modifier onlyTokenOwner(Token memory token, address transactionExecutor) {
        if (IERC721(token.collection).ownerOf(token.id) != transactionExecutor) {
            revert RegistryErrors.NotTokenOwner();
        }
        _;
    }

    modifier onlyHandleOrTokenOwner(
        Handle memory handle,
        Token memory token,
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

    function initialize() external initializer {}

    // V1 --> V2 Migration function
    function migrationLinkHandleWithToken(uint256 handleId, uint256 tokenId) external {
        if (msg.sender != LENS_HUB) {
            revert RegistryErrors.OnlyLensHub();
        }
        Handle memory handle = Handle({collection: LENS_HANDLES, id: handleId});
        Token memory token = Token({collection: LENS_HUB, id: tokenId});
        handleToToken[_handleHash(handle)] = token;
        tokenToHandle[_tokenHash(token)] = handle;
        emit RegistryEvents.HandleLinked(handle, token);
    }

    // NOTE: Simplified interfaces for the first iteration - Namespace and LensHub are constants
    /// @inheritdoc ITokenHandleRegistry
    function linkHandleWithToken(uint256 handleId, uint256 tokenId, bytes calldata /* data */) external {
        _linkHandleWithToken(
            Handle({collection: LENS_HANDLES, id: handleId}),
            Token({collection: LENS_HUB, id: tokenId})
        );
    }

    // NOTE: Simplified interfaces for the first iteration - Namespace and LensHub are constants
    /// @inheritdoc ITokenHandleRegistry
    function unlinkHandleFromToken(uint256 handleId, uint256 tokenId) external {
        _unlinkHandleFromToken(
            Handle({collection: LENS_HANDLES, id: handleId}),
            Token({collection: LENS_HUB, id: tokenId})
        );
    }

    // NOTE: Simplified interfaces for the first iteration - Namespace and LensHub are constants
    /// @inheritdoc ITokenHandleRegistry
    function resolveHandle(uint256 handleId) external view returns (uint256) {
        return _resolveHandle(Handle({collection: LENS_HANDLES, id: handleId})).id;
    }

    // NOTE: Simplified interfaces for the first iteration - Namespace and LensHub are constants
    /// @inheritdoc ITokenHandleRegistry
    function resolveToken(uint256 tokenId) external view returns (uint256) {
        return _resolveToken(Token({collection: LENS_HUB, id: tokenId})).id;
    }

    //////////////////////////////////////
    ///        INTERNAL FUNCTIONS      ///
    //////////////////////////////////////

    function _resolveHandle(Handle memory handle) internal view returns (Token storage) {
        return handleToToken[_handleHash(handle)];
    }

    function _resolveToken(Token memory token) internal view returns (Handle storage) {
        return tokenToHandle[_tokenHash(token)];
    }

    function _linkHandleWithToken(
        Handle memory handle,
        Token memory token
    ) internal onlyTokenOwner(token, msg.sender) onlyHandleOwner(handle, msg.sender) {
        _unlinkIfAlreadyLinked(handle, token);
        handleToToken[_handleHash(handle)] = token;
        tokenToHandle[_tokenHash(token)] = handle;
        emit RegistryEvents.HandleLinked(handle, token);
    }

    function _unlinkIfAlreadyLinked(Handle memory handle, Token memory token) internal {
        Token memory currentToken = handleToToken[_handleHash(handle)];
        Handle memory currentHandle = tokenToHandle[_tokenHash(token)];
        if (currentToken.collection != address(0) || currentToken.id != 0) {
            delete tokenToHandle[_tokenHash(currentToken)];
        }
        if (currentHandle.collection != address(0) || currentHandle.id != 0) {
            delete handleToToken[_handleHash(currentHandle)];
        }
    }

    function _unlinkHandleFromToken(
        Handle memory handle,
        Token memory token
    ) internal onlyHandleOrTokenOwner(handle, token, msg.sender) {
        delete handleToToken[_handleHash(handle)];
        delete tokenToHandle[_tokenHash(token)];
        emit RegistryEvents.HandleUnlinked(handle, token);
    }

    // Utility functions for mappings

    function _handleHash(Handle memory handle) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(handle.collection, handle.id));
    }

    function _tokenHash(Token memory token) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(token.collection, token.id));
    }

    // VersionedInitializable

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
