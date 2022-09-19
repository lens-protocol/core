// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import './BaseTest.t.sol';

contract BaseSigTest is BaseTest {
    uint256 constant signerKey = 0x04546b;
    uint256 constant otherSignerKey = 0x737562;
    address immutable signer = vm.addr(signerKey);
    address immutable otherSigner = vm.addr(otherSignerKey);

    function _getCollectTypeDataHash(
        uint256 profileId,
        uint256 pubId,
        bytes memory data,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                COLLECT_WITH_SIG_TYPEHASH,
                profileId,
                pubId,
                keccak256(data),
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function _calculateDigest(bytes32 hashedMessage) internal view returns (bytes32) {
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, hashedMessage));
        return digest;
    }

    function _getSigStruct(
        uint256 pKey,
        bytes32 digest,
        uint256 deadline
    ) internal returns (DataTypes.EIP712Signature memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pKey, digest);
        return DataTypes.EIP712Signature({v: v, r: r, s: s, deadline: deadline});
    }
}
