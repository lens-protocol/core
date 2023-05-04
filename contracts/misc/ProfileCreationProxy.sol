// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
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
        // We mint the handle & profile to this contract first, then link it to the profile
        address destination = createProfileParams.to;
        createProfileParams.to = address(this);
        uint256 profileId = ILensHub(LENS_HUB).createProfile(createProfileParams);
        uint256 handleId = LENS_HANDLES.mintHandle(address(this), handle);

        TOKEN_HANDLE_REGISTRY.linkHandleWithToken({handleId: handleId, tokenId: profileId, data: ''});

        // Transfer the handle & profile to the destination
        LENS_HANDLES.transferFrom(address(this), destination, handleId);
        ILensHub(LENS_HUB).transferFrom(address(this), destination, profileId);

        return (profileId, handleId);
    }

    function proxyCreateHandle(address to, string calldata handle) external onlyOwner returns (uint256) {
        return LENS_HANDLES.mintHandle(to, handle);
    }
}
