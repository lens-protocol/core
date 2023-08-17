// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import 'forge-std/Script.sol';

contract KeyExists is Script {
    // TODO: Move somewhere else
    // TODO: Replace with forge-std/StdJson.sol::keyExists(...) when/if this PR is approved:
    //       https://github.com/foundry-rs/forge-std/pull/226
    function keyExists(string memory json, string memory key) public returns (bool) {
        try vm.parseJsonString(json, key) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }
}
