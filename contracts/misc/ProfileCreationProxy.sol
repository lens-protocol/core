// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {LensV2Migration} from 'contracts/misc/LensV2Migration.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {ImmutableOwnable} from 'contracts/misc/ImmutableOwnable.sol';

import {ILensHandles} from 'contracts/interfaces/ILensHandles.sol';
import {ITokenHandleRegistry} from 'contracts/interfaces/ITokenHandleRegistry.sol';

/**
 * @title ProfileCreationProxy
 * @author Lens Protocol
 *
 * @notice This is an ownable proxy contract that enforces ".lens" handle suffixes at profile creation.
 * Only the owner can create profiles.
 */
contract ProfileCreationProxy is ImmutableOwnable {
    ILensHandles immutable LENS_HANDLES;
    ITokenHandleRegistry immutable TOKEN_HANDLE_REGISTRY;

    error ProfileAlreadyExists();

    constructor(
        address owner,
        address hub,
        address lensHandles,
        address tokenHandleRegistry
    ) ImmutableOwnable(owner, hub) {
        LENS_HANDLES = ILensHandles(lensHandles);
        TOKEN_HANDLE_REGISTRY = ITokenHandleRegistry(tokenHandleRegistry);
    }

    function proxyCreateProfile(
        Types.CreateProfileParams calldata createProfileParams
    ) external onlyOwner returns (uint256) {
        return ILensHub(LENS_HUB).createProfile(createProfileParams);
    }

    function proxyCreateProfileWithHandle(
        Types.CreateProfileParams memory createProfileParams,
        string calldata handle
    ) external onlyOwner returns (uint256, uint256) {
        // Check if LensHubV1 already has a profile with this handle that was not migrated yet:
        bytes32 handleHash = keccak256(bytes(string.concat(handle, '.lens')));
        if (LensV2Migration(LENS_HUB).getProfileIdByHandleHash(handleHash) != 0) {
            revert ProfileAlreadyExists(); // TODO: Should we move this to some Errors library? so we can test it easier
        }

        // We mint the handle & profile to this contract first, then link it to the profile
        // This will not allow to initialize follow modules that require funds from the msg.sender,
        // but we assume only simple follow modules should be set during profile creation.
        // Complex ones can be set after the profile is created.
        address destination = createProfileParams.to;
        createProfileParams.to = address(this);
        uint256 profileId = ILensHub(LENS_HUB).createProfile(createProfileParams);
        uint256 handleId = LENS_HANDLES.mintHandle(address(this), handle);

        TOKEN_HANDLE_REGISTRY.link({handleId: handleId, tokenId: profileId});

        // Transfer the handle & profile to the destination
        LENS_HANDLES.transferFrom(address(this), destination, handleId);
        ILensHub(LENS_HUB).transferFrom(address(this), destination, profileId);

        return (profileId, handleId);
    }

    function proxyCreateHandle(address to, string calldata handle) external onlyOwner returns (uint256) {
        return LENS_HANDLES.mintHandle(to, handle);
    }
}

/*
    APPROACH #1: Fork LensV1 from existing chain, deploy LensV2, upgrade, and test the migrations
    - It's not clean, controllable by us, unless we create new profiles in V1 and new follows (non deterministic)
    APPROACH #2: Deploy LensV1, add some profiles (then some follows too), deploy LensV2, upgrade, and test the migrations
    - We need a repo of V1 (which we already import)

    in TestSetup setup() we need:
    - if fork: we get Lens V1 addresses
    - if not fork: we deploy Lens V1 addresses



    ONE APPROACH:
        onV2 modifier:
        - do an upgrade from Lens V1 to V2

        without onV2 modifier we test on V1:
        - Upgrade (we try to upgrade V1 -> V2 in test)
        - Migrations (we do what we need on V1, and then upgrade to V2)

    ANOTHER APPROACH:
        BaseTest function upgradeToV2():
        - will upgrade the V1 contracts to V2 whenever we need
*/
