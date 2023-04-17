// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/foundry/base/TestSetup.t.sol';
import 'contracts/libraries/constants/Types.sol';
import 'test/foundry/base/BaseTest.t.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';
import {Currency} from 'test/mocks/Currency.sol';
import {NFT} from 'test/mocks/NFT.sol';

contract BaseModuleTest is BaseTest {
    Currency currency;
    NFT nft;
    uint256 profileId;

    constructor() TestSetup() {
        currency = new Currency();
        nft = new NFT();
        profileId = _createProfile(profileOwner);
    }
}
