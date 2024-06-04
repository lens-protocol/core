// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';
import {LensV2UpgradeContract} from 'contracts/misc/LensV2UpgradeContract.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {LensHandles} from 'contracts/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/namespaces/TokenHandleRegistry.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {LensV2UpgradeContract} from 'contracts/misc/LensV2UpgradeContract.sol';
import {ProxyAdmin} from 'contracts/misc/access/ProxyAdmin.sol';
import {LensHubInitializable} from 'contracts/misc/LensHubInitializable.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {ILensHandles} from 'contracts/interfaces/ILensHandles.sol';
import {ITokenHandleRegistry} from 'contracts/interfaces/ITokenHandleRegistry.sol';
import {ProfileCreationProxy} from 'contracts/misc/ProfileCreationProxy.sol';
import {PermissionlessCreator} from 'contracts/misc/PermissionlessCreator.sol';
import {CreditsFaucet} from 'contracts/misc/CreditsFaucet.sol';
import {CollectNFT} from 'contracts/modules/act/collect/CollectNFT.sol';
import {CollectPublicationAction} from 'contracts/modules/act/collect/CollectPublicationAction.sol';
import {SimpleFeeCollectModule} from 'contracts/modules/act/collect/SimpleFeeCollectModule.sol';
import {MultirecipientFeeCollectModule} from 'contracts/modules/act/collect/MultirecipientFeeCollectModule.sol';
import {FeeFollowModule} from './../contracts/modules/follow/FeeFollowModule.sol';
import {RevertFollowModule} from 'contracts/modules/follow/RevertFollowModule.sol';
import {DegreesOfSeparationReferenceModule} from 'contracts/modules/reference/DegreesOfSeparationReferenceModule.sol';
import {FollowerOnlyReferenceModule} from 'contracts/modules/reference/FollowerOnlyReferenceModule.sol';
import {TokenGatedReferenceModule} from 'contracts/modules/reference/TokenGatedReferenceModule.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {ModuleRegistry} from 'contracts/misc/ModuleRegistry.sol';
import {IModuleRegistry} from 'contracts/interfaces/IModuleRegistry.sol';
import {LitAccessControl} from 'contracts/misc/access/LitAccessControl.sol';
import {PublicActProxy} from './../contracts/misc/PublicActProxy.sol';
import {Governance} from './../contracts/misc/access/Governance.sol';
import {ProxyAdmin} from './../contracts/misc/access/ProxyAdmin.sol';
import {ERC2981CollectionRoyalties} from './../contracts/base/ERC2981CollectionRoyalties.sol';

import {ArrayHelpers} from 'test/helpers/ArrayHelpers.sol';

