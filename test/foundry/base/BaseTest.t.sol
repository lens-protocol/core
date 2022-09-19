// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

// Deployments
import '../../../contracts/core/LensHub.sol';
import '../../../contracts/core/FollowNFT.sol';
import '../../../contracts/core/CollectNFT.sol';
import '../../../contracts/core/modules/collect/FreeCollectModule.sol';
import '../../../contracts/upgradeability/TransparentUpgradeableProxy.sol';
import '../../../contracts/libraries/DataTypes.sol';
import '../../../contracts/libraries/Constants.sol';
import '../../../contracts/libraries/Errors.sol';
import '../../../contracts/libraries/GeneralLib.sol';
import '../../../contracts/libraries/ProfileTokenURILogic.sol';

contract BaseTest is Test {
    uint256 constant firstProfileId = 1;
    address constant deployer = address(1);
    address constant profileOwner = address(2);
    // UserOne is the test address, replaced with "me."
    address constant otherUser = address(3);
    address constant governance = address(4);

    string constant mockHandle = 'handle.lens';
    string constant mockURI = 'ipfs://QmUXfQWe43RKx31VzA2BnbwhSMW8WuaJvszFWChD59m76U';

    address immutable me = address(this);
    bytes32 immutable domainSeparator;

    CollectNFT immutable collectNFT;
    FollowNFT immutable followNFT;
    LensHub immutable hubImpl;
    TransparentUpgradeableProxy immutable hubAsProxy;
    LensHub immutable hub;
    FreeCollectModule immutable freeCollectModule;

    DataTypes.CreateProfileData mockCreateProfileData =
        DataTypes.CreateProfileData({
            to: profileOwner,
            handle: mockHandle,
            imageURI: mockURI,
            followModule: address(0),
            followModuleInitData: '',
            followNFTURI: mockURI
        });

    DataTypes.PostData mockPostData;

    constructor() {
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

        // Deploy the FreeCollectModule.
        freeCollectModule = new FreeCollectModule(hubProxyAddr);

        // End deployments.
        vm.stopPrank();

        // Start governance actions.
        vm.startPrank(governance);

        // Set the state to unpaused.
        hub.setState(DataTypes.ProtocolState.Unpaused);

        // Whitelist the FreeCollectModule.
        hub.whitelistCollectModule(address(freeCollectModule), true);

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

        // Precompute basic post data.
        mockPostData = DataTypes.PostData({
            profileId: firstProfileId,
            contentURI: mockURI,
            collectModule: address(freeCollectModule),
            collectModuleInitData: abi.encode(false),
            referenceModule: address(0),
            referenceModuleInitData: ''
        });
    }

    function setUp() public virtual {
        hub.createProfile(mockCreateProfileData);
    }

    function _toUint256Array(uint256 n) internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](1);
        ret[0] = n;
        return ret;
    }

    function _toBytesArray(bytes memory n) internal pure returns (bytes[] memory) {
        bytes[] memory ret = new bytes[](1);
        ret[0] = n;
        return ret;
    }
}
