// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';

contract ArrayHelpers {
    function testArrayHelpers() public {
        // Prevents being counted in Foundry Coverage
    }

    function _emptyUint256Array() internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](0);
        return ret;
    }

    function _emptyPubTypesArray() internal pure returns (Types.PublicationType[] memory) {
        Types.PublicationType[] memory ret = new Types.PublicationType[](0);
        return ret;
    }

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

    function _emptyBytesArray() internal pure returns (bytes[] memory) {
        bytes[] memory ret = new bytes[](0);
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

    function _emptyAddressArray() internal pure returns (address[] memory) {
        address[] memory ret = new address[](0);
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
