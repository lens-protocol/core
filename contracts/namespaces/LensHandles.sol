// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ImmutableOwnable} from 'contracts/misc/ImmutableOwnable.sol';
import {ILensHandles} from 'contracts/interfaces/ILensHandles.sol';
import {HandlesEvents} from 'contracts/namespaces/constants/Events.sol';
import {HandlesErrors} from 'contracts/namespaces/constants/Errors.sol';
import {HandleTokenURILib} from 'contracts/libraries/token-uris/HandleTokenURILib.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';

contract LensHandles is ILensHandles, ERC721, ImmutableOwnable {
    string constant NAMESPACE = 'lens';
    bytes32 constant NAMESPACE_HASH = keccak256(bytes(NAMESPACE));

    modifier onlyOwnerOrWhitelistedProfileCreator() {
        if (msg.sender != OWNER && !ILensHub(LENS_HUB).isProfileCreatorWhitelisted(msg.sender)) {
            revert HandlesErrors.NotOwnerNorWhitelisted();
        }
        _;
    }

    mapping(uint256 tokenId => string localName) public handles;

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
        return HandleTokenURILib.getTokenURI(tokenId, handles[tokenId]);
    }

    /// @inheritdoc ILensHandles
    function mintHandle(
        address to,
        string calldata localName
    ) external onlyOwnerOrWhitelistedProfileCreator returns (uint256) {
        _validateLocalName(localName);
        bytes32 localNameHash = keccak256(bytes(localName));
        bytes32 handleHash = keccak256(abi.encodePacked(localNameHash, NAMESPACE_HASH));
        uint256 handleId = uint256(handleHash);
        _mint(to, handleId);
        handles[handleId] = localName;
        emit HandlesEvents.HandleMinted(localName, NAMESPACE, handleId, to);
        return handleId;
    }

    function burn(uint256 tokenId) external {
        if (msg.sender != ownerOf(tokenId)) {
            revert HandlesErrors.NotOwner();
        }
        _burn(tokenId);
    }

    function getNamespace() external pure returns (string memory) {
        return NAMESPACE;
    }

    function getNamespaceHash() external pure returns (bytes32) {
        return NAMESPACE_HASH;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    //////////////////////////////////////
    ///        INTERNAL FUNCTIONS      ///
    //////////////////////////////////////

    function _validateLocalName(string memory handle) internal pure {
        uint256 handleLength = bytes(handle).length;
        if (handleLength == 0) {
            revert HandlesErrors.HandleLengthInvalid();
        }

        bytes1 firstByte = bytes(handle)[0];
        if (firstByte == '-' || firstByte == '_') {
            revert HandlesErrors.HandleFirstCharInvalid();
        }

        uint256 i;
        while (i < handleLength) {
            if (bytes(handle)[i] == '.') {
                revert HandlesErrors.HandleContainsInvalidCharacters();
            }
            unchecked {
                ++i;
            }
        }
    }
}
