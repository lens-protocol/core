// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ITokenHandleRegistry {
    // V1->V2 Migration function
    function migrationLinkHandleWithToken(uint256 handleId, uint256 tokenId) external;

    function linkHandleWithToken(uint256 handleId, uint256 tokenId, bytes calldata data) external;

    function unlinkHandleFromToken(uint256 handleId, uint256 tokenId) external;

    function resolveHandle(uint256 handleId) external view returns (uint256);

    function resolveToken(uint256 tokenId) external view returns (uint256);
}
