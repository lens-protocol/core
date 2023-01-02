// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract AssumptionHelpers {
    uint256 constant ISSECP256K1_CURVE_ORDER =
        115792089237316195423570985008687907852837564279074904382605163141518161494337;

    function _isValidPk(uint256 pkCandidate) internal pure returns (bool) {
        return pkCandidate > 0 && pkCandidate < ISSECP256K1_CURVE_ORDER;
    }
}
