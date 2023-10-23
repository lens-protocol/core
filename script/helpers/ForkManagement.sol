// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'forge-std/Script.sol';

contract ForkManagement is Script {
    // add this to be excluded from coverage report
    function testForkManagement() public {}

    using stdJson for string;

    string targetEnv;
    bool fork;
    string network;
    string json;
    uint256 forkBlockNumber;

    // TODO: Replace with forge-std/StdJson.sol::keyExists(...) when/if this PR is approved:
    //       https://github.com/foundry-rs/forge-std/pull/226
    function keyExists(string memory key) internal view returns (bool) {
        return json.parseRaw(key).length > 0;
    }

    function isEnvSet(string memory key) internal view returns (bool) {
        try vm.envString(key) {
            return true;
        } catch {
            return false;
        }
    }

    modifier onlyFork() {
        if (fork) {
            _;
        } else {
            return;
        }
    }

    function initFork() internal {
        targetEnv = vm.envOr('TESTING_FORK', string(''));

        if (bytes(targetEnv).length > 0) {
            fork = true;
            console.log('\n\n Testing using %s fork', targetEnv);
            loadJson();
            network = getNetwork();
            vm.createSelectFork(network);
            forkBlockNumber = vm.envOr('TESTING_FORK_BLOCK', block.number);
            console.log('Fork Block number:', forkBlockNumber);
            checkNetworkParams();
            loadBaseAddresses();
        } else {
            fork = false;
            deployBaseContracts();
        }
    }

    function loadJson() internal {
        string memory root = vm.projectRoot();
        string memory path = string(abi.encodePacked(root, '/addresses.json'));
        json = vm.readFile(path);
    }

    function checkNetworkParams() internal {
        network = json.readString(string(abi.encodePacked('.', targetEnv, '.network')));
        uint256 chainId = json.readUint(string(abi.encodePacked('.', targetEnv, '.chainId')));

        console.log('\nTarget environment:', targetEnv);
        console.log('Network:', network);
        if (block.chainid != chainId) revert('Wrong chainId');
        console.log('ChainId:', chainId);
    }

    function getNetwork() internal returns (string memory) {
        return json.readString(string(abi.encodePacked('.', targetEnv, '.network')));
    }

    function loadBaseAddresses() internal virtual {}

    function deployBaseContracts() internal virtual {}
}
