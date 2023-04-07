// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import {ForkManagement} from 'test/foundry/helpers/ForkManagement.sol';
import {CollectNFT} from 'contracts/CollectNFT.sol';
import {LensHub} from 'contracts/LensHub.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {TransparentUpgradeableProxy} from 'contracts/base/upgradeability/TransparentUpgradeableProxy.sol';
import {ModuleGlobals} from 'contracts/misc/ModuleGlobals.sol';
import {LensHandles} from 'contracts/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/namespaces/TokenHandleRegistry.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

contract MigrationsTest is Test, ForkManagement {
    using stdJson for string;

    uint256 internal constant LENS_PROTOCOL_PROFILE_ID = 1;
    uint256 internal constant ENUMERABLE_GET_FIRST_PROFILE = 0;

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

    uint256[] followerProfileIds = new uint256[](10);

    function loadBaseAddresses(string memory targetEnv) internal virtual {
        console.log('targetEnv:', targetEnv);

        hubProxyAddr = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy')));
        console.log('hubProxyAddr:', hubProxyAddr);

        hub = LensHub(hubProxyAddr);

        console.log('Hub:', address(hub));

        // address followNFTAddr = hub.getFollowNFTImpl();
        address collectNFTAddr = hub.getCollectNFTImpl();

        address hubImplAddr = address(uint160(uint256(vm.load(hubProxyAddr, PROXY_IMPLEMENTATION_STORAGE_SLOT))));
        console.log('Found hubImplAddr:', hubImplAddr);

        proxyAdmin = address(uint160(uint256(vm.load(hubProxyAddr, ADMIN_SLOT))));

        collectNFT = CollectNFT(collectNFTAddr);
        hubAsProxy = TransparentUpgradeableProxy(payable(address(hub)));
        moduleGlobals = ModuleGlobals(json.readAddress(string(abi.encodePacked('.', targetEnv, '.ModuleGlobals'))));

        governance = hub.getGovernance();
    }

    function setUp() public onlyFork {
        loadBaseAddresses(forkEnv);

        // Precompute needed addresses.
        address lensHandlesAddress = computeCreateAddress(deployer, 0);
        address tokenHandleRegistryAddress = computeCreateAddress(deployer, 1);

        console.log('lensHandlesAddress:', lensHandlesAddress);
        console.log('tokenHandleRegistryAddress:', tokenHandleRegistryAddress);

        vm.startPrank(deployer);

        lensHandles = new LensHandles(owner, address(hub));
        assertEq(address(lensHandles), lensHandlesAddress);

        tokenHandleRegistry = new TokenHandleRegistry(address(hub), lensHandlesAddress);
        assertEq(address(tokenHandleRegistry), tokenHandleRegistryAddress);

        followNFT = new FollowNFT(address(hub));

        // TODO: Last 3 addresses are for the follow modules for migration purposes.
        hubImpl = new LensHub({
            moduleGlobals: address(0),
            followNFTImpl: address(followNFT),
            collectNFTImpl: address(collectNFT),
            lensHandlesAddress: lensHandlesAddress,
            tokenHandleRegistryAddress: tokenHandleRegistryAddress,
            legacyFeeFollowModule: address(0),
            legacyProfileFollowModule: address(0),
            newFeeFollowModule: address(0)
        });

        vm.stopPrank();

        // TODO: This can be moved and split
        uint256 idOfProfileFollowed = 8;
        address followNFTAddress = hub.getFollowNFT(idOfProfileFollowed);
        for (uint256 i = 0; i < 10; i++) {
            uint256 followTokenId = i + 1;
            address followerOwner = IERC721(followNFTAddress).ownerOf(followTokenId);
            uint256 followerProfileId = IERC721Enumerable(address(hub)).tokenOfOwnerByIndex(
                followerOwner,
                ENUMERABLE_GET_FIRST_PROFILE
            );
            followerProfileIds[i] = followerProfileId;
        }

        // TODO: Upgrade can be moved to a separate function
        vm.prank(proxyAdmin);
        hubAsProxy.upgradeTo(address(hubImpl));
    }

    function testProfileMigration() public onlyFork {
        uint256[] memory profileIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            profileIds[i] = i + 1;
        }
        hub.batchMigrateProfiles(profileIds);
    }

    function testFollowMigration() public onlyFork {
        uint256 idOfProfileFollowed = 8;

        address followNFTAddress = hub.getFollowNFT(idOfProfileFollowed);

        uint256[] memory idsOfProfileFollowed = new uint256[](10);
        address[] memory followNFTAddresses = new address[](10);
        uint256[] memory followTokenIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            uint256 followTokenId = i + 1;

            idsOfProfileFollowed[i] = idOfProfileFollowed;
            followNFTAddresses[i] = followNFTAddress;
            followTokenIds[i] = followTokenId;
        }

        hub.batchMigrateFollows(followerProfileIds, idsOfProfileFollowed, followNFTAddresses, followTokenIds);
    }
}
