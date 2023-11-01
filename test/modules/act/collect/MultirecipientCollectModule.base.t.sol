// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'forge-std/Test.sol';
import 'test/modules/act/collect/BaseFeeCollectModule.base.t.sol';
import {MultirecipientFeeCollectModule, MultirecipientFeeCollectModuleInitData, RecipientData} from 'contracts/modules/act/collect/MultirecipientFeeCollectModule.sol';

contract MultirecipientCollectModuleBase is BaseFeeCollectModuleBase {
    function testMultirecipientCollectModuleBase() public {
        // Prevents being counted in Foundry Coverage
    }

    using stdJson for string;
    uint16 constant BPS_MAX = 10000;
    uint256 MAX_RECIPIENTS = 5;

    MultirecipientFeeCollectModule multirecipientFeeCollectModule;
    MultirecipientFeeCollectModuleInitData multirecipientExampleInitData;

    function setUp() public virtual override {
        super.setUp();

        // Deploy & Whitelist MultirecipientFeeCollectModule
        if (fork && keyExists(json, string(abi.encodePacked('.', forkEnv, '.MultirecipientFeeCollectModule')))) {
            multirecipientFeeCollectModule = MultirecipientFeeCollectModule(
                json.readAddress(string(abi.encodePacked('.', forkEnv, '.MultirecipientFeeCollectModule')))
            );
            console.log('Testing against already deployed module at:', address(multirecipientFeeCollectModule));
        } else {
            vm.prank(deployer);
            multirecipientFeeCollectModule = new MultirecipientFeeCollectModule(
                hubProxyAddr,
                collectPublicationAction,
                address(moduleRegistry),
                address(this)
            );
        }
        baseFeeCollectModule = address(multirecipientFeeCollectModule);
        if (address(currency) == address(0)) {
            currency = new MockCurrency();
        }
    }

    function getEncodedInitData() internal virtual override returns (bytes memory) {
        multirecipientExampleInitData.amount = exampleInitData.amount;
        multirecipientExampleInitData.collectLimit = exampleInitData.collectLimit;
        multirecipientExampleInitData.currency = exampleInitData.currency;
        multirecipientExampleInitData.referralFee = exampleInitData.referralFee;
        multirecipientExampleInitData.followerOnly = exampleInitData.followerOnly;
        multirecipientExampleInitData.endTimestamp = exampleInitData.endTimestamp;
        if (multirecipientExampleInitData.recipients.length == 0) {
            multirecipientExampleInitData.recipients.push(
                RecipientData({recipient: exampleInitData.recipient, split: BPS_MAX / 2})
            );
            multirecipientExampleInitData.recipients.push(
                RecipientData({recipient: exampleInitData.recipient, split: BPS_MAX / 2})
            );
        }

        return abi.encode(multirecipientExampleInitData);
    }
}
