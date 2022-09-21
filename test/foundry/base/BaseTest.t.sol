// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './TestSetup.t.sol';

contract BaseTest is TestSetup {
    function _getFollowTypedDataHash(
        uint256[] memory profileIds,
        bytes[] memory datas,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        uint256 dataLength = datas.length;
        bytes32[] memory dataHashes = new bytes32[](dataLength);
        for (uint256 i = 0; i < dataLength; ) {
            dataHashes[i] = keccak256(datas[i]);
            unchecked {
                ++i;
            }
        }

        bytes32 structHash = keccak256(
            abi.encode(
                FOLLOW_WITH_SIG_TYPEHASH,
                keccak256(abi.encodePacked(profileIds)),
                keccak256(abi.encodePacked(dataHashes)),
                nonce,
                deadline
            )
        );

        return _calculateDigest(structHash);
    }

    function _getCollectTypedDataHash(
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

    function _toUint256Array(uint256 n) internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](1);
        ret[0] = n;
        return ret;
    }

    function _toBytesArray(bytes memory n) internal pure returns (bytes[] memory) {
        bytes[] memory ret = new bytes[](1);
        ret[0] = n;
        return ret;
    }
}
