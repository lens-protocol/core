// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';
import {ArrayHelpers} from 'script/helpers/ArrayHelpers.sol';
import {LibString} from 'solady/utils/LibString.sol';
import {PublicActProxy} from 'contracts/misc/PublicActProxy.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';

contract DeployPublicActProxy is Script, ForkManagement, ArrayHelpers {
    using stdJson for string;

    string addressesFile = 'addressesV2.txt';

    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    // TODO: Use from test/ContractAddresses
    struct Module {
        address addy;
        string name;
    }

    LensAccount deployer;
    LensAccount governance;
    LensAccount proxyAdmin;

    string mnemonic;

    address lensHub;
    address collectPublicationAction;

    address publicActProxy;

    function findModuleHelper(
        Module[] memory modules,
        string memory moduleNameToFind
    ) internal pure returns (Module memory) {
        for (uint256 i = 0; i < modules.length; i++) {
            if (LibString.eq(modules[i].name, moduleNameToFind)) {
                return modules[i];
            }
        }
        revert('Module not found');
    }

    function saveContractAddress(string memory contractName, address deployedAddress) internal {
        // console.log('Saving %s (%s) into addresses under %s environment', contractName, deployedAddress, targetEnv);
        string[] memory inputs = new string[](5);
        inputs[0] = 'node';
        inputs[1] = 'script/helpers/saveAddress.js';
        inputs[2] = targetEnv;
        inputs[3] = contractName;
        inputs[4] = vm.toString(deployedAddress);
        // bytes memory res =
        vm.ffi(inputs);
        // string memory output = abi.decode(res, (string));
        // console.log(output);
    }

    function _logDeployedAddress(address deployedAddress, string memory addressLabel) internal {
        console.log('\n+ + + ', addressLabel, ': ', deployedAddress);
        vm.writeLine(addressesFile, string.concat(addressLabel, string.concat(': ', vm.toString(deployedAddress))));
        saveContractAddress(addressLabel, deployedAddress);
    }

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
        (governance.owner, governance.ownerPk) = deriveRememberKey(mnemonic, 1);
        console.log('\n- - - GOVERNANCE: %s', governance.owner);
        (proxyAdmin.owner, proxyAdmin.ownerPk) = deriveRememberKey(mnemonic, 2);
        console.log('\n- - - PROXYADMIN: %s', proxyAdmin.owner);

        console.log('\n');

        console.log('Current block:', block.number);
    }

    function loadBaseAddresses() internal override {
        lensHub = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHub')));
        vm.label(lensHub, 'LensHub');
        console.log('Lens Hub Proxy: %s', lensHub);

        Module[] memory actModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', targetEnv, '.Modules.v2.act'))),
            (Module[])
        );
        collectPublicationAction = findModuleHelper(actModules, 'CollectPublicationAction').addy;
        vm.label(collectPublicationAction, 'CollectPublicationAction');
        console.log('CollectPublicationAction: %s', collectPublicationAction);
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadBaseAddresses();
        loadPrivateKeys();
        deploy();
        governanceActions();
    }

    function deploy() internal {
        vm.startBroadcast(deployer.ownerPk);
        {
            publicActProxy = address(
                new PublicActProxy({lensHub: lensHub, collectPublicationAction: collectPublicationAction})
            );
            _logDeployedAddress(publicActProxy, 'PublicActProxy');
        }
        vm.stopBroadcast();
    }

    function governanceActions() internal {
        uint256 anonymousProfileId = json.readUint(string(abi.encodePacked('.', targetEnv, '.AnonymousProfileId')));
        console.log('Anonymous Profile Id: %s', anonymousProfileId);
        vm.startBroadcast(deployer.ownerPk);
        {
            ILensHub(lensHub).changeDelegatedExecutorsConfig(
                anonymousProfileId,
                _toAddressArray(publicActProxy),
                _toBoolArray(true)
            );
        }
        vm.stopBroadcast();
        console.log('PublicActProxy added as DelegatedExecutor of AnonymousProfileId: %s', publicActProxy);
    }
}
