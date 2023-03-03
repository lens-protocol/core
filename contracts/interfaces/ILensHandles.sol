// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface ILensHandles is IERC721 {
    // Constant for upgradeability purposes, see VersionedInitializable. Do not confuse with EIP-712 revision number.

    /**
     * @notice Mints a handle in the given namespace.
     * @notice A handle is composed by a local name and a namespace, separated by dot.
     * @notice Example: `john.lens` is a handle composed by the local name `john` and the namespace `lens`.
     *
     * @param to The address where the handle is being minted to.
     * @param localName The local name of the handle.
     */
    function mintHandle(address to, string calldata localName) external returns (uint256);

    function burn(uint256 tokenId) external;

    function getNamespace() external pure returns (string memory);

    function getNamespaceHash() external pure returns (bytes32);
}
