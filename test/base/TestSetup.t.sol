// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

// Deployments
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {ArrayHelpers} from 'test/helpers/ArrayHelpers.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';
import {MetaTxLib} from 'contracts/libraries/MetaTxLib.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import 'test/Constants.sol';
import {LibString} from 'solady/utils/LibString.sol';
import {ContractAddressesLoaderDeployer} from 'test/base/ContractAddressesLoaderDeployer.t.sol';

import {LensHub} from 'contracts/LensHub.sol';
import {LensHubInitializable} from 'contracts/misc/LensHubInitializable.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {LegacyCollectNFT} from 'contracts/misc/LegacyCollectNFT.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {LensHandles} from 'contracts/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/namespaces/TokenHandleRegistry.sol';
import {MockActionModule} from 'test/mocks/MockActionModule.sol';
import {MockReferenceModule} from 'test/mocks/MockReferenceModule.sol';
import {ModuleRegistry} from 'contracts/misc/ModuleRegistry.sol';
import {ILensGovernable} from 'contracts/interfaces/ILensGovernable.sol';

import {ProfileTokenURI} from 'contracts/misc/token-uris/ProfileTokenURI.sol';
import {FollowTokenURI} from 'contracts/misc/token-uris/FollowTokenURI.sol';
import {HandleTokenURI} from 'contracts/misc/token-uris/HandleTokenURI.sol';

// TODO: Move these to Interface file in test folder.
struct OldCreateProfileParams {
    address to;
    string handle;
    string imageURI;
    address followModule;
    bytes followModuleInitData;
    string followNFTURI;
}

struct OldMirrorData {
    uint256 profileId;
    uint256 pointedProfileId;
    uint256 pointedPubId;
    bytes referenceModuleData;
    address referenceModule;
    bytes referenceModuleInitData;
}

struct OldPostData {
    uint256 profileId;
    string contentURI;
    address collectModule;
    bytes collectModuleInitData;
    address referenceModule;
    bytes referenceModuleInitData;
}

struct OldCommentData {
    uint256 profileId;
    string contentURI;
    uint256 profileIdPointed;
    uint256 pubIdPointed;
    bytes referenceModuleData;
    address collectModule;
    bytes collectModuleInitData;
    address referenceModule;
    bytes referenceModuleInitData;
}

struct OldProfileStruct {
    uint256 pubCount;
    address followModule;
    address followNFT;
    string handle;
    string imageURI;
    string followNFTURI;
}

interface IOldHub {
    function createProfile(OldCreateProfileParams memory createProfileParams) external returns (uint256);

    function follow(uint256[] calldata profileIds, bytes[] calldata datas) external returns (uint256[] memory);

    function collect(uint256 profileId, uint256 pubId, bytes calldata data) external returns (uint256);

    function post(OldPostData calldata vars) external returns (uint256);

    function comment(OldCommentData calldata vars) external returns (uint256);

    function mirror(OldMirrorData memory createProfileParams) external returns (uint256);

    function getProfile(uint256 profileId) external view returns (OldProfileStruct memory);

    function getCollectNFTImpl() external view returns (address);
}

