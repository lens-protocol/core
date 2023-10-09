// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';
import 'test/helpers/KeyExists.sol';
import 'test/helpers/ContractAddresses.sol';

contract ForkManagement is Script, KeyExists, ContractAddresses {
    using stdJson for string;

    function testForkManagement() public {
        // Prevents being counted in Foundry Coverage
    }

    string forkEnv;
    uint256 forkVersion;
    bool fork;
    string network;
    string json;
    uint256 forkBlockNumber;

    modifier onlyFork() {
        if (bytes(forkEnv).length == 0) {
            return;
        }
        _;
    }

    modifier notFork() {
        if (bytes(forkEnv).length != 0) {
            return;
        }
        _;
    }

    function setUp() public virtual {
        // TODO: Replace with envOr when it's released
        forkEnv = vm.envOr({name: string('TESTING_FORK'), defaultValue: string('')});
        forkVersion = vm.envOr({name: string('TESTING_FORK_CURRENT_VERSION'), defaultValue: uint256(0)});

        if (bytes(forkEnv).length > 0) {
            fork = true;
            if (forkVersion == 0) {
                console.log('TESTING_FORK_CURRENT_VERSION not set');
                revert('TESTING_FORK_CURRENT_VERSION not set');
            }
            console.log('\n\n Testing using %s fork', forkEnv);
            loadJson();

            network = getNetwork();

            forkBlockNumber = vm.envOr({name: string('TESTING_FORK_BLOCK'), defaultValue: uint256(0)});
            if (forkBlockNumber != 0) {
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
        console.log('ChainId:', block.chainid);
    }

    function getNetwork() internal returns (string memory) {
        return json.readString(string.concat('.', forkEnv, '.network'));
    }
}
