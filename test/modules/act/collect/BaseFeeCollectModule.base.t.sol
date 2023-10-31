// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'test/base/BaseTest.t.sol';
import {SimpleFeeCollectModule} from 'contracts/modules/act/collect/SimpleFeeCollectModule.sol';
import {BaseFeeCollectModuleInitData} from 'contracts/modules/interfaces/IBaseFeeCollectModule.sol';
import {MockCurrency} from 'test/mocks/MockCurrency.sol';

contract BaseFeeCollectModuleBase is BaseTest {
    function testBaseFeeCollectModuleBase() public {
        // Prevents being counted in Foundry Coverage
    }

    using stdJson for string;
    address baseFeeCollectModule;
    address constant collectPublicationAction = address(0xC011EC7AC7104);

    MockCurrency currency;

    BaseFeeCollectModuleInitData exampleInitData;

    uint256 constant DEFAULT_COLLECT_LIMIT = 3;
    uint16 constant REFERRAL_FEE_BPS = 250;

    function setUp() public virtual override {
        super.setUp();

        // Deploy & Whitelist BaseFeeCollectModule
        if (fork && keyExists(json, string(abi.encodePacked('.', forkEnv, '.SimpleFeeCollectModule')))) {
            baseFeeCollectModule = address(
                SimpleFeeCollectModule(
                    json.readAddress(string(abi.encodePacked('.', forkEnv, '.SimpleFeeCollectModule')))
                )
            );
            console.log('Testing against already deployed module at:', baseFeeCollectModule);
        } else {
            vm.prank(deployer);
            baseFeeCollectModule = address(
                new SimpleFeeCollectModule(
                    address(hub),
                    collectPublicationAction,
                    address(moduleRegistry),
                    address(this)
                )
            );
        }
        currency = new MockCurrency();

        exampleInitData.amount = 1 ether;
        exampleInitData.collectLimit = 0;
        exampleInitData.currency = address(currency);
        exampleInitData.referralFee = 0;
        exampleInitData.followerOnly = false;
        exampleInitData.endTimestamp = 0;
        exampleInitData.recipient = defaultAccount.owner;
    }

    function getEncodedInitData() internal virtual returns (bytes memory) {
        return abi.encode(exampleInitData);
    }
}
