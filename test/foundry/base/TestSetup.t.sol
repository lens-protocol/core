// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

// Deployments
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {LensHub} from 'contracts/core/LensHub.sol';
import {FollowNFT} from 'contracts/core/FollowNFT.sol';
import {CollectNFT} from 'contracts/core/CollectNFT.sol';
import {ModuleGlobals} from 'contracts/core/modules/ModuleGlobals.sol';
import {TransparentUpgradeableProxy} from 'contracts/upgradeability/TransparentUpgradeableProxy.sol';
import {DataTypes} from 'contracts/libraries/DataTypes.sol';
import 'contracts/libraries/Constants.sol';
import {Errors} from 'contracts/libraries/Errors.sol';
import {Events} from 'contracts/libraries/Events.sol';
import {GeneralLib} from 'contracts/libraries/GeneralLib.sol';
import {ProfileTokenURILogic} from 'contracts/libraries/ProfileTokenURILogic.sol';
import {MockCollectModule} from 'contracts/mocks/MockCollectModule.sol';
import {MockReferenceModule} from 'contracts/mocks/MockReferenceModule.sol';
import '../helpers/ForkManagement.sol';
import '../Constants.sol';

contract TestSetup is Test, ForkManagement {
    using stdJson for string;

    uint256 newProfileId;
    address deployer;
    address governance;
    address treasury;

    string constant MOCK_URI = 'ipfs://QmUXfQWe43RKx31VzA2BnbwhSMW8WuaJvszFWChD59m76U';

    uint256 constant otherSignerKey = 0x737562;
    uint256 constant profileOwnerKey = 0x04546b;
    address immutable profileOwner = vm.addr(profileOwnerKey);
    address immutable otherSigner = vm.addr(otherSignerKey);
    address immutable me = address(this);

    bytes32 domainSeparator;

    uint16 TREASURY_FEE_BPS;
    uint16 constant TREASURY_FEE_MAX_BPS = 10000;

    address hubProxyAddr;
    CollectNFT collectNFT;
    FollowNFT followNFT;
    LensHub hubImpl;
    TransparentUpgradeableProxy hubAsProxy;
    LensHub hub;
    MockCollectModule mockCollectModule;
    MockReferenceModule mockReferenceModule;
    ModuleGlobals moduleGlobals;

    DataTypes.CreateProfileData mockCreateProfileData;

    DataTypes.PostData mockPostData;
    DataTypes.CommentData mockCommentData;
    DataTypes.MirrorData mockMirrorData;
    DataTypes.CollectData mockCollectData;
    DataTypes.SetDefaultProfileWithSigData mockSetDefaultProfileData;

    function isEnvSet(string memory key) internal returns (bool) {
        try vm.envString(key) {
            return true;
        } catch {
            return false;
        }
    }

    constructor() {
        // TODO: Replace with envOr when it's released
        forkEnv = isEnvSet('TESTING_FORK') ? vm.envString('TESTING_FORK') : '';

        if (bytes(forkEnv).length > 0) {
            fork = true;
            console.log('\n\n Testing using %s fork', forkEnv);
            json = loadJson();

            network = getNetwork(json, forkEnv);

            if (isEnvSet('FORK_BLOCK')) {
                forkBlockNumber = vm.envUint('FORK_BLOCK');
                vm.createSelectFork(network, forkBlockNumber);
                console.log('Fork Block number (FIXED BLOCK):', forkBlockNumber);
            } else {
                vm.createSelectFork(network);
                forkBlockNumber = block.number;
                console.log('Fork Block number:', forkBlockNumber);
            }

            checkNetworkParams(json, forkEnv);

            loadBaseAddresses(forkEnv);
        } else {
            deployBaseContracts();
        }
        ///////////////////////////////////////// Start governance actions.
        vm.startPrank(governance);

        if (hub.getState() != DataTypes.ProtocolState.Unpaused)
            hub.setState(DataTypes.ProtocolState.Unpaused);

        // Whitelist the test contract as a profile creator
        hub.whitelistProfileCreator(me, true);

        vm.stopPrank();
        ///////////////////////////////////////// End governance actions.
    }

    // TODO: Replace with forge-std/StdJson.sol::keyExists(...) when/if this PR is approved:
    //       https://github.com/foundry-rs/forge-std/pull/226
    function keyExists(string memory key) internal returns (bool) {
        return json.parseRaw(key).length > 0;
    }

    function loadBaseAddresses(string memory targetEnv) internal virtual {
        bytes32 PROXY_IMPLEMENTATION_STORAGE_SLOT = bytes32(
            uint256(keccak256('eip1967.proxy.implementation')) - 1
        );

        console.log('targetEnv:', targetEnv);

        hubProxyAddr = json.readAddress(string(abi.encodePacked('.', targetEnv, '.LensHubProxy')));
        console.log('hubProxyAddr:', hubProxyAddr);

        hub = LensHub(hubProxyAddr);

        console.log('Hub:', address(hub));

        address followNFTAddr = hub.getFollowNFTImpl();
        address collectNFTAddr = hub.getCollectNFTImpl();

        address hubImplAddr = address(
            uint160(uint256(vm.load(hubProxyAddr, PROXY_IMPLEMENTATION_STORAGE_SLOT)))
        );
        console.log('Found hubImplAddr:', hubImplAddr);
        hubImpl = LensHub(hubImplAddr);
        followNFT = FollowNFT(followNFTAddr);
        collectNFT = CollectNFT(collectNFTAddr);
        hubAsProxy = TransparentUpgradeableProxy(payable(address(hub)));
        moduleGlobals = ModuleGlobals(
            json.readAddress(string(abi.encodePacked('.', targetEnv, '.ModuleGlobals')))
        );

        newProfileId = uint256(vm.load(hubProxyAddr, bytes32(uint256(22)))) + 1;
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

        TREASURY_FEE_BPS = 50;

        ///////////////////////////////////////// Start deployments.
        vm.startPrank(deployer);

        // Precompute needed addresss.
        address followNFTAddr = computeCreateAddress(deployer, 1);
        address collectNFTAddr = computeCreateAddress(deployer, 2);
        hubProxyAddr = computeCreateAddress(deployer, 3);

        // Deploy implementation contracts.
        hubImpl = new LensHub(followNFTAddr, collectNFTAddr);
        followNFT = new FollowNFT(hubProxyAddr);
        collectNFT = new CollectNFT(hubProxyAddr);

        // Deploy and initialize proxy.
        bytes memory initData = abi.encodeCall(
            hubImpl.initialize,
            ('Lens Protocol Profiles', 'LPP', governance)
        );
        hubAsProxy = new TransparentUpgradeableProxy(address(hubImpl), deployer, initData);

        // Cast proxy to LensHub interface.
        hub = LensHub(address(hubAsProxy));

        // Deploy the MockCollectModule.
        mockCollectModule = new MockCollectModule();

        // Deploy the MockReferenceModule.
        mockReferenceModule = new MockReferenceModule();

        vm.stopPrank();
        ///////////////////////////////////////// End deployments.

        // Start governance actions.
        vm.startPrank(governance);

        // Whitelist the FreeCollectModule.
        hub.whitelistCollectModule(address(mockCollectModule), true);

        // Whitelist the MockReferenceModule.
        hub.whitelistReferenceModule(address(mockReferenceModule), true);

        // End governance actions.
        vm.stopPrank();
    }

    function setUp() public virtual {
        // Compute the domain separator.
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256('Lens Protocol Profiles'),
                EIP712_REVISION_HASH,
                block.chainid,
                hubProxyAddr
            )
        );

        // precompute basic profile creaton data.
        mockCreateProfileData = DataTypes.CreateProfileData({
            to: profileOwner,
            imageURI: MOCK_URI,
            followModule: address(0),
            followModuleInitData: '',
            followNFTURI: MOCK_URI
        });

        // Precompute basic post data.
        mockPostData = DataTypes.PostData({
            profileId: newProfileId,
            contentURI: MOCK_URI,
            collectModule: address(mockCollectModule),
            collectModuleInitData: abi.encode(1),
            referenceModule: address(0),
            referenceModuleInitData: ''
        });

        // Precompute basic comment data.
        mockCommentData = DataTypes.CommentData({
            profileId: newProfileId,
            contentURI: MOCK_URI,
            profileIdPointed: newProfileId,
            pubIdPointed: FIRST_PUB_ID,
            referenceModuleData: '',
            collectModule: address(mockCollectModule),
            collectModuleInitData: abi.encode(1),
            referenceModule: address(0),
            referenceModuleInitData: ''
        });

        // Precompute basic mirror data.
        mockMirrorData = DataTypes.MirrorData({
            profileId: newProfileId,
            profileIdPointed: newProfileId,
            pubIdPointed: FIRST_PUB_ID,
            referenceModuleData: '',
            referenceModule: address(0),
            referenceModuleInitData: ''
        });

        // Precompute basic collect data.
        mockCollectData = DataTypes.CollectData({
            collector: profileOwner,
            profileId: newProfileId,
            pubId: FIRST_PUB_ID,
            data: ''
        });

        mockSetDefaultProfileData = DataTypes.SetDefaultProfileWithSigData({
            delegatedSigner: otherSigner,
            wallet: profileOwner,
            profileId: newProfileId,
            sig: DataTypes.EIP712Signature({v: 0, r: bytes32(0), s: bytes32(0), deadline: 0}) // blank sig
        });

        hub.createProfile(mockCreateProfileData);
    }
}