contract DeployFreshLensV2 is Script, ForkManagement, ArrayHelpers {
    using stdJson for string;

    string addressesFile = 'addressesV2.txt';

    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    string mnemonic;

    uint256 internal PROFILE_GUARDIAN_COOLDOWN;
    uint256 internal HANDLE_GUARDIAN_COOLDOWN;

    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    LensAccount deployer;
    LensAccount governance;
    LensAccount proxyAdmin;
    LensAccount treasury;
    LensAccount profileCreator;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
    PermissionlessCreator permissionlessCreatorImpl;
    TransparentUpgradeableProxy permissionlessCreatorProxy;
    PermissionlessCreator permissionlessCreator;
    CreditsFaucet creditsFaucet;
    ProfileCreationProxy profileCreationProxy;
    CollectNFT collectNFT;
    CollectPublicationAction collectPublicationActionImpl;
    TransparentUpgradeableProxy collectPublicationActionProxy;
    CollectPublicationAction collectPublicationAction;
    SimpleFeeCollectModule simpleFeeCollectModule;
    MultirecipientFeeCollectModule multirecipientFeeCollectModule;
    FeeFollowModule feeFollowModule;
    RevertFollowModule revertFollowModule;
    DegreesOfSeparationReferenceModule degreesOfSeparationReferenceModule;
    FollowerOnlyReferenceModule followerOnlyReferenceModule;
    TokenGatedReferenceModule tokenGatedReferenceModule;
    LitAccessControl litAccessControlImpl;
    TransparentUpgradeableProxy litAccessControlProxy;
    LitAccessControl litAccessControl;
    PublicActProxy publicActProxy;
    Governance governanceContract;
    ProxyAdmin proxyAdminContract;
    uint256 anonymousProfileId;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
        (proxyAdmin.owner, proxyAdmin.ownerPk) = deriveRememberKey(mnemonic, 2);
        console.log('\n- - - PROXYADMIN: %s', proxyAdmin.owner);
        (treasury.owner, treasury.ownerPk) = deriveRememberKey(mnemonic, 3);
        console.log('\n- - - TREASURY: %s', treasury.owner);
        profileCreator.owner = 0x6C1e1bC39b13f9E0Af9424D76De899203F47755F;
        console.log('\n- - - PROFILE CREATOR: %s', profileCreator.owner);
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

    function _logDeployedAddress(address deployedAddress, string memory addressLabel) internal {
        console.log('\n+ + + ', addressLabel, ': ', deployedAddress);
        vm.writeLine(addressesFile, string.concat(addressLabel, string.concat(': ', vm.toString(deployedAddress))));
        saveContractAddress(addressLabel, deployedAddress);
    }

    function _logDeployedModule(address deployedAddress, string memory moduleName, string memory moduleType) internal {
        string memory lensVersion = 'v2';
        console.log('\n+ + + ', moduleName, ': ', deployedAddress);
        vm.writeLine(addressesFile, string.concat(moduleName, string.concat(': ', vm.toString(deployedAddress))));
        saveModule(moduleName, deployedAddress, lensVersion, moduleType);
    }

    function loadDeployParams() internal {
        HANDLE_GUARDIAN_COOLDOWN = json.readUint(
            string(abi.encodePacked('.', targetEnv, '.LensHandlesGuardianTimelock'))
        );
        if (HANDLE_GUARDIAN_COOLDOWN == 0) {
            console.log('HANDLE_GUARDIAN_COOLDOWN not set');
            revert('HANDLE_GUARDIAN_COOLDOWN not set');
        }
        console.log('HANDLE_GUARDIAN_COOLDOWN: %s', HANDLE_GUARDIAN_COOLDOWN);

        PROFILE_GUARDIAN_COOLDOWN = json.readUint(
            string(abi.encodePacked('.', targetEnv, '.LensProfilesGuardianTimelock'))
        );
        if (PROFILE_GUARDIAN_COOLDOWN == 0) {
            console.log('PROFILE_GUARDIAN_COOLDOWN not set');
            revert('PROFILE_GUARDIAN_COOLDOWN not set');
        }
        console.log('PROFILE_GUARDIAN_COOLDOWN: %s', PROFILE_GUARDIAN_COOLDOWN);
    }

    function _deployCore() internal {
        moduleRegistryImpl = new ModuleRegistry();
        _logDeployedAddress(address(moduleRegistryImpl), 'ModuleRegistryImpl');
        moduleRegistryProxy = new TransparentUpgradeableProxy({
            _logic: address(moduleRegistryImpl),
            admin_: proxyAdmin.owner,
            _data: ''
        });
        moduleRegistry = ModuleRegistry(address(moduleRegistryProxy));
        _logDeployedAddress(address(moduleRegistry), 'ModuleRegistry');

        uint256 currentDeployerNonce = vm.getNonce(deployer.owner);
        /**
         * FollowNFT (currentDeployerNonce)
         * LensHubInitializable aka LensHubImpl (currentDeployerNonce + 1)
         * TransparentUpgradeableProxy aka LensHubProxy (currentDeployerNonce + 2)
         */
        uint256 lensHubProxyDeploymentNonce = currentDeployerNonce + 2;
        address expectedLensHubProxyAddress = computeCreateAddress(deployer.owner, lensHubProxyDeploymentNonce);

        followNFT = new FollowNFT(expectedLensHubProxyAddress);
        _logDeployedAddress(address(followNFT), 'FollowNFT');

        lensHubImpl = new LensHubInitializable({
            followNFTImpl: address(followNFT),
            collectNFTImpl: address(0), // No needed on a fresh V2 deployment, no publications will have legacy collect.
            moduleRegistry: address(moduleRegistry),
            tokenGuardianCooldown: PROFILE_GUARDIAN_COOLDOWN,
            migrationParams: Types.MigrationParams({
                lensHandlesAddress: address(0),
                tokenHandleRegistryAddress: address(0),
                legacyFeeFollowModule: address(0),
                legacyProfileFollowModule: address(0),
                newFeeFollowModule: address(0)
            }) // No needed on a fresh V2 deployment, no migration needed.
        });
        _logDeployedAddress(address(lensHubImpl), 'LensHubImpl');

        hubProxy = new TransparentUpgradeableProxy({
            _logic: address(lensHubImpl),
            admin_: proxyAdmin.owner,
            _data: abi.encodeWithSelector(
                LensHubInitializable.initialize.selector,
                'Lens Protocol Profiles', // Name
                'LPP', // Symbol
                governance.owner
            )
        });
        hub = ILensHub(address(hubProxy));
        _logDeployedAddress(address(hub), 'LensHub');

        handlesImpl = new LensHandles({
            owner: governance.owner,
            lensHub: address(hub),
            tokenGuardianCooldown: HANDLE_GUARDIAN_COOLDOWN
        });
        _logDeployedAddress(address(handlesImpl), 'LensHandlesImpl');

        handlesProxy = new TransparentUpgradeableProxy({
            _logic: address(handlesImpl),
            admin_: proxyAdmin.owner,
            _data: ''
        });
        _logDeployedAddress(address(handlesProxy), 'LensHandles');
        handles = ILensHandles(address(handlesProxy));

        tokenHandleRegistryImpl = new TokenHandleRegistry({lensHub: address(hub), lensHandles: address(handles)});
        _logDeployedAddress(address(tokenHandleRegistryImpl), 'TokenHandleRegistryImpl');

        tokenHandleRegistryProxy = new TransparentUpgradeableProxy({
            _logic: address(tokenHandleRegistryImpl),
            admin_: proxyAdmin.owner,
            _data: ''
        });
        _logDeployedAddress(address(tokenHandleRegistryProxy), 'TokenHandleRegistry');
        tokenHandleRegistry = ITokenHandleRegistry(address(tokenHandleRegistryProxy));

        permissionlessCreatorImpl = new PermissionlessCreator(
            governance.owner,
            address(hub),
            address(handles),
            address(tokenHandleRegistry)
        );
        permissionlessCreatorProxy = new TransparentUpgradeableProxy({
            _logic: address(permissionlessCreatorImpl),
            admin_: proxyAdmin.owner,
            _data: ''
        });
        permissionlessCreator = PermissionlessCreator(address(permissionlessCreatorProxy));
        _logDeployedAddress(address(permissionlessCreator), 'PermissionlessCreator');

        if (isTestnet) {
            // Credit faucet is added as provider in the permissionless creator later in this script.
            creditsFaucet = new CreditsFaucet(address(permissionlessCreatorProxy));
            _logDeployedAddress(address(creditsFaucet), 'CreditsFaucet');

            profileCreationProxy = new ProfileCreationProxy(
                governance.owner,
                address(hub),
                address(handles),
                address(tokenHandleRegistry)
            );
            _logDeployedAddress(address(profileCreationProxy), 'ProfileCreationProxy');
        }

        currentDeployerNonce = vm.getNonce(deployer.owner);
        /**
         * CollectNFT (currentDeployerNonce)
         * CollectPublicationAction aka CollectPublicationActionImpl (currentDeployerNonce + 1)
         * TransparentUpgradeableProxy aka CollectPublicationActionProxy (currentDeployerNonce + 2)
         */
        uint256 collectPublicationActionProxyDeploymentNonce = currentDeployerNonce + 2;
        address expectedCollectPublicationActionProxyAddress = computeCreateAddress(
            deployer.owner,
            collectPublicationActionProxyDeploymentNonce
        );

        collectNFT = new CollectNFT({hub: address(hub), actionModule: expectedCollectPublicationActionProxyAddress});
        _logDeployedAddress(address(collectNFT), 'CollectNFT');

        collectPublicationActionImpl = new CollectPublicationAction({
            hub: address(hub),
            collectNFTImpl: address(collectNFT),
            moduleOwner: governance.owner
        });

        collectPublicationActionProxy = new TransparentUpgradeableProxy({
            _logic: address(collectPublicationActionImpl),
            admin_: proxyAdmin.owner,
            _data: ''
        });
        collectPublicationAction = CollectPublicationAction(address(collectPublicationActionProxy));
        _logDeployedModule(address(collectPublicationAction), 'CollectPublicationAction', 'act');
    }

    function _deployFollowModules() internal {
        feeFollowModule = new FeeFollowModule({
            hub: address(hub),
            moduleRegistry: address(moduleRegistry),
            moduleOwner: governance.owner
        });
        _logDeployedModule(address(feeFollowModule), 'FeeFollowModule', 'follow');

        revertFollowModule = new RevertFollowModule({moduleOwner: governance.owner});
        _logDeployedModule(address(revertFollowModule), 'RevertFollowModule', 'follow');
    }

    function _deployCollectModules() internal {
        simpleFeeCollectModule = new SimpleFeeCollectModule({
            hub: address(hub),
            actionModule: address(collectPublicationAction),
            moduleRegistry: address(moduleRegistry),
            moduleOwner: governance.owner
        });
        _logDeployedModule(address(simpleFeeCollectModule), 'SimpleFeeCollectModule', 'collect');

        multirecipientFeeCollectModule = new MultirecipientFeeCollectModule({
            hub: address(hub),
            actionModule: address(collectPublicationAction),
            moduleRegistry: address(moduleRegistry),
            moduleOwner: governance.owner
        });
        _logDeployedModule(address(multirecipientFeeCollectModule), 'MultirecipientFeeCollectModule', 'collect');
    }

    function _deployReferenceModules() internal {
        degreesOfSeparationReferenceModule = new DegreesOfSeparationReferenceModule({
            hub: address(hub),
            moduleOwner: governance.owner
        });
        _logDeployedModule(
            address(degreesOfSeparationReferenceModule),
            'DegreesOfSeparationReferenceModule',
            'reference'
        );

        followerOnlyReferenceModule = new FollowerOnlyReferenceModule({
            hub: address(hub),
            moduleOwner: governance.owner
        });
        _logDeployedModule(address(followerOnlyReferenceModule), 'FollowerOnlyReferenceModule', 'reference');
    }

    function _deployPeripherialContracts() internal {
        litAccessControlImpl = new LitAccessControl(address(hub), address(collectPublicationAction));
        _logDeployedAddress(address(litAccessControlImpl), 'LitAccessControlImpl');

        litAccessControlProxy = new TransparentUpgradeableProxy({
            _logic: address(litAccessControlImpl),
            admin_: proxyAdmin.owner,
            _data: ''
        });
        litAccessControl = LitAccessControl(address(litAccessControlProxy));
        _logDeployedAddress(address(litAccessControl), 'LitAccessControl');

        publicActProxy = new PublicActProxy({lensHub: address(hub)});
        _logDeployedAddress(address(publicActProxy), 'PublicActProxy');
    }

    // TODO: Use from test/ContractAddresses?
    struct Currency {
        address addy;
        string symbol;
    }

    function _registerCurrencies() internal {
        console.log('\n[Registering currencies]');

        Currency[] memory currencies = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', targetEnv, '.Currencies'))),
            (Currency[])
        );

        for (uint256 i = 0; i < currencies.length; i++) {
            moduleRegistry.registerErc20Currency(currencies[i].addy);
            console.log('\n* * * ', currencies[i].symbol, ' registered as currency: ', currencies[i].addy);
            vm.writeLine(
                addressesFile,
                string.concat(currencies[i].symbol, string.concat(': ', vm.toString(currencies[i].addy)))
            );
        }
    }

    function _registerModules() internal {
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

        collectPublicationAction.registerCollectModule(address(simpleFeeCollectModule));
        console.log('\n* * * SimpleFeeCollectModule registered as collect module');

        collectPublicationAction.registerCollectModule(address(multirecipientFeeCollectModule));
        console.log('\n* * * MultirecipientFeeCollectModule registered as collect module');
    }

    function deploy() internal {
        loadDeployParams();

        vm.startBroadcast(deployer.ownerPk);
        {
            _deployCore();

            _deployCollectModules();

            _deployFollowModules();

            _deployReferenceModules();

            _deployPeripherialContracts();
        }
        vm.stopBroadcast();

        vm.startBroadcast(governance.ownerPk);
        {
            if (isTestnet) {
                console.log('\n[Adding Credits Faucet as Credit Provider]');
                permissionlessCreator.addCreditProvider(address(creditsFaucet));

                hub.whitelistProfileCreator(address(profileCreationProxy), true);
                console.log('\n* * * Profile creation proxy contract registered as profile creator');
            }

            _registerCurrencies();

            hub.whitelistProfileCreator(address(permissionlessCreator), true);
            console.log('\n* * * Permissionless creator contract registered as profile creator');

            _registerModules();

            hub.setState(Types.ProtocolState.Unpaused);
            console.log('\n* * * Protocol unpaused');

            hub.setTreasury(treasury.owner);
            console.log('\n* * * Treasury set to: ', treasury.owner);
            saveContractAddress('Treasury', treasury.owner);

            uint256 treasuryFee = json.readUint(string(abi.encodePacked('.', targetEnv, '.TreasuryFee')));
            if (treasuryFee > 10_000) {
                revert('Treasury fee exceeding max BPS');
            }
            hub.setTreasuryFee(uint16(treasuryFee));
            console.log('\n* * * Treasury fee set to: ', treasuryFee);

            uint256 profileRoyaltyFee = json.readUint(string(abi.encodePacked('.', targetEnv, '.ProfileRoyaltyFee')));
            ERC2981CollectionRoyalties(address(hub)).setRoyalty(profileRoyaltyFee);

            uint256 handleRoyaltyFee = json.readUint(string(abi.encodePacked('.', targetEnv, '.HandleRoyaltyFee')));
            ERC2981CollectionRoyalties(address(handles)).setRoyalty(handleRoyaltyFee);

            anonymousProfileId = permissionlessCreator.createProfile({
                createProfileParams: Types.CreateProfileParams({
                    to: deployer.owner,
                    followModule: address(0),
                    followModuleInitData: ''
                }),
                delegatedExecutors: new address[](0)
            });

            vm.writeLine(addressesFile, string.concat('AnonymousProfileId :', vm.toString(anonymousProfileId)));
            console.log('\n* * * Anonymous profile created with id: ', anonymousProfileId);
            saveValue('AnonymousProfileId', vm.toString(anonymousProfileId));
        }
        vm.stopBroadcast();

        vm.startBroadcast(deployer.ownerPk);
        {
            if (isTestnet) {
                // Add PublicActProxy as a delegatedExecutor of anonymousProfileId
                hub.changeDelegatedExecutorsConfig(
                    anonymousProfileId,
                    _toAddressArray(address(publicActProxy)),
                    _toBoolArray(true)
                );
                console.log(
                    'PublicActProxy added as DelegatedExecutor of AnonymousProfileId: %s',
                    address(publicActProxy)
                );
            } else {
                console.log('Skipping governance actions for mainnet');
                console.log('Add PublicActProxy as DelegatedExecutor of AnonymousProfileId manually!');
            }

            // Deploy governance and proxy-admin controllable-by-contract contracts, and transfer ownership.
            governanceContract = new Governance(address(hub), governance.owner);
            _logDeployedAddress(address(governanceContract), 'GovernanceContract');
            _logDeployedAddress(governance.owner, 'GovernanceContractAdmin');

            proxyAdminContract = new ProxyAdmin(address(hub), address(0), proxyAdmin.owner);
            _logDeployedAddress(address(proxyAdminContract), 'ProxyAdminContract');
            _logDeployedAddress(proxyAdmin.owner, 'ProxyAdminContractAdmin');
        }
        vm.stopBroadcast();

        vm.startBroadcast(governance.ownerPk);
        {
            hub.setGovernance(address(governanceContract));
            // hub.setEmergencyAdmin(governance.owner); // TODO: WHO ?
        }
        vm.stopBroadcast();

        vm.startBroadcast(proxyAdmin.ownerPk);
        {
            hubProxy.changeAdmin(address(proxyAdminContract));
        }
        vm.stopBroadcast();
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadPrivateKeys();
        deploy();
        // _writeBackendEnvFile();
        // _interact();
    }
}
