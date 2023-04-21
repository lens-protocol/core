// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';

/**
 * @dev This is a mock contract that always returns the wrong value upon being checked with EIP-1271.
 */
contract BadMockEIP1271Implementer is IERC1271 {
    function isValidSignature(
        bytes32 /* _hash */,
        bytes memory /* _signature */
    ) external pure override returns (bytes4) {
        return bytes4(0xFFFFFFFF);
    }
}
