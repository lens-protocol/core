// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {RegistryTypes} from 'contracts/namespaces/constants/Types.sol';

library HandlesEvents {
    event HandleMinted(string handle, string namespace, uint256 handleId, address to, uint256 timestamp);
}

library RegistryEvents {
    event HandleLinked(RegistryTypes.Handle handle, RegistryTypes.Token token, uint256 timestamp);

    /**
     * WARNING: If a linked handle or token is burnt, this event will not be emitted.
     * Indexers should also take into account token burns through ERC-721 Transfer events to track all unlink actions.
     * The `resolveHandle` and `resolveToken` functions will properly reflect the unlink in any case.
     */
    event HandleUnlinked(RegistryTypes.Handle handle, RegistryTypes.Token token, uint256 timestamp);
}
