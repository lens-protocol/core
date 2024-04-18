// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'forge-std/Test.sol';
import {ProtocolSharedRevenueDistribution, ProtocolSharedRevenueMinFeeMintModule, ProtocolSharedRevenueMinFeeMintModuleInitData} from 'contracts/modules/act/collect/ProtocolSharedRevenueMinFeeMintModule.sol';
import {BaseFeeCollectModuleBase} from 'test/modules/act/collect/BaseFeeCollectModule.base.t.sol';
import {MockCurrency} from 'test/mocks/MockCurrency.sol';

contract ProtocolSharedRevenueMinFeeMintModuleBase is BaseFeeCollectModuleBase {
    function testProtocolSharedRevenueMinFeeMintModuleBase() public {
        // Prevents being counted in Foundry Coverage
    }

    using stdJson for string;

    uint16 constant BPS_MAX = 10000;

    address creatorClientAddress = makeAddr('CREATOR_CLIENT');
    address executorClientAddress = makeAddr('EXECUTOR_CLIENT');

    MockCurrency bonsai;
    uint256 mintFee = 10 ether;
    ProtocolSharedRevenueMinFeeMintModule mintFeeModule;
    ProtocolSharedRevenueMinFeeMintModuleInitData mintFeeModuleExampleInitData;

    function setUp() public virtual override {
        super.setUp();

        // Deploy & Whitelist ProtocolSharedRevenueMinFeeMintModule
        if (fork && keyExists(json, string(abi.encodePacked('.', forkEnv, '.ProtocolSharedRevenueMinFeeMintModule')))) {
            mintFeeModule = ProtocolSharedRevenueMinFeeMintModule(
                json.readAddress(string(abi.encodePacked('.', forkEnv, '.ProtocolSharedRevenueMinFeeMintModule')))
            );
            console.log('Testing against already deployed module at:', address(mintFeeModule));
        } else {
            vm.prank(deployer);
            mintFeeModule = new ProtocolSharedRevenueMinFeeMintModule(
                address(hub),
                collectPublicationAction,
                address(moduleRegistry),
                address(this)
            );
        }

        baseFeeCollectModule = address(mintFeeModule);
        if (address(currency) == address(0)) {
            currency = new MockCurrency();
        }

        bonsai = new MockCurrency();

        vm.startPrank(mintFeeModule.owner());
        mintFeeModule.setMintFeeParams(address(bonsai), mintFee);
        mintFeeModule.setProtocolSharedRevenueDistribution(
            ProtocolSharedRevenueDistribution({
                creatorSplit: 5000,
                protocolSplit: 2000,
                creatorClientSplit: 1500,
                executorClientSplit: 1500
            })
        );
        vm.stopPrank();
    }

    function getEncodedInitData() internal virtual override returns (bytes memory) {
        mintFeeModuleExampleInitData.amount = exampleInitData.amount;
        mintFeeModuleExampleInitData.collectLimit = exampleInitData.collectLimit;
        mintFeeModuleExampleInitData.currency = exampleInitData.currency;
        mintFeeModuleExampleInitData.referralFee = exampleInitData.referralFee;
        mintFeeModuleExampleInitData.followerOnly = exampleInitData.followerOnly;
        mintFeeModuleExampleInitData.endTimestamp = exampleInitData.endTimestamp;
        mintFeeModuleExampleInitData.recipient = exampleInitData.recipient;
        mintFeeModuleExampleInitData.creatorClient = creatorClientAddress;

        return abi.encode(mintFeeModuleExampleInitData);
    }
}
