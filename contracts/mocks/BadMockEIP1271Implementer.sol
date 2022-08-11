// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IEIP1271Implementer} from '../interfaces/IEIP1271Implementer.sol';

// todo: should receive 65 length bytes and decode manually.
contract BadMockEIP1271Implementer is IEIP1271Implementer {
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        override
        returns (bytes4)
    {
        return bytes4(0xFFFFFFFF);
    }
}
