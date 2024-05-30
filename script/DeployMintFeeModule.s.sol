// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';
import {ProtocolSharedRevenueDistribution, ProtocolSharedRevenueMinFeeMintModule} from 'contracts/modules/act/collect/ProtocolSharedRevenueMinFeeMintModule.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {CollectPublicationAction} from 'contracts/modules/act/collect/CollectPublicationAction.sol';
import {IModuleRegistry} from 'contracts/interfaces/IModuleRegistry.sol';
import {LibString} from 'solady/utils/LibString.sol';

contract DeployMintFeeModule is Script, ForkManagement {
    using stdJson for string;

    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    LensAccount _deployer;
    LensAccount governance;
    LensAccount proxyAdmin;

    string mnemonic;

    address lensHub;
    address collectPublicationAction;
    address moduleRegistry;
    address governanceOwner;
    address proxyAdminContractAdmin;
    address bonsai;

    ProtocolSharedRevenueMinFeeMintModule mintFeeModule;
    address mintFeeModuleImpl;
    address payable mintFeeModuleProxyAddr;

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

        (governance.owner, governance.ownerPk) = deriveRememberKey(mnemonic, 1);
        console.log('\n- - - GOVERNANCE: %s', governance.owner);

        (proxyAdmin.owner, proxyAdmin.ownerPk) = deriveRememberKey(mnemonic, 2);
        console.log('\n- - - PROXY ADMIN: %s', proxyAdmin.owner);

        console.log('\n');

        console.log('Current block:', block.number);
    }

    struct Currency {
        address addy;
        string symbol;
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

    function findModuleHelper_noFail(
        Module[] memory modules,
        string memory moduleNameToFind
    ) internal pure returns (Module memory) {
        for (uint256 i = 0; i < modules.length; i++) {
            if (LibString.eq(modules[i].name, moduleNameToFind)) {
                return modules[i];
            }
        }
        return Module(address(0), '');
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

    function _logDeployedModule(address deployedAddress, string memory moduleName, string memory moduleType) internal {
        string memory lensVersion = 'v2';
        console.log('\n+ + + ', moduleName, ': ', deployedAddress);
        saveModule(moduleName, deployedAddress, lensVersion, moduleType);
    }

    function loadBaseAddresses() internal override {
        lensHub = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHub')));
        vm.label(lensHub, 'LensHub');
        console.log('Lens Hub Proxy: %s', lensHub);

        Module[] memory actModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', targetEnv, '.Modules.v2.act'))),
            (Module[])
        );
        collectPublicationAction = findModuleHelper(actModules, 'CollectPublicationAction').addy;
        vm.label(collectPublicationAction, 'CollectPublicationAction');
        console.log('CollectPublicationAction: %s', collectPublicationAction);

        Module[] memory collectModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', targetEnv, '.Modules.v2.collect'))),
            (Module[])
        );
        mintFeeModuleProxyAddr = payable(
            findModuleHelper_noFail(collectModules, 'ProtocolSharedRevenueMinFeeMintModule').addy
        );

        moduleRegistry = json.readAddress(string(abi.encodePacked('.', targetEnv, '.ModuleRegistry')));
        vm.label(moduleRegistry, 'ModuleRegistry');
        console.log('ModuleRegistry: %s', moduleRegistry);

        governanceOwner = json.readAddress(string(abi.encodePacked('.', targetEnv, '.GovernanceContractAdmin')));
        vm.label(governanceOwner, 'GovernanceOwner');
        console.log('Governance Owner: %s', governanceOwner);

        proxyAdminContractAdmin = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.ProxyAdminContractAdmin'))
        );
        vm.label(proxyAdminContractAdmin, 'ProxyAdminContractAdmin');
        console.log('Proxy Admin Contract Admin: %s', proxyAdminContractAdmin);

        Currency[] memory currencies = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', targetEnv, '.Currencies'))),
            (Currency[])
        );

        for (uint256 i = 0; i < currencies.length; i++) {
            if (LibString.eq(currencies[i].symbol, 'BONSAI')) {
                bonsai = currencies[i].addy;
            }
        }
        vm.label(bonsai, 'BONSAI');
        console.log('BONSAI: %s', bonsai);
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadBaseAddresses();
        loadPrivateKeys();
        deploy();
        moduleRegistryActions();
        governanceActions();
    }

    function deploy() internal {
        vm.startBroadcast(_deployer.ownerPk);
        {
            mintFeeModuleImpl = address(
                new ProtocolSharedRevenueMinFeeMintModule({
                    hub: lensHub,
                    actionModule: collectPublicationAction,
                    moduleRegistry: moduleRegistry,
                    moduleOwner: governanceOwner
                })
            );
            console.log(
                '\n* * * Deployed ProtocolSharedRevenueMinFeeMintModule implementation at: ',
                mintFeeModuleImpl
            );
            console.log('With parameters:');
            console.log('\tHub: ', lensHub);
            console.log('\tAction Module: ', collectPublicationAction);
            console.log('\tModule Registry: ', moduleRegistry);
            console.log('\tModule Owner: ', governanceOwner);
        }
        vm.stopBroadcast();

        if (mintFeeModuleProxyAddr == address(0)) {
            console.log('\n* * * MintFeeModule proxy not found - deploying from scratch...');
            vm.startBroadcast(_deployer.ownerPk);
            {
                mintFeeModule = ProtocolSharedRevenueMinFeeMintModule(
                    address(
                        new TransparentUpgradeableProxy(
                            mintFeeModuleImpl,
                            proxyAdminContractAdmin,
                            abi.encodeCall(mintFeeModule.initialize, (governanceOwner))
                        )
                    )
                );
            }
            vm.stopBroadcast();

            _logDeployedModule(address(mintFeeModule), 'ProtocolSharedRevenueMinFeeMintModule', 'collect');
        } else {
            console.log('\n* * * MintFeeModule proxy found - upgrading...');
            console.log('\tProxyAdminContractAdmin: ', proxyAdminContractAdmin);
            console.log('\tproxyAdmin.owner: ', proxyAdmin.owner);
            vm.startBroadcast(proxyAdmin.ownerPk);
            {
                TransparentUpgradeableProxy(mintFeeModuleProxyAddr).upgradeTo(mintFeeModuleImpl);
            }
            vm.stopBroadcast();
            mintFeeModule = ProtocolSharedRevenueMinFeeMintModule(mintFeeModuleProxyAddr);
            console.log('\n* * * MintFeeModule upgraded to new implementation: ', mintFeeModuleImpl);
        }
    }

    function moduleRegistryActions() internal {
        vm.startBroadcast(_deployer.ownerPk);
        IModuleRegistry(moduleRegistry).registerErc20Currency(bonsai);
        console.log('\n* * * BONSAI registered as currency: ', bonsai);

        CollectPublicationAction(collectPublicationAction).registerCollectModule(address(mintFeeModule));
        console.log('\n* * * MintFeeModule registered as collect module in CollectPublicationAction');
        vm.stopBroadcast();
    }

    function governanceActions() internal {
        console.log('\n* * * Owner of mintFeeModule:', mintFeeModule.owner());
        vm.startBroadcast(governance.ownerPk);
        {
            mintFeeModule.setMintFeeParams(bonsai, 10 ether);
            console.log('\n* * * MintFeeModule mint fee set to 10 BONSAI');

            mintFeeModule.setProtocolSharedRevenueDistribution(
                ProtocolSharedRevenueDistribution({
                    creatorSplit: 5000,
                    protocolSplit: 2000,
                    creatorClientSplit: 1500,
                    executorClientSplit: 1500
                })
            );
            console.log('\n* * * MintFeeModule revenue distribution set to:');
            console.log('\tCreator: 50%');
            console.log('\tProtocol: 20%');
            console.log('\tCreator Client: 15%');
            console.log('\tExecutor Client: 15%');
        }
        vm.stopBroadcast();
    }
}
