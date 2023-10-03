// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';
import {LensHub as LegacyLensHub} from './../lib/core-private/contracts/core/LensHub.sol';
import {LensHub as LensHubV2} from 'contracts/LensHub.sol';
import {LensV2UpgradeContract} from 'contracts/misc/LensV2UpgradeContract.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {LensHandles} from 'contracts/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/namespaces/TokenHandleRegistry.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {FeeFollowModule} from 'contracts/modules/follow/FeeFollowModule.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {LensV2UpgradeContract} from 'contracts/misc/LensV2UpgradeContract.sol';
import {ProxyAdmin} from 'contracts/misc/access/ProxyAdmin.sol';
import {ModuleRegistry} from 'contracts/misc/ModuleRegistry.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {LibString} from 'solady/utils/LibString.sol';

import {ArrayHelpers} from 'test/helpers/ArrayHelpers.sol';

contract LensV2UpgradeDeployment is Script, ForkManagement, ArrayHelpers {
    using stdJson for string;

    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    uint256 constant PROFILE_GUARDIAN_COOLDOWN = 7 days;
    uint256 constant HANDLE_GUARDIAN_COOLDOWN = 0;

    string mnemonic;

    // TODO: move this somewhere common
    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    address lensHub;
    LegacyLensHub legacyLensHub;
    address legacyLensHubImpl;
    address lensHubV2Impl;

    address followNFTImpl;
    address legacyCollectNFTImpl;
    address lensHandlesImpl;
    address lensHandles;
    address tokenHandleRegistryImpl;
    address tokenHandleRegistry;
    address legacyFeeFollowModule;
    address legacyProfileFollowModule;
    address feeFollowModule;
    address moduleRegistry;

    LensAccount _deployer;
    address governance;
    address proxyAdmin;
    address migrationAdmin;

    ProxyAdmin proxyAdminContract;

    function loadBaseAddresses() internal override {
        lensHub = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy')));
        legacyLensHub = LegacyLensHub(lensHub);
        vm.label(lensHub, 'LensHub');
        console.log('Lens Hub Proxy: %s', address(legacyLensHub));

        legacyLensHubImpl = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubImplementation')));
        vm.label(legacyLensHubImpl, 'LensHubImplementation');
        console.log('Legacy Lens Hub Impl: %s', address(legacyLensHubImpl));

        Module[] memory followModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', targetEnv, '.Modules.v1.follow'))),
            (Module[])
        );

        legacyFeeFollowModule = findModuleHelper(followModules, 'FeeFollowModule').addy;
        vm.label(legacyFeeFollowModule, 'LegacyFeeFollowModule');
        console.log('Legacy Fee Follow Module: %s', legacyFeeFollowModule);

        legacyProfileFollowModule = findModuleHelper(followModules, 'ProfileFollowModule').addy;
        vm.label(legacyProfileFollowModule, 'LegacyProfileFollowModule');
        console.log('Legacy Profile Follow Module: %s', legacyProfileFollowModule);

        proxyAdmin = address(uint160(uint256(vm.load(lensHub, ADMIN_SLOT))));
        vm.label(proxyAdmin, 'ProxyAdmin');
        console.log('Proxy Admin: %s', proxyAdmin);

        migrationAdmin = proxyAdmin;
        // TODO: change this to the real migration admin
        // json.readAddress(string(abi.encodePacked('.', targetEnv, '.MigrationAdmin')));
        vm.label(migrationAdmin, 'MigrationAdmin');
        console.log('Migration Admin: %s', migrationAdmin);
    }

    function loadPrivateKeys() internal {
        if (isEnvSet('MNEMONIC')) {
            mnemonic = vm.envString('MNEMONIC');
        }

        if (bytes(mnemonic).length == 0) {
            revert('Missing mnemonic');
        }

        (_deployer.owner, _deployer.ownerPk) = deriveRememberKey(mnemonic, 0);
        console.log('Deployer: %s', _deployer.owner);

        console.log('Current block:', block.number);
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadBaseAddresses();
        loadPrivateKeys();

        governance = legacyLensHub.getGovernance();
        vm.label(governance, 'Governance');
        console.log('Governance: %s', governance);

        deploy();
    }

    function deploy() internal {
        string memory addressesFile = 'addressesV2.txt';

        console.log('Address this:', address(this));

        // Get Legacy CollectNFTImpl address
        legacyCollectNFTImpl = legacyLensHub.getCollectNFTImpl();
        vm.label(legacyCollectNFTImpl, 'LegacyCollectNFTImpl');
        console.log('Legacy CollectNFTImpl: %s', legacyCollectNFTImpl);

        // Who should be the owner of LensHandles? Setting it for LensHub governance
        address lensHandlesOwner = legacyLensHub.getGovernance();
        vm.label(lensHandlesOwner, 'LensHandlesOwner');
        console.log('LensHandlesOwner: %s', lensHandlesOwner);

        ///////Broadcasting transactions///////
        vm.startBroadcast(_deployer.ownerPk);

        // Deploy FollowNFTImpl(hub)
        followNFTImpl = address(new FollowNFT(lensHub));
        vm.writeLine(addressesFile, string.concat('FollowNFTImpl: ', vm.toString(followNFTImpl)));
        console.log('FollowNFTImpl: %s', followNFTImpl);

        // Deploy LensHandles(owner, hub) implementation
        lensHandlesImpl = address(new LensHandles(lensHandlesOwner, lensHub, HANDLE_GUARDIAN_COOLDOWN));
        vm.writeLine(addressesFile, string.concat('LensHandlesImpl: ', vm.toString(lensHandlesImpl)));
        console.log('LensHandlesImpl: %s', lensHandlesImpl);

        // Make LensHandles a transparentUpgradeableProxy
        lensHandles = address(new TransparentUpgradeableProxy(lensHandlesImpl, proxyAdmin, ''));
        vm.writeLine(addressesFile, string.concat('LensHandles: ', vm.toString(lensHandles)));
        console.log('LensHandles: %s', lensHandles);

        // Deploy TokenHandleRegistry(hub, lensHandles) implementation
        tokenHandleRegistryImpl = address(new TokenHandleRegistry(lensHub, lensHandles));
        vm.writeLine(addressesFile, string.concat('TokenHandleRegistryImpl: ', vm.toString(tokenHandleRegistryImpl)));
        console.log('TokenHandleRegistryImpl: %s', tokenHandleRegistryImpl);

        // Make TokenHandleRegistry a transparentUpgradeableProxy
        tokenHandleRegistry = address(new TransparentUpgradeableProxy(tokenHandleRegistryImpl, proxyAdmin, ''));
        vm.writeLine(addressesFile, string.concat('TokenHandleRegistry: ', vm.toString(tokenHandleRegistry)));
        console.log('TokenHandleRegistry: %s', tokenHandleRegistry);

        // Deploy ModuleRegistry
        moduleRegistry = address(new ModuleRegistry());
        vm.writeLine(addressesFile, string.concat('ModuleRegistry: ', vm.toString(moduleRegistry)));
        console.log('ModuleRegistry: %s', moduleRegistry);

        console.log('PROFILE_GUARDIAN_COOLDOWN: %s', PROFILE_GUARDIAN_COOLDOWN);

        // Deploy new FeeFollowModule(hub, moduleGlobals)
        feeFollowModule = address(new FeeFollowModule(lensHub, moduleRegistry));
        vm.writeLine(addressesFile, string.concat('FeeFollowModule: ', vm.toString(feeFollowModule)));
        console.log('FeeFollowModule: %s', feeFollowModule);

        // Pass all the fucking shit and deploy LensHub V2 Impl with:
        lensHubV2Impl = address(
            new LensHubV2(
                followNFTImpl,
                legacyCollectNFTImpl,
                moduleRegistry,
                PROFILE_GUARDIAN_COOLDOWN,
                Types.MigrationParams({
                    lensHandlesAddress: lensHandles,
                    tokenHandleRegistryAddress: tokenHandleRegistry,
                    legacyFeeFollowModule: legacyFeeFollowModule,
                    legacyProfileFollowModule: legacyProfileFollowModule,
                    newFeeFollowModule: feeFollowModule,
                    migrationAdmin: migrationAdmin
                })
            )
        );
        vm.writeLine(addressesFile, string.concat('LensHubV2Impl: ', vm.toString(lensHubV2Impl)));
        console.log('LensHubV2Impl: %s', lensHubV2Impl);

        Governance governanceContract = new Governance(address(legacyLensHub), governance);
        vm.writeLine(addressesFile, string.concat('GovernanceContract: ', vm.toString(address(governanceContract))));
        console.log('GovernanceContract: %s', address(governanceContract));

        proxyAdminContract = new ProxyAdmin(address(legacyLensHub), legacyLensHubImpl, proxyAdmin);
        vm.writeLine(addressesFile, string.concat('ProxyAdminContract: ', vm.toString(address(proxyAdminContract))));
        console.log('ProxyAdminContract: %s', address(proxyAdminContract));

        address lensV2UpgradeContract = address(
            new LensV2UpgradeContract({
                proxyAdminAddress: address(proxyAdminContract),
                governanceAddress: address(governanceContract),
                owner: governance,
                lensHub: address(legacyLensHub),
                newImplementationAddress: lensHubV2Impl
            })
        );
        vm.writeLine(addressesFile, string.concat('LensV2UpgradeContract: ', vm.toString(lensV2UpgradeContract)));
        console.log('LensV2UpgradeContract: %s', lensV2UpgradeContract);

        vm.stopBroadcast();
    }

    // TODO: Use from test/ContractAddresses
    struct Module {
        address addy;
        string name;
    }

    // TODO: Move this somewhere common (also in UpgradeForkTest)
    function findModuleHelper(
        Module[] memory modules,
        string memory moduleNameToFind
    ) internal pure returns (Module memory) {
        for (uint256 i = 0; i < modules.length; i++) {
            if (LibString.eq(modules[i].name, moduleNameToFind)) {
                return modules[i];
            }
        }
        revert('Module not found');
    }
}
