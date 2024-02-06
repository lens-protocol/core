// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';
import {LibString} from 'solady/utils/LibString.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {PermissionlessCreator} from 'contracts/misc/PermissionlessCreator.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {LensHubInitializable} from 'contracts/misc/LensHubInitializable.sol';

contract DeployPermissionlessCreator is Script, ForkManagement {
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

    address lensHandlesAddress;
    address tokenHandleRegistryAddress;

    address governanceContract;
    address governanceAdmin;

    address proxyAdminContractAdmin;

    address permissionlessCreatorImpl;
    address permissionlessCreator;

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

        lensHandlesAddress = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHandles')));

        tokenHandleRegistryAddress = json.readAddress(string(abi.encodePacked('.', targetEnv, '.TokenHandleRegistry')));

        governanceContract = LensHubInitializable(lensHub).getGovernance();
        vm.label(governanceContract, 'Governance');
        console.log('Governance Contract: %s', governanceContract);

        governanceAdmin = Governance(governanceContract).owner();
        vm.label(governanceAdmin, 'GovernanceAdmin');
        console.log('Governance Contract Admin: %s', governanceAdmin);

        proxyAdminContractAdmin = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.ProxyAdminContractAdmin'))
        );
        vm.label(proxyAdminContractAdmin, 'ProxyAdminContractAdmin');
        console.log('ProxyAdmin Contract Admin: %s', proxyAdminContractAdmin);
    }

    function deploy() internal {
        if (lensHub == address(0)) {
            console.log('LensHub not set');
            revert('LensHub not set');
        }

        if (proxyAdminContractAdmin == address(0)) {
            console.log('ProxyAdminContractAdmin not set');
            revert('ProxyAdminContractAdmin not set');
        }

        if (lensHandlesAddress == address(0)) {
            console.log('lensHandlesAddress not set');
            revert('lensHandlesAddress not set');
        }

        if (tokenHandleRegistryAddress == address(0)) {
            console.log('tokenHandleRegistryAddress not set');
            revert('tokenHandleRegistryAddress not set');
        }

        // Pass all the fucking shit and deploy LensHub V2 Impl with:
        vm.startBroadcast(_deployer.ownerPk);

        permissionlessCreatorImpl = address(
            new PermissionlessCreator(governanceAdmin, lensHub, lensHandlesAddress, tokenHandleRegistryAddress)
        );

        // Make LensHandles a transparentUpgradeableProxy
        permissionlessCreator = address(
            new TransparentUpgradeableProxy(permissionlessCreatorImpl, proxyAdminContractAdmin, '')
        );
        vm.stopBroadcast();

        vm.writeLine(
            addressesFile,
            string.concat('PermissionlessCreatorImpl: ', vm.toString(permissionlessCreatorImpl))
        );
        saveContractAddress('PermissionlessCreatorImpl', permissionlessCreatorImpl);
        console.log('PermissionlessCreatorImpl: %s', permissionlessCreatorImpl);

        vm.writeLine(addressesFile, string.concat('PermissionlessCreator: ', vm.toString(permissionlessCreator)));
        saveContractAddress('PermissionlessCreator', permissionlessCreator);
        console.log('PermissionlessCreator: %s', permissionlessCreator);
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
