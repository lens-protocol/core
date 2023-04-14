// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

// Deployments
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {LensHub} from 'contracts/LensHub.sol';
import {LensHubInitializable} from 'contracts/misc/LensHubInitializable.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {CollectNFT} from 'contracts/CollectNFT.sol';
import {ModuleGlobals} from 'contracts/misc/ModuleGlobals.sol';
import {TransparentUpgradeableProxy} from 'contracts/base/upgradeability/TransparentUpgradeableProxy.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {ProfileTokenURILib} from 'contracts/libraries/token-uris/ProfileTokenURILib.sol';
import {MockActionModule} from 'test/mocks/MockActionModule.sol';
import {MockReferenceModule} from 'test/mocks/MockReferenceModule.sol';
import {ForkManagement} from 'test/foundry/helpers/ForkManagement.sol';
import {ArrayHelpers} from 'test/foundry/helpers/ArrayHelpers.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';
import {MetaTxLib} from 'contracts/libraries/MetaTxLib.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import 'test/foundry/Constants.sol';

contract TestSetup is Test, ForkManagement, ArrayHelpers {
    using stdJson for string;

    function testTestSetup() public {
        // Prevents being counted in Foundry Coverage
    }

    uint256 newProfileId; // TODO: We should get rid of this everywhere, and create dedicated profiles instead (see Follow tests)

    address deployer;
    address governance;
    address treasury;

    string constant MOCK_URI = 'ipfs://QmUXfQWe43RKx31VzA2BnbwhSMW8WuaJvszFWChD59m76U';

    uint256 constant otherSignerKey = 0x737562;
    uint256 constant profileOwnerKey = 0x04546b;
    uint256 constant alienSignerKey = 0x123456;
    address immutable profileOwner = vm.addr(profileOwnerKey);
    address immutable otherSigner = vm.addr(otherSignerKey);
    address immutable alienSigner = vm.addr(alienSignerKey);
    address immutable me = address(this);

    bytes32 domainSeparator;

    uint16 TREASURY_FEE_BPS;
    uint16 constant TREASURY_FEE_MAX_BPS = 10000;

    address hubProxyAddr;
    CollectNFT collectNFT;
    FollowNFT followNFT;
    LensHubInitializable hubImpl;
    TransparentUpgradeableProxy hubAsProxy;
    LensHub hub;
    MockActionModule mockActionModule;
    MockReferenceModule mockReferenceModule;
    ModuleGlobals moduleGlobals;

    Types.CreateProfileParams mockCreateProfileParams;

    Types.PostParams mockPostParams;
    Types.CommentParams mockCommentParams;
    Types.MirrorParams mockMirrorParams;
    Types.CollectParams mockCollectParams;
    Types.PublicationActionParams mockActParams;

    constructor() {
        if (bytes(forkEnv).length > 0) {
            loadBaseAddresses(forkEnv);
        } else {
            deployBaseContracts();
        }
        ///////////////////////////////////////// Start governance actions.
        vm.startPrank(governance);

        if (hub.getState() != Types.ProtocolState.Unpaused) hub.setState(Types.ProtocolState.Unpaused);

        // Whitelist the test contract as a profile creator
        hub.whitelistProfileCreator(me, true);

        vm.stopPrank();
        ///////////////////////////////////////// End governance actions.
    }

    function loadBaseAddresses(string memory targetEnv) internal virtual {
        bytes32 PROXY_IMPLEMENTATION_STORAGE_SLOT = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);

        console.log('targetEnv:', targetEnv);

        hubProxyAddr = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy')));
        console.log('hubProxyAddr:', hubProxyAddr);

        hub = LensHub(hubProxyAddr);

        console.log('Hub:', address(hub));

        address followNFTAddr = hub.getFollowNFTImpl();
        address collectNFTAddr = hub.getCollectNFTImpl();

        address hubImplAddr = address(uint160(uint256(vm.load(hubProxyAddr, PROXY_IMPLEMENTATION_STORAGE_SLOT))));
        console.log('Found hubImplAddr:', hubImplAddr);
        hubImpl = LensHubInitializable(hubImplAddr);
        followNFT = FollowNFT(followNFTAddr);
        collectNFT = CollectNFT(collectNFTAddr);
        hubAsProxy = TransparentUpgradeableProxy(payable(address(hub)));
        moduleGlobals = ModuleGlobals(json.readAddress(string(abi.encodePacked('.', targetEnv, '.ModuleGlobals'))));

        newProfileId = _getNextProfileId();
        console.log('newProfileId:', newProfileId);

        deployer = address(1);

        governance = hub.getGovernance();
        treasury = moduleGlobals.getTreasury();

        TREASURY_FEE_BPS = moduleGlobals.getTreasuryFee();
    }

    function deployBaseContracts() internal {
        newProfileId = FIRST_PROFILE_ID;
        deployer = address(1);
        governance = address(2);
        treasury = address(3);

        TREASURY_FEE_BPS = 50;

        ///////////////////////////////////////// Start deployments.
        vm.startPrank(deployer);

        // Precompute needed addresses.
        address followNFTAddr = computeCreateAddress(deployer, 1);
        address collectNFTAddr = computeCreateAddress(deployer, 2);
        hubProxyAddr = computeCreateAddress(deployer, 3);

        // Deploy implementation contracts.
        // TODO: Last 3 addresses are for the follow modules for migration purposes.
        hubImpl = new LensHubInitializable({
            moduleGlobals: address(0),
            followNFTImpl: followNFTAddr,
            collectNFTImpl: collectNFTAddr,
            lensHandlesAddress: address(0),
            tokenHandleRegistryAddress: address(0),
            legacyFeeFollowModule: address(0),
            legacyProfileFollowModule: address(0),
            newFeeFollowModule: address(0)
        });
        followNFT = new FollowNFT(hubProxyAddr);
        collectNFT = new CollectNFT(hubProxyAddr);

        // Deploy and initialize proxy.
        bytes memory initData = abi.encodeCall(hubImpl.initialize, ('Lens Protocol Profiles', 'LPP', governance));
        hubAsProxy = new TransparentUpgradeableProxy(address(hubImpl), deployer, initData);

        // Cast proxy to LensHub interface.
        hub = LensHub(address(hubAsProxy));

        // Deploy the MockActionModule.
        mockActionModule = new MockActionModule();

        // Deploy the MockReferenceModule.
        mockReferenceModule = new MockReferenceModule();

        moduleGlobals = new ModuleGlobals(governance, treasury, TREASURY_FEE_BPS);

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
        // Compute the domain separator.
        domainSeparator = keccak256(
            abi.encode(
                Typehash.EIP712_DOMAIN,
                keccak256('Lens Protocol Profiles'),
                MetaTxLib.EIP712_DOMAIN_VERSION_HASH,
                block.chainid,
                hubProxyAddr
            )
        );

        // precompute basic profile creation data.
        mockCreateProfileParams = Types.CreateProfileParams({
            to: profileOwner,
            imageURI: MOCK_URI,
            followModule: address(0),
            followModuleInitData: '',
            followNFTURI: MOCK_URI
        });

        // Precompute basic post data.
        mockPostParams = Types.PostParams({
            profileId: newProfileId,
            contentURI: MOCK_URI,
            actionModules: _toAddressArray(address(mockActionModule)),
            actionModulesInitDatas: _toBytesArray(abi.encode(1)),
            referenceModule: address(0),
            referenceModuleInitData: ''
        });

        // Precompute basic comment data.
        mockCommentParams = Types.CommentParams({
            profileId: newProfileId,
            contentURI: MOCK_URI,
            pointedProfileId: newProfileId,
            pointedPubId: FIRST_PUB_ID,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            referenceModuleData: '',
            actionModules: _toAddressArray(address(mockActionModule)),
            actionModulesInitDatas: _toBytesArray(abi.encode(1)),
            referenceModule: address(0),
            referenceModuleInitData: ''
        });

        // Precompute basic mirror data.
        mockMirrorParams = Types.MirrorParams({
            profileId: newProfileId,
            pointedProfileId: newProfileId,
            pointedPubId: FIRST_PUB_ID,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            referenceModuleData: ''
        });

        mockActParams = Types.PublicationActionParams({
            publicationActedProfileId: newProfileId,
            publicationActedId: FIRST_PUB_ID,
            actorProfileId: newProfileId,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            actionModuleAddress: address(mockActionModule),
            actionModuleData: abi.encode(true)
        });

        // // Precompute basic collect data.
        // mockCollectParams = Types.CollectParams({
        //     publicationCollectedProfileId: newProfileId,
        //     publicationCollectedId: FIRST_PUB_ID,
        //     collectorProfileId: newProfileId,
        //     referrerProfileIds: _emptyUint256Array(),
        //     referrerPubIds: _emptyUint256Array(),
        //     collectModuleData: ''
        // });

        hub.createProfile(mockCreateProfileParams);
    }

    // TODO: Find a better place for such helpers that have access to Hub without rekting inheritance
    function _getNextProfileId() internal returns (uint256) {
        return uint256(vm.load(hubProxyAddr, bytes32(uint256(StorageLib.PROFILE_COUNTER_SLOT)))) + 1;
    }
}
