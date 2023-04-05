// SPDX-License-Identifier: MIT

// TODO: Replace solidity version in all interfaces with >0.6.0
pragma solidity >0.6.0;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Timestamped} from 'contracts/interfaces/IERC721Timestamped.sol';
import {IERC721Burnable} from 'contracts/interfaces/IERC721Burnable.sol';
import {IERC721MetaTx} from 'contracts/interfaces/IERC721MetaTx.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

interface ILensERC721 is IERC721, IERC721Timestamped, IERC721Burnable, IERC721MetaTx, IERC721Metadata {}
