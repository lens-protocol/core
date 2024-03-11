// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILensHubEventHooks} from '../interfaces/ILensHubEventHooks.sol';
import {Errors} from '../libraries/constants/Errors.sol';
import {StorageLib} from '../libraries/StorageLib.sol';
import {Events} from '../libraries/constants/Events.sol';

abstract contract LensHubEventHooks is ILensHubEventHooks {
    /// @inheritdoc ILensHubEventHooks
    function emitUnfollowedEvent(
        uint256 unfollowerProfileId,
        uint256 idOfProfileUnfollowed,
        address transactionExecutor
    ) external override {
        address expectedFollowNFT = StorageLib.getProfile(idOfProfileUnfollowed).followNFT;
        if (msg.sender != expectedFollowNFT) {
            revert Errors.CallerNotFollowNFT();
        }
        emit Events.Unfollowed(unfollowerProfileId, idOfProfileUnfollowed, transactionExecutor, block.timestamp);
    }

    //////////////////////////////////////
    ///       DEPRECATED FUNCTIONS     ///
    //////////////////////////////////////

    // Deprecated in V2. Kept here just for backwards compatibility with Lens V1 Collect NFTs.
    function emitCollectNFTTransferEvent(
        uint256 profileId,
        uint256 pubId,
        uint256 collectNFTId,
        address from,
        address to
    ) external {
        address expectedCollectNFT = StorageLib.getPublication(profileId, pubId).__DEPRECATED__collectNFT;
        if (msg.sender != expectedCollectNFT) {
            revert Errors.CallerNotCollectNFT();
        }
        emit Events.CollectNFTTransferred(profileId, pubId, collectNFTId, from, to, block.timestamp);
    }
}
