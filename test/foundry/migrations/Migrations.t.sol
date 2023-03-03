// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import {ForkManagement} from 'test/foundry/helpers/ForkManagement.sol';
import {CollectNFT} from 'contracts/CollectNFT.sol';
import {LensHub} from 'contracts/LensHub.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {TransparentUpgradeableProxy} from 'contracts/base/upgradeability/TransparentUpgradeableProxy.sol';
import {ModuleGlobals} from 'contracts/misc/ModuleGlobals.sol';
import {LensHandles} from 'contracts/misc/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/misc/namespaces/TokenHandleRegistry.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

contract MigrationsTest is Test, ForkManagement {
    using stdJson for string;

    uint256 internal constant LENS_PROTOCOL_PROFILE_ID = 1;

    bytes32 constant PROXY_IMPLEMENTATION_STORAGE_SLOT =
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);

    address owner = address(0x087E4);
    address deployer = address(1);
    address governance;
    address treasury;
    address hubProxyAddr;
    address proxyAdmin;

    LensHandles lensHandles;
    TokenHandleRegistry tokenHandleRegistry;

    CollectNFT collectNFT;
    FollowNFT followNFT;
    LensHub hubImpl;
    TransparentUpgradeableProxy hubAsProxy;
    LensHub hub;
    ModuleGlobals moduleGlobals;

    function loadBaseAddresses(string memory targetEnv) internal virtual {
        console.log('targetEnv:', targetEnv);

        hubProxyAddr = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy')));
        console.log('hubProxyAddr:', hubProxyAddr);

        hub = LensHub(hubProxyAddr);

        console.log('Hub:', address(hub));

        address followNFTAddr = hub.getFollowNFTImpl();
        address collectNFTAddr = hub.getCollectNFTImpl();

        address hubImplAddr = address(uint160(uint256(vm.load(hubProxyAddr, PROXY_IMPLEMENTATION_STORAGE_SLOT))));
        console.log('Found hubImplAddr:', hubImplAddr);

        proxyAdmin = address(uint160(uint256(vm.load(hubProxyAddr, ADMIN_SLOT))));

        followNFT = FollowNFT(followNFTAddr);
        collectNFT = CollectNFT(collectNFTAddr);
        hubAsProxy = TransparentUpgradeableProxy(payable(address(hub)));
        moduleGlobals = ModuleGlobals(json.readAddress(string(abi.encodePacked('.', targetEnv, '.ModuleGlobals'))));

        governance = hub.getGovernance();
    }

    function setUp() public onlyFork {
        loadBaseAddresses(forkEnv);

        // Precompute needed addresss.
        address lensHandlesAddress = computeCreateAddress(deployer, 0);
        address tokenHandleRegistryAddress = computeCreateAddress(deployer, 1);

        vm.startPrank(deployer);

        lensHandles = new LensHandles(owner, address(hub));
        assertEq(address(lensHandles), lensHandlesAddress);

        tokenHandleRegistry = new TokenHandleRegistry(address(hub), lensHandlesAddress);
        assertEq(address(tokenHandleRegistry), tokenHandleRegistryAddress);

        hubImpl = new LensHub(address(followNFT), address(collectNFT), lensHandlesAddress, tokenHandleRegistryAddress);
        vm.stopPrank();

        vm.prank(proxyAdmin);
        hubAsProxy.upgradeTo(address(hubImpl));
    }

    function testMigrationsPublic() public onlyFork {
        uint256[] memory profileIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            profileIds[i] = i + 1;
        }
        hub.batchMigrateProfiles(profileIds);
    }
}
