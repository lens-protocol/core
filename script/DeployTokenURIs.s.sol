// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';
import {ProfileTokenURI} from 'contracts/misc/token-uris/ProfileTokenURI.sol';
import {HandleTokenURI} from 'contracts/misc/token-uris/HandleTokenURI.sol';
import {FollowTokenURI} from 'contracts/misc/token-uris/FollowTokenURI.sol';

contract DeployTokenURIs is Script, ForkManagement {
    using stdJson for string;

    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    LensAccount _deployer;

    string mnemonic;

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

    function loadPrivateKeys() internal {
        if (isEnvSet('MNEMONIC')) {
            mnemonic = vm.envString('MNEMONIC');
        }

        if (bytes(mnemonic).length == 0) {
            revert('Missing mnemonic');
        }

        console.log('\n');

        (_deployer.owner, _deployer.ownerPk) = deriveRememberKey(mnemonic, 0);
        console.log('Deployer address: %s', address(_deployer.owner));

        console.log('\n');

        console.log('Current block:', block.number);
    }

    function deploy() internal {
        vm.startBroadcast(_deployer.ownerPk);
        address profileTokenURI = address(new ProfileTokenURI());
        address handleTokenURI = address(new HandleTokenURI());
        address followTokenURI = address(new FollowTokenURI());
        vm.stopBroadcast();

        console.log('\n');
        console.log('ProfileTokenURI address: %s', address(profileTokenURI));
        saveContractAddress('ProfileTokenURI', profileTokenURI);
        console.log('HandleTokenURI address: %s', address(handleTokenURI));
        saveContractAddress('HandleTokenURI', handleTokenURI);
        console.log('FollowTokenURI address: %s', address(followTokenURI));
        saveContractAddress('FollowTokenURI', followTokenURI);
        console.log('\n');
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
