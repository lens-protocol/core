// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';
import {LensV2UpgradeContract} from 'contracts/misc/LensV2UpgradeContract.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {LensHandles} from 'contracts/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/namespaces/TokenHandleRegistry.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {FeeConfig, FeeFollowModule} from 'contracts/modules/follow/FeeFollowModule.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {LensV2UpgradeContract} from 'contracts/misc/LensV2UpgradeContract.sol';
import {ProxyAdmin} from 'contracts/misc/access/ProxyAdmin.sol';
import {LensHubInitializable} from 'contracts/misc/LensHubInitializable.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {ILensHandles} from 'contracts/interfaces/ILensHandles.sol';
import {ITokenHandleRegistry} from 'contracts/interfaces/ITokenHandleRegistry.sol';
import {ProfileCreationProxy} from 'contracts/misc/ProfileCreationProxy.sol';
import {CollectNFT} from 'contracts/modules/act/collect/CollectNFT.sol';
import {CollectPublicationAction} from 'contracts/modules/act/collect/CollectPublicationAction.sol';
import {SimpleFeeCollectModule} from 'contracts/modules/act/collect/SimpleFeeCollectModule.sol';
import {MultirecipientFeeCollectModule} from 'contracts/modules/act/collect/MultirecipientFeeCollectModule.sol';
import {RevertFollowModule} from 'contracts/modules/follow/RevertFollowModule.sol';
import {DegreesOfSeparationReferenceModule} from 'contracts/modules/reference/DegreesOfSeparationReferenceModule.sol';
import {FollowerOnlyReferenceModule} from 'contracts/modules/reference/FollowerOnlyReferenceModule.sol';
import {TokenGatedReferenceModule} from 'contracts/modules/reference/TokenGatedReferenceModule.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {ModuleRegistry} from 'contracts/misc/ModuleRegistry.sol';
import {IModuleRegistry} from 'contracts/interfaces/IModuleRegistry.sol';
import {BaseFeeCollectModuleInitData} from 'contracts/modules/interfaces/IBaseFeeCollectModule.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {PublicActProxy} from 'contracts/misc/PublicActProxy.sol';
import {LitAccessControl} from 'contracts/misc/access/LitAccessControl.sol';
import {LibString} from 'solady/utils/LibString.sol';

import {ArrayHelpers} from 'script/helpers/ArrayHelpers.sol';

