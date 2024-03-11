// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILensImplGetters} from '../interfaces/ILensImplGetters.sol';

contract LensImplGetters is ILensImplGetters {
    address internal immutable FOLLOW_NFT_IMPL;
    address internal immutable __LEGACY__COLLECT_NFT_IMPL;
    address internal immutable MODULE_REGISTRY;

    constructor(address followNFTImpl, address collectNFTImpl, address moduleRegistry) {
        FOLLOW_NFT_IMPL = followNFTImpl;
        __LEGACY__COLLECT_NFT_IMPL = collectNFTImpl;
        MODULE_REGISTRY = moduleRegistry;
    }

    /// @inheritdoc ILensImplGetters
    function getFollowNFTImpl() external view override returns (address) {
        return FOLLOW_NFT_IMPL;
    }

    /// @inheritdoc ILensImplGetters
    function getLegacyCollectNFTImpl() external view override returns (address) {
        return __LEGACY__COLLECT_NFT_IMPL; // LEGACY support: Used only for compatibility with V1 collectible posts.
    }

    /// @inheritdoc ILensImplGetters
    function getModuleRegistry() external view override returns (address) {
        return MODULE_REGISTRY;
    }
}
