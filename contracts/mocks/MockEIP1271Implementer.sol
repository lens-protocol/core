// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import 'hardhat/console.sol';
import {IEIP1271Implementer} from '../interfaces/IEIP1271Implementer.sol';

// todo: should receive 65 length bytes and decode manually.
contract MockEIP1271Implementer is IEIP1271Implementer {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant MAGIC_VALUE = 0x1626ba7e;

    address public immutable OWNER;

    constructor() {
        OWNER = msg.sender;
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        override
        returns (bytes4)
    {
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(_signature, (bytes32, bytes32, uint8));
        console.log('Decoded r:');
        console.logBytes32(r);
        console.log('Decoded s:');
        console.logBytes32(s);
        console.log('Decoded v:');
        console.log(v);
        console.log('ON CHAIN HASHED MESSAGE:');
        console.logBytes32(keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', _hash)));
        address signer = ecrecover(
            keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', _hash)),
            v,
            r,
            s
        );
        console.log('On-chain recovered signer:', signer);
        console.log('On-chain owner:', OWNER);
        require(signer != address(0), 'Invalid recovery');
        return signer == OWNER ? MAGIC_VALUE : bytes4(0xFFFFFFFF);
    }
}
