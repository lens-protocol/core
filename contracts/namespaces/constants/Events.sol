// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {RegistryTypes} from './Types.sol';

library HandlesEvents {
    event HandleMinted(string handle, string namespace, uint256 handleId, address to, uint256 timestamp);

    /**
     * @dev Emitted when an address' Token Guardian state change is triggered.
     *
     * @param wallet The address whose Token Guardian state change is being triggered.
     * @param enabled True if the Token Guardian is being enabled, false if it is being disabled.
     * @param tokenGuardianDisablingTimestamp The UNIX timestamp when disabling the Token Guardian will take effect,
     * if disabling it. Zero if the protection is being enabled.
     * @param timestamp The UNIX timestamp of the change being triggered.
     */
    event TokenGuardianStateChanged(
        address indexed wallet,
        bool indexed enabled,
        uint256 tokenGuardianDisablingTimestamp,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a collection's token URI is updated.
     * @param fromTokenId The ID of the smallest token that requires its token URI to be refreshed.
     * @param toTokenId The ID of the biggest token that requires its token URI to be refreshed. Max uint256 to refresh
     * all of them.
     */
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);
}

library RegistryEvents {
    event HandleLinked(
        RegistryTypes.Handle handle,
        RegistryTypes.Token token,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * WARNING: If a linked handle or token is burnt, this event will not be emitted.
     * Indexers should also take into account token burns through ERC-721 Transfer events to track all unlink actions.
     * The `resolveHandle` and `resolveToken` functions will properly reflect the unlink in any case.
     */
    event HandleUnlinked(
        RegistryTypes.Handle handle,
        RegistryTypes.Token token,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a signer's nonce is used and, as a consequence, the next available nonce is updated.
     *
     * @param signer The signer whose next available nonce was updated.
     * @param nonce The next available nonce that can be used to execute a meta-tx successfully.
     * @param timestamp The UNIX timestamp of the nonce being used.
     */
    event NonceUpdated(address indexed signer, uint256 nonce, uint256 timestamp);
}
