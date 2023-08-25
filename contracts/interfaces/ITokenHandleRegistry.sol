// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title ITokenHandleRegistry
 * @author Lens Protocol
 *
 * @notice The interface for TokenHandleRegistry contract that is responsible for linking a handle NFT to a token NFT.
 * Linking means a connection between the two NFTs is created, and the handle NFT can be used to resolve the token NFT
 * or vice versa.
 * The registry is responsible for keeping track of the links between the NFTs, and for resolving them.
 * The first version of the registry is hard-coded to support only the .lens namespace and the Lens Protocol Profiles.
 */
interface ITokenHandleRegistry {
    /**
     * @notice Lens V1 -> V2 migration function. Links a handle NFT to a profile NFT without additional checks to save
     * gas.
     * Will be called by the migration function (in MigrationLib) in LensHub, only for new handles being migrated.
     *
     * @custom:permissions LensHub
     *
     * @param handleId ID of the .lens namespace handle NFT
     * @param profileId ID of the Lens Protocol Profile NFT
     */
    function migrationLink(uint256 handleId, uint256 profileId) external;

    /**
     * @notice Links a handle NFT with a profile NFT.
     * Linking means a connection between the two NFTs is created, and the handle NFT can be used to resolve the profile
     * NFT or vice versa.
     * @custom:permissions Both NFTs must be owned by the same address, and caller must be the owner of profile or its
     * approved DelegatedExecutor.
     *
     * @dev In the first version of the registry, the NFT contracts are hard-coded:
     *  - Handle is hard-coded to be of the .lens namespace
     *  - Token is hard-coded to be of the Lens Protocol Profile
     * In future versions, the registry will be more flexible and allow for different namespaces and tokens, so this
     * function might be deprecated and replaced with a new one accepting addresses of the handle and token contracts.
     *
     * @param handleId ID of the .lens namespace handle NFT
     * @param profileId ID of the Lens Protocol Profile NFT
     */
    function link(uint256 handleId, uint256 profileId) external;

    /**
     * @notice Unlinks a handle NFT from a profile NFT.
     * @custom:permissions Caller can be the owner of either of the NFTs.
     *
     * @dev In the first version of the registry, the contracts are hard-coded:
     *  - Handle is hard-coded to be of the .lens namespace
     *  - Token is hard-coded to be of the Lens Protocol Profile
     * In future versions, the registry will be more flexible and allow for different namespaces and tokens, so this
     * function might be deprecated and replaced with a new one accepting addresses of the handle and token contracts.
     *
     * @param handleId ID of the .lens namespace handle NFT
     * @param profileId ID of the Lens Protocol Profile NFT
     */
    function unlink(uint256 handleId, uint256 profileId) external;

    /**
     * @notice Resolves a handle NFT to a profile NFT.
     *
     * @dev In the first version of the registry, the contracts are hard-coded:
     *  - Handle is hard-coded to be of the .lens namespace
     *  - Token is hard-coded to be of the Lens Protocol Profile
     * In future versions, the registry will be more flexible and allow for different namespaces and tokens, so this
     * function might be deprecated and replaced with a new one.
     *
     * @param handleId ID of the .lens namespace handle NFT
     *
     * @return tokenId ID of the Lens Protocol Profile NFT
     */
    function resolve(uint256 handleId) external view returns (uint256);

    /**
     * @notice Gets a default handle for a profile NFT (aka reverse resolution).
     *
     * @dev In the first version of the registry, the contracts are hard-coded:
     *  - Handle is hard-coded to be of the .lens namespace
     *  - Token is hard-coded to be of the Lens Protocol Profile
     * In future versions, the registry will be more flexible and allow for different namespaces and tokens, so this
     * function might be deprecated and replaced with a new one.
     *
     * @param tokenId ID of the Lens Protocol Profile NFT
     *
     * @return handleId ID of the .lens namespace handle NFT
     */
    function getDefaultHandle(uint256 tokenId) external view returns (uint256);
}
