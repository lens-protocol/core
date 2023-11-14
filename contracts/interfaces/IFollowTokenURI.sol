// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IFollowTokenURI {
    function getTokenURI(
        uint256 followTokenId,
        uint256 followedProfileId,
        uint256 originalFollowTimestamp
    ) external pure returns (string memory);
}
