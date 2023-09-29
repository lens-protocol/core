// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {ILensProtocol} from 'contracts/interfaces/ILensProtocol.sol';
import {ILensGovernable} from 'contracts/interfaces/ILensGovernable.sol';
import {ILensHubEventHooks} from 'contracts/interfaces/ILensHubEventHooks.sol';
import {ILensImplGetters} from 'contracts/interfaces/ILensImplGetters.sol';
import {ILensProfiles} from 'contracts/interfaces/ILensProfiles.sol';
import {ILensVersion} from 'contracts/interfaces/ILensVersion.sol';

interface ILensHub is
    ILensProfiles,
    ILensProtocol,
    ILensGovernable,
    ILensHubEventHooks,
    ILensImplGetters,
    ILensVersion
{}
