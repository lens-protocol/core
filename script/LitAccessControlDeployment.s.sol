// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';
import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import {LitAccessControl} from 'contracts/misc/access/LitAccessControl.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract LitAccessControlDeployment is Script, ForkManagement {
    using stdJson for string;

    string mnemonic;

    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    LensAccount deployer;
    LensAccount proxyAdmin;

    function loadPrivateKeys() internal {
        if (isEnvSet('MNEMONIC')) {
            mnemonic = vm.envString('MNEMONIC');
        }

        if (bytes(mnemonic).length == 0) {
            revert('Missing mnemonic');
        }

        console.log('\n- - - CURRENT BLOCK: ', block.number);

        (deployer.owner, deployer.ownerPk) = deriveRememberKey(mnemonic, 0);
        console.log('\n- - - DEPLOYER: %s', deployer.owner);
        (proxyAdmin.owner, proxyAdmin.ownerPk) = deriveRememberKey(mnemonic, 2);
        console.log('\n- - - PROXYADMIN: %s', proxyAdmin.owner);
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadPrivateKeys();
        deploy();
    }

    function deploy() internal {
        vm.startBroadcast(deployer.ownerPk);
        address lensHub = 0xC1E77eE73403B8a7478884915aA599932A677870; // TODO: Replace with reading from Addressbook
        address collectPublicationAction = 0x5FE7918C3Ef48E6C5Fd79dD22A3120a3C4967aC2; // TODO: Replace with reading from Addressbook

        address litAccessControlImpl = address(new LitAccessControl(lensHub, collectPublicationAction));

        console.log('\n- - - LitAccessControl implementation deployed: %s', litAccessControlImpl);
        console.log('\n      - LensHub: %s', lensHub);
        console.log('\n      - CollectPublicationAction: %s', collectPublicationAction);

        address litAccessControl = address(
            new TransparentUpgradeableProxy({
                _logic: address(litAccessControlImpl),
                admin_: proxyAdmin.owner,
                _data: ''
            })
        );

        console.log('\n- - - LitAccessControl proxy deployed: %s', litAccessControl);
        console.log('\n      - ProxyAdmin: %s', proxyAdmin.owner);

        vm.stopBroadcast();
    }
}
