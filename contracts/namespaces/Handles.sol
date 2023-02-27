// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {VersionedInitializable} from 'contracts/upgradeability/VersionedInitializable.sol';

// enum CollectionType {
//     LENS_V2_PROFILES = 0,
//     ERC721 = 1
// }

// TODO: Move to a Errors file
library Errors {
    error NotHandleOwner();
    error NotProfileOwner();
    error NotHandleOrProfileOwner();
}

// TODO: Move to a Events file
library Events {
    event HandleLinked(uint256 handleId, uint256 profileId);
    event HandleUnlinked(uint256 handleId, uint256 profileId);
}

// struct Token {
//     uint256 id;
//     address collection; // 0x0 = LensHub
//     // CollectionType collectionType;
//     uint8 storageVersion; // ?? dunno if needed but just an idea to distinguish
// }

contract Handles is ERC721, Ownable, VersionedInitializable {
    // Constant for upgradeability purposes, see VersionedInitializable. Do not confuse with EIP-712 revision number.
    uint256 internal constant REVISION = 1;

    address immutable LENS_HUB;
    bytes32 immutable NAMESPACE_HASH = keccak256('lens');

    // V3
    // mapping(uint256 handleId => bytes data) handleToData;
    // mapping(bytes32 dataHash => uint256 handleId) dataToHandle;

    // V2
    // mapping(uint256 handleId => Token token) handleToToken;
    // mapping(bytes32 tokenHash => uint256 handleId) tokenToHandle;

    // TODO: In future we might replace ProfileId with a struct that contains the tokenId and the collection
    // V1
    mapping(uint256 handleId => uint256 profileId) handleToProfile;
    mapping(uint256 profileId => uint256 handleId) profileToHandle;
    // TODO: In future we can add support for multiple handles per profile while still keeping the default handle above
    // mapping(uint256 profileId => mapping(uint256 handleId => bool linked)) profileToHandles;

    modifier onlyHandleOwner(uint256 handleId, address transactionExecutor) {
        if (ownerOf(handleId) != transactionExecutor) {
            revert Errors.NotHandleOwner();
        }
        _;
    }

    modifier onlyProfileOwner(uint256 profileId, address transactionExecutor) {
        if (IERC721(LENS_HUB).ownerOf(profileId) != transactionExecutor) {
            revert Errors.NotProfileOwner();
        }
        _;
    }

    modifier onlyHandleOrProfileOwner(
        uint256 handleId,
        uint256 profileId,
        address transactionExecutor
    ) {
        // The transaction executor must at least be the owner of either the handle or the profile.
        // Used for unlinking (so either the handle owner or the profile owner can unlink)
        if (ownerOf(handleId) != transactionExecutor && IERC721(LENS_HUB).ownerOf(profileId) != transactionExecutor) {
            revert Errors.NotHandleOrProfileOwner();
        }
        _;
    }

    // NOTE: We don't need to construct/initialize ERC721 name/symbol as we use immutable constants for the first version.
    constructor(address lensHub, address owner) ERC721('', '') {
        LENS_HUB = lensHub;
        Ownable._transferOwnership(owner);
    }

    function name() public pure override returns (string memory) {
        return '.lenbs Handles';
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

    function linkHandleWithProfile(
        uint256 handleId,
        uint256 profileId
    ) external onlyProfileOwner(profileId, msg.sender) onlyHandleOwner(handleId, msg.sender) {
        handleToProfile[handleId] = profileId;
        profileToHandle[profileId] = handleId;
        emit Events.HandleLinked(handleId, profileId);
    }

    function unlinkHandleFromProfile(
        uint256 handleId,
        uint256 profileId
    ) external onlyHandleOrProfileOwner(handleId, profileId, msg.sender) {
        delete handleToProfile[handleId];
        delete profileToHandle[profileId];
        emit Events.HandleUnlinked(handleId, profileId);
    }

    function resolveProfile(uint256 profileId) external view returns (uint256) {
        return profileToHandle[profileId];
    }

    function resolveHandle(uint256 handleId) external view returns (uint256) {
        return handleToProfile[handleId];
    }

    //////////////////////////////////////
    ///        INTERNAL FUNCTIONS      ///
    //////////////////////////////////////

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
