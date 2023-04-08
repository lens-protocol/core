// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title IERC721Burnable
 * @author Lens Protocol
 *
 * @notice Extension of ERC-721 including a function that allows the token to be burned.
 */
interface IERC721Burnable {
    /**
     * @notice Burns an NFT, removing it from circulation and essentially destroying it.
     * @custom:permission Owner of the NFT.
     *
     * @param tokenId The token ID of the token to burn.
     */
    function burn(uint256 tokenId) external;
}
