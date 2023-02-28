// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

// TODO: Move to a Errors file

library Errors {
    error NotHandleOwner();
    error NotProfileOwner();
    error NotHandleOrProfileOwner();
}

struct ProfileToken {
    uint256 id; // SLOT1
    address collection; // SLOT2 - end
    uint96 _gap; // SLOT2 - start
}

struct Namespace {
    uint256 id; // SLOT1
    address collection; // SLOT2 - end
    uint96 _gap; // SLOT2 - start
}

// TODO: Move to a Events file
library Events {
    event HandleLinked(Handle handle, Profile profile);
    event HandleUnlinked(Handle handle, Profile profile);
}

// TODO: Make upgradeable?
contract NamespaceRegistry {
    address immutable LENS_HUB;
    address immutable NAMESPACE;

    /// 1to1 mapping for now, can be replaced to support multiple handles per profile if using mappings
    /// NOTE: Using bytes32 _handleHash(Handle) and _profileHash(Profile) as keys because solidity doesn't support structs as keys.
    mapping(bytes32 handle => Profile profile) handleToProfile;
    mapping(bytes32 profile => Handle handle) profileToHandle;

    modifier onlyHandleOwner(Handle memory handle, address transactionExecutor) {
        if (IERC721(handle.namespace).ownerOf(handle.handleId) != transactionExecutor) {
            revert Errors.NotHandleOwner();
        }
        _;
    }

    modifier onlyProfileOwner(Profile memory profile, address transactionExecutor) {
        if (IERC721(profile.lensHub).ownerOf(profile.profileId) != transactionExecutor) {
            revert Errors.NotProfileOwner();
        }
        _;
    }

    modifier onlyHandleOrProfileOwner(
        Handle memory handle,
        Profile memory profile,
        address transactionExecutor
    ) {
        // The transaction executor must be the owner of the handle or the profile (or both).
        if (
            !(IERC721(handle.namespace).ownerOf(handle.handleId) == transactionExecutor ||
                IERC721(profile.lensHub).ownerOf(profile.profileId) == transactionExecutor)
        ) {
            revert Errors.NotHandleOrProfileOwner();
        }
        _;
    }

    // NOTE: We don't need whitelisting yet as we use immutable constants for the first version.
    constructor(address lensHub, address namespace) {
        LENS_HUB = lensHub;
        NAMESPACE = namespace;
    }

    // NOTE: Simplified interfaces for the first version - Namespace and LensHub are constants
    // TODO: Custom logic for linking/unlinking handles and profiles (modules, with bytes passed)
    function linkHandleWithProfile(uint256 handleId, uint256 profileId) external {
        _linkHandleWithProfile(
            Handle({namespace: NAMESPACE, handleId: handleId}),
            Profile({lensHub: LENS_HUB, profileId: profileId})
        );
    }

    function unlinkHandleFromProfile(uint256 handleId, uint256 profileId) external {
        _unlinkHandleFromProfile(
            Handle({namespace: NAMESPACE, handleId: handleId}),
            Profile({lensHub: LENS_HUB, profileId: profileId})
        );
    }

    // TODO: Think of better name?
    // handleToProfile(handleId)?
    // resolveProfileByHandle(handleId)?
    function resolveProfile(uint256 handleId) external view returns (uint256) {
        return _resolveProfile(Handle({namespace: NAMESPACE, handleId: handleId})).profileId;
    }

    // TODO: Same here - think of better name?
    // profileToHandle(profileId)?
    // resolveHandleByProfile(profileId)?
    function resolveHandle(uint256 profileId) external view returns (uint256) {
        return _resolveHandle(Profile({lensHub: LENS_HUB, profileId: profileId})).handleId;
    }

    // Internal functions

    function _resolveProfile(Handle memory handle) internal view returns (Profile storage) {
        return handleToProfile[_handleHash(handle)];
    }

    function _resolveHandle(Profile memory profile) internal view returns (Handle storage) {
        return profileToHandle[_profileHash(profile)];
    }

    function _linkHandleWithProfile(
        Handle memory handle,
        Profile memory profile
    ) internal onlyProfileOwner(profile, msg.sender) onlyHandleOwner(handle, msg.sender) {
        handleToProfile[_handleHash(handle)] = profile;
        profileToHandle[_profileHash(profile)] = handle;
        emit Events.HandleLinked(handle, profile);
    }

    function _unlinkHandleFromProfile(
        Handle memory handle,
        Profile memory profile
    ) internal onlyHandleOrProfileOwner(handle, profile, msg.sender) {
        delete handleToProfile[_handleHash(handle)];
        delete profileToHandle[_profileHash(profile)];
        emit Events.HandleUnlinked(handle, profile);
    }

    // Utility functions for mappings

    function _handleHash(Handle memory handle) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(handle.namespace, handle.handleId));
    }

    function _profileHash(Profile memory profile) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(profile.lensHub, profile.profileId));
    }
}
