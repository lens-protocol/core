// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

import '../IToucanContractRegistry.sol';
import '../ICarbonProjectVintages.sol';

import 'hardhat/console.sol'; // dev & testing

contract ProjectVintageUtils {
    function checkProjectVintageTokenExists(
        address contractRegistry,
        uint256 tokenId
    ) internal virtual {
        address c = IToucanContractRegistry(contractRegistry)
            .carbonProjectVintagesAddress();
        require(
            ICarbonProjectVintages(c).exists(tokenId),
            'Carbon project vintage does not yet exist'
        );
    }
}
