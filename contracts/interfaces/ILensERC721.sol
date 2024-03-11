// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Timestamped} from './IERC721Timestamped.sol';
import {IERC721Burnable} from './IERC721Burnable.sol';
import {IERC721MetaTx} from './IERC721MetaTx.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

interface ILensERC721 is IERC721, IERC721Timestamped, IERC721Burnable, IERC721MetaTx, IERC721Metadata {}
