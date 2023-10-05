// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title ILensVersion
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub Version getters and emitter.
 * It allows to emit a LensHub version during an upgrade, and also to get the current version.
 */
interface ILensVersion {
    /**
     * @notice Returns the LensHub current Version.
     *
     * @return version The LensHub current Version.
     */
    function getVersion() external view returns (string memory);

    /**
     * @notice Returns the LensHub current Git Commit.
     *
     * @return gitCommit The LensHub current Git Commit.
     */
    function getGitCommit() external view returns (bytes20);

    /**
     * @notice Emits the LensHub current Version. Used in upgradeAndCall().
     */
    function emitVersion() external;
}
