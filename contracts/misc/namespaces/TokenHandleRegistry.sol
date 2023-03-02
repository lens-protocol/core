// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {VersionedInitializable} from 'contracts/base/upgradeability/VersionedInitializable.sol';

// TODO: Move to Errors file
library Errors {
    error NotHandleOwner();
    error NotTokenOwner();
    error NotHandleOrTokenOwner();
}

// TODO: Move to Types file
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

// TODO: Move to Events file
library Events {
    event HandleLinked(Handle handle, Token token);
    event HandleUnlinked(Handle handle, Token token);
}

/// This contract just links two tokens together:
///     handle.lens <-> Lens Profile #1
///     qwer.punk <-> Lens Profile #2
///     myname.lens <-> Cryptopunk #69
///     vitalik.eth <-> BAYC #234
contract TokenHandleRegistry is VersionedInitializable {
    // Constant for upgradeability purposes, see VersionedInitializable. Do not confuse with EIP-712 revision number.
    uint256 internal constant REVISION = 1;

    address immutable LENS_HUB;
    address immutable LENS_HANDLES;

    // Migration constants
    address immutable migrator;

    /// 1to1 mapping for now, can be replaced to support multiple handles per token if using mappings
    /// NOTE: Using bytes32 _handleHash(Handle) and _tokenHash(Token) as keys because solidity doesn't support structs as keys.
    mapping(bytes32 handle => Token token) handleToToken;
    mapping(bytes32 token => Handle handle) tokenToHandle;

    modifier onlyHandleOwner(Handle memory handle, address transactionExecutor) {
        if (IERC721(handle.collection).ownerOf(handle.id) != transactionExecutor) {
            revert Errors.NotHandleOwner();
        }
        _;
    }

    modifier onlyTokenOwner(Token memory token, address transactionExecutor) {
        if (IERC721(token.collection).ownerOf(token.id) != transactionExecutor) {
            revert Errors.NotTokenOwner();
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
            revert Errors.NotHandleOrTokenOwner();
        }
        _;
    }

    // NOTE: We don't need whitelisting yet as we use immutable constants for the first version.
    constructor(address lensHub, address lensHandles, address migratorAddress) {
        LENS_HUB = lensHub;
        LENS_HANDLES = lensHandles;
        migrator = migratorAddress;
    }

    function initialize() external initializer {}

    // V1->V2 Migration function
    function migrationLinkHandleWithToken(uint256 handleId, uint256 tokenId) external {
        require(msg.sender == migrator, 'Only migrator');
        Handle memory handle = Handle({collection: LENS_HANDLES, id: handleId});
        Token memory token = Token({collection: LENS_HUB, id: tokenId});
        handleToToken[_handleHash(handle)] = token;
        tokenToHandle[_tokenHash(token)] = handle;
        emit Events.HandleLinked(handle, token);
    }

    // NOTE: Simplified interfaces for the first version - Namespace and LensHub are constants
    // TODO: Custom logic for linking/unlinking handles and tokens (modules, with bytes passed)
    function linkHandleWithToken(uint256 handleId, uint256 tokenId) external {
        _linkHandleWithToken(
            Handle({collection: LENS_HANDLES, id: handleId}),
            Token({collection: LENS_HUB, id: tokenId})
        );
    }

    function unlinkHandleFromToken(uint256 handleId, uint256 tokenId) external {
        _unlinkHandleFromToken(
            Handle({collection: LENS_HANDLES, id: handleId}),
            Token({collection: LENS_HUB, id: tokenId})
        );
    }

    // TODO: Think of better name?
    // handleToToken(handleId)?
    // resolveTokenByHandle(handleId)?
    function resolveHandle(uint256 handleId) external view returns (uint256) {
        return _resolveHandle(Handle({collection: LENS_HANDLES, id: handleId})).id;
    }

    // TODO: Same here - think of better name?
    // tokenToHandle(tokenId)?
    // resolveHandleByToken(tokenId)?
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
        handleToToken[_handleHash(handle)] = token;
        tokenToHandle[_tokenHash(token)] = handle;
        emit Events.HandleLinked(handle, token);
    }

    function _unlinkHandleFromToken(
        Handle memory handle,
        Token memory token
    ) internal onlyHandleOrTokenOwner(handle, token, msg.sender) {
        delete handleToToken[_handleHash(handle)];
        delete tokenToHandle[_tokenHash(token)];
        emit Events.HandleUnlinked(handle, token);
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
