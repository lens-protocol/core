// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Timestamped} from 'contracts/interfaces/IERC721Timestamped.sol';
import {IERC721Burnable} from 'contracts/interfaces/IERC721Burnable.sol';
import {IERC721MetaTx} from 'contracts/interfaces/IERC721MetaTx.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

interface ILensERC721 is IERC721, IERC721Timestamped, IERC721Burnable, IERC721MetaTx, IERC721Metadata {
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    /// TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    /// THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    /// operator, or the approved address for this NFT. Throws if `_from` is
    /// not the current owner. Throws if `_to` is the zero address. Throws if
    /// `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format
    function transferFromWithData(address _from, address _to, uint256 _tokenId, bytes memory _data) external;
}
