// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {ILensProtocol} from './ILensProtocol.sol';
import {ILensGovernable} from './ILensGovernable.sol';
import {ILensHubEventHooks} from './ILensHubEventHooks.sol';
import {ILensImplGetters} from './ILensImplGetters.sol';
import {ILensProfiles} from './ILensProfiles.sol';
import {ILensVersion} from './ILensVersion.sol';

interface ILensHub is
    ILensProfiles,
    ILensProtocol,
    ILensGovernable,
    ILensHubEventHooks,
    ILensImplGetters,
    ILensVersion
{}
