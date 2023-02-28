// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title IERC721MetaTx
 * @author Lens Protocol
 *
 * @notice Includes functions realted to EIP-712 meta-tx signatures.
 */
interface IERC721MetaTx {
    /**
     * @notice Returns EIP-712 signature nonce.
     *
     * @param signer The address whom the nonce is being queried for.
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
