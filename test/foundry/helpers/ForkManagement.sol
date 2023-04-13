// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';

contract ForkManagement is Script {
    using stdJson for string;

    function testForkManagement() public {
        // Prevents being counted in Foundry Coverage
    }

    string forkEnv;
    bool fork;
    string network;
    string json;
    uint256 forkBlockNumber;

    modifier onlyFork() {
        if (bytes(forkEnv).length == 0) return;
        _;
    }

    // TODO: Move somewhere else
    function isEnvSet(string memory key) internal returns (bool) {
        try vm.envString(key) {
            return true;
        } catch {
            return false;
        }
    }

    // TODO: Move somewhere else
    // TODO: Replace with forge-std/StdJson.sol::keyExists(...) when/if this PR is approved:
    //       https://github.com/foundry-rs/forge-std/pull/226
    function keyExists(string memory key) internal returns (bool) {
        return json.parseRaw(key).length > 0;
    }

    constructor() {
        // TODO: Replace with envOr when it's released
        forkEnv = isEnvSet('TESTING_FORK') ? vm.envString('TESTING_FORK') : '';

        if (bytes(forkEnv).length > 0) {
            fork = true;
            console.log('\n\n Testing using %s fork', forkEnv);
            loadJson();

            network = getNetwork();

            if (isEnvSet('FORK_BLOCK')) {
                forkBlockNumber = vm.envUint('FORK_BLOCK');
                vm.createSelectFork(network, forkBlockNumber);
                console.log('Fork Block number (FIXED BLOCK):', forkBlockNumber);
            } else {
                vm.createSelectFork(network);
                forkBlockNumber = block.number;
                console.log('Fork Block number:', forkBlockNumber);
            }

            checkNetworkParams();
        }
    }

    function loadJson() internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, '/addresses.json');
        json = vm.readFile(path);
    }

    function checkNetworkParams() internal returns (uint256 chainId) {
        network = json.readString(string.concat('.', forkEnv, '.network'));
        chainId = json.readUint(string.concat('.', forkEnv, '.chainId'));

        console.log('\nTarget environment:', forkEnv);
        console.log('Network:', network);
        if (block.chainid != chainId) revert('Wrong chainId');
        console.log('ChainId:', chainId);
    }

    function getNetwork() internal returns (string memory) {
        return json.readString(string.concat('.', forkEnv, '.network'));
    }
}