contract E_GovernanceActions is Script, ForkManagement, ArrayHelpers {
    // TODO: Use from test/ContractAddresses
    struct Module {
        address addy;
        string name;
    }

    // add this to be excluded from coverage report
    function testLensV2DeployPeriphery() public {}

    using stdJson for string;

    string addressesFile = 'addressesV2.txt';

    string mnemonic;

    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    LensAccount deployer;
    LensAccount governance;
    Governance governanceContract;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    address profileCreator;
    address proxyAdminContractAdmin;

    ModuleRegistry moduleRegistryImpl;
    TransparentUpgradeableProxy moduleRegistryProxy;
    ModuleRegistry moduleRegistry;
    FollowNFT followNFT;
    LensHubInitializable lensHubImpl;
    TransparentUpgradeableProxy hubProxy;
    ILensHub hub;
    LensHandles handlesImpl;
    TransparentUpgradeableProxy handlesProxy;
    ILensHandles handles;
    TokenHandleRegistry tokenHandleRegistryImpl;
    TransparentUpgradeableProxy tokenHandleRegistryProxy;
    ITokenHandleRegistry tokenHandleRegistry;
    ProfileCreationProxy profileCreationProxy;
    CollectNFT collectNFT;
    address collectPublicationAction;
    address simpleFeeCollectModule;
    address multirecipientFeeCollectModule;
    address feeFollowModule;
    address revertFollowModule;
    address degreesOfSeparationReferenceModule;
    address followerOnlyReferenceModule;
    address tokenGatedReferenceModule;
    PublicActProxy publicActProxy;
    address litAccessControl;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // TODO: Move this to helpers somewhere
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

    function loadPrivateKeys() internal {
        if (isEnvSet('MNEMONIC')) {
            mnemonic = vm.envString('MNEMONIC');
        }

        if (bytes(mnemonic).length == 0) {
            revert('Missing mnemonic');
        }

        console.log('\n- - - CURRENT BLOCK: ', block.number);

        (deployer.owner, deployer.ownerPk) = deriveRememberKey(mnemonic, 0);
        console.log('\n- - - DEPLOYER: %s', deployer.owner);
        (governance.owner, governance.ownerPk) = deriveRememberKey(mnemonic, 1);
        console.log('\n- - - GOVERNANCE: %s', governance.owner);
    }

    function loadBaseAddresses() internal override {
        Module[] memory followModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', targetEnv, '.Modules.v2.follow'))),
            (Module[])
        );

        feeFollowModule = findModuleHelper(followModules, 'FeeFollowModule').addy;
        vm.label(feeFollowModule, 'FeeFollowModule');
        console.log('FeeFollowModule: %s', feeFollowModule);

        revertFollowModule = findModuleHelper(followModules, 'RevertFollowModule').addy;
        vm.label(revertFollowModule, 'RevertFollowModule');
        console.log('RevertFollowModule: %s', revertFollowModule);

        Module[] memory referenceModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', targetEnv, '.Modules.v2.reference'))),
            (Module[])
        );

        degreesOfSeparationReferenceModule = findModuleHelper(referenceModules, 'DegreesOfSeparationReferenceModule')
            .addy;
        vm.label(degreesOfSeparationReferenceModule, 'DegreesOfSeparationReferenceModule');
        console.log('DegreesOfSeparationReferenceModule: %s', degreesOfSeparationReferenceModule);

        followerOnlyReferenceModule = findModuleHelper(referenceModules, 'FollowerOnlyReferenceModule').addy;
        vm.label(followerOnlyReferenceModule, 'FollowerOnlyReferenceModule');
        console.log('FollowerOnlyReferenceModule: %s', followerOnlyReferenceModule);

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

        simpleFeeCollectModule = findModuleHelper(collectModules, 'SimpleFeeCollectModule').addy;
        vm.label(simpleFeeCollectModule, 'SimpleFeeCollectModule');
        console.log('SimpleFeeCollectModule: %s', simpleFeeCollectModule);

        multirecipientFeeCollectModule = findModuleHelper(collectModules, 'MultirecipientFeeCollectModule').addy;
        vm.label(multirecipientFeeCollectModule, 'MultirecipientFeeCollectModule');
        console.log('MultirecipientFeeCollectModule: %s', multirecipientFeeCollectModule);

        address governanceContractAdmin = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.GovernanceContractAdmin'))
        );

        if (isEnvSet('DEPLOYMENT_ENVIRONMENT')) {
            if (LibString.eq(vm.envString('DEPLOYMENT_ENVIRONMENT'), 'production')) {} else {
                console.log('DEPLOYMENT_ENVIRONMENT is not production');
                revert();
            }
        } else {
            if (governance.owner != governanceContractAdmin) {
                console.log(
                    'Mock Governance %s != Governance contract admin %s',
                    governance.owner,
                    governanceContractAdmin
                );
                revert();
            }
        }

        profileCreator = json.readAddress(string(abi.encodePacked('.', targetEnv, '.ProfileCreator')));
        vm.label(profileCreator, 'ProfileCreator');
        console.log('ProfileCreator: %s', profileCreator);

        proxyAdminContractAdmin = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.ProxyAdminContractAdmin'))
        );
        vm.label(proxyAdminContractAdmin, 'ProxyAdminContractAdmin');
        console.log('ProxyAdminContractAdmin: %s', proxyAdminContractAdmin);

        hub = ILensHub(json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy'))));
        vm.label(address(hub), 'LensHub');
        console.log('Lens Hub Proxy: %s', address(hub));

        handles = ILensHandles(json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHandles'))));
        vm.label(address(handles), 'LensHandles');
        console.log('Lens Handles: %s', address(handles));

        tokenHandleRegistry = ITokenHandleRegistry(
            json.readAddress(string(abi.encodePacked('.', targetEnv, '.TokenHandleRegistry')))
        );
        vm.label(address(tokenHandleRegistry), 'TokenHandleRegistry');
        console.log('Token Handle Registry: %s', address(tokenHandleRegistry));

        moduleRegistry = ModuleRegistry(json.readAddress(string(abi.encodePacked('.', targetEnv, '.ModuleRegistry'))));
        vm.label(address(moduleRegistry), 'ModuleRegistry');
        console.log('Module Registry: %s', address(moduleRegistry));

        governanceContract = Governance(
            json.readAddress(string(abi.encodePacked('.', targetEnv, '.GovernanceContract')))
        );
        vm.label(address(governanceContract), 'GovernanceContract');
        console.log('Governance Contract: %s', address(governanceContract));

        profileCreationProxy = ProfileCreationProxy(
            json.readAddress(string(abi.encodePacked('.', targetEnv, '.ProfileCreationProxy')))
        );
        vm.label(address(profileCreationProxy), 'ProfileCreationProxy');
        console.log('Profile Creation Proxy: %s', address(profileCreationProxy));
    }

    function _governanceActions() internal {
        if (isEnvSet('DEPLOYMENT_ENVIRONMENT')) {
            if (LibString.eq(vm.envString('DEPLOYMENT_ENVIRONMENT'), 'production')) {} else {
                console.log('DEPLOYMENT_ENVIRONMENT is not production');
                revert();
            }
        } else {
            vm.startBroadcast(governance.ownerPk);

            governanceContract.lensHub_whitelistProfileCreator(address(profileCreationProxy), true);
            console.log(
                '\n* * * Profile creator proxy %s registered as profile creator',
                address(profileCreationProxy)
            );

            governanceContract.lensHub_setState(Types.ProtocolState.Unpaused);
            console.log('\n* * * Protocol unpaused');

            vm.stopBroadcast();
        }
    }

    function _registerCurrencies() internal {
        vm.startBroadcast(deployer.ownerPk);

        // TODO: Get the currency addresses from the addresses.json
        moduleRegistry.registerErc20Currency(address(0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e));
        console.log('\n* * * USDC registered as currency');
        vm.writeLine(
            addressesFile,
            string.concat('USDC: ', vm.toString(address(0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e)))
        );

        moduleRegistry.registerErc20Currency(address(0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F));
        console.log('\n* * * DAI registered as currency');
        vm.writeLine(
            addressesFile,
            string.concat('DAI: ', vm.toString(address(0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F)))
        );

        moduleRegistry.registerErc20Currency(address(0x3C68CE8504087f89c640D02d133646d98e64ddd9));
        console.log('\n* * * WETH registered as currency');
        vm.writeLine(
            addressesFile,
            string.concat('WETH: ', vm.toString(address(0x3C68CE8504087f89c640D02d133646d98e64ddd9)))
        );

        moduleRegistry.registerErc20Currency(address(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889));
        console.log('\n* * * WMATIC registered as currency');
        vm.writeLine(
            addressesFile,
            string.concat('WMATIC: ', vm.toString(address(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889)))
        );
        vm.stopBroadcast();
    }

    function _registerModules() internal {
        vm.startBroadcast(deployer.ownerPk);

        // Follow modules
        moduleRegistry.registerModule(address(feeFollowModule), uint256(IModuleRegistry.ModuleType.FOLLOW_MODULE));
        console.log('\n* * * FeeFollowModule registered as follow module');

        moduleRegistry.registerModule(address(revertFollowModule), uint256(IModuleRegistry.ModuleType.FOLLOW_MODULE));
        console.log('\n* * * RevertFollowModule registered as follow module');

        // Reference modules
        moduleRegistry.registerModule(
            address(degreesOfSeparationReferenceModule),
            uint256(IModuleRegistry.ModuleType.REFERENCE_MODULE)
        );
        console.log('\n* * * DegreesOfSeparationReferenceModule registered');

        moduleRegistry.registerModule(
            address(followerOnlyReferenceModule),
            uint256(IModuleRegistry.ModuleType.REFERENCE_MODULE)
        );
        console.log('\n* * * FollowerOnlyReferenceModule registered');

        // Collect modules
        moduleRegistry.registerModule(
            address(collectPublicationAction),
            uint256(IModuleRegistry.ModuleType.PUBLICATION_ACTION_MODULE)
        );
        console.log('\n* * * CollectPublicationAction registered as action module');

        CollectPublicationAction(collectPublicationAction).registerCollectModule(address(simpleFeeCollectModule));
        console.log('\n* * * SimpleFeeCollectModule registered as collect module');

        CollectPublicationAction(collectPublicationAction).registerCollectModule(
            address(multirecipientFeeCollectModule)
        );
        console.log('\n* * * MultirecipientFeeCollectModule registered as collect module');

        vm.stopBroadcast();
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadPrivateKeys();
        loadBaseAddresses();
        _governanceActions();
        _registerCurrencies();
        _registerModules();
    }
}
