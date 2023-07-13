// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import 'test/base/BaseTest.t.sol';

abstract contract ERC721Test is BaseTest {
    function _getERC721TokenAddress() internal view virtual returns (address);

    function _mintERC721(address to) internal virtual returns (uint256);
}
