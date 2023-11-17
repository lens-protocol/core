// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IProfileTokenURI {
    function getTokenURI(uint256 profileId, uint256 mintTimestamp) external view returns (string memory);
}
