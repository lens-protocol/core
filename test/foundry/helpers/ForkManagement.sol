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

    function loadJson() internal returns (string memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, '/addresses.json');
        string memory json = vm.readFile(path);
        return json;
    }

    function checkNetworkParams(string memory json, string memory targetEnv)
        internal
        returns (string memory network, uint256 chainId)
    {
        network = json.readString(string.concat('.', targetEnv, '.network'));
        chainId = json.readUint(string.concat('.', targetEnv, '.chainId'));

        console.log('\nTarget environment:', targetEnv);
        console.log('Network:', network);
        if (block.chainid != chainId) revert('Wrong chainId');
        console.log('ChainId:', chainId);
    }

    function getNetwork(string memory json, string memory targetEnv)
        internal
        returns (string memory)
    {
        return json.readString(string.concat('.', targetEnv, '.network'));
    }
}
