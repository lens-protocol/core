// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ModuleGlobals} from '../contracts/core/modules/ModuleGlobals.sol';

import 'forge-std/Script.sol';

contract Deploy is Script {
    uint16 constant TREASURY_FEE_BPS = 50;

    // TODO: Replace with loading in addresses from mnemonic?
    address immutable user = vm.addr(1);
    address immutable userTwo = vm.addr(2);
    address immutable userThree = vm.addr(3);
    address immutable governance = vm.addr(4);
    address immutable treasury = vm.addr(5);

    function run() external {
        vm.startBroadcast();

        ModuleGlobals moduleGlobals = new ModuleGlobals(governance, treasury, TREASURY_FEE_BPS);

        uint256 deployerNonce = vm.getNonce(msg.sender);

        uint256 followNFTNonce = deployerNonce + 1;
        uint256 collectNFTNonce = deployerNonce + 2;
        uint256 hubProxyNonce = deployerNonce + 3;

    //      address followNFTImplAddress = address(
    // keccak256(RLP.encode([deployer.address, followNFTNonce])).substr(26)
    // );

        vm.stopBroadcast();
    }
}
