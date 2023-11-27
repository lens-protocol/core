// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';
import {LibString} from 'solady/utils/LibString.sol';
import {LensHubInitializable} from 'contracts/misc/LensHubInitializable.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {LensHandles} from 'contracts/namespaces/LensHandles.sol';

contract DeployLegacyCollectFix is Script, ForkManagement {
    using stdJson for string;

    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    LensAccount _deployer;

    string mnemonic;

    uint256 internal PROFILE_GUARDIAN_COOLDOWN;
    uint256 internal HANDLE_GUARDIAN_COOLDOWN;

    address lensHub;
    address legacyCollectNFTImpl;
    address followNFTImpl;
    address moduleRegistry;

    address lensHandlesAddress;
    address tokenHandleRegistryAddress;
    address legacyFeeFollowModule;
    address legacyProfileFollowModule;
    address newFeeFollowModule;
    address lensHandlesOwner;
    address lensHandlesImpl;

    address governanceContract;
    address governanceAdmin;
    address lensHubV2Impl;

    string addressesFile = 'addressesV2.txt';

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

    function loadPrivateKeys() internal {
        if (isEnvSet('MNEMONIC')) {
            mnemonic = vm.envString('MNEMONIC');
        }

        if (bytes(mnemonic).length == 0) {
            revert('Missing mnemonic');
        }

        console.log('\n');

        (_deployer.owner, _deployer.ownerPk) = deriveRememberKey(mnemonic, 0);
        console.logBytes32(bytes32(_deployer.ownerPk));
        console.log('Deployer address: %s', address(_deployer.owner));

        console.log('\n');

        console.log('Current block:', block.number);
    }

    function loadBaseAddresses() internal override {
        lensHub = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy')));
        vm.label(lensHub, 'LensHub');
        console.log('Lens Hub Proxy: %s', lensHub);

        followNFTImpl = json.readAddress(string(abi.encodePacked('.', targetEnv, '.FollowNFTImpl')));
        vm.label(followNFTImpl, 'FollowNFTImpl');
        console.log('FollowNFTImpl: %s', followNFTImpl);

        legacyCollectNFTImpl = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LegacyCollectNFTImpl')));
        vm.label(legacyCollectNFTImpl, 'LegacyCollectNFTImpl');
        console.log('LegacyCollectNFTImpl: %s', legacyCollectNFTImpl);

        moduleRegistry = json.readAddress(string(abi.encodePacked('.', targetEnv, '.ModuleRegistry')));
        vm.label(moduleRegistry, 'ModuleRegistry');
        console.log('ModuleRegistry: %s', moduleRegistry);

        PROFILE_GUARDIAN_COOLDOWN = json.readUint(
            string(abi.encodePacked('.', targetEnv, '.LensProfilesGuardianTimelock'))
        );
        console.log('PROFILE_GUARDIAN_COOLDOWN: %s', PROFILE_GUARDIAN_COOLDOWN);

        HANDLE_GUARDIAN_COOLDOWN = json.readUint(
            string(abi.encodePacked('.', targetEnv, '.LensHandlesGuardianTimelock'))
        );
        console.log('HANDLE_GUARDIAN_COOLDOWN: %s', HANDLE_GUARDIAN_COOLDOWN);

        lensHandlesAddress = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHandles')));

        tokenHandleRegistryAddress = json.readAddress(string(abi.encodePacked('.', targetEnv, '.TokenHandleRegistry')));

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

        followModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', targetEnv, '.Modules.v2.follow'))),
            (Module[])
        );

        newFeeFollowModule = findModuleHelper(followModules, 'FeeFollowModule').addy;
        vm.label(newFeeFollowModule, 'NewFeeFollowModule');
        console.log('New Fee Follow Module: %s', newFeeFollowModule);

        governanceContract = LensHubInitializable(lensHub).getGovernance();
        governanceAdmin = Governance(governanceContract).owner();

        lensHandlesOwner = governanceAdmin;
        vm.label(lensHandlesOwner, 'LensHandlesOwner');
        console.log('LensHandlesOwner: %s', lensHandlesOwner);
    }

    function deploy() internal {
        if (lensHub == address(0)) {
            console.log('LensHub not set');
            revert('LensHub not set');
        }

        if (lensHandlesOwner == address(0)) {
            console.log('lensHandlesOwner not set');
            revert('lensHandlesOwner not set');
        }

        if (HANDLE_GUARDIAN_COOLDOWN == 0) {
            console.log('HANDLE_GUARDIAN_COOLDOWN not set');
            revert('HANDLE_GUARDIAN_COOLDOWN not set');
        }

        vm.startBroadcast(_deployer.ownerPk);

        // Deploy LensHandles(owner, hub) implementation
        lensHandlesImpl = address(new LensHandles(lensHandlesOwner, lensHub, HANDLE_GUARDIAN_COOLDOWN));
        vm.stopBroadcast();

        vm.writeLine(addressesFile, string.concat('FollowNFTImpl: ', vm.toString(followNFTImpl)));
        saveContractAddress('FollowNFTImpl', followNFTImpl);
        console.log('FollowNFTImpl: %s', followNFTImpl);

        vm.writeLine(addressesFile, string.concat('LensHandlesImpl: ', vm.toString(lensHandlesImpl)));
        saveContractAddress('LensHandlesImpl', lensHandlesImpl);
        console.log('LensHandlesImpl: %s', lensHandlesImpl);

        if (legacyCollectNFTImpl == address(0)) {
            console.log('LegacyCollectNFTImpl not set');
            revert('LegacyCollectNFTImpl not set');
        }

        if (moduleRegistry == address(0)) {
            console.log('ModuleRegistry not set');
            revert('ModuleRegistry not set');
        }

        if (PROFILE_GUARDIAN_COOLDOWN == 0) {
            console.log('PROFILE_GUARDIAN_COOLDOWN not set');
            revert('PROFILE_GUARDIAN_COOLDOWN not set');
        }

        console.log('PROFILE_GUARDIAN_COOLDOWN: %s', PROFILE_GUARDIAN_COOLDOWN);

        // Pass all the fucking shit and deploy LensHub V2 Impl with:
        vm.startBroadcast(_deployer.ownerPk);
        lensHubV2Impl = address(
            new LensHubInitializable(
                followNFTImpl,
                legacyCollectNFTImpl,
                moduleRegistry,
                PROFILE_GUARDIAN_COOLDOWN,
                Types.MigrationParams({
                    lensHandlesAddress: lensHandlesAddress,
                    tokenHandleRegistryAddress: tokenHandleRegistryAddress,
                    legacyFeeFollowModule: legacyFeeFollowModule,
                    legacyProfileFollowModule: legacyProfileFollowModule,
                    newFeeFollowModule: newFeeFollowModule
                })
            )
        );
        vm.stopBroadcast();

        console.log('"arguments": [');
        console.log('\t"%s"', followNFTImpl);
        console.log('\t"%s"', legacyCollectNFTImpl);
        console.log('\t"%s"', moduleRegistry);
        console.log('\t"%s"', PROFILE_GUARDIAN_COOLDOWN);
        console.log(
            '\t"%s"',
            string.concat(
                '(',
                vm.toString(lensHandlesAddress),
                ', ',
                vm.toString(tokenHandleRegistryAddress),
                ', ',
                vm.toString(legacyFeeFollowModule),
                ', ',
                vm.toString(legacyProfileFollowModule),
                ', ',
                vm.toString(newFeeFollowModule),
                ')'
            )
        );
        console.log(']');

        vm.writeLine(addressesFile, string.concat('LensHubV2Impl: ', vm.toString(lensHubV2Impl)));
        saveContractAddress('LensHubV2Impl', lensHubV2Impl);
        console.log('LensHubV2Impl: %s', lensHubV2Impl);
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadBaseAddresses();
        loadPrivateKeys();
        deploy();
    }
}
