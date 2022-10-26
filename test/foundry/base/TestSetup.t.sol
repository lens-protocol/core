// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

// Deployments
import '../../../contracts/core/LensHub.sol';
import '../../../contracts/core/FollowNFT.sol';
import '../../../contracts/core/CollectNFT.sol';
import '../../../contracts/upgradeability/TransparentUpgradeableProxy.sol';
import '../../../contracts/libraries/DataTypes.sol';
import '../../../contracts/libraries/Constants.sol';
import '../../../contracts/libraries/Errors.sol';
import '../../../contracts/libraries/GeneralLib.sol';
import '../../../contracts/libraries/ProfileTokenURILogic.sol';
import '../../../contracts/mocks/MockCollectModule.sol';
import '../../../contracts/mocks/MockReferenceModule.sol';

contract TestSetup is Test {
    uint256 constant firstProfileId = 1;
    address constant deployer = address(1);
    // UserOne is the test address, replaced with "me."
    address constant governance = address(2);

    string constant mockHandle = 'handle.lens';
    string constant mockURI = 'ipfs://QmUXfQWe43RKx31VzA2BnbwhSMW8WuaJvszFWChD59m76U';
    uint256 constant profileOwnerKey = 0x04546b;
    uint256 constant otherSignerKey = 0x737562;

    address profileOwner = vm.addr(profileOwnerKey);
    address otherSigner = vm.addr(otherSignerKey);
    address me = address(this);
    bytes32 domainSeparator;

    CollectNFT collectNFT;
    FollowNFT followNFT;
    LensHub hubImpl;
    TransparentUpgradeableProxy hubAsProxy;
    LensHub hub;
    MockCollectModule mockCollectModule;
    MockReferenceModule mockReferenceModule;

    DataTypes.CreateProfileData mockCreateProfileData;

    DataTypes.PostData mockPostData;
    DataTypes.CommentData mockCommentData;
    DataTypes.MirrorData mockMirrorData;

    function setUp() public virtual {
        // Start deployments.
        vm.startPrank(deployer);

        // Precompute needed addresss.
        address followNFTAddr = computeCreateAddress(deployer, 1);
        address collectNFTAddr = computeCreateAddress(deployer, 2);
        address hubProxyAddr = computeCreateAddress(deployer, 3);

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

        // End deployments.
        vm.stopPrank();

        // Start governance actions.
        vm.startPrank(governance);

        // Set the state to unpaused.
        hub.setState(DataTypes.ProtocolState.Unpaused);

        // Whitelist the FreeCollectModule.
        hub.whitelistCollectModule(address(mockCollectModule), true);

        // Whitelist the MockReferenceModule.
        hub.whitelistReferenceModule(address(mockReferenceModule), true);

        // Whitelist the test contract as a profile creator
        hub.whitelistProfileCreator(me, true);

        // End governance actions.
        vm.stopPrank();

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
            imageURI: mockURI,
            followModule: address(0),
            followModuleInitData: '',
            followNFTURI: mockURI
        });

        // Precompute basic post data.
        mockPostData = DataTypes.PostData({
            profileId: firstProfileId,
            contentURI: mockURI,
            collectModule: address(mockCollectModule),
            collectModuleInitData: abi.encode(1),
            referenceModule: address(0),
            referenceModuleInitData: ''
        });

        // Precompute basic comment data.
        mockCommentData = DataTypes.CommentData({
            profileId: firstProfileId,
            contentURI: mockURI,
            profileIdPointed: firstProfileId,
            pubIdPointed: 1,
            referenceModuleData: '',
            collectModule: address(mockCollectModule),
            collectModuleInitData: abi.encode(1),
            referenceModule: address(0),
            referenceModuleInitData: ''
        });

        // Precompute basic mirror data.
        mockMirrorData = DataTypes.MirrorData({
            profileId: firstProfileId,
            profileIdPointed: firstProfileId,
            pubIdPointed: 1,
            referenceModuleData: '',
            referenceModule: address(0),
            referenceModuleInitData: ''
        });

        hub.createProfile(mockCreateProfileData);
    }
}
