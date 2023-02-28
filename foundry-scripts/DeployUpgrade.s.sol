// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';
import 'forge-std/console2.sol';

import 'contracts/LensHub.sol';
import 'contracts/FollowNFT.sol';
import 'contracts/CollectNFT.sol';

/**
 * This script will deploy the current repository implementations, using the given environment
 * hub proxy address.
 */
contract DeployUpgradeScript is Script {
    function run() public {
        uint256 deployerKey = vm.envUint('DEPLOYER_KEY');
        address deployer = vm.addr(deployerKey);
        address hubProxyAddr = vm.envAddress('HUB_PROXY_ADDRESS');

        // Start deployments.
        vm.startBroadcast(deployerKey);

        // Precompute needed addresss.
        address followNFTAddr = computeCreateAddress(deployer, 1);
        address collectNFTAddr = computeCreateAddress(deployer, 2);

        // Deploy implementation contracts.
        address hubImpl = address(new LensHub(followNFTAddr, collectNFTAddr));
        address followNFT = address(new FollowNFT(hubProxyAddr));
        address collectNFT = address(new CollectNFT(hubProxyAddr));

        vm.writeFile('addrs', '');
        vm.writeLine('addrs', string(abi.encodePacked('hubImpl: ', vm.toString(hubImpl))));
        vm.writeLine('addrs', string(abi.encodePacked('followNFT: ', vm.toString(followNFT))));
        vm.writeLine('addrs', string(abi.encodePacked('collectNFT: ', vm.toString(collectNFT))));
    }
}