contract TestSetup is Test, ContractAddressesLoaderDeployer, ArrayHelpers {
    using stdJson for string;

    function testTestSetup() public {
        // Prevents being counted in Foundry Coverage
    }

    function loadBaseAddresses(string memory targetEnv) internal virtual {
        console.log('targetEnv:', targetEnv);

        lensVersion = forkVersion;

        hubProxyAddr = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHub')));
        vm.label(hubProxyAddr, 'LENS_HUB');
        console.log('hubProxyAddr:', hubProxyAddr);

        hub = LensHub(hubProxyAddr);

        console.log('Hub:', address(hub));

        address followNFTAddr = hub.getFollowNFTImpl();

        address legacyCollectNFTAddr;
        if (lensVersion == 2) {
            legacyCollectNFTAddr = hub.getLegacyCollectNFTImpl();
        } else {
            console.log('lensVersion is: %s. Trying to getCollectNFTImpl...', lensVersion);
            legacyCollectNFTAddr = IOldHub(address(hub)).getCollectNFTImpl();
        }

        address hubImplAddr = address(uint160(uint256(vm.load(hubProxyAddr, PROXY_IMPLEMENTATION_STORAGE_SLOT))));
        console.log('Found hubImplAddr:', hubImplAddr);
        hubImpl = LensHubInitializable(hubImplAddr);
        followNFT = FollowNFT(followNFTAddr);
        legacyCollectNFT = LegacyCollectNFT(legacyCollectNFTAddr);
        hubAsProxy = TransparentUpgradeableProxy(payable(address(hub)));

        governanceMultisig = hub.getGovernance();
        vm.label(governanceMultisig, 'GOVERNANCE_MULTISIG');

        governance = governanceMultisig; // TODO: Temporary, look at ContractAddresses.sol for context

        deployer = _loadAddressAs('DEPLOYER');

        migrationAdmin = _loadAddressAs('MIGRATION_ADMIN');

        if (lensVersion == 2) {
            treasury = hub.getTreasury();
            vm.label(treasury, 'TREASURY');

            TREASURY_FEE_BPS = hub.getTreasuryFee();
        } else {
            ILensGovernable moduleGlobals = ILensGovernable(
                json.readAddress(string(abi.encodePacked('.', targetEnv, '.ModuleGlobals')))
            );
            vm.label(address(moduleGlobals), 'ModuleGlobals');
            console.log('ModuleGlobals: %s', address(moduleGlobals));

            treasury = moduleGlobals.getTreasury();
            console.log('Real Treasury: %s', treasury);

            TREASURY_FEE_BPS = moduleGlobals.getTreasuryFee();
            console.log('Real Treasury Fee: %s', TREASURY_FEE_BPS);
        }

        proxyAdmin = address(uint160(uint256(vm.load(hubProxyAddr, ADMIN_SLOT))));
        vm.label(proxyAdmin, 'HUB_PROXY_ADMIN');

        if (keyExists(json, string(abi.encodePacked('.', targetEnv, '.LensHandles')))) {
            console.log('LensHandles key does exist');
            lensHandles = LensHandles(json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHandles'))));
        } else {
            console.log('LensHandles key does not exist');
            if (forkVersion == 1) {
                console.log('No LensHandles address found - deploying new one');
                address lensHandlesImpl = address(
                    new LensHandles(governanceMultisig, address(hubAsProxy), HANDLE_GUARDIAN_COOLDOWN)
                );
                vm.label(lensHandlesImpl, 'LENS_HANDLES_IMPL');

                // TODO: Replace deployer owner with proxyAdmin.
                lensHandles = LensHandles(address(new TransparentUpgradeableProxy(lensHandlesImpl, deployer, '')));
                vm.label(address(lensHandles), 'LENS_HANDLES');
            } else {
                console.log('No LensHandles address found in addressBook, which is required for V2');
                revert('No LensHandles address found in addressBook, which is required for V2');
            }
        }

        if (keyExists(json, string(abi.encodePacked('.', targetEnv, '.TokenHandleRegistry')))) {
            console.log('TokenHandleRegistry key does exist');
            tokenHandleRegistry = TokenHandleRegistry(
                json.readAddress(string(abi.encodePacked('.', targetEnv, '.TokenHandleRegistry')))
            );
        } else {
            console.log('TokenHandleRegistry key does not exist');
            if (forkVersion == 1) {
                address tokenHandleRegistryImpl = address(
                    new TokenHandleRegistry(address(hubAsProxy), address(lensHandles))
                );
                vm.label(tokenHandleRegistryImpl, 'TOKEN_HANDLE_REGISTRY_IMPL');

                // TODO: Replace deployer owner with proxyAdmin.
                tokenHandleRegistry = TokenHandleRegistry(
                    address(new TransparentUpgradeableProxy(tokenHandleRegistryImpl, deployer, ''))
                );
                vm.label(address(tokenHandleRegistry), 'TOKEN_HANDLE_REGISTRY');
            } else {
                console.log('No TokenHandleRegistry address found in addressBook, which is required for V2');
                revert('No TokenHandleRegistry address found in addressBook, which is required for V2');
            }
        }

        loadOrDeploy_GovernanceContract();

        loadOrDeploy_ProxyAdminContract();

        loadOrDeploy_ModuleRegistryContract();

        loadOrDeploy_ProfileTokenURIContract();
        loadOrDeploy_FollowTokenURIContract();
        loadOrDeploy_HandleTokenURIContract();

        if (lensVersion == 1) {
            vm.prank(governance);
            hub.whitelistProfileCreator(address(this), true);
            beforeUpgrade();
            upgradeToV2();
        }

        if (forkVersion == 2) {
            lensVersion = 2;
        }

        vm.startPrank(deployer);

        // Deploy the MockActionModule.
        mockActionModule = new MockActionModule(address(this));
        vm.label(address(mockActionModule), 'MOCK_ACTION_MODULE');

        // Deploy the MockReferenceModule.
        mockReferenceModule = new MockReferenceModule(address(this));
        vm.label(address(mockReferenceModule), 'MOCK_REFERENCE_MODULE');

        vm.stopPrank();
        ///////////////////////////////////////// End deployments.
    }

    function beforeUpgrade() internal virtual {
        // Override to execute Lens V1 state setup.
    }

    function upgradeToV2() internal virtual {
        // Precompute needed addresses.
        address followNFTImplAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 1);
        address legacyCollectNFTImplAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 2);

        vm.startPrank(deployer);
        // Deploy implementation contracts.
        // TODO: Last 3 addresses are for the follow modules for migration purposes.
        hubImpl = new LensHubInitializable({ // TODO: Should we use the usual LensHub, not Initializable?
            followNFTImpl: followNFTImplAddr,
            collectNFTImpl: legacyCollectNFTImplAddr,
            moduleRegistry: address(moduleRegistry),
            tokenGuardianCooldown: PROFILE_GUARDIAN_COOLDOWN,
            migrationParams: Types.MigrationParams({
                lensHandlesAddress: address(lensHandles),
                tokenHandleRegistryAddress: address(tokenHandleRegistry),
                legacyFeeFollowModule: address(0), // TODO: Fill this in
                legacyProfileFollowModule: address(0), // TODO: Fill this in
                newFeeFollowModule: address(0) // TODO: Fill this in
            })
        });
        followNFT = new FollowNFT(hubProxyAddr);
        legacyCollectNFT = new LegacyCollectNFT(hubProxyAddr);
        vm.stopPrank();

        // Upgrade the hub.
        TransparentUpgradeableProxy oldHubAsProxy = TransparentUpgradeableProxy(payable(hubProxyAddr));
        vm.prank(proxyAdmin);
        oldHubAsProxy.upgradeTo(address(hubImpl));

        vm.startPrank(governance);
        hub.setTreasury(treasury);
        hub.setTreasuryFee(TREASURY_FEE_BPS);
        hub.setProfileTokenURIContract(address(profileTokenURIContract));
        hub.setFollowTokenURIContract(address(followTokenURIContract));
        vm.stopPrank();

        vm.startPrank(lensHandles.OWNER());
        lensHandles.setHandleTokenURIContract(address(handleTokenURIContract));
        vm.stopPrank();

        lensVersion = 2;
    }

    function deployBaseContracts() internal {
        deployer = _loadAddressAs('DEPLOYER');
        governanceMultisig = _loadAddressAs('GOVERNANCE_MULTISIG');
        governance = governanceMultisig; // TODO: Temporary, look at ContractAddresses.sol for context
        treasury = _loadAddressAs('TREASURY');
        migrationAdmin = _loadAddressAs('MIGRATION_ADMIN');

        TREASURY_FEE_BPS = 50;

        ///////////////////////////////////////// Start deployments.
        vm.startPrank(deployer);

        // Deploy ModuleRegistry implementation and proxy.
        address moduleRegistryImpl = address(new ModuleRegistry());
        vm.label(moduleRegistryImpl, 'MODULE_REGISTRY_IMPL');

        moduleRegistry = ModuleRegistry(address(new TransparentUpgradeableProxy(moduleRegistryImpl, deployer, '')));
        vm.label(address(moduleRegistry), 'MODULE_REGISTRY');

        // Precompute needed addresses.
        address followNFTImplAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 1);
        address legacyCollectNFTImplAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 2);
        hubProxyAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 3);
        address lensHandlesImplAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 4);
        address lensHandlesProxyAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 5);
        address tokenHandleRegistryImplAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 6);
        address tokenHandleRegistryProxyAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 7);

        // Deploy implementation contracts.
        // TODO: Last 3 addresses are for the follow modules for migration purposes.
        hubImpl = new LensHubInitializable({
            followNFTImpl: followNFTImplAddr,
            collectNFTImpl: legacyCollectNFTImplAddr,
            moduleRegistry: address(moduleRegistry),
            tokenGuardianCooldown: PROFILE_GUARDIAN_COOLDOWN,
            migrationParams: Types.MigrationParams({
                lensHandlesAddress: lensHandlesProxyAddr,
                tokenHandleRegistryAddress: tokenHandleRegistryProxyAddr,
                legacyFeeFollowModule: address(0),
                legacyProfileFollowModule: address(0),
                newFeeFollowModule: address(0)
            })
        });
        followNFT = new FollowNFT(hubProxyAddr);
        legacyCollectNFT = new LegacyCollectNFT(hubProxyAddr);

        // Deploy and initialize proxy.
        bytes memory initData = abi.encodeCall(
            hubImpl.initialize,
            ('Lens Protocol Profiles', 'LPP', governanceMultisig) // TODO: Replace this with GovernanceContract
        );
        // TODO: Replace deployer owner with proxyAdmin.
        hubAsProxy = new TransparentUpgradeableProxy(address(hubImpl), deployer, initData);

        // Deploy LensHandles implementation.
        address lensHandlesImpl = address(
            new LensHandles(governanceMultisig, address(hubAsProxy), HANDLE_GUARDIAN_COOLDOWN)
        );
        assertEq(lensHandlesImpl, lensHandlesImplAddr);
        vm.label(lensHandlesImpl, 'LENS_HANDLES_IMPL');

        // TODO: Replace deployer owner with proxyAdmin.
        lensHandles = LensHandles(address(new TransparentUpgradeableProxy(lensHandlesImpl, deployer, '')));
        assertEq(address(lensHandles), lensHandlesProxyAddr);
        vm.label(address(lensHandles), 'LENS_HANDLES');

        // Deploy TokenHandleRegistry implementation.
        address tokenHandleRegistryImpl = address(new TokenHandleRegistry(address(hubAsProxy), lensHandlesProxyAddr));
        assertEq(tokenHandleRegistryImpl, tokenHandleRegistryImplAddr);
        vm.label(tokenHandleRegistryImpl, 'TOKEN_HANDLE_REGISTRY_IMPL');

        // TODO: Replace deployer owner with proxyAdmin.
        tokenHandleRegistry = TokenHandleRegistry(
            address(new TransparentUpgradeableProxy(tokenHandleRegistryImpl, deployer, ''))
        );
        assertEq(address(tokenHandleRegistry), tokenHandleRegistryProxyAddr);
        vm.label(address(tokenHandleRegistry), 'TOKEN_HANDLE_REGISTRY');

        // Cast proxy to LensHub interface.
        hub = LensHub(address(hubAsProxy));
        vm.label(address(hub), 'LENS_HUB');

        proxyAdmin = address(uint160(uint256(vm.load(hubProxyAddr, ADMIN_SLOT))));
        vm.label(proxyAdmin, 'HUB_PROXY_ADMIN');

        // Deploy the MockActionModule.
        mockActionModule = new MockActionModule(address(this));
        vm.label(address(mockActionModule), 'MOCK_ACTION_MODULE');

        // Deploy the MockReferenceModule.
        mockReferenceModule = new MockReferenceModule(address(this));
        vm.label(address(mockReferenceModule), 'MOCK_REFERENCE_MODULE');

        profileTokenURIContract = new ProfileTokenURI();
        vm.label(address(profileTokenURIContract), 'PROFILE_TOKEN_URI');

        followTokenURIContract = new FollowTokenURI();
        vm.label(address(followTokenURIContract), 'FOLLOW_TOKEN_URI');

        handleTokenURIContract = new HandleTokenURI();
        vm.label(address(handleTokenURIContract), 'HANDLE_TOKEN_URI');

        vm.stopPrank();
        ///////////////////////////////////////// End deployments.

        vm.startPrank(governance);
        hub.setTreasury(treasury);
        hub.setTreasuryFee(TREASURY_FEE_BPS);
        hub.setProfileTokenURIContract(address(profileTokenURIContract));
        hub.setFollowTokenURIContract(address(followTokenURIContract));
        vm.stopPrank();

        vm.startPrank(lensHandles.OWNER());
        lensHandles.setHandleTokenURIContract(address(handleTokenURIContract));
        vm.stopPrank();

        lensVersion = 2;
    }

    function setUp() public virtual override {
        if (__setUpDone) {
            // Avoid setUp to be run more than once.
            return;
        }

        super.setUp();

        if (bytes(forkEnv).length > 0) {
            loadBaseAddresses(forkEnv);
        } else {
            deployBaseContracts();
        }
        ///////////////////////////////////////// Start governance actions.
        vm.startPrank(governanceMultisig);

        if (hub.getState() != Types.ProtocolState.Unpaused) {
            hub.setState(Types.ProtocolState.Unpaused);
        }

        // Whitelist the test contract as a profile creator
        hub.whitelistProfileCreator(address(this), true);

        vm.stopPrank();
        ///////////////////////////////////////// End governance actions.

        domainSeparator = keccak256(
            abi.encode(
                Typehash.EIP712_DOMAIN,
                keccak256('Lens Protocol Profiles'),
                MetaTxLib.EIP712_DOMAIN_VERSION_HASH,
                block.chainid,
                hubProxyAddr
            )
        );

        if (lensVersion == 2) {
            defaultAccount = _loadAccountAs('DEFAULT_ACCOUNT');
            defaultPub = _loadDefaultPublication();
        }

        if (lensVersion == 0) {
            console.log("LensVersion is 0 - something's not right");
            revert("LensVersion is 0 - something's not right");
        }

        // Avoid setUp to be run more than once.
        __setUpDone = true;
        console.log("TestSetup's setUp() done");
    }

    function _createProfile(address profileOwner) internal returns (uint256) {
        Types.CreateProfileParams memory createProfileParams = _getDefaultCreateProfileParams();
        createProfileParams.to = profileOwner;
        console.log('CREATING PROFILE');
        return hub.createProfile(createProfileParams);
    }

    function _createProfile(address profileOwner, string memory handle) internal returns (uint256) {
        OldCreateProfileParams memory oldCreateProfileParams = OldCreateProfileParams({
            to: profileOwner,
            handle: LibString.lower(handle),
            imageURI: string.concat(MOCK_URI, '/imageURI/', LibString.lower(handle)),
            followModule: address(0),
            followModuleInitData: '',
            followNFTURI: string.concat(MOCK_URI, '/followNFTURI/', LibString.lower(handle))
        });
        uint256 profileId = IOldHub(address(hub)).createProfile(oldCreateProfileParams);
        console.log('CREATING V1 PROFILE: %s (Profile#%s)', LibString.lower(handle), profileId);
        return profileId;
    }

    function _loadAccountAs(string memory accountLabel) internal returns (TestAccount memory) {
        return _loadAccountAs({accountLabel: accountLabel, requireCustomProfileOnFork: false});
    }

    function _loadAccountAs(
        string memory accountLabel,
        bool requireCustomProfileOnFork
    ) internal returns (TestAccount memory) {
        // We derive a new account from the given label.
        (address accountOwner, uint256 accountOwnerPk) = makeAddrAndKey(accountLabel);
        uint256 accountProfileId;
        if (fork) {
            // If testing in a fork, load the desired profile from .env and transfer it to the derived account.
            accountProfileId = vm.envOr({
                name: string.concat('FORK_TEST_ACCOUNT__', accountLabel, '__PROFILE_ID'),
                defaultValue: uint256(0)
            });
            // If the custom profile wasn't founde in the .env file and it was required, reverts.
            if (accountProfileId == 0 && requireCustomProfileOnFork) {
                revert(
                    string.concat(
                        'Custom profile not set for ',
                        accountLabel,
                        '. Add ',
                        string.concat('FORK_TEST_ACCOUNT__', accountLabel, '__PROFILE_ID'),
                        ' env variable or set `requireCustomProfileOnFork` as false for it.'
                    )
                );
            }
        }
        if (accountProfileId != 0) {
            // If profile was loaded from .env, we transfer it to the generated account. This is needed as otherwise we
            // won't have the private key of the owner, which is needed for signing meta-tx in some tests.
            address currentProfileOwner = hub.ownerOf(accountProfileId);

            vm.startPrank(currentProfileOwner);
            if (hub.getTokenGuardianDisablingTimestamp(currentProfileOwner) == 0) {
                hub.DANGER__disableTokenGuardian();
            }
            if (hub.getTokenGuardianDisablingTimestamp(currentProfileOwner) > block.timestamp) {
                vm.warp(hub.getTokenGuardianDisablingTimestamp(currentProfileOwner));
            }
            hub.transferFrom(currentProfileOwner, accountOwner, accountProfileId);
            vm.stopPrank();
        } else {
            // If profile was not loaded yet, we create a fresh one.
            if (lensVersion == 1) {
                accountProfileId = _createProfile(accountOwner, accountLabel);
            } else if (lensVersion == 2) {
                accountProfileId = _createProfile(accountOwner);
            } else {
                console.log('Lens version %s is not supported', lensVersion);
                revert('Lens version not supported');
            }
        }
        return TestAccount({ownerPk: accountOwnerPk, owner: accountOwner, profileId: accountProfileId});
    }

    function _loadDefaultPublication() internal returns (TestPublication memory) {
        if (fork) {
            // If testing in a fork, try loading the profile ID from .env file.
            uint256 profileId = vm.envOr({name: 'FORK_TEST_PUB__DEFAULT__PROFILE_ID', defaultValue: uint256(0)});
            if (profileId != 0) {
                // If profile ID was in the .env file, pub ID must be there too, otherwise fail.
                uint256 pubId = vm.envUint('FORK_TEST_PUB__DEFAULT__PUB_ID');
                Types.PublicationType loadedPubType = hub.getPublicationType(profileId, pubId);
                if (loadedPubType == Types.PublicationType.Nonexistent) {
                    revert('Default publication loaded from .env file does not exist in the fork you are testing on.');
                } else if (loadedPubType == Types.PublicationType.Mirror) {
                    // As you cannot reference a mirror or act on it.
                    revert('Default publication loaded from .env file cannot be a mirror.');
                }
                return TestPublication(profileId, pubId);
            }
        }
        vm.prank(defaultAccount.owner);
        return TestPublication(defaultAccount.profileId, hub.post(_getDefaultPostParams()));
    }

    function _loadAddressAs(string memory addressLabel) internal returns (address) {
        address loadedAddress;
        if (fork) {
            loadedAddress = vm.envOr({
                name: string.concat('FORK__', addressLabel, '__ADDRESS'),
                defaultValue: address(0)
            });
            if (loadedAddress != address(0)) {
                vm.label(loadedAddress, addressLabel);
                return loadedAddress;
            }
        }
        return makeAddr(addressLabel);
    }

    function _getNextProfileId() internal view returns (uint256) {
        return uint256(vm.load(hubProxyAddr, bytes32(uint256(StorageLib.PROFILE_COUNTER_SLOT)))) + 1;
    }

    function _getDefaultCreateProfileParams() internal view returns (Types.CreateProfileParams memory) {
        return
            Types.CreateProfileParams({to: defaultAccount.owner, followModule: address(0), followModuleInitData: ''});
    }

    function _getDefaultPostParams() internal view returns (Types.PostParams memory) {
        return
            Types.PostParams({
                profileId: defaultAccount.profileId,
                contentURI: MOCK_URI,
                actionModules: _toAddressArray(address(mockActionModule)),
                actionModulesInitDatas: _toBytesArray(abi.encode(true)),
                referenceModule: address(0),
                referenceModuleInitData: ''
            });
    }

    function _getDefaultCommentParams() internal view returns (Types.CommentParams memory) {
        return
            Types.CommentParams({
                profileId: defaultAccount.profileId,
                contentURI: MOCK_URI,
                pointedProfileId: defaultPub.profileId,
                pointedPubId: defaultPub.pubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _toAddressArray(address(mockActionModule)),
                actionModulesInitDatas: _toBytesArray(abi.encode(true)),
                referenceModule: address(0),
                referenceModuleInitData: ''
            });
    }

    function _getDefaultMirrorParams() internal view returns (Types.MirrorParams memory) {
        return
            Types.MirrorParams({
                profileId: defaultAccount.profileId,
                metadataURI: '',
                pointedProfileId: defaultPub.profileId,
                pointedPubId: defaultPub.pubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: ''
            });
    }

    function _getDefaultQuoteParams() internal view returns (Types.QuoteParams memory) {
        return
            Types.QuoteParams({
                profileId: defaultAccount.profileId,
                contentURI: MOCK_URI,
                pointedProfileId: defaultPub.profileId,
                pointedPubId: defaultPub.pubId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referenceModuleData: '',
                actionModules: _toAddressArray(address(mockActionModule)),
                actionModulesInitDatas: _toBytesArray(abi.encode(true)),
                referenceModule: address(0),
                referenceModuleInitData: ''
            });
    }

    function _getDefaultPublicationActionParams() internal view returns (Types.PublicationActionParams memory) {
        return
            Types.PublicationActionParams({
                publicationActedProfileId: defaultPub.profileId,
                publicationActedId: defaultPub.pubId,
                actorProfileId: defaultAccount.profileId,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                actionModuleAddress: address(mockActionModule),
                actionModuleData: abi.encode(true)
            });
    }
}
