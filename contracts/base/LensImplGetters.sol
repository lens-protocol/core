// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILensImplGetters} from 'contracts/interfaces/ILensImplGetters.sol';

contract LensImplGetters is ILensImplGetters {
    address internal immutable FOLLOW_NFT_IMPL;
    address internal immutable COLLECT_NFT_IMPL;

    constructor(address followNFTImpl, address collectNFTImpl) {
        FOLLOW_NFT_IMPL = followNFTImpl;
        COLLECT_NFT_IMPL = collectNFTImpl;
    }

    /// @inheritdoc ILensImplGetters
    function getFollowNFTImpl() external view override returns (address) {
        return FOLLOW_NFT_IMPL;
    }

    /// @inheritdoc ILensImplGetters
    function getCollectNFTImpl() external view override returns (address) {
        return COLLECT_NFT_IMPL;
    }
}
