// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';

import {MockCurrency} from 'script/mocks/MockCurrency.sol';

contract DeployMockCurrency is Script, ForkManagement {
    using stdJson for string;

    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    LensAccount deployer;
    LensAccount governance;
    LensAccount proxyAdmin;

    string mnemonic;

    function loadPrivateKeys() internal {
        if (isEnvSet('MNEMONIC')) {
            mnemonic = vm.envString('MNEMONIC');
        }

        if (bytes(mnemonic).length == 0) {
            revert('Missing mnemonic');
        }

        console.log('\n');

        (deployer.owner, deployer.ownerPk) = deriveRememberKey(mnemonic, 0);
        console.log('\n- - - DEPLOYER: %s', deployer.owner);
        console.log('\n- - - DEPLOYER PK: %s', deployer.ownerPk);
        (governance.owner, governance.ownerPk) = deriveRememberKey(mnemonic, 1);
        console.log('\n- - - GOVERNANCE: %s', governance.owner);
        console.log('\n- - - GOVERNANCE PK: %s', governance.ownerPk);
        (proxyAdmin.owner, proxyAdmin.ownerPk) = deriveRememberKey(mnemonic, 2);
        console.log('\n- - - PROXYADMIN: %s', proxyAdmin.owner);
        console.log('\n- - - PROXYADMIN PK: %s', proxyAdmin.ownerPk);

        console.log('\n');

        console.log('Current block:', block.number);
    }

    function deploy() internal {
        console.log('Deploying...');

        string memory name = 'Bonsai';
        string memory symbol = 'BONSAI';

        vm.startBroadcast(deployer.ownerPk);
        address mockCurrency = address(new MockCurrency(name, symbol));
        vm.stopBroadcast();

        console.log('Deployed MockCurrency(%s, %s) at: %s', name, symbol, mockCurrency);
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadBaseAddresses();
        loadPrivateKeys();
        deploy();
    }
}
