// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';
import {ILensGovernable} from 'contracts/interfaces/ILensGovernable.sol';
import {LensHubInitializable} from 'contracts/misc/LensHubInitializable.sol';
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
import {LegacyCollectNFT} from 'contracts/misc/LegacyCollectNFT.sol';

import {ArrayHelpers} from 'script/helpers/ArrayHelpers.sol';

contract A_DeployLensV2Upgrade is Script, ForkManagement, ArrayHelpers {
    // add this to be excluded from coverage report
    function testLensV2UpgradeDeployment() public {}

    using stdJson for string;

    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    bytes32 constant PROXY_IMPLEMENTATION_STORAGE_SLOT =
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);

    uint256 internal PROFILE_GUARDIAN_COOLDOWN;
    uint256 internal HANDLE_GUARDIAN_COOLDOWN;

    string mnemonic;

    // TODO: move this somewhere common
    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    address lensHub;
    ILensGovernable legacyLensHub; // We just need the `getGovernance` function
    address legacyLensHubImpl;
    address lensHubV2Impl;

    ILensGovernable moduleGlobals; // We use `getTreasury` and `getTreasuryFee` functions

    address followNFTImpl;
    address legacyCollectNFTImpl;
    address lensHandlesImpl;
    address lensHandles;
    address tokenHandleRegistryImpl;
    address tokenHandleRegistry;
    address legacyFeeFollowModule;
    address legacyProfileFollowModule;
    address feeFollowModule;
    address moduleRegistryImpl;
    address moduleRegistry;

    LensAccount _deployer;
    LensAccount _proxyAdmin;
    LensAccount _governance;
    LensAccount _treasury;

    address treasury;
    address governance;
    address proxyAdmin;
    address lensHandlesOwner;

    uint16 treasuryFee;

    ProxyAdmin proxyAdminContract;

    function loadBaseAddresses() internal override {
        lensHub = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy')));
        legacyLensHub = ILensGovernable(lensHub);
        vm.label(lensHub, 'LensHub');
        console.log('Lens Hub Proxy: %s', address(legacyLensHub));

        legacyLensHubImpl = address(uint160(uint256(vm.load(lensHub, PROXY_IMPLEMENTATION_STORAGE_SLOT))));
        vm.label(legacyLensHubImpl, 'LensHubImplementation');
        console.log('Legacy Lens Hub Impl: %s', address(legacyLensHubImpl));

        moduleGlobals = ILensGovernable(json.readAddress(string(abi.encodePacked('.', targetEnv, '.ModuleGlobals'))));
        vm.label(address(moduleGlobals), 'ModuleGlobals');
        console.log('ModuleGlobals: %s', address(moduleGlobals));

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

        console.log('\n');

        if (isEnvSet('DEPLOYMENT_ENVIRONMENT')) {
            if (LibString.eq(vm.envString('DEPLOYMENT_ENVIRONMENT'), 'production')) {} else {
                console.log('DEPLOYMENT_ENVIRONMENT is not production');
                revert();
            }
            console.log('DEPLOYMENT_ENVIRONMENT is production');
            console.log('Using governance and proxy admin from the LensHub to set as admins of contracts:');
            governance = legacyLensHub.getGovernance();
            console.log('\tReal Governance: %s', governance);

            proxyAdmin = address(uint160(uint256(vm.load(lensHub, ADMIN_SLOT))));
            console.log('\tReal ProxyAdmin: %s', proxyAdmin);

            treasury = moduleGlobals.getTreasury();
            console.log('\tReal Treasury: %s', treasury);

            treasuryFee = moduleGlobals.getTreasuryFee();
            console.log('\tReal Treasury Fee: %s', treasuryFee);
        } else {
            console.log('Using governance and proxy admin from test mnemonic:');

            (_governance.owner, _governance.ownerPk) = deriveRememberKey(mnemonic, 1);
            console.log('\tMock Governance: %s', _governance.owner);
            governance = _governance.owner;

            (_proxyAdmin.owner, _proxyAdmin.ownerPk) = deriveRememberKey(mnemonic, 2);
            console.log('\tMock ProxyAdmin: %s', _proxyAdmin.owner);
            proxyAdmin = _proxyAdmin.owner;

            (_treasury.owner, _treasury.ownerPk) = deriveRememberKey(mnemonic, 3);
            console.log('\tMock Treasury: %s', _treasury.owner);
            treasury = _treasury.owner;

            treasuryFee = 50;
            console.log('\tMock Treasury Fee: %s', treasuryFee);
        }
        console.log('\n');

        vm.label(proxyAdmin, 'ProxyAdmin');

        vm.label(governance, 'Governance');

        vm.label(treasury, 'Treasury');

        saveContractAddress('Treasury', treasury);
        saveValue('TreasuryFee', vm.toString(treasuryFee));

        PROFILE_GUARDIAN_COOLDOWN = json.readUint(
            string(abi.encodePacked('.', targetEnv, '.LensProfilesGuardianTimelock'))
        );
        console.log('PROFILE_GUARDIAN_COOLDOWN: %s', PROFILE_GUARDIAN_COOLDOWN);

        HANDLE_GUARDIAN_COOLDOWN = json.readUint(
            string(abi.encodePacked('.', targetEnv, '.LensHandlesGuardianTimelock'))
        );
        console.log('HANDLE_GUARDIAN_COOLDOWN: %s', HANDLE_GUARDIAN_COOLDOWN);

        lensHandlesOwner = legacyLensHub.getGovernance();
        vm.label(lensHandlesOwner, 'LensHandlesOwner');
        console.log('LensHandlesOwner: %s', lensHandlesOwner);

        console.log('Address this:', address(this));
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

    function saveContractAddress(string memory contractName, address deployedAddress) internal {
        // console.log('Saving %s (%s) into addresses under %s environment', contractName, deployedAddress, targetEnv);
        string[] memory inputs = new string[](5);
        inputs[0] = 'node';
        inputs[1] = 'script/helpers/saveAddress.js';
        inputs[2] = targetEnv;
        inputs[3] = contractName;
        inputs[4] = vm.toString(deployedAddress);
        // bytes memory res =
        vm.ffi(inputs);
        // string memory output = abi.decode(res, (string));
        // console.log(output);
    }

    function saveValue(string memory contractName, string memory str) internal {
        // console.log('Saving %s (%s) into addresses under %s environment', contractName, deployedAddress, targetEnv);
        string[] memory inputs = new string[](5);
        inputs[0] = 'node';
        inputs[1] = 'script/helpers/saveAddress.js';
        inputs[2] = targetEnv;
        inputs[3] = contractName;
        inputs[4] = str;
        // bytes memory res =
        vm.ffi(inputs);
        // string memory output = abi.decode(res, (string));
        // console.log(output);
    }

    function deploy() internal {
        string memory addressesFile = 'addressesV2.txt';

        ///////Broadcasting transactions///////
        vm.startBroadcast(_deployer.ownerPk);

        // Deploy LegacyCollectNFTImpl
        legacyCollectNFTImpl = address(new LegacyCollectNFT(lensHub));
        vm.label(legacyCollectNFTImpl, 'LegacyCollectNFTImpl');
        saveContractAddress('LegacyCollectNFTImpl', legacyCollectNFTImpl);
        console.log('Legacy CollectNFTImpl: %s', legacyCollectNFTImpl);

        // Deploy FollowNFTImpl(hub)
        followNFTImpl = address(new FollowNFT(lensHub));
        vm.writeLine(addressesFile, string.concat('FollowNFTImpl: ', vm.toString(followNFTImpl)));
        saveContractAddress('FollowNFTImpl', followNFTImpl);
        console.log('FollowNFTImpl: %s', followNFTImpl);

        // Deploy LensHandles(owner, hub) implementation
        lensHandlesImpl = address(new LensHandles(lensHandlesOwner, lensHub, HANDLE_GUARDIAN_COOLDOWN));
        vm.writeLine(addressesFile, string.concat('LensHandlesImpl: ', vm.toString(lensHandlesImpl)));
        saveContractAddress('LensHandlesImpl', lensHandlesImpl);
        console.log('LensHandlesImpl: %s', lensHandlesImpl);

        // Make LensHandles a transparentUpgradeableProxy
        lensHandles = address(new TransparentUpgradeableProxy(lensHandlesImpl, proxyAdmin, ''));
        vm.writeLine(addressesFile, string.concat('LensHandles: ', vm.toString(lensHandles)));
        saveContractAddress('LensHandles', lensHandles);
        console.log('LensHandles: %s', lensHandles);

        // Deploy TokenHandleRegistry(hub, lensHandles) implementation
        tokenHandleRegistryImpl = address(new TokenHandleRegistry(lensHub, lensHandles));
        vm.writeLine(addressesFile, string.concat('TokenHandleRegistryImpl: ', vm.toString(tokenHandleRegistryImpl)));
        saveContractAddress('TokenHandleRegistryImpl', tokenHandleRegistryImpl);
        console.log('TokenHandleRegistryImpl: %s', tokenHandleRegistryImpl);

        // Make TokenHandleRegistry a transparentUpgradeableProxy
        tokenHandleRegistry = address(new TransparentUpgradeableProxy(tokenHandleRegistryImpl, proxyAdmin, ''));
        vm.writeLine(addressesFile, string.concat('TokenHandleRegistry: ', vm.toString(tokenHandleRegistry)));
        saveContractAddress('TokenHandleRegistry', tokenHandleRegistry);
        console.log('TokenHandleRegistry: %s', tokenHandleRegistry);

        // Deploy ModuleRegistry
        moduleRegistryImpl = address(new ModuleRegistry());
        vm.writeLine(addressesFile, string.concat('ModuleRegistryImpl: ', vm.toString(moduleRegistryImpl)));
        saveContractAddress('ModuleRegistryImpl', moduleRegistryImpl);
        console.log('ModuleRegistryImpl: %s', moduleRegistryImpl);

        // Make ModuleRegistry a transparentUpgradeableProxy
        moduleRegistry = address(new TransparentUpgradeableProxy(moduleRegistryImpl, proxyAdmin, ''));
        vm.writeLine(addressesFile, string.concat('ModuleRegistry: ', vm.toString(moduleRegistry)));
        saveContractAddress('ModuleRegistry', moduleRegistry);
        console.log('ModuleRegistry: %s', moduleRegistry);

        console.log('PROFILE_GUARDIAN_COOLDOWN: %s', PROFILE_GUARDIAN_COOLDOWN);

        if (governance != address(0)) {
            console.log('Governance is set');
            revert('Governance is not set');
        }

        // Deploy new FeeFollowModule(hub, moduleRegistry)
        feeFollowModule = address(new FeeFollowModule(lensHub, moduleRegistry, governance));
        vm.writeLine(addressesFile, string.concat('FeeFollowModule: ', vm.toString(feeFollowModule)));
        saveModule('FeeFollowModule', address(feeFollowModule), 'v2', 'follow');
        console.log('FeeFollowModule: %s', feeFollowModule);

        // Pass all the fucking shit and deploy LensHub V2 Impl with:
        lensHubV2Impl = address(
            new LensHubInitializable(
                followNFTImpl,
                legacyCollectNFTImpl,
                moduleRegistry,
                PROFILE_GUARDIAN_COOLDOWN,
                Types.MigrationParams({
                    lensHandlesAddress: lensHandles,
                    tokenHandleRegistryAddress: tokenHandleRegistry,
                    legacyFeeFollowModule: legacyFeeFollowModule,
                    legacyProfileFollowModule: legacyProfileFollowModule,
                    newFeeFollowModule: feeFollowModule
                })
            )
        );

        //   "arguments": [
        //     "0x072E491679Ed6f4fF4d419Ba909D5789116f2182",
        //     "0x0000000000000000000000000000000000000000",
        //     "0x36a6aDc2cE99F3b3dcEDe8508Be7A6aCC61B5655",
        //     "300",
        //     "(0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000)"
        //   ],
        console.log('"arguments": [');
        console.log('\t"%s"', followNFTImpl);
        console.log('\t"%s"', legacyCollectNFTImpl);
        console.log('\t"%s"', moduleRegistry);
        console.log('\t"%s"', PROFILE_GUARDIAN_COOLDOWN);
        console.log(
            '\t"%s"',
            string.concat(
                '(',
                vm.toString(lensHandles),
                ', ',
                vm.toString(tokenHandleRegistry),
                ', ',
                vm.toString(legacyFeeFollowModule),
                ', ',
                vm.toString(legacyProfileFollowModule),
                ', ',
                vm.toString(feeFollowModule),
                ')'
            )
        );
        console.log(']');

        vm.writeLine(addressesFile, string.concat('LensHubV2Impl: ', vm.toString(lensHubV2Impl)));
        saveContractAddress('LensHubV2Impl', lensHubV2Impl);
        console.log('LensHubV2Impl: %s', lensHubV2Impl);

        Governance governanceContract = new Governance(address(legacyLensHub), governance);
        vm.writeLine(addressesFile, string.concat('GovernanceContract: ', vm.toString(address(governanceContract))));
        saveContractAddress('GovernanceContract', address(governanceContract));
        console.log('GovernanceContract: %s', address(governanceContract));
        saveContractAddress('GovernanceContractAdmin', governance);

        proxyAdminContract = new ProxyAdmin(address(legacyLensHub), legacyLensHubImpl, proxyAdmin);
        vm.writeLine(addressesFile, string.concat('ProxyAdminContract: ', vm.toString(address(proxyAdminContract))));
        saveContractAddress('ProxyAdminContract', address(proxyAdminContract));
        saveContractAddress('ProxyAdminContractAdmin', proxyAdmin);
        console.log('ProxyAdminContract: %s', address(proxyAdminContract));

        address lensV2UpgradeContract = address(
            new LensV2UpgradeContract({
                proxyAdminAddress: address(proxyAdminContract),
                governanceAddress: address(governanceContract),
                owner: proxyAdmin,
                lensHub: address(legacyLensHub),
                newImplementationAddress: lensHubV2Impl,
                treasury: treasury,
                treasuryFee: treasuryFee
            })
        );

        vm.writeLine(addressesFile, string.concat('LensV2UpgradeContract: ', vm.toString(lensV2UpgradeContract)));
        saveContractAddress('LensV2UpgradeContract', lensV2UpgradeContract);
        console.log('LensV2UpgradeContract: %s', lensV2UpgradeContract);
        console.log('"arguments": [');
        console.log('\t"%s"', address(proxyAdminContract));
        console.log('\t"%s"', address(governanceContract));
        console.log('\t"%s"', governance);
        console.log('\t"%s"', address(legacyLensHub));
        console.log('\t"%s"', lensHubV2Impl);
        console.log('\t"%s"', treasury);
        console.log('\t"%s"', treasuryFee);
        console.log(']');

        console.log('\n');
        console.log('After running this script - change LensHub proxy admin and governance to:');
        console.log(
            'From: %s -> To: Governance contract: %s',
            legacyLensHub.getGovernance(),
            address(governanceContract)
        );
        console.log(
            'From: %s -> To: ProxyAdmin contract: %s',
            address(uint160(uint256(vm.load(lensHub, ADMIN_SLOT)))),
            address(proxyAdminContract)
        );
        console.log('\n');

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

    function saveModule(
        string memory moduleName,
        address moduleAddress,
        string memory lensVersion,
        string memory moduleType
    ) internal {
        // console.log('Saving %s (%s) into addresses under %s environment', moduleName, moduleAddress, targetEnv);
        string[] memory inputs = new string[](7);
        inputs[0] = 'node';
        inputs[1] = 'script/helpers/saveAddress.js';
        inputs[2] = targetEnv;
        inputs[3] = moduleName;
        inputs[4] = vm.toString(moduleAddress);
        inputs[5] = lensVersion;
        inputs[6] = moduleType;
        // bytes memory res =
        vm.ffi(inputs);
        // string memory output = abi.decode(res, (string));
        // console.log(output);
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadPrivateKeys();
        loadBaseAddresses();

        deploy();
    }
}
