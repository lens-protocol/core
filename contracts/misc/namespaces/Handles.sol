// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {VersionedInitializable} from 'contracts/base/upgradeability/VersionedInitializable.sol';

library Events {
    event HandleMinted(string handle, string namespace, uint256 handleId, address to);
}

// TODO list:
// 1. Code a contract that can batch-mint those handles
// 2. Code a contract that can batch-link handles to profiles

contract LensHandles is ERC721, Ownable, VersionedInitializable {
    // Constant for upgradeability purposes, see VersionedInitializable. Do not confuse with EIP-712 revision number.
    uint256 internal constant REVISION = 1;

    string constant NAMESPACE = 'lens';
    bytes32 constant NAMESPACE_HASH = keccak256(bytes(NAMESPACE));

    constructor(address owner) ERC721('', '') {
        Ownable._transferOwnership(owner);
    }

    function name() public pure override returns (string memory) {
        return string.concat(symbol(), ' Handles');
    }

    function symbol() public pure override returns (string memory) {
        return string.concat('.', NAMESPACE);
    }

    function initialize(address owner) external initializer {
        Ownable._transferOwnership(owner);
    }

    /**
     * @notice Mints a handle in the given namespace.
     * @notice A handle is composed by a local name and a namespace, separated by dot.
     * @notice Example: `john.lens` is a handle composed by the local name `john` and the namespace `lens`.
     *
     * @param to The address where the handle is being minted to.
     * @param localName The local name of the handle.
     */
    function mintHandle(address to, string calldata localName) external onlyOwner returns (uint256) {
        bytes32 localNameHash = keccak256(bytes(localName));
        bytes32 handleHash = keccak256(abi.encodePacked(localNameHash, NAMESPACE_HASH));
        uint256 handleId = uint256(handleHash);
        _mint(to, handleId);
        emit Events.HandleMinted(localName, NAMESPACE, handleId, to);
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

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
