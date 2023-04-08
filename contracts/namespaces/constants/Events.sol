// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {RegistryTypes} from 'contracts/namespaces/constants/Types.sol';

library HandlesEvents {
    event HandleMinted(string handle, string namespace, uint256 handleId, address to);
}

library RegistryEvents {
    event HandleLinked(RegistryTypes.Handle handle, RegistryTypes.Token token);
    event HandleUnlinked(RegistryTypes.Handle handle, RegistryTypes.Token token);
}
