// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

/**
 * @title ICollectNFT
 * @author Lens Protocol
 *
 * @notice This is the interface for the CollectNFT contract. Which is cloned upon the first collect for any given
 * publication.
 */
interface ICollectNFT {
    /**
     * @notice Initializes the collect NFT, setting the hub as the privileged minter and storing the associated
     * profile and publication ID.
     *
     * @param profileId The token ID of the profile in the hub that this collectNFT points to.
     * @param pubId The profile publication ID in the hub that this collectNFT points to.
     */
    function initialize(uint256 profileId, uint256 pubId) external;

    /**
     * @notice Mints a collect NFT to the specified address. This can only be called by the hub, and is called
     * upon collection.
     *
     * @param to The address to mint the NFT to.
     *
     * @return uint256 An interger representing the minted token ID.
     */
    function mint(address to) external returns (uint256);

    /**
     * @notice Returns the source publication pointer mapped to this collect NFT.
     *
     * @return tuple First the profile ID uint256, and second the pubId uint256.
     */
    function getSourcePublicationPointer() external view returns (uint256, uint256);
}
