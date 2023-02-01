// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';

contract ForkManagement is Script {
    using stdJson for string;

    string forkEnv;
    bool fork;
    string network;
    string json;
    uint256 forkBlockNumber;

    modifier onlyFork() {
        if (bytes(forkEnv).length == 0) return;
        _;
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
