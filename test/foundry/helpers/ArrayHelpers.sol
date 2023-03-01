// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ArrayHelpers {
    function _toUint256Array(uint256 n) internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](1);
        ret[0] = n;
        return ret;
    }

    function _toUint256Array(uint256 n0, uint256 n1) internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](2);
        ret[0] = n0;
        ret[1] = n1;
        return ret;
    }

    function _toBytesArray(bytes memory b) internal pure returns (bytes[] memory) {
        bytes[] memory ret = new bytes[](1);
        ret[0] = b;
        return ret;
    }

    function _toBytesArray(bytes memory b0, bytes memory b1) internal pure returns (bytes[] memory) {
        bytes[] memory ret = new bytes[](2);
        ret[0] = b0;
        ret[1] = b1;
        return ret;
    }

    function _toBoolArray(bool b) internal pure returns (bool[] memory) {
        bool[] memory ret = new bool[](1);
        ret[0] = b;
        return ret;
    }

    function _toBoolArray(bool b0, bool b1) internal pure returns (bool[] memory) {
        bool[] memory ret = new bool[](2);
        ret[0] = b0;
        ret[1] = b1;
        return ret;
    }

    function _toAddressArray(address a) internal pure returns (address[] memory) {
        address[] memory ret = new address[](1);
        ret[0] = a;
        return ret;
    }

    function _toAddressArray(address a0, address a1) internal pure returns (address[] memory) {
        address[] memory ret = new address[](2);
        ret[0] = a0;
        ret[1] = a1;
        return ret;
    }
}
