// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

// Deployments
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {LensHub} from 'contracts/LensHub.sol';
import {LensHubInitializable} from 'contracts/misc/LensHubInitializable.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {LegacyCollectNFT} from 'contracts/misc/LegacyCollectNFT.sol';
import {ModuleGlobals} from 'contracts/misc/ModuleGlobals.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {ProfileTokenURILib} from 'contracts/libraries/token-uris/ProfileTokenURILib.sol';
import {MockActionModule} from 'test/mocks/MockActionModule.sol';
import {MockReferenceModule} from 'test/mocks/MockReferenceModule.sol';
import {ForkManagement} from 'test/helpers/ForkManagement.sol';
import {ArrayHelpers} from 'test/helpers/ArrayHelpers.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';
import {MetaTxLib} from 'contracts/libraries/MetaTxLib.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import 'test/Constants.sol';
import {LensHandles} from 'contracts/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/namespaces/TokenHandleRegistry.sol';

contract TestSetup is Test, ForkManagement, ArrayHelpers {
    using stdJson for string;

    function testTestSetup() public {
        // Prevents being counted in Foundry Coverage
    }

    ////////////////////////////////// Types
    struct TestAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    struct TestPublication {
        uint256 profileId;
        uint256 pubId;
    }

    ////////////////////////////////// Accounts
    TestAccount defaultAccount;

    ////////////////////////////////// Publications
    TestPublication defaultPub;

    ////////////////////////////////// Relevant actors' addresses
    address deployer;
    address governance;
    address treasury;
    address modulesGovernance;
    address proxyAdmin;

    ////////////////////////////////// Relevant values or constants
    uint16 TREASURY_FEE_BPS;
    uint16 constant TREASURY_FEE_MAX_BPS = 10000; // TODO: This should be a constant in 'contracts/libraries/constants/'
    string constant MOCK_URI = 'ipfs://QmUXfQWe43RKx31VzA2BnbwhSMW8WuaJvszFWChD59m76U';
    bytes32 domainSeparator;

    ////////////////////////////////// Deployed addresses
    address hubProxyAddr;
    LegacyCollectNFT legacyCollectNFT;
    FollowNFT followNFT;
    LensHubInitializable hubImpl;
    TransparentUpgradeableProxy hubAsProxy;
    LensHub hub;
    MockActionModule mockActionModule;
    MockReferenceModule mockReferenceModule;
    ModuleGlobals moduleGlobals;
    LensHandles lensHandles;
    TokenHandleRegistry tokenHandleRegistry;

    // TODO: Avoid constructors in favour of setUp function - Failing asserts in constructor won't make the test fail!
    constructor() {
        if (bytes(forkEnv).length > 0) {
            loadBaseAddresses(forkEnv);
        } else {
            deployBaseContracts();
        }
        ///////////////////////////////////////// Start governance actions.
        vm.startPrank(governance);

        if (hub.getState() != Types.ProtocolState.Unpaused) {
            hub.setState(Types.ProtocolState.Unpaused);
        }

        // Whitelist the test contract as a profile creator
        hub.whitelistProfileCreator(address(this), true);

        vm.stopPrank();
        ///////////////////////////////////////// End governance actions.
    }

    function loadBaseAddresses(string memory targetEnv) internal virtual {
        console.log('targetEnv:', targetEnv);

        hubProxyAddr = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy')));
        console.log('hubProxyAddr:', hubProxyAddr);

        hub = LensHub(hubProxyAddr);

        console.log('Hub:', address(hub));

        address followNFTAddr = hub.getFollowNFTImpl();
        address legacyCollectNFTAddr = hub.getCollectNFTImpl();

        address hubImplAddr = address(uint160(uint256(vm.load(hubProxyAddr, PROXY_IMPLEMENTATION_STORAGE_SLOT))));
        console.log('Found hubImplAddr:', hubImplAddr);
        hubImpl = LensHubInitializable(hubImplAddr);
        followNFT = FollowNFT(followNFTAddr);
        legacyCollectNFT = LegacyCollectNFT(legacyCollectNFTAddr);
        hubAsProxy = TransparentUpgradeableProxy(payable(address(hub)));
        moduleGlobals = ModuleGlobals(json.readAddress(string(abi.encodePacked('.', targetEnv, '.ModuleGlobals'))));
        lensHandles = LensHandles(json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHandles'))));
        tokenHandleRegistry = TokenHandleRegistry(
            json.readAddress(string(abi.encodePacked('.', targetEnv, '.TokenHandleRegistry')))
        );

        deployer = _loadAddressAs('DEPLOYER');

        governance = hub.getGovernance();
        vm.label(governance, 'GOVERNANCE');

        modulesGovernance = moduleGlobals.getGovernance();
        vm.label(governance, 'MODULES_GOVERNANCE');

        treasury = moduleGlobals.getTreasury();
        vm.label(governance, 'TREASURY');

        proxyAdmin = address(uint160(uint256(vm.load(hubProxyAddr, ADMIN_SLOT))));
        vm.label(proxyAdmin, 'HUB_PROXY_ADMIN');

        TREASURY_FEE_BPS = moduleGlobals.getTreasuryFee();
    }

    function deployBaseContracts() internal {
        deployer = _loadAddressAs('DEPLOYER');
        governance = _loadAddressAs('GOVERNANCE');
        treasury = _loadAddressAs('TREASURY');
        modulesGovernance = _loadAddressAs('MODULES_GOVERNANCE');

        TREASURY_FEE_BPS = 50;

        moduleGlobals = new ModuleGlobals(modulesGovernance, treasury, TREASURY_FEE_BPS);
        vm.label(address(moduleGlobals), 'MODULE_GLOBALS');

        ///////////////////////////////////////// Start deployments.
        vm.startPrank(deployer);

        // Precompute needed addresses.
        address followNFTAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 1);
        address legacyCollectNFTAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 2);
        hubProxyAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 3);
        address lensHandlesImplAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 4);
        address lensHandlesProxyAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 5);
        address tokenHandleRegistryImplAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 6);
        address tokenHandleRegistryProxyAddr = computeCreateAddress(deployer, vm.getNonce(deployer) + 7);

        // Deploy implementation contracts.
        // TODO: Last 3 addresses are for the follow modules for migration purposes.
        hubImpl = new LensHubInitializable({
            moduleGlobals: address(moduleGlobals),
            followNFTImpl: followNFTAddr,
            collectNFTImpl: legacyCollectNFTAddr,
            lensHandlesAddress: lensHandlesProxyAddr,
            tokenHandleRegistryAddress: tokenHandleRegistryProxyAddr,
            legacyFeeFollowModule: address(0),
            legacyProfileFollowModule: address(0),
            newFeeFollowModule: address(0),
            tokenGuardianCooldown: PROFILE_GUARDIAN_COOLDOWN
        });
        followNFT = new FollowNFT(hubProxyAddr);
        legacyCollectNFT = new LegacyCollectNFT(hubProxyAddr);

        // Deploy and initialize proxy.
        bytes memory initData = abi.encodeCall(hubImpl.initialize, ('Lens Protocol Profiles', 'LPP', governance));
        // TODO: Replace deployer owner with proxyAdmin.
        hubAsProxy = new TransparentUpgradeableProxy(address(hubImpl), deployer, initData);

        // Deploy LensHandles implementation.
        address lensHandlesImpl = address(new LensHandles(governance, address(hubAsProxy), HANDLE_GUARDIAN_COOLDOWN));
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
        mockActionModule = new MockActionModule();
        vm.label(address(mockActionModule), 'MOCK_ACTION_MODULE');

        // Deploy the MockReferenceModule.
        mockReferenceModule = new MockReferenceModule();
        vm.label(address(mockReferenceModule), 'MOCK_REFERENCE_MODULE');

        vm.stopPrank();
        ///////////////////////////////////////// End deployments.

        // Start governance actions.
        vm.startPrank(governance);

        // Whitelist the MockActionModule.
        hub.whitelistActionModule(address(mockActionModule), true);

        // Whitelist the MockReferenceModule.
        hub.whitelistReferenceModule(address(mockReferenceModule), true);

        // End governance actions.
        vm.stopPrank();
    }

    function setUp() public virtual {
        domainSeparator = keccak256(
            abi.encode(
                Typehash.EIP712_DOMAIN,
                keccak256('Lens Protocol Profiles'),
                MetaTxLib.EIP712_DOMAIN_VERSION_HASH,
                block.chainid,
                hubProxyAddr
            )
        );
        defaultAccount = _loadAccountAs('DEFAULT_ACCOUNT');
        defaultPub = _loadDefaultPublication();
    }

    function _createProfile(address profileOwner) internal returns (uint256) {
        Types.CreateProfileParams memory createProfileParams = _getDefaultCreateProfileParams();
        createProfileParams.to = profileOwner;
        return hub.createProfile(createProfileParams);
    }

    function _loadAccountAs(string memory accountLabel) internal returns (TestAccount memory) {
        return _loadAccountAs({accountLabel: accountLabel, requireCustomProfileOnFork: true});
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
            hub.DANGER__disableTokenGuardian();
            vm.warp(hub.getTokenGuardianDisablingTimestamp(currentProfileOwner));
            hub.transferFrom(currentProfileOwner, accountOwner, accountProfileId);
            vm.stopPrank();
        } else {
            // If profile was not loaded yet, we create a fresh one.
            accountProfileId = _createProfile(accountOwner);
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
            Types.CreateProfileParams({
                to: defaultAccount.owner,
                imageURI: MOCK_URI,
                followModule: address(0),
                followModuleInitData: ''
            });
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
