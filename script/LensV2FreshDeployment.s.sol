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

import {ArrayHelpers} from 'test/helpers/ArrayHelpers.sol';

contract LensV2FreshDeployment is Script, ForkManagement, ArrayHelpers {
    using stdJson for string;

    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    string mnemonic;

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

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadPrivateKeys();
        deploy();
        _writeBackendEnvFile();
        _interact();
    }

    function deploy() internal {
        string memory addressesFile = 'addressesV2.txt';

        vm.startBroadcast(deployer.ownerPk);

        moduleRegistryImpl = new ModuleRegistry();
        console.log('\n+ + + ModuleRegistryIpml: %s', address(moduleRegistryImpl));
        vm.writeLine(addressesFile, string.concat('ModuleRegistryIpml: ', vm.toString(address(moduleRegistryImpl))));
        moduleRegistryProxy = new TransparentUpgradeableProxy({
            _logic: address(moduleRegistryImpl),
            admin_: proxyAdmin.owner,
            _data: ''
        });
        console.log('\n+ + + ModuleRegistry: %s', address(moduleRegistryProxy));
        vm.writeLine(addressesFile, string.concat('ModuleRegistry: ', vm.toString(address(moduleRegistryProxy))));
        moduleRegistry = ModuleRegistry(address(moduleRegistryProxy));

        uint256 currentDeployerNonce = vm.getNonce(deployer.owner);
        /**
         * FollowNFT (currentDeployerNonce)
         * LensHubInitializable aka LensHubImpl (currentDeployerNonce + 1)
         * TransparentUpgradeableProxy aka LensHubProxy (currentDeployerNonce + 2)
         */
        uint256 lensHubProxyDeploymentNonce = currentDeployerNonce + 2;
        address expectedLensHubProxyAddress = computeCreateAddress(deployer.owner, lensHubProxyDeploymentNonce);

        followNFT = new FollowNFT(expectedLensHubProxyAddress);
        console.log('\n+ + + FollowNFT: %s', address(followNFT));
        vm.writeLine(addressesFile, string.concat('FollowNFT: ', vm.toString(address(followNFT))));

        lensHubImpl = new LensHubInitializable({
            followNFTImpl: address(followNFT),
            collectNFTImpl: address(0), // No needed on a fresh V2 deployment, no publications will have legacy collect.
            moduleRegistry: address(moduleRegistry),
            tokenGuardianCooldown: 5 minutes,
            migrationParams: Types.MigrationParams({
                lensHandlesAddress: address(0),
                tokenHandleRegistryAddress: address(0),
                legacyFeeFollowModule: address(0),
                legacyProfileFollowModule: address(0),
                newFeeFollowModule: address(0),
                migrationAdmin: address(0)
            }) // No needed on a fresh V2 deployment, no migration needed.
        });
        console.log('\n+ + + LensHubImpl: %s', address(lensHubImpl));
        vm.writeLine(addressesFile, string.concat('LensHubImpl: ', vm.toString(address(lensHubImpl))));

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
        console.log('\n+ + + LensHub: %s', address(hub));
        vm.writeLine(addressesFile, string.concat('LensHub: ', vm.toString(address(hub))));

        handlesImpl = new LensHandles({
            owner: governance.owner,
            lensHub: address(hub),
            tokenGuardianCooldown: 5 minutes
        });
        console.log('\n+ + + LensHandlesImpl: %s', address(handlesImpl));
        vm.writeLine(addressesFile, string.concat('LensHandlesImpl: ', vm.toString(address(handlesImpl))));

        handlesProxy = new TransparentUpgradeableProxy({
            _logic: address(handlesImpl),
            admin_: proxyAdmin.owner,
            _data: ''
        });
        console.log('\n+ + + LensHandles: %s', address(handlesProxy));
        vm.writeLine(addressesFile, string.concat('LensHandles: ', vm.toString(address(handlesProxy))));
        handles = ILensHandles(address(handlesProxy));

        tokenHandleRegistryImpl = new TokenHandleRegistry({lensHub: address(hub), lensHandles: address(handles)});
        console.log('\n+ + + TokenHandleRegistryImpl: %s', address(tokenHandleRegistryImpl));
        vm.writeLine(
            addressesFile,
            string.concat('TokenHandleRegistryImpl: ', vm.toString(address(tokenHandleRegistryImpl)))
        );

        tokenHandleRegistryProxy = new TransparentUpgradeableProxy({
            _logic: address(tokenHandleRegistryImpl),
            admin_: proxyAdmin.owner,
            _data: ''
        });
        console.log('\n+ + + TokenHandleRegistry: %s', address(tokenHandleRegistryProxy));
        vm.writeLine(
            addressesFile,
            string.concat('TokenHandleRegistry: ', vm.toString(address(tokenHandleRegistryProxy)))
        );
        tokenHandleRegistry = ITokenHandleRegistry(address(tokenHandleRegistryProxy));

        profileCreationProxy = new ProfileCreationProxy({
            owner: profileCreator.owner,
            hub: address(hub),
            lensHandles: address(handles),
            tokenHandleRegistry: address(tokenHandleRegistry)
        });
        console.log('\n+ + + ProfileCreationProxy: %s', address(profileCreationProxy));
        vm.writeLine(
            addressesFile,
            string.concat('ProfileCreationProxy: ', vm.toString(address(profileCreationProxy)))
        );

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
        console.log('\n+ + + CollectNFT: %s', address(collectNFT));
        vm.writeLine(addressesFile, string.concat('CollectNFT: ', vm.toString(address(collectNFT))));

        collectPublicationActionImpl = new CollectPublicationAction({
            hub: address(hub),
            collectNFTImpl: address(collectNFT)
        });
        console.log('\n+ + + CollectPublicationActionImpl: %s', address(collectPublicationActionImpl));
        vm.writeLine(
            addressesFile,
            string.concat('CollectPublicationActionImpl: ', vm.toString(address(collectPublicationActionImpl)))
        );

        collectPublicationActionProxy = new TransparentUpgradeableProxy({
            _logic: address(collectPublicationActionImpl),
            admin_: proxyAdmin.owner,
            _data: ''
        });
        console.log('\n+ + + CollectPublicationActionProxy: %s', address(collectPublicationActionProxy));
        vm.writeLine(
            addressesFile,
            string.concat('CollectPublicationActionProxy: ', vm.toString(address(collectPublicationActionProxy)))
        );
        collectPublicationAction = CollectPublicationAction(address(collectPublicationActionProxy));

        simpleFeeCollectModule = new SimpleFeeCollectModule({
            hub: address(hub),
            actionModule: address(collectPublicationActionProxy)
        });
        console.log('\n+ + + SimpleFeeCollectModule: %s', address(simpleFeeCollectModule));
        vm.writeLine(
            addressesFile,
            string.concat('SimpleFeeCollectModule: ', vm.toString(address(simpleFeeCollectModule)))
        );

        multirecipientFeeCollectModule = new MultirecipientFeeCollectModule({
            hub: address(hub),
            actionModule: address(collectPublicationActionProxy)
        });
        console.log('\n+ + + MultirecipientFeeCollectModule: %s', address(multirecipientFeeCollectModule));
        vm.writeLine(
            addressesFile,
            string.concat('MultirecipientFeeCollectModule: ', vm.toString(address(multirecipientFeeCollectModule)))
        );

        feeFollowModule = new FeeFollowModule({hub: address(hub)});
        console.log('\n+ + + FeeFollowModule: %s', address(feeFollowModule));
        vm.writeLine(addressesFile, string.concat('FeeFollowModule: ', vm.toString(address(feeFollowModule))));

        revertFollowModule = new RevertFollowModule();
        console.log('\n+ + + RevertFollowModule: %s', address(revertFollowModule));
        vm.writeLine(addressesFile, string.concat('RevertFollowModule: ', vm.toString(address(revertFollowModule))));

        degreesOfSeparationReferenceModule = new DegreesOfSeparationReferenceModule({hub: address(hub)});
        console.log('\n+ + + DegreesOfSeparationReferenceModule: %s', address(degreesOfSeparationReferenceModule));
        vm.writeLine(
            addressesFile,
            string.concat(
                'DegreesOfSeparationReferenceModule: ',
                vm.toString(address(degreesOfSeparationReferenceModule))
            )
        );

        followerOnlyReferenceModule = new FollowerOnlyReferenceModule({hub: address(hub)});
        console.log('\n+ + + FollowerOnlyReferenceModule: %s', address(followerOnlyReferenceModule));
        vm.writeLine(
            addressesFile,
            string.concat('FollowerOnlyReferenceModule: ', vm.toString(address(followerOnlyReferenceModule)))
        );

        // NOTE: TokenGatedReferenceModule temporarily removed from the deployment
        // tokenGatedReferenceModule = new TokenGatedReferenceModule({hub: address(hub)});
        // console.log('\n+ + + TokenGatedReferenceModule: %s', address(tokenGatedReferenceModule));
        // vm.writeLine(
        //     addressesFile,
        //     string.concat('TokenGatedReferenceModule: ', vm.toString(address(tokenGatedReferenceModule)))
        // );

        vm.writeLine(
            addressesFile,
            string.concat('FollowerOnlyReferenceModule: ', vm.toString(address(followerOnlyReferenceModule)))
        );

        vm.stopBroadcast();

        // This can potentially be moved to a `setUp` function after the `deploy` one.
        vm.startBroadcast(governance.ownerPk);

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

        hub.whitelistProfileCreator(address(profileCreationProxy), true);
        console.log('\n* * * Profile creator proxy registered as profile creator');

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

        hub.setState(Types.ProtocolState.Unpaused);
        console.log('\n* * * Protocol unpaused');

        vm.stopBroadcast();
    }

    function _interact() internal {
        vm.broadcast(deployer.ownerPk);
        ProfileCreationProxy temporarilyCreationProxy = new ProfileCreationProxy({
            owner: deployer.owner,
            hub: address(hub),
            lensHandles: address(handles),
            tokenHandleRegistry: address(tokenHandleRegistry)
        });

        vm.broadcast(governance.ownerPk);
        hub.whitelistProfileCreator(address(temporarilyCreationProxy), true);

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

        vm.broadcast(governance.ownerPk);
        hub.whitelistProfileCreator(address(temporarilyCreationProxy), false);
    }

    function _writeBackendEnvFile() internal {
        string memory backendEnv = 'backendEnv.txt';
        vm.writeLine(backendEnv, '## Hub');
        vm.writeLine(backendEnv, string.concat('LENS_HUB_PROXY=', vm.toString(address(hub))));
        vm.writeLine(backendEnv, '## LensHandles');
        vm.writeLine(backendEnv, string.concat('LENS_HANDLE_PROXY=', vm.toString(address(handles))));
        vm.writeLine(backendEnv, '# TokenHandleRegistry');
        vm.writeLine(
            backendEnv,
            string.concat('LENS_TOKEN_HANDLE_REGISTRY_PROXY=', vm.toString(address(tokenHandleRegistry)))
        );
        vm.writeLine(backendEnv, '# Collection open actions');
        vm.writeLine(
            backendEnv,
            string.concat('LENS_COLLECT_PUBLICATION_ACTION_PROXY=', vm.toString(address(collectPublicationAction)))
        );
        vm.writeLine(backendEnv, '## Profile creation proxy');
        vm.writeLine(backendEnv, string.concat('PROFILE_CREATION_PROXY=', vm.toString(address(profileCreationProxy))));
        vm.writeLine(backendEnv, '## ModuleGlobals');
        vm.writeLine(backendEnv, string.concat('GLOBAL_MODULE=', vm.toString(address(moduleRegistry))));
        vm.writeLine(backendEnv, '# v2 modules');
        vm.writeLine(
            backendEnv,
            string.concat(
                'MULTIRECIPIENT_FEE_COLLECT_OPEN_ACTION_MODULE=',
                vm.toString(address(multirecipientFeeCollectModule))
            )
        );
        vm.writeLine(
            backendEnv,
            string.concat('SIMPLE_COLLECT_OPEN_ACTION_MODULE=', vm.toString(address(simpleFeeCollectModule)))
        );
        vm.writeLine(backendEnv, '### follow modules');
        vm.writeLine(backendEnv, string.concat('FEE_FOLLOW_MODULE=', vm.toString(address(feeFollowModule))));
        vm.writeLine(backendEnv, string.concat('REVERT_FOLLOW_MODULE=', vm.toString(address(revertFollowModule))));
        vm.writeLine(backendEnv, '## REFERENCE MODULES');
        vm.writeLine(
            backendEnv,
            string.concat('FOLLOWER_ONLY_REFERENCE_MODULE=', vm.toString(address(followerOnlyReferenceModule)))
        );
        vm.writeLine(
            backendEnv,
            string.concat(
                'DEGREE_OF_SEPERATION_REFERENCE_MODULE=',
                vm.toString(address(degreesOfSeparationReferenceModule))
            )
        );
    }
}
