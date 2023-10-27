// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library Typehash {

    bytes32 constant EIP712_DOMAIN = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

    bytes32 constant LINK = keccak256('Link(uint256 handleId,uint256 profileId,uint256 nonce,uint256 deadline)');

    bytes32 constant UNLINK = keccak256('Unlink(uint256 handleId,uint256 profileId,uint256 nonce,uint256 deadline)');
}
