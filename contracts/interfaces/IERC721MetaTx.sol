// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title IERC721MetaTx
 * @author Lens Protocol
 *
 * @notice Extension of ERC-721 including meta-tx signatures related functions.
 */
interface IERC721MetaTx {
    /**
     * @notice Returns the current signature nonce of the given signer.
     *
     * @param signer The address for which to query the nonce.
     *
     * @return uint256 The current nonce of the given signer.
     */
    function nonces(address signer) external view returns (uint256);

    /**
     * @notice Returns the EIP-712 domain separator for this contract.
     *
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);
}
