// This test should upgrade the forked Polygon deployment, and run a series of tests.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import 'forge-std/console2.sol';
import 'test/foundry/base/BaseTest.t.sol';
import 'test/mocks/MockReferenceModule.sol';
import 'test/mocks/MockDeprecatedReferenceModule.sol';
import 'test/mocks/MockCollectModule.sol';
import 'test/mocks/MockDeprecatedCollectModule.sol';
import 'test/mocks/MockFollowModule.sol';
import 'test/mocks/MockDeprecatedFollowModule.sol';
import 'contracts/interfaces/ILensMultiState.sol';
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
    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    address constant POLYGON_HUB_PROXY = 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;
    address constant MUMBAI_HUB_PROXY = 0x60Ae865ee4C725cd04353b5AAb364553f56ceF82;

    uint256 polygonForkId;
    uint256 mumbaiForkId;

    address mockCollectModuleAddr;
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

        // Setup the new deployment and helper memory structs.
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
        hub.setGovernance(me);
        assertEq(hub.getGovernance(), me);
    }

    function _fullCreateProfileSequence(address gov, ILensHub hub) private returns (uint256) {
        // In order to make this test suite evergreen, we must try setting a modern follow module since we don't know
        // which version of the hub we're working with, if this fails, then we should use a deprecated one.

        // mockCreateProfileParams.handle = vm.toString(IERC721Enumerable(address(hub)).totalSupply());
        mockCreateProfileParams.followModule = mockFollowModuleAddr;

        uint256 profileId;
        try hub.createProfile(mockCreateProfileParams) returns (uint256 retProfileId) {
            profileId = retProfileId;
            console2.log('Profile created with modern follow module.');
        } catch {
            console2.log('Profile creation with modern follow module failed. Attempting with deprecated module.');

            address mockDeprecatedFollowModule = address(new MockDeprecatedFollowModule());

            vm.prank(gov);
            hub.whitelistFollowModule(mockDeprecatedFollowModule, true);

            // precompute basic profile creaton data.
            mockCreateProfileParams = Types.CreateProfileParams({
                to: me,
                imageURI: MOCK_URI,
                followModule: address(0),
                followModuleInitData: abi.encode(1),
                followNFTURI: MOCK_URI
            });

            OldCreateProfileParams memory oldCreateProfileParams = OldCreateProfileParams(
                mockCreateProfileParams.to,
                vm.toString((IERC721Enumerable(address(hub)).totalSupply())),
                mockCreateProfileParams.imageURI,
                mockDeprecatedFollowModule,
                mockCreateProfileParams.followModuleInitData,
                mockCreateProfileParams.followNFTURI
            );

            oldCreateProfileParams.followModule = mockDeprecatedFollowModule;
            profileId = IOldHub(address(hub)).createProfile(oldCreateProfileParams);
        }
        return profileId;
    }

    function _fullPublishSequence(uint256 profileId, address gov, ILensHub hub) private {
        // First check if the new interface works, if not, use the old interface.

        // Set the proper initial params, these must be redundantly reset as they may have been set
        // to different values in memory.
        mockPostParams.profileId = profileId;
        mockPostParams.collectModule = mockCollectModuleAddr;
        mockPostParams.referenceModule = mockReferenceModuleAddr;

        mockCommentParams.profileId = profileId;
        mockCommentParams.pointedProfileId = profileId;

        mockMirrorParams.profileId = profileId;
        mockMirrorParams.pointedProfileId = profileId;

        // Set the modern reference module, the modern collect module is already set by default.
        mockPostParams.referenceModule = mockReferenceModuleAddr;

        try hub.post(mockPostParams) returns (uint256 retPubId) {
            console2.log('Post published with modern collect and reference module, continuing with modern modules.');
            uint256 postId = retPubId;
            assertEq(postId, 1);

            mockCommentParams.collectModule = mockCollectModuleAddr;
            mockCommentParams.referenceModule = mockReferenceModuleAddr;

            // Validate post.
            assertEq(postId, 1);
            Types.Publication memory pub = hub.getPub(profileId, postId);
            assertEq(pub.pointedProfileId, 0);
            assertEq(pub.pointedPubId, 0);
            assertEq(pub.contentURI, mockPostParams.contentURI);
            assertEq(pub.referenceModule, mockPostParams.referenceModule);
            assertEq(pub.collectModule, mockPostParams.collectModule);
            assertEq(pub.collectNFT, address(0));

            // Comment.
            uint256 commentId = hub.comment(mockCommentParams);

            // Validate comment.
            assertEq(commentId, 2);
            pub = hub.getPub(profileId, commentId);
            assertEq(pub.pointedProfileId, mockCommentParams.pointedProfileId);
            assertEq(pub.pointedPubId, mockCommentParams.pointedPubId);
            assertEq(pub.contentURI, mockCommentParams.contentURI);
            assertEq(pub.referenceModule, mockCommentParams.referenceModule);
            assertEq(pub.collectModule, mockCommentParams.collectModule);
            assertEq(pub.collectNFT, address(0));

            // Mirror.
            uint256 mirrorId = hub.mirror(mockMirrorParams);

            // Validate mirror.
            assertEq(mirrorId, 3);
            pub = hub.getPub(profileId, mirrorId);
            assertEq(pub.pointedProfileId, mockMirrorParams.pointedProfileId);
            assertEq(pub.pointedPubId, mockMirrorParams.pointedPubId);
            assertEq(pub.contentURI, '');
            assertEq(pub.referenceModule, address(0));
            assertEq(pub.collectModule, address(0));
            assertEq(pub.collectNFT, address(0));
        } catch {
            console2.log('Post with modern collect and reference module failed, Attempting with deprecated modules');

            address mockDeprecatedCollectModule = address(new MockDeprecatedCollectModule());
            address mockDeprecatedReferenceModule = address(new MockDeprecatedReferenceModule());

            vm.startPrank(gov);
            hub.whitelistCollectModule(mockDeprecatedCollectModule, true);
            hub.whitelistReferenceModule(mockDeprecatedReferenceModule, true);
            vm.stopPrank();

            // Post.
            mockPostParams.collectModule = mockDeprecatedCollectModule;
            mockPostParams.referenceModule = mockDeprecatedReferenceModule;
            uint256 postId = hub.post(mockPostParams);

            // Validate post.
            assertEq(postId, 1);
            Types.Publication memory pub = hub.getPub(profileId, postId);
            assertEq(pub.pointedProfileId, 0);
            assertEq(pub.pointedPubId, 0);
            assertEq(pub.contentURI, mockPostParams.contentURI);
            assertEq(pub.referenceModule, mockPostParams.referenceModule);
            assertEq(pub.collectModule, mockPostParams.collectModule);
            assertEq(pub.collectNFT, address(0));

            // Comment.
            mockCommentParams.collectModule = mockDeprecatedCollectModule;
            mockCommentParams.referenceModule = mockDeprecatedReferenceModule;
            uint256 commentId = hub.comment(mockCommentParams);

            // Validate comment.
            assertEq(commentId, 2);
            pub = hub.getPub(profileId, commentId);
            assertEq(pub.pointedProfileId, mockCommentParams.pointedProfileId);
            assertEq(pub.pointedPubId, mockCommentParams.pointedPubId);
            assertEq(pub.contentURI, mockCommentParams.contentURI);
            assertEq(pub.referenceModule, mockCommentParams.referenceModule);
            assertEq(pub.collectModule, mockCommentParams.collectModule);
            assertEq(pub.collectNFT, address(0));

            // Mirror.
            OldMirrorParams memory oldMirrorParams = OldMirrorParams({
                profileId: mockMirrorParams.profileId,
                pointedProfileId: mockMirrorParams.pointedProfileId,
                pointedPubId: mockMirrorParams.pointedPubId,
                referenceModuleData: mockMirrorParams.referenceModuleData,
                referenceModule: mockDeprecatedReferenceModule,
                referenceModuleInitData: mockCommentParams.referenceModuleInitData
            });

            uint256 mirrorId = IOldHub(address(hub)).mirror(oldMirrorParams);

            // Validate mirror.
            assertEq(mirrorId, 3);
            pub = hub.getPub(profileId, mirrorId);
            assertEq(pub.pointedProfileId, mockMirrorParams.pointedProfileId);
            assertEq(pub.pointedPubId, mockMirrorParams.pointedPubId);
            assertEq(pub.contentURI, '');
            assertEq(pub.referenceModule, mockDeprecatedReferenceModule);
            assertEq(pub.collectModule, address(0));
            assertEq(pub.collectNFT, address(0));
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
                    referrerProfileIds: _emptyUint256Array(),
                    referrerPubIds: _emptyUint256Array(),
                    collectModuleData: ''
                })
            );
            hub.collect(
                Types.CollectParams({
                    publicationCollectedProfileId: profileId,
                    publicationCollectedId: 2,
                    collectorProfileId: profileId,
                    referrerProfileIds: _emptyUint256Array(),
                    referrerPubIds: _emptyUint256Array(),
                    collectModuleData: ''
                })
            );
            hub.collect(
                Types.CollectParams({
                    publicationCollectedProfileId: profileId,
                    publicationCollectedId: 3,
                    collectorProfileId: profileId,
                    referrerProfileIds: _emptyUint256Array(),
                    referrerPubIds: _emptyUint256Array(),
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
        address collectNFTAddr = computeCreateAddress(deployer, 2);

        // Deploy implementation contracts.
        hubImpl = new LensHub(followNFTAddr, collectNFTAddr, address(0), address(0));
        followNFT = new FollowNFT(hubProxyAddr);
        collectNFT = new CollectNFT(hubProxyAddr);

        // Deploy the mock modules.
        mockCollectModuleAddr = address(new MockCollectModule());
        mockReferenceModuleAddr = address(new MockReferenceModule());
        mockFollowModuleAddr = address(new MockFollowModule());

        // End deployments.
        vm.stopPrank();

        hub = LensHub(hubProxyAddr);
        // Start gov actions.
        vm.startPrank(gov);
        hub.whitelistProfileCreator(me, true);
        hub.whitelistFollowModule(mockFollowModuleAddr, true);
        hub.whitelistCollectModule(mockCollectModuleAddr, true);
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

        // NOTE: Structs are invalid as-is. Handle and modules must be set on the fly.

        // precompute basic profile creaton data.
        mockCreateProfileParams = Types.CreateProfileParams({
            to: me,
            imageURI: MOCK_URI,
            followModule: address(0),
            followModuleInitData: abi.encode(1),
            followNFTURI: MOCK_URI
        });

        // Precompute basic post data.
        mockPostParams = Types.PostParams({
            profileId: 0,
            contentURI: MOCK_URI,
            collectModule: address(0),
            collectModuleInitData: abi.encode(1),
            referenceModule: address(0),
            referenceModuleInitData: abi.encode(1)
        });

        // Precompute basic comment data.
        mockCommentParams = Types.CommentParams({
            profileId: 0,
            contentURI: MOCK_URI,
            pointedProfileId: newProfileId,
            pointedPubId: 1,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            referenceModuleData: '',
            collectModule: address(0),
            collectModuleInitData: abi.encode(1),
            referenceModule: address(0),
            referenceModuleInitData: abi.encode(1)
        });

        // Precompute basic mirror data.
        mockMirrorParams = Types.MirrorParams({
            profileId: 0,
            pointedProfileId: newProfileId,
            pointedPubId: 1,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            referenceModuleData: ''
        });
    }
}
