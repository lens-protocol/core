// This test should upgrade the forked Polygon deployment, and run a series of tests.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import 'forge-std/console2.sol';
import '../base/BaseTest.t.sol';
import '../../../contracts/mocks/MockReferenceModule.sol';
import '../../../contracts/mocks/MockDeprecatedReferenceModule.sol';
import '../../../contracts/mocks/MockCollectModule.sol';
import '../../../contracts/mocks/MockDeprecatedCollectModule.sol';
import '../../../contracts/mocks/MockFollowModule.sol';
import '../../../contracts/mocks/MockDeprecatedFollowModule.sol';
import '../../../contracts/interfaces/IERC721Time.sol';
import '../../../contracts/interfaces/ILensMultiState.sol';

interface IOldHub {
    function follow(uint256[] calldata profileIds, bytes[] calldata datas) external;

    function collect(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external;

    function setDefaultProfile(uint256 profileId) external;

    function defaultProfile(address wallet) external view returns (uint256);
}

contract UpgradeForkTest is BaseTest {
    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    address constant MOCK_DISPATCHER_ADDRESS = address(0x4546b);
    address constant POLYGON_HUB_PROXY = 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;
    address constant MUMBAI_HUB_PROXY = 0x60Ae865ee4C725cd04353b5AAb364553f56ceF82;

    uint256 polygonForkId;
    uint256 mumbaiForkId;

    address mockCollectModuleAddr;
    address mockFollowModuleAddr;
    address mockReferenceModuleAddr;

    function setUp() public override {
        string memory polygonForkUrl = vm.envString('POLYGON_RPC_URL');
        string memory mumbaiForkUrl = vm.envString('MUMBAI_RPC_URL');

        polygonForkId = vm.createFork(polygonForkUrl);
        mumbaiForkId = vm.createFork(mumbaiForkUrl);
    }

    function testUpgradePolygon() public {
        vm.selectFork(polygonForkId);
        _fullRun(POLYGON_HUB_PROXY);
    }

    function testUpgradeMumbai() public {
        vm.selectFork(mumbaiForkId);
        _fullRun(MUMBAI_HUB_PROXY);
    }

    function _fullRun(address hubProxyAddr) private {
        ILensHub hub = ILensHub(hubProxyAddr);
        address proxyAdmin = address(uint160(uint256(vm.load(hubProxyAddr, ADMIN_SLOT))));
        address gov = hub.getGovernance();

        // Setup the new deployment and helper memory structs.
        _forkSetup(hubProxyAddr, gov);

        // Create a profile on the old hub, set the default profile and dispatcher.
        uint256 profileId = _fullCreateProfileSequence(gov, hub);

        // Post, comment, mirror.
        _fullPublishSequence(profileId, gov, hub);

        // Follow, Collect.
        _fullFollowCollectSequence(profileId, hub);

        // Get the profile.
        DataTypes.ProfileStruct memory profileStruct = hub.getProfile(profileId);
        bytes memory encodedProfile = abi.encode(profileStruct);

        // Upgrade the hub.
        TransparentUpgradeableProxy oldHubAsProxy = TransparentUpgradeableProxy(
            payable(hubProxyAddr)
        );
        vm.prank(proxyAdmin);
        oldHubAsProxy.upgradeTo(address(hubImpl));

        // Ensure governance is the same.
        assertEq(hub.getGovernance(), gov);

        // Ensure profile is the same.
        profileStruct = hub.getProfile(profileId);
        bytes memory postUpgradeEncodedProfile = abi.encode(profileStruct);
        assertEq(postUpgradeEncodedProfile, encodedProfile);

        // Create a profile on the new hub, set the default profile and dispatcher.
        profileId = _fullCreateProfileSequence(gov, hub);

        // Post, comment, mirror.
        _fullPublishSequence(profileId, gov, hub);

        // Follow, Collect.
        _fullFollowCollectSequence(profileId, hub);

        // Fourth, set new data and ensure getters return the new data (proper slots set).
        vm.prank(gov);
        hub.setGovernance(me);
        assertEq(hub.getGovernance(), me);
    }

    function _fullCreateProfileSequence(address gov, ILensHub hub) private returns (uint256) {
        // In order to make this test suite evergreen, we must try setting a modern follow module since we don't know
        // which version of the hub we're working with, if this fails, then we should use a deprecated one.

        mockCreateProfileData.handle = vm.toString(IERC721Enumerable(address(hub)).totalSupply());
        mockCreateProfileData.followModule = mockFollowModuleAddr;

        uint256 profileId;
        try hub.createProfile(mockCreateProfileData) returns (uint256 retProfileId) {
            profileId = retProfileId;
            console2.log('Profile created with modern follow module.');
            hub.setDefaultProfile(me, profileId);
            assertEq(hub.getDefaultProfile(me), profileId);
        } catch {
            console2.log(
                'Profile creation with modern follow module failed. Attempting with deprecated module.'
            );
            address mockDeprecatedFollowModule = address(new MockDeprecatedFollowModule());

            vm.prank(gov);
            hub.whitelistFollowModule(mockDeprecatedFollowModule, true);

            mockCreateProfileData.followModule = mockDeprecatedFollowModule;
            profileId = hub.createProfile(mockCreateProfileData);
            IOldHub(address(hub)).setDefaultProfile(profileId);
            assertEq(IOldHub(address(hub)).defaultProfile(me), profileId);
        }
        hub.setDispatcher(profileId, MOCK_DISPATCHER_ADDRESS);
        assertEq(hub.getDispatcher(profileId), MOCK_DISPATCHER_ADDRESS);
        return profileId;
    }

    function _fullPublishSequence(
        uint256 profileId,
        address gov,
        ILensHub hub
    ) private {
        // First check if the new interface works, if not, use the old interface.

        // Set the proper initial params, these must be redundantly reset as they may have been set
        // to different values in memory.
        mockPostData.profileId = profileId;
        mockPostData.collectModule = mockCollectModuleAddr;
        mockPostData.referenceModule = mockReferenceModuleAddr;

        mockCommentData.profileId = profileId;
        mockCommentData.profileIdPointed = profileId;

        mockMirrorData.profileId = profileId;
        mockMirrorData.profileIdPointed = profileId;

        // Set the modern reference module, the modern collect module is already set by default.
        mockPostData.referenceModule = mockReferenceModuleAddr;

        try hub.post(mockPostData) returns (uint256 retPubId) {
            console2.log(
                'Post published with modern collect and reference module, continuing with modern modules.'
            );
            uint256 postId = retPubId;
            assertEq(postId, 1);

            mockCommentData.collectModule = mockCollectModuleAddr;
            mockCommentData.referenceModule = mockReferenceModuleAddr;
            mockMirrorData.referenceModule = mockReferenceModuleAddr;

            // Validate post.
            assertEq(postId, 1);
            DataTypes.PublicationStruct memory pub = hub.getPub(profileId, postId);
            assertEq(pub.profileIdPointed, 0);
            assertEq(pub.pubIdPointed, 0);
            assertEq(pub.contentURI, mockPostData.contentURI);
            assertEq(pub.referenceModule, mockPostData.referenceModule);
            assertEq(pub.collectModule, mockPostData.collectModule);
            assertEq(pub.collectNFT, address(0));

            // Comment.
            uint256 commentId = hub.comment(mockCommentData);

            // Validate comment.
            assertEq(commentId, 2);
            pub = hub.getPub(profileId, commentId);
            assertEq(pub.profileIdPointed, mockCommentData.profileIdPointed);
            assertEq(pub.pubIdPointed, mockCommentData.pubIdPointed);
            assertEq(pub.contentURI, mockCommentData.contentURI);
            assertEq(pub.referenceModule, mockCommentData.referenceModule);
            assertEq(pub.collectModule, mockCommentData.collectModule);
            assertEq(pub.collectNFT, address(0));

            // Mirror.
            uint256 mirrorId = hub.mirror(mockMirrorData);

            // Validate mirror.
            assertEq(mirrorId, 3);
            pub = hub.getPub(profileId, mirrorId);
            assertEq(pub.profileIdPointed, mockMirrorData.profileIdPointed);
            assertEq(pub.pubIdPointed, mockMirrorData.pubIdPointed);
            assertEq(pub.contentURI, '');
            assertEq(pub.referenceModule, mockMirrorData.referenceModule);
            assertEq(pub.collectModule, address(0));
            assertEq(pub.collectNFT, address(0));
        } catch {
            console2.log(
                'Post with modern collect and reference module failed, Attempting with deprecated modules'
            );

            address mockDeprecatedCollectModule = address(new MockDeprecatedCollectModule());
            address mockDeprecatedReferenceModule = address(new MockDeprecatedReferenceModule());

            vm.startPrank(gov);
            hub.whitelistCollectModule(mockDeprecatedCollectModule, true);
            hub.whitelistReferenceModule(mockDeprecatedReferenceModule, true);
            vm.stopPrank();

            // Post.
            mockPostData.collectModule = mockDeprecatedCollectModule;
            mockPostData.referenceModule = mockDeprecatedReferenceModule;
            uint256 postId = hub.post(mockPostData);

            // Validate post.
            assertEq(postId, 1);
            DataTypes.PublicationStruct memory pub = hub.getPub(profileId, postId);
            assertEq(pub.profileIdPointed, 0);
            assertEq(pub.pubIdPointed, 0);
            assertEq(pub.contentURI, mockPostData.contentURI);
            assertEq(pub.referenceModule, mockPostData.referenceModule);
            assertEq(pub.collectModule, mockPostData.collectModule);
            assertEq(pub.collectNFT, address(0));

            // Comment.
            mockCommentData.collectModule = mockDeprecatedCollectModule;
            mockCommentData.referenceModule = mockDeprecatedReferenceModule;
            uint256 commentId = hub.comment(mockCommentData);

            // Validate comment.
            assertEq(commentId, 2);
            pub = hub.getPub(profileId, commentId);
            assertEq(pub.profileIdPointed, mockCommentData.profileIdPointed);
            assertEq(pub.pubIdPointed, mockCommentData.pubIdPointed);
            assertEq(pub.contentURI, mockCommentData.contentURI);
            assertEq(pub.referenceModule, mockCommentData.referenceModule);
            assertEq(pub.collectModule, mockCommentData.collectModule);
            assertEq(pub.collectNFT, address(0));

            // Mirror.
            mockMirrorData.referenceModule = mockDeprecatedReferenceModule;
            uint256 mirrorId = hub.mirror(mockMirrorData);

            // Validate mirror.
            assertEq(mirrorId, 3);
            pub = hub.getPub(profileId, mirrorId);
            assertEq(pub.profileIdPointed, mockMirrorData.profileIdPointed);
            assertEq(pub.pubIdPointed, mockMirrorData.pubIdPointed);
            assertEq(pub.contentURI, '');
            assertEq(pub.referenceModule, mockMirrorData.referenceModule);
            assertEq(pub.collectModule, address(0));
            assertEq(pub.collectNFT, address(0));
        }
    }

    function _fullFollowCollectSequence(uint256 profileId, ILensHub hub) private {
        // First check if the new interface works, if not, use the old interface.
        uint256[] memory profileIds = new uint256[](1);
        profileIds[0] = profileId;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';

        try hub.follow(me, profileIds, datas) {
            console2.log(
                'Follow with modern interface succeeded, continuing with modern interface.'
            );
            hub.collect(me, profileId, 1, '');
            hub.collect(me, profileId, 2, '');
            hub.collect(me, profileId, 3, '');
        } catch {
            console2.log(
                'Follow with modern interface failed, proceeding with deprecated interface.'
            );
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
        hubImpl = new LensHub(followNFTAddr, collectNFTAddr);
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
                EIP712_DOMAIN_TYPEHASH,
                keccak256('Lens Protocol Profiles'),
                EIP712_REVISION_HASH,
                block.chainid,
                hubProxyAddr
            )
        );

        // NOTE: Structs are invalid as-is. Handle and modules must be set on the fly.

        // precompute basic profile creaton data.
        mockCreateProfileData = DataTypes.CreateProfileData({
            to: me,
            handle: '',
            imageURI: mockURI,
            followModule: address(0),
            followModuleInitData: abi.encode(1),
            followNFTURI: mockURI
        });

        // Precompute basic post data.
        mockPostData = DataTypes.PostData({
            profileId: 0,
            contentURI: mockURI,
            collectModule: address(0),
            collectModuleInitData: abi.encode(1),
            referenceModule: address(0),
            referenceModuleInitData: abi.encode(1)
        });

        // Precompute basic comment data.
        mockCommentData = DataTypes.CommentData({
            profileId: 0,
            contentURI: mockURI,
            profileIdPointed: firstProfileId,
            pubIdPointed: 1,
            referenceModuleData: '',
            collectModule: address(0),
            collectModuleInitData: abi.encode(1),
            referenceModule: address(0),
            referenceModuleInitData: abi.encode(1)
        });

        // Precompute basic mirror data.
        mockMirrorData = DataTypes.MirrorData({
            profileId: 0,
            profileIdPointed: firstProfileId,
            pubIdPointed: 1,
            referenceModuleData: '',
            referenceModule: address(0),
            referenceModuleInitData: abi.encode(1)
        });
    }
}
