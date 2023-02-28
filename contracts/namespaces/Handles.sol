// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {VersionedInitializable} from 'contracts/upgradeability/VersionedInitializable.sol';

struct Token {
    uint256 id;
    address collection;
}

contract Handles is ERC721, Ownable, VersionedInitializable {
    // Constant for upgradeability purposes, see VersionedInitializable. Do not confuse with EIP-712 revision number.
    uint256 internal constant REVISION = 1;

    address immutable LENS_HUB;
    bytes32 immutable NAMESPACE_HASH = keccak256('lens');

    // TODO: In future we might replace ProfileId with a struct that contains the tokenId and the collection
    // V1
    // mapping(uint256 handleId => uint256 profileId) handleToProfile;
    // mapping(uint256 profileId => uint256 handleId) profileToHandle;
    // TODO: In future we can add support for multiple handles per profile while still keeping the default handle above
    // mapping(uint256 profileId => mapping(uint256 handleId => bool linked)) profileToHandles;

    // NOTE: We don't need to construct/initialize ERC721 name/symbol as we use immutable constants for the first version.
    constructor(address lensHub, address owner) ERC721('', '') {
        LENS_HUB = lensHub;
        Ownable._transferOwnership(owner);
    }

    function name() public pure override returns (string memory) {
        return '.lens Handles';
    }

    function symbol() public pure override returns (string memory) {
        return '.lens';
    }

    function initialize(address owner) external initializer {
        Ownable._transferOwnership(owner);
    }

    function mintHandle(address to, string calldata handle) external onlyOwner returns (uint256) {
        bytes32 handleHash = keccak256(abi.encodePacked(handle, NAMESPACE_HASH));
        uint256 handleId = uint256(handleHash);
        _mint(to, handleId);
        return handleId;
    }

    //////////////////////////////////////
    ///        INTERNAL FUNCTIONS      ///
    //////////////////////////////////////

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
