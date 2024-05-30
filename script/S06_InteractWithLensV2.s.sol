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
import {BaseFeeCollectModuleInitData} from 'contracts/modules/interfaces/IBaseFeeCollectModule.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {PublicActProxy} from 'contracts/misc/PublicActProxy.sol';
import {LitAccessControl} from 'contracts/misc/access/LitAccessControl.sol';
import {LibString} from 'solady/utils/LibString.sol';

import {ArrayHelpers} from 'script/helpers/ArrayHelpers.sol';

contract S06_InteractWithLensV2 is Script, ForkManagement, ArrayHelpers {
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
        address governanceContractAdmin = json.readAddress(
            string(abi.encodePacked('.', targetEnv, '.GovernanceContractAdmin'))
        );

        if (isEnvSet('DEPLOYMENT_ENVIRONMENT')) {
            if (!LibString.eq(vm.envString('DEPLOYMENT_ENVIRONMENT'), 'production')) {
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

        hub = ILensHub(json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHub'))));
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

        Module[] memory actModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', targetEnv, '.Modules.v2.act'))),
            (Module[])
        );

        collectPublicationAction = CollectPublicationAction(
            findModuleHelper(actModules, 'CollectPublicationAction').addy
        );
        vm.label(address(collectPublicationAction), 'CollectPublicationAction');
        console.log('CollectPublicationAction: %s', address(collectPublicationAction));

        Module[] memory collectModules = abi.decode(
            vm.parseJson(json, string(abi.encodePacked('.', targetEnv, '.Modules.v2.collect'))),
            (Module[])
        );

        simpleFeeCollectModule = SimpleFeeCollectModule(
            findModuleHelper(collectModules, 'SimpleFeeCollectModule').addy
        );
        vm.label(address(simpleFeeCollectModule), 'SimpleFeeCollectModule');
        console.log('SimpleFeeCollectModule: %s', address(simpleFeeCollectModule));

        multirecipientFeeCollectModule = MultirecipientFeeCollectModule(
            findModuleHelper(collectModules, 'MultirecipientFeeCollectModule').addy
        );
        vm.label(address(multirecipientFeeCollectModule), 'MultirecipientFeeCollectModule');
        console.log('MultirecipientFeeCollectModule: %s', address(multirecipientFeeCollectModule));
    }

    function _interact() internal {
        vm.startBroadcast(deployer.ownerPk);
        ProfileCreationProxy temporarilyCreationProxy = new ProfileCreationProxy({
            owner: deployer.owner,
            hub: address(hub),
            lensHandles: address(handles),
            tokenHandleRegistry: address(tokenHandleRegistry)
        });
        vm.stopBroadcast();

        // TODO: Replace this with a true governance for a fork from production
        vm.startBroadcast(governance.ownerPk);
        governanceContract.lensHub_whitelistProfileCreator(address(temporarilyCreationProxy), true);
        vm.stopBroadcast();

        vm.startBroadcast(deployer.ownerPk);

        (uint256 firstProfileId, ) = temporarilyCreationProxy.proxyCreateProfileWithHandle({
            createProfileParams: Types.CreateProfileParams({
                to: deployer.owner,
                followModule: address(0),
                followModuleInitData: ''
            }),
            handle: 'firstprofile'
        });

        (uint256 secondProfileId, ) = temporarilyCreationProxy.proxyCreateProfileWithHandle({
            createProfileParams: Types.CreateProfileParams({
                to: deployer.owner,
                followModule: address(0),
                followModuleInitData: ''
            }),
            handle: 'secondprofile'
        });

        (uint256 anonymousProfileId, ) = temporarilyCreationProxy.proxyCreateProfileWithHandle({
            createProfileParams: Types.CreateProfileParams({
                to: deployer.owner,
                followModule: address(0),
                followModuleInitData: ''
            }),
            handle: 'annoymouse'
        });

        saveValue('AnonymousProfileId', vm.toString(anonymousProfileId));

        // set DE to publicActProxy
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: anonymousProfileId,
            delegatedExecutors: _toAddressArray(address(publicActProxy)),
            approvals: _toBoolArray(true)
        });

        hub.follow({
            followerProfileId: firstProfileId,
            idsOfProfilesToFollow: _toUint256Array(secondProfileId),
            followTokenIds: _toUint256Array(0),
            datas: _toBytesArray('')
        });

        hub.post(
            Types.PostParams({
                profileId: firstProfileId,
                contentURI: 'ipfs://HelloWorld',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // unfollow
        hub.unfollow({unfollowerProfileId: firstProfileId, idsOfProfilesToUnfollow: _toUint256Array(secondProfileId)});

        FeeConfig memory feeConfig = FeeConfig({
            currency: 0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e,
            amount: 69000000,
            recipient: address(0xcB6C7b2E340D50701d45d55507f19A5cE5d72330)
        });

        // set a follow module
        hub.setFollowModule({
            profileId: firstProfileId,
            followModule: address(feeFollowModule),
            followModuleInitData: abi.encode(feeConfig)
        });

        // set metadata
        hub.setProfileMetadataURI({profileId: firstProfileId, metadataURI: 'ipfs://TestingMetadataURI'});

        BaseFeeCollectModuleInitData memory collectModuleInitData = BaseFeeCollectModuleInitData({
            amount: 0,
            collectLimit: 69,
            currency: address(0),
            referralFee: 2500,
            followerOnly: false,
            endTimestamp: 0,
            recipient: address(0xcB6C7b2E340D50701d45d55507f19A5cE5d72330)
        });

        // comment with open action
        hub.comment(
            Types.CommentParams({
                profileId: firstProfileId,
                contentURI: 'ipfs://testCommentURI',
                pointedProfileId: firstProfileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _toAddressArray(address(collectPublicationAction)),
                actionModulesInitDatas: _toBytesArray(
                    abi.encode(simpleFeeCollectModule, abi.encode(collectModuleInitData))
                ),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // collect it
        hub.act(
            Types.PublicationActionParams({
                publicationActedProfileId: firstProfileId,
                publicationActedId: 2,
                actorProfileId: firstProfileId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                actionModuleAddress: address(collectPublicationAction),
                actionModuleData: abi.encode(
                    address(0x1A1cDf59C94a682a067fA2D288C2167a8506abd7),
                    abi.encode(address(0), 0)
                )
            })
        );

        // mirror
        hub.mirror(
            Types.MirrorParams({
                profileId: firstProfileId,
                metadataURI: 'ipfs://testMirrorURI',
                pointedProfileId: firstProfileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: ''
            })
        );

        // quote (all of the same one)
        hub.quote(
            Types.QuoteParams({
                profileId: firstProfileId,
                contentURI: 'ipfs://testQuoteURI',
                pointedProfileId: firstProfileId,
                pointedPubId: 1,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _emptyAddressArray(),
                actionModulesInitDatas: _emptyBytesArray(),
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        // block
        hub.setBlockStatus({
            byProfileId: firstProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(secondProfileId),
            blockStatus: _toBoolArray(true)
        });

        // unblock
        hub.setBlockStatus({
            byProfileId: firstProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(secondProfileId),
            blockStatus: _toBoolArray(false)
        });

        // set random address for profile manager
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: firstProfileId,
            delegatedExecutors: _toAddressArray(address(0x1A1cDf59C94a682a067fA2D288C2167a8506abd7)),
            approvals: _toBoolArray(true)
        });

        // unset profile guardian
        hub.DANGER__disableTokenGuardian();

        vm.stopBroadcast();

        // TODO: Replace this with a true governance for a fork from production
        vm.startBroadcast(governance.ownerPk);
        governanceContract.lensHub_whitelistProfileCreator(address(temporarilyCreationProxy), false);
        vm.stopBroadcast();
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadPrivateKeys();
        loadBaseAddresses();
        _interact();
    }
}
