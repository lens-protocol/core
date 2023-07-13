// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title ILegacyCollectNFT
 * @author Lens Protocol
 *
 * @notice This is the interface for the Lens V1 CollectNFT contract. Which is cloned upon the first collect for any
 * given publication.
 */
interface ILegacyCollectNFT {
    /**
     * @notice Initializes the collect NFT, setting the feed as the privileged minter, storing the collected publication
     * pointer and initializing the name and symbol in the LensNFTBase contract.
     * @custom:permissions LensHub.
     *
     * @param profileId The token ID of the profile in the hub that this Collect NFT points to.
     * @param pubId The profile publication ID in the hub that this Collect NFT points to.
     * @param name The name to set for this NFT.
     * @param symbol The symbol to set for this NFT.
     */
    function initialize(
        uint256 profileId,
        uint256 pubId,
        string calldata name,
        string calldata symbol
    ) external;

    /**
     * @notice Mints a collect NFT to the specified address.
     * @custom:permissions LensHub.
     *
     * @param to The address to mint the NFT to.
     *
     * @return uint256 An integer representing the minted token ID.
     */
    function mint(address to) external returns (uint256);

    /**
     * @notice Returns the source publication of this collect NFT.
     *
     * @return tuple First is the profile ID, and second is the publication ID.
     */
    function getSourcePublicationPointer() external view returns (uint256, uint256);
}
