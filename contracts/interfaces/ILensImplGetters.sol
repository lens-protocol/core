// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title ILensImplGetters
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract's implementation getters. These implementations will be used
 * for deploying each respective contract for each profile.
 */
interface ILensImplGetters {
    /**
     * @notice Returns the Follow NFT implementation address that is used for all deployed Follow NFTs.
     *
     * @return address The Follow NFT implementation address.
     */
    function getFollowNFTImpl() external view returns (address);

    /**
     * @notice Returns the Collect NFT implementation address that is used for each new deployed Collect NFT.
     * @custom:pending-deprecation
     *
     * @return address The Collect NFT implementation address.
     */
    function getLegacyCollectNFTImpl() external view returns (address);

    /**
     * @notice Returns the address of the registry that stores all modules that are used by the Lens Protocol.
     *
     * @return address The address of the Module Registry contract.
     */
    function getModuleRegistry() external view returns (address);
}
