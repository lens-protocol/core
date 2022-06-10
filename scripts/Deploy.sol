// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Helper} from '../contracts/mocks/Helper.sol';
import {ModuleGlobals} from '../contracts/core/modules/ModuleGlobals.sol';

import {Script} from 'forge-std/Script.sol';

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        Helper helper = new Helper();
        ModuleGlobals moduleGlobals = new ModuleGlobals();

        vm.stopBroadcast();
    }
}
