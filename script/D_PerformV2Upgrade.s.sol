// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';
import {ILensGovernable} from 'contracts/interfaces/ILensGovernable.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {LensV2UpgradeContract} from 'contracts/misc/LensV2UpgradeContract.sol';
import {ProxyAdmin} from 'contracts/misc/access/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract D_PerformV2Upgrade is Script, ForkManagement {
    // add this to be excluded from coverage report
    function testLensV1ToV2Upgrade() public {}

    using stdJson for string;

    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);

    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    string mnemonic;

    LensAccount _deployer;
    LensAccount _governance;
    LensAccount _proxyAdmin;

    ILensGovernable legacyLensHub; // We just need the `getGovernance` function
    TransparentUpgradeableProxy lensHubAsProxy;
    LensV2UpgradeContract lensV2UpgradeContract;
    Governance governanceContract;
    address proxyAdmin;
    ProxyAdmin proxyAdminContract;

    function loadBaseAddresses() internal override {
        address lensHubProxyAddress = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy')));
        legacyLensHub = ILensGovernable(lensHubProxyAddress);
        vm.label(lensHubProxyAddress, 'LensHub');
        console.log('Lens Hub Proxy: %s', address(legacyLensHub));
        lensHubAsProxy = TransparentUpgradeableProxy(payable(lensHubProxyAddress));

        address lensV2UpgradeContractAddress = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.LensV2UpgradeContract'))
        );
        lensV2UpgradeContract = LensV2UpgradeContract(lensV2UpgradeContractAddress);
        vm.label(lensV2UpgradeContractAddress, 'LensV2UpgradeContract');
        console.log('Lens V2 Upgrade Contract: %s', address(lensV2UpgradeContract));

        address governanceContractAddress = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.GovernanceContract'))
        );
        governanceContract = Governance(governanceContractAddress);
        vm.label(governanceContractAddress, 'GovernanceContract');
        console.log('Governance Contract: %s', address(governanceContract));

        proxyAdmin = address(uint160(uint256(vm.load(lensHubProxyAddress, ADMIN_SLOT))));
        vm.label(proxyAdmin, 'ProxyAdmin');
        console.log('LensHubProxy Current Admin: %s', proxyAdmin);

        address proxyAdminContractAddress = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.ProxyAdminContract'))
        );
        proxyAdminContract = ProxyAdmin(proxyAdminContractAddress);
        vm.label(proxyAdminContractAddress, 'ProxyAdmin');
        console.log('Proxy Admin Contract: %s', address(proxyAdminContract));
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
        console.log('Deployer address: %s', address(_deployer.owner));

        (_governance.owner, _governance.ownerPk) = deriveRememberKey(mnemonic, 1);
        console.log('Governance mock owner address: %s', address(_governance.owner));

        (_proxyAdmin.owner, _proxyAdmin.ownerPk) = deriveRememberKey(mnemonic, 2);
        console.log('ProxyAdmin mock owner address: %s', address(_proxyAdmin.owner));

        console.log('\n');

        console.log('Current block:', block.number);
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadBaseAddresses();
        loadPrivateKeys();

        address governance = legacyLensHub.getGovernance();
        console.log('LensHub Current governance: %s', address(governance));

        require(governance == address(governanceContract), 'LensHub Governance should be set to GovernanceContract');

        // vm.broadcast(_governance.ownerPk);
        // legacyLensHub.setGovernance(address(governanceContract));
        // console.log('Changed the governance from %s to %s', address(governance), address(governanceContract));

        // vm.broadcast(_deployer.ownerPk);
        // lensHubAsProxy.changeAdmin(address(proxyAdminContract));
        // console.log('Changed the proxy admin from %s to %s', address(_deployer.owner), address(proxyAdminContract));

        console.log('proxyAdminContract owner(): %s', proxyAdminContract.owner());

        vm.broadcast(_proxyAdmin.ownerPk);
        proxyAdminContract.setControllerContract(address(lensV2UpgradeContract));
        console.log(
            'Changed the proxyAdminContract controller contract from %s to %s',
            address(0),
            address(lensV2UpgradeContract)
        );

        console.log('governanceContract owner(): %s', governanceContract.owner());

        vm.broadcast(_governance.ownerPk);
        governanceContract.setControllerContract(address(lensV2UpgradeContract));
        console.log(
            'Changed the governanceContract controller contract from %s to %s',
            address(0),
            address(lensV2UpgradeContract)
        );

        console.log('New Implementation: %s', lensV2UpgradeContract.newImplementation());

        console.log('LensV2 Upgrade Contract PROXY_ADMIN: %s', address(lensV2UpgradeContract.PROXY_ADMIN()));
        console.log('LensV2 Upgrade Contract GOVERNANCE: %s', address(lensV2UpgradeContract.GOVERNANCE()));

        vm.broadcast(_governance.ownerPk);
        lensV2UpgradeContract.executeLensV2Upgrade();
        console.log('Upgrade complete!');

        bytes32 PROXY_IMPLEMENTATION_STORAGE_SLOT = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
        address hubImplAddr = address(
            uint160(uint256(vm.load(address(legacyLensHub), PROXY_IMPLEMENTATION_STORAGE_SLOT)))
        );
        console.log('New implementation:', hubImplAddr);
    }
}
