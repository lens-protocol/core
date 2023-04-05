// SPDX-License-Identifier: MIT

// TODO: Replace solidity version in all interfaces with >0.6.0
pragma solidity >0.6.0;

import {ILensProtocol} from 'contracts/interfaces/ILensProtocol.sol';
import {ILensGovernable} from 'contracts/interfaces/ILensGovernable.sol';
import {ILensHubEventHooks} from 'contracts/interfaces/ILensHubEventHooks.sol';
import {ILensImplGetters} from 'contracts/interfaces/ILensImplGetters.sol';
import {ILensERC721} from 'contracts/interfaces/ILensERC721.sol';

interface ILensHub is ILensERC721, ILensProtocol, ILensGovernable, ILensHubEventHooks, ILensImplGetters {}
