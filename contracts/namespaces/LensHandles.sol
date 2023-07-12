// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ImmutableOwnable} from 'contracts/misc/ImmutableOwnable.sol';
import {ILensHandles} from 'contracts/interfaces/ILensHandles.sol';
import {HandlesEvents} from 'contracts/namespaces/constants/Events.sol';
import {HandlesErrors} from 'contracts/namespaces/constants/Errors.sol';
import {HandleTokenURILib} from 'contracts/libraries/token-uris/HandleTokenURILib.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';

/**
 * A handle is defined as a local name inside a namespace context. A handle is represented as the local name with its
 * namespace applied as a suffix, using the dot symbol as separator.
 *
 *      handle = ${localName}.${namespace}
 *
 * Handle and local name can be used interchangeably once you are in a context of a namespace, as it became redundant.
 *
 *      handle === ${localName} ; inside some namespace.
 */
contract LensHandles is ERC721, ImmutableOwnable, ILensHandles {
    uint256 internal constant MAX_HANDLE_LENGTH = 31;
    string internal constant NAMESPACE = 'lens';
    uint256 internal immutable NAMESPACE_LENGTH = bytes(NAMESPACE).length;
    uint256 internal constant SEPARATOR_LENGTH = 1; // bytes('.').length;
    bytes32 internal constant NAMESPACE_HASH = keccak256(bytes(NAMESPACE));

    modifier onlyOwnerOrWhitelistedProfileCreator() {
        if (
            msg.sender != OWNER && !ILensHub(LENS_HUB).isProfileCreatorWhitelisted(msg.sender)
        ) {
            revert HandlesErrors.NotOwnerNorWhitelisted();
        }
        _;
    }

    modifier onlyHub() {
        if (msg.sender != LENS_HUB) {
            revert HandlesErrors.NotHub();
        }
        _;
    }

    mapping(uint256 tokenId => string localName) internal _localNames;

    constructor(address owner, address lensHub) ERC721('', '') ImmutableOwnable(owner, lensHub) {}

    function name() public pure override returns (string memory) {
        return string.concat(symbol(), ' Handles');
    }

    function symbol() public pure override returns (string memory) {
        return string.concat('.', NAMESPACE);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return HandleTokenURILib.getTokenURI(tokenId, _localNames[tokenId]);
    }

    /// @inheritdoc ILensHandles
    function mintHandle(address to, string calldata localName)
        external
        onlyOwnerOrWhitelistedProfileCreator
        returns (uint256)
    {
        _validateLocalName(localName);
        return _mintHandle(to, localName);
    }

    function migrateHandle(address to, string calldata localName) external onlyHub returns (uint256) {
        _validateLocalNameMigration(localName);
        return _mintHandle(to, localName);
    }

    function burn(uint256 tokenId) external {
        if (msg.sender != ownerOf(tokenId)) {
            revert HandlesErrors.NotOwner();
        }
        _burn(tokenId);
        delete _localNames[tokenId];
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function getNamespace() external pure returns (string memory) {
        return NAMESPACE;
    }

    function getNamespaceHash() external pure returns (bytes32) {
        return NAMESPACE_HASH;
    }

    // TODO: Should we revert if it doesn't exist?
    function getLocalName(uint256 tokenId) public view returns (string memory) {
        string memory localName = _localNames[tokenId];
        if (bytes(localName).length == 0) {
            revert HandlesErrors.DoesNotExist();
        }
        return _localNames[tokenId];
    }

    // TODO: Should we revert if it doesn't exist?
    function getHandle(uint256 tokenId) public view returns (string memory) {
        string memory localName = getLocalName(tokenId);
        return string.concat(localName, '.', NAMESPACE);
    }

    function getTokenId(string memory localName) public pure returns (uint256) {
        return uint256(keccak256(bytes(localName)));
    }

    //////////////////////////////////////
    ///        INTERNAL FUNCTIONS      ///
    //////////////////////////////////////

    function _mintHandle(address to, string calldata localName) internal returns (uint256) {
        uint256 tokenId = getTokenId(localName);
        _mint(to, tokenId);
        _localNames[tokenId] = localName;
        emit HandlesEvents.HandleMinted(localName, NAMESPACE, tokenId, to, block.timestamp);
        return tokenId;
    }

    function _validateLocalNameMigration(string memory localName) internal view {
        bytes memory localNameAsBytes = bytes(localName);
        uint256 localNameLength = localNameAsBytes.length;

        if (localNameLength == 0 || localNameLength + SEPARATOR_LENGTH + NAMESPACE_LENGTH > MAX_HANDLE_LENGTH) {
            revert HandlesErrors.HandleLengthInvalid();
        }

        bytes1 firstByte = localNameAsBytes[0];
        if (firstByte == '-' || firstByte == '_') {
            revert HandlesErrors.HandleFirstCharInvalid();
        }

        uint256 i;
        while (i < localNameLength) {
            if (!_isAlphaNumeric(localNameAsBytes[i]) && localNameAsBytes[i] != '-' && localNameAsBytes[i] != '_') {
                revert HandlesErrors.HandleContainsInvalidCharacters();
            }
            unchecked {
                ++i;
            }
        }
    }

    function _validateLocalName(string memory localName) internal view {
        bytes memory localNameAsBytes = bytes(localName);
        uint256 localNameLength = localNameAsBytes.length;

        if (localNameLength == 0 || localNameLength + SEPARATOR_LENGTH + NAMESPACE_LENGTH > MAX_HANDLE_LENGTH) {
            revert HandlesErrors.HandleLengthInvalid();
        }

        if (localNameAsBytes[0] == '_') {
            revert HandlesErrors.HandleFirstCharInvalid();
        }

        uint256 i;
        while (i < localNameLength) {
            if (!_isAlphaNumeric(localNameAsBytes[i]) && localNameAsBytes[i] != '_') {
                revert HandlesErrors.HandleContainsInvalidCharacters();
            }
            unchecked {
                ++i;
            }
        }
    }

    function _isAlphaNumeric(bytes1 char) internal pure returns (bool) {
        return (char >= '0' && char <= '9') || (char >= 'a' && char <= 'z');
    }
}
