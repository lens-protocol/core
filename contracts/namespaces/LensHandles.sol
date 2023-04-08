// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {VersionedInitializable} from 'contracts/base/upgradeability/VersionedInitializable.sol';
import {ImmutableOwnable} from 'contracts/misc/ImmutableOwnable.sol';
import {ILensHandles} from 'contracts/interfaces/ILensHandles.sol';
import {HandlesEvents} from 'contracts/namespaces/constants/Events.sol';
import {HandlesErrors} from 'contracts/namespaces/constants/Errors.sol';

contract LensHandles is ILensHandles, ERC721, VersionedInitializable, ImmutableOwnable {
    // Constant for upgradeability purposes, see VersionedInitializable. Do not confuse it with the EIP-712 revision number.
    uint256 internal constant REVISION = 1;

    string constant NAMESPACE = 'lens';
    bytes32 constant NAMESPACE_HASH = keccak256(bytes(NAMESPACE));

    constructor(address owner, address lensHub) ERC721('', '') ImmutableOwnable(owner, lensHub) {}

    function name() public pure override returns (string memory) {
        return string.concat(symbol(), ' Handles');
    }

    function symbol() public pure override returns (string memory) {
        return string.concat('.', NAMESPACE);
    }

    function initialize() external initializer {}

    /// @inheritdoc ILensHandles
    function mintHandle(address to, string calldata localName) external onlyOwnerOrHub returns (uint256) {
        _validateLocalName(localName);
        bytes32 localNameHash = keccak256(bytes(localName));
        bytes32 handleHash = keccak256(abi.encodePacked(localNameHash, NAMESPACE_HASH));
        uint256 handleId = uint256(handleHash);
        _mint(to, handleId);
        emit HandlesEvents.HandleMinted(localName, NAMESPACE, handleId, to);
        return handleId;
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function getNamespace() external pure returns (string memory) {
        return NAMESPACE;
    }

    function getNamespaceHash() external pure returns (bytes32) {
        return NAMESPACE_HASH;
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

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
