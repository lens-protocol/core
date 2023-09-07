pragma solidity ^0.8.13;

import 'forge-std/Script.sol';
import 'forge-std/console2.sol';

import 'contracts/LensHub.sol';
import 'contracts/FollowNFT.sol';
import 'contracts/modules/act/collect/CollectNFT.sol';

import 'contracts/misc/migrations/ProfileMigration.sol';
import {LensHandles} from 'contracts/misc/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/misc/namespaces/TokenHandleRegistry.sol';

/**
 * This script will deploy the current repository implementations, using the given environment
 * hub proxy address.
 */
contract DeployUpgradeScript is Script {
    function run() public {
        string memory deployerMnemonic = vm.envString('MNEMONIC');
        uint256 deployerKey = vm.deriveKey(deployerMnemonic, 0);
        address deployer = vm.addr(deployerKey);
        address hubProxyAddr = vm.envAddress('HUB_PROXY_ADDRESS');

        address owner = deployer;

        LensHub hub = LensHub(hubProxyAddr);
        address followNFTAddress = hub.getFollowNFTImpl();
        address collectNFTAddress = hub.getLegacyCollectNFTImpl();

        uint256 deployerNonce = vm.getNonce(deployer);

        // Precompute needed addresss.
        address lensHandlesAddress = computeCreateAddress(deployer, deployerNonce);
        address migratorAddress = computeCreateAddress(deployer, deployerNonce + 1);
        address tokenHandleRegistryAddress = computeCreateAddress(deployer, deployerNonce + 2);

        // Start deployments.
        vm.startBroadcast(deployerKey);

        LensHandles lensHandles = new LensHandles(owner, address(hub), migratorAddress);
        console.log(address(lensHandles), lensHandlesAddress);

        ProfileMigration migrator = new ProfileMigration(
            owner,
            address(hub),
            lensHandlesAddress,
            tokenHandleRegistryAddress
        );
        console.log(address(migrator), migratorAddress);

        TokenHandleRegistry tokenHandleRegistry = new TokenHandleRegistry(
            address(hub),
            lensHandlesAddress,
            migratorAddress
        );
        console.log(address(tokenHandleRegistry), tokenHandleRegistryAddress);

        address hubImpl = address(
            new LensHub(
                followNFTAddress,
                collectNFTAddress,
                migratorAddress,
                lensHandlesAddress,
                tokenHandleRegistryAddress
            )
        );
        console.log('New hub impl:', hubImpl);
        vm.stopBroadcast();
    }
}
