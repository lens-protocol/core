// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {Types} from '../libraries/constants/Types.sol';

/**
 * @title IERC721Timestamped
 * @author Lens Protocol
 *
 * @notice Extension of ERC-721 including a struct for token data, which contains the owner and the mint timestamp, as
 * well as their associated getters.
 */
interface IERC721Timestamped {
    /**
     * @notice Returns the mint timestamp associated with a given NFT.
     *
     * @param tokenId The token ID of the NFT to query the mint timestamp for.
     *
     * @return uint256 Mint timestamp, this is stored as a uint96 but returned as a uint256 to reduce unnecessary
     * padding.
     */
    function mintTimestampOf(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the token data associated with a given NFT. This allows fetching the token owner and
     * mint timestamp in a single call.
     *
     * @param tokenId The token ID of the NFT to query the token data for.
     *
     * @return TokenData A struct containing both the owner address and the mint timestamp.
     */
    function tokenDataOf(uint256 tokenId) external view returns (Types.TokenData memory);

    /**
     * @notice Returns whether a token with the given token ID exists.
     *
     * @param tokenId The token ID of the NFT to check existence for.
     *
     * @return bool True if the token exists.
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @notice Returns the amount of tokens in circulation.
     *
     * @return uint256 The current total supply of tokens.
     */
    function totalSupply() external view returns (uint256);
}
