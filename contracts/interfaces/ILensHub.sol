// SPDX-License-Identifier: MIT

// TODO: Replace solidity version in all interfaces with >0.6.0
pragma solidity >0.6.0;

import {ILensProtocol} from 'contracts/interfaces/ILensProtocol.sol';
import {ILensGovernable} from 'contracts/interfaces/ILensGovernable.sol';
import {ILensHubEventHooks} from 'contracts/interfaces/ILensHubEventHooks.sol';
import {ILensHubImplGetters} from 'contracts/interfaces/ILensHubImplGetters.sol';

interface ILensHub is ILensProtocol, ILensGovernable, ILensHubEventHooks, ILensHubImplGetters {
    // TODO: Remove `ILensHub`, and replace for its proper underlying interface.
}
