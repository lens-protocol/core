// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title Token-Handle Registry
 * @author Lens Protocol
 *
 * @notice This contract is responsible for linking a handle NFT to a token NFT.
 * Linking means a connection between the two NFTs is created, and the handle NFT can be used to resolve the token NFT
 * or vice versa:
 *   handle.lens <-> Lens Profile #1 (<< only this is supported in the first iteration)
 *   redblue.punk <-> Lens Profile #2
 *   myname.lens <-> Cryptopunk #69
 *   vitalik.eth <-> BAYC #420
 * The registry is responsible for keeping track of the links between the NFTs, and for resolving them.
 * The first iteration of the registry is hard-coded to support only the .lens namespace and the Lens Protocol Profiles.
 */
interface ITokenHandleRegistry {
    //
    /**
     * @notice V1->V2 Migration function. Links a handle NFT to a profile NFT without additional checks to save gas.
     * Will be called by the migration function (in MigrationLib) in LensHub, only for new handles being migrated.
     *
     * @custom:permissions LensHub
     *
     * @param handleId ID of the .lens namespace handle NFT
     * @param tokenId ID of the Lens Protocol Profile NFT
     */
    function migrationLinkHandleWithToken(uint256 handleId, uint256 tokenId) external;

    /**
     * @notice Links a handle NFT to a profile NFT.
     * Linking means a connection between the two NFTs is created, and the handle NFT can be used to resolve the profile
     * NFT or vice versa.
     * @custom:permissions Caller must own both NFTs.
     *
     * @dev In the first iteration of the registry, the NFT contracts are hard-coded:
     *  - Handle is hard-coded to be of the .lens namespace
     *  - Token is hard-coded to be of the Lens Protocol Profile
     * In future iterations, the registry will be more flexible and allow for different namespaces and tokens, so this
     * function might be deprecated and replaced with a new one accepting addresses of the handle and token contracts.
     *
     *
     * @param handleId ID of the .lens namespace handle NFT
     * @param tokenId ID of the Lens Protocol Profile NFT
     * @param data Not used for now, but can be used to pass additional data to the function in future iterations.
     */
    function linkHandleWithToken(uint256 handleId, uint256 tokenId, bytes calldata data) external;

    /**
     * @notice Unlinks a handle NFT from a profile NFT.
     * @custom:permissions Called can be the owner of either of the NFTs.
     *
     * @dev In the first iteration of the registry, the contracts are hard-coded:
     *  - Handle is hard-coded to be of the .lens namespace
     *  - Token is hard-coded to be of the Lens Protocol Profile
     * In future iterations, the registry will be more flexible and allow for different namespaces and tokens, so this
     * function might be deprecated and replaced with a new one accepting addresses of the handle and token contracts.
     *
     * @param handleId ID of the .lens namespace handle NFT
     * @param tokenId ID of the Lens Protocol Profile NFT
     */
    function unlinkHandleFromToken(uint256 handleId, uint256 tokenId) external;

    /**
     * @notice Resolves a handle NFT to a profile NFT.
     *
     * @dev In the first iteration of the registry, the contracts are hard-coded:
     *  - Handle is hard-coded to be of the .lens namespace
     *  - Token is hard-coded to be of the Lens Protocol Profile
     * In future iterations, the registry will be more flexible and allow for different namespaces and tokens, so this
     * function might be deprecated and replaced with a new one.
     *
     * @param handleId ID of the .lens namespace handle NFT
     *
     * @return tokenId ID of the Lens Protocol Profile NFT
     */
    function resolveHandle(uint256 handleId) external view returns (uint256);

    /**
     * @notice Resolves a profile NFT to a handle NFT.
     *
     * @dev In the first iteration of the registry, the contracts are hard-coded:
     *  - Handle is hard-coded to be of the .lens namespace
     *  - Token is hard-coded to be of the Lens Protocol Profile
     * In future iterations, the registry will be more flexible and allow for different namespaces and tokens, so this
     * function might be deprecated and replaced with a new one.
     *
     * @param tokenId ID of the Lens Protocol Profile NFT
     *
     * @return handleId ID of the .lens namespace handle NFT
     */
    function resolveToken(uint256 tokenId) external view returns (uint256);
}
