// This test should upgrade the forked Polygon deployment, and run a series of tests.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import 'forge-std/console2.sol';
import 'test/base/BaseTest.t.sol';
import 'test/mocks/MockReferenceModule.sol';
import 'test/mocks/MockDeprecatedReferenceModule.sol';
import 'test/mocks/MockDeprecatedCollectModule.sol';
import 'test/mocks/MockFollowModule.sol';
import 'test/mocks/MockDeprecatedFollowModule.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';

struct OldCreateProfileParams {
    address to;
    string handle;
    string imageURI;
    address followModule;
    bytes followModuleInitData;
    string followNFTURI;
}

struct OldMirrorParams {
    uint256 profileId;
    uint256 pointedProfileId;
    uint256 pointedPubId;
    bytes referenceModuleData;
    address referenceModule;
    bytes referenceModuleInitData;
}

interface IOldHub {
    function createProfile(OldCreateProfileParams memory createProfileParams) external returns (uint256);

    function mirror(OldMirrorParams memory createProfileParams) external returns (uint256);

    function follow(uint256[] calldata profileIds, bytes[] calldata datas) external;

    function collect(uint256 profileId, uint256 pubId, bytes calldata data) external;
}

contract UpgradeForkTest is BaseTest {
    address constant POLYGON_HUB_PROXY = 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;
    address constant MUMBAI_HUB_PROXY = 0x60Ae865ee4C725cd04353b5AAb364553f56ceF82;

    uint256 polygonForkId;
    uint256 mumbaiForkId;

    address mockFollowModuleAddr;
    address mockReferenceModuleAddr;

    function setUp() public override {
        if (bytes(forkEnv).length > 0) {
            // TODO: Consider adding a "FORK" bool env variable to explicitly enable fork testing and not require ENVs for general tests
            string memory polygonForkUrl = vm.envString('POLYGON_RPC_URL');
            string memory mumbaiForkUrl = vm.envString('MUMBAI_RPC_URL');

            polygonForkId = vm.createFork(polygonForkUrl);
            mumbaiForkId = vm.createFork(mumbaiForkUrl);
        }
    }

    function testUpgradePolygon() public onlyFork {
        vm.selectFork(polygonForkId);
        _fullRun(POLYGON_HUB_PROXY);
    }

    function testUpgradeMumbai() public onlyFork {
        vm.selectFork(mumbaiForkId);
        _fullRun(MUMBAI_HUB_PROXY);
    }

    function _fullRun(address hubProxyAddr) private {
        ILensHub hub = ILensHub(hubProxyAddr);
        address proxyAdmin = address(uint160(uint256(vm.load(hubProxyAddr, ADMIN_SLOT))));
        address gov = hub.getGovernance();

        // Set up the new deployment and helper memory structs.
        _forkSetup(hubProxyAddr, gov);

        // Create a profile on the old hub, set the default profile.
        uint256 profileId = _fullCreateProfileSequence(gov, hub);

        // Post, comment, mirror.
        _fullPublishSequence(profileId, gov, hub);

        // Follow, Collect.
        _fullFollowCollectSequence(profileId, gov, hub);

        // Get the profile.
        Types.Profile memory Profile = hub.getProfile(profileId);
        bytes memory encodedProfile = abi.encode(Profile);

        // Upgrade the hub.
        TransparentUpgradeableProxy oldHubAsProxy = TransparentUpgradeableProxy(payable(hubProxyAddr));
        vm.prank(proxyAdmin);
        oldHubAsProxy.upgradeTo(address(hubImpl));

        // Ensure governance is the same.
        assertEq(hub.getGovernance(), gov);

        // Ensure profile is the same.
        Profile = hub.getProfile(profileId);
        bytes memory postUpgradeEncodedProfile = abi.encode(Profile);
        assertEq(postUpgradeEncodedProfile, encodedProfile);

        // Create a profile on the new hub, set the default profile.
        profileId = _fullCreateProfileSequence(gov, hub);

        // Post, comment, mirror.
        _fullPublishSequence(profileId, gov, hub);

        // Follow, Collect.
        _fullFollowCollectSequence(profileId, gov, hub);

        // Fourth, set new data and ensure getters return the new data (proper slots set).
        vm.prank(gov);
        hub.setGovernance(address(this));
        assertEq(hub.getGovernance(), address(this));
    }

    function _fullCreateProfileSequence(address gov, ILensHub hub) private returns (uint256) {
        // To make this test suite evergreen, we must try setting a modern follow module since we don't know
        // which version of the hub we're working with, if this fails, then we should use a deprecated one.

        Types.CreateProfileParams memory createProfileParams = _getDefaultCreateProfileParams();
        createProfileParams.followModule = mockFollowModuleAddr;

        uint256 profileId;
        try hub.createProfile(createProfileParams) returns (uint256 retProfileId) {
            profileId = retProfileId;
            console2.log('Profile created with modern follow module.');
        } catch {
            console2.log('Profile creation with modern follow module failed. Attempting with deprecated module.');

            address mockDeprecatedFollowModule = address(new MockDeprecatedFollowModule());

            vm.prank(gov);
            hub.whitelistFollowModule(mockDeprecatedFollowModule, true);

            // precompute basic profile creaton data.
            createProfileParams = Types.CreateProfileParams({
                to: address(this),
                imageURI: MOCK_URI,
                followModule: address(0),
                followModuleInitData: abi.encode(true)
            });

            OldCreateProfileParams memory oldCreateProfileParams = OldCreateProfileParams(
                createProfileParams.to,
                vm.toString((IERC721Enumerable(address(hub)).totalSupply())),
                createProfileParams.imageURI,
                mockDeprecatedFollowModule,
                createProfileParams.followModuleInitData,
                MOCK_URI
            );

            oldCreateProfileParams.followModule = mockDeprecatedFollowModule;
            profileId = IOldHub(address(hub)).createProfile(oldCreateProfileParams);
        }
        return profileId;
    }

    function _fullPublishSequence(uint256 profileId, address gov, ILensHub hub) private {
        // First check if the new interface works, if not, use the old interface.

        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.profileId = profileId;
        postParams.referenceModule = mockReferenceModuleAddr;

        Types.CommentParams memory commentParams = _getDefaultCommentParams();
        commentParams.profileId = profileId;
        commentParams.pointedProfileId = profileId;

        Types.MirrorParams memory mirrorParams = _getDefaultMirrorParams();
        mirrorParams.profileId = profileId;
        mirrorParams.pointedProfileId = profileId;

        // Set the modern reference module, the modern collect module is already set by default.
        postParams.referenceModule = mockReferenceModuleAddr;

        try hub.post(postParams) returns (uint256 retPubId) {
            console2.log('Post published with modern collect and reference module, continuing with modern modules.');
            uint256 postId = retPubId;
            assertEq(postId, 1);

            commentParams.referenceModule = mockReferenceModuleAddr;

            // Validate post.
            assertEq(postId, 1);
            Types.Publication memory pub = hub.getPublication(profileId, postId);
            assertEq(pub.pointedProfileId, 0);
            assertEq(pub.pointedPubId, 0);
            assertEq(pub.contentURI, postParams.contentURI);
            assertEq(pub.referenceModule, postParams.referenceModule);
            // assertEq(pub.collectModule, postParams.collectModule); // TODO: Proper test
            // assertEq(pub.collectNFT, address(0));

            // Comment.
            uint256 commentId = hub.comment(commentParams);

            // Validate comment.
            assertEq(commentId, 2);
            pub = hub.getPublication(profileId, commentId);
            assertEq(pub.pointedProfileId, commentParams.pointedProfileId);
            assertEq(pub.pointedPubId, commentParams.pointedPubId);
            assertEq(pub.contentURI, commentParams.contentURI);
            assertEq(pub.referenceModule, commentParams.referenceModule);
            // assertEq(pub.collectModule, commentParams.collectModule); // TODO: Proper test
            // assertEq(pub.collectNFT, address(0));

            // Mirror.
            uint256 mirrorId = hub.mirror(mirrorParams);

            // Validate mirror.
            assertEq(mirrorId, 3);
            pub = hub.getPublication(profileId, mirrorId);
            assertEq(pub.pointedProfileId, mirrorParams.pointedProfileId);
            assertEq(pub.pointedPubId, mirrorParams.pointedPubId);
            assertEq(pub.contentURI, '');
            assertEq(pub.referenceModule, address(0));
            // assertEq(pub.collectModule, address(0)); // TODO: Proper tests
            // assertEq(pub.collectNFT, address(0));
        } catch {
            console2.log('Post with modern collect and reference module failed, Attempting with deprecated modules');

            // address mockDeprecatedCollectModule = address(new MockDeprecatedCollectModule()); // TODO: Proper test
            address mockDeprecatedReferenceModule = address(new MockDeprecatedReferenceModule());

            vm.startPrank(gov);
            // hub.whitelistCollectModule(mockDeprecatedCollectModule, true); // TODO: Proper test
            hub.whitelistReferenceModule(mockDeprecatedReferenceModule, true);
            vm.stopPrank();

            // Post.
            // postParams.collectModule = mockDeprecatedCollectModule; // TODO: Proper test
            postParams.referenceModule = mockDeprecatedReferenceModule;
            uint256 postId = hub.post(postParams);

            // Validate post.
            assertEq(postId, 1);
            Types.Publication memory pub = hub.getPublication(profileId, postId);
            assertEq(pub.pointedProfileId, 0);
            assertEq(pub.pointedPubId, 0);
            assertEq(pub.contentURI, postParams.contentURI);
            assertEq(pub.referenceModule, postParams.referenceModule);
            // assertEq(pub.collectModule, postParams.collectModule); // TODO: Proper test
            // assertEq(pub.collectNFT, address(0));

            // Comment.
            // commentParams.collectModule = mockDeprecatedCollectModule; // TODO: Proper test
            commentParams.referenceModule = mockDeprecatedReferenceModule;
            uint256 commentId = hub.comment(commentParams);

            // Validate comment.
            assertEq(commentId, 2);
            pub = hub.getPublication(profileId, commentId);
            assertEq(pub.pointedProfileId, commentParams.pointedProfileId);
            assertEq(pub.pointedPubId, commentParams.pointedPubId);
            assertEq(pub.contentURI, commentParams.contentURI);
            assertEq(pub.referenceModule, commentParams.referenceModule);
            // assertEq(pub.collectModule, commentParams.collectModule); // TODO: Proper test
            // assertEq(pub.collectNFT, address(0));

            // Mirror.
            OldMirrorParams memory oldMirrorParams = OldMirrorParams({
                profileId: mirrorParams.profileId,
                pointedProfileId: mirrorParams.pointedProfileId,
                pointedPubId: mirrorParams.pointedPubId,
                referenceModuleData: mirrorParams.referenceModuleData,
                referenceModule: mockDeprecatedReferenceModule,
                referenceModuleInitData: commentParams.referenceModuleInitData
            });

            uint256 mirrorId = IOldHub(address(hub)).mirror(oldMirrorParams);

            // Validate mirror.
            assertEq(mirrorId, 3);
            pub = hub.getPublication(profileId, mirrorId);
            assertEq(pub.pointedProfileId, mirrorParams.pointedProfileId);
            assertEq(pub.pointedPubId, mirrorParams.pointedPubId);
            assertEq(pub.contentURI, '');
            assertEq(pub.referenceModule, mockDeprecatedReferenceModule);
            // assertEq(pub.collectModule, address(0)); // TODO: Proper test
            // assertEq(pub.collectNFT, address(0));
        }
    }

    function _fullFollowCollectSequence(uint256 profileId, address gov, ILensHub hub) private {
        // First check if the new interface works, if not, use the old interface.
        uint256[] memory profileIds = new uint256[](1);
        profileIds[0] = profileId;
        uint256[] memory followTokenIds = new uint256[](1);
        followTokenIds[0] = 0;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';

        uint256 secondProfileId = _fullCreateProfileSequence(gov, hub);

        try hub.follow(secondProfileId, profileIds, followTokenIds, datas) {
            console2.log('Follow with modern interface succeeded, continuing with modern interface.');
            hub.collect(
                Types.CollectParams({
                    publicationCollectedProfileId: profileId,
                    publicationCollectedId: 1,
                    collectorProfileId: profileId,
                    referrerProfileId: 0,
                    referrerPubId: 0,
                    collectModuleData: ''
                })
            );
            hub.collect(
                Types.CollectParams({
                    publicationCollectedProfileId: profileId,
                    publicationCollectedId: 2,
                    collectorProfileId: profileId,
                    referrerProfileId: 0,
                    referrerPubId: 0,
                    collectModuleData: ''
                })
            );
            hub.collect(
                Types.CollectParams({
                    publicationCollectedProfileId: profileId,
                    publicationCollectedId: 3,
                    collectorProfileId: profileId,
                    referrerProfileId: 0,
                    referrerPubId: 0,
                    collectModuleData: ''
                })
            );
        } catch {
            console2.log('Follow with modern interface failed, proceeding with deprecated interface.');
            IOldHub(address(hub)).follow(profileIds, datas);
            IOldHub(address(hub)).collect(profileId, 1, '');
            IOldHub(address(hub)).collect(profileId, 2, '');
            IOldHub(address(hub)).collect(profileId, 3, '');
        }
    }

    function _forkSetup(address hubProxyAddr, address gov) private {
        // Start deployments.
        vm.startPrank(deployer);

        // Precompute needed addresss.
        address followNFTAddr = computeCreateAddress(deployer, 1);
        address legacyCollectNFTAddr = computeCreateAddress(deployer, 2);

        // Deploy implementation contracts.
        // TODO: Last 3 addresses are for the follow modules for migration purposes.
        hubImpl = new LensHubInitializable({
            moduleGlobals: address(0),
            followNFTImpl: followNFTAddr,
            collectNFTImpl: legacyCollectNFTAddr,
            lensHandlesAddress: address(0),
            tokenHandleRegistryAddress: address(0),
            legacyFeeFollowModule: address(0),
            legacyProfileFollowModule: address(0),
            newFeeFollowModule: address(0)
        });
        followNFT = new FollowNFT(hubProxyAddr);
        legacyCollectNFT = new LegacyCollectNFT(hubProxyAddr);

        // Deploy the mock modules.
        mockReferenceModuleAddr = address(new MockReferenceModule());
        mockFollowModuleAddr = address(new MockFollowModule());

        // End deployments.
        vm.stopPrank();

        hub = LensHub(hubProxyAddr);
        // Start gov actions.
        vm.startPrank(gov);
        hub.whitelistProfileCreator(address(this), true);
        hub.whitelistFollowModule(mockFollowModuleAddr, true);
        hub.whitelistReferenceModule(mockReferenceModuleAddr, true);

        // End gov actions.
        vm.stopPrank();

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
    }
}
