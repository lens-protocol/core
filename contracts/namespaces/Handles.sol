// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

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

contract Handles is ERC721, Ownable {
    address immutable LENS_HUB;

    mapping(uint256 handleId => uint256 profileId) handleToProfile;
    mapping(uint256 profileId => uint256 handleId) profileToHandle;

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

    // NOTE: We don't need whitelisting yet as we use immutable constants for the first version.
    constructor(address lensHub) ERC721('Lens Canonical Handles', '.lens') {
        LENS_HUB = lensHub;
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
}
