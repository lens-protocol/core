// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';
import {LensHub as LegacyLensHub} from '@lens-v1/contracts/core/LensHub.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {LensV2UpgradeContract} from 'contracts/misc/LensV2UpgradeContract.sol';
import {ProxyAdmin} from 'contracts/misc/access/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract LensV1ChangeAdmins is Script, ForkManagement {
    using stdJson for string;

    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);

    LegacyLensHub legacyLensHub;
    TransparentUpgradeableProxy lensHubAsProxy;
    Governance governanceContract;
    address proxyAdmin;
    address governance;
    ProxyAdmin proxyAdminContract;

    function loadBaseAddresses() internal override {
        address lensHubProxyAddress = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy')));
        legacyLensHub = LegacyLensHub(lensHubProxyAddress);
        vm.label(lensHubProxyAddress, 'LensHub');
        console.log('Legacy Lens Hub: %s', address(legacyLensHub));
        lensHubAsProxy = TransparentUpgradeableProxy(payable(lensHubProxyAddress));

        address governanceContractAddress = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.GovernanceContract'))
        );
        governanceContract = Governance(governanceContractAddress);
        vm.label(governanceContractAddress, 'GovernanceContract');
        console.log('Governance Contract: %s', address(governanceContract));

        governance = legacyLensHub.getGovernance();
        console.log('LensHub Current governance: %s', address(governance));

        address proxyAdminContractAddress = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.ProxyAdminContract'))
        );
        proxyAdminContract = ProxyAdmin(proxyAdminContractAddress);
        vm.label(proxyAdminContractAddress, 'ProxyAdmin');
        console.log('Proxy Admin Contract: %s', address(proxyAdminContract));

        proxyAdmin = address(uint160(uint256(vm.load(lensHubProxyAddress, ADMIN_SLOT))));
        vm.label(proxyAdmin, 'ProxyAdmin');
        console.log('LensHub Current Proxy Admin: %s', proxyAdmin);
    }

    function castTransaction(address from, address to, string memory functionSignature, string memory params) internal {
        string[] memory inputs = new string[](10);
        inputs[0] = 'cast';
        inputs[1] = 'send';
        inputs[2] = '--rpc-url';
        inputs[3] = network;
        inputs[4] = '--unlocked';
        inputs[5] = '--from';
        inputs[6] = vm.toString(from);
        inputs[7] = vm.toString(to);
        inputs[8] = functionSignature;
        inputs[9] = params;

        // Print inputs:
        console.log('Inputs:');
        for (uint256 i = 0; i < inputs.length; i++) {
            console.log('\t%s', inputs[i]);
        }

        vm.ffi(inputs);
    }

    function _changeAdmins() internal {
        castTransaction(
            governance,
            address(legacyLensHub),
            'setGovernance(address)',
            vm.toString(address(governanceContract))
        );

        castTransaction(
            proxyAdmin,
            address(lensHubAsProxy),
            'changeAdmin(address)',
            vm.toString(address(proxyAdminContract))
        );
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadBaseAddresses();
        _changeAdmins();
    }
}
