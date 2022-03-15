// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

/**
 * @title IWhitelist
 * @author Lens Protocol
 *
 * @notice This is the interface for the Whitelist contract, which acts as a helper to whitelist actors and modules.
 */
interface IWhitelist {
    /**
     * @notice Returns whether or not a profile creator is whitelisted.
     *
     * @param profileCreator The address of the profile creator to check.
     *
     * @return A boolean, true if the profile creator is whitelisted.
     */
    function isProfileCreatorWhitelisted(address profileCreator) external view returns (bool);

    /**
     * @notice Returns whether or not a follow module is whitelisted.
     *
     * @param followModule The address of the follow module to check.
     *
     * @return A boolean, true if the the follow module is whitelisted.
     */
    function isFollowModuleWhitelisted(address followModule) external view returns (bool);

    /**
     * @notice Returns whether or not a collect module is whitelisted.
     *
     * @param collectModule The address of the collect module to check.
     *
     * @return A boolean, true if the the collect module is whitelisted.
     */
    function isCollectModuleWhitelisted(address collectModule) external view returns (bool);

    /**
     * @notice Returns whether or not a reference module is whitelisted.
     *
     * @param referenceModule The address of the reference module to check.
     *
     * @return A boolean, true if the the reference module is whitelisted.
     */
    function isReferenceModuleWhitelisted(address referenceModule) external view returns (bool);
}
