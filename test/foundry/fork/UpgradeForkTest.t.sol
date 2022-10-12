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

interface IOldHub {
    function setDefaultProfile(uint256 profileId) external;
}

contract UpgradeForkTest is BaseTest {
    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    address constant POLYGON_HUB_PROXY = 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;
    address constant MUMBAI_HUB_PROXY = 0x60Ae865ee4C725cd04353b5AAb364553f56ceF82;

    uint256 polygonForkId;
    uint256 mumbaiForkId;

    function setUp() public override {
        string memory polygonForkUrl = vm.envString('POLYGON_RPC_URL');
        string memory mumbaiForkUrl = vm.envString('MUMBAI_RPC_URL');

        polygonForkId = vm.createFork(polygonForkUrl);
        mumbaiForkId = vm.createFork(mumbaiForkUrl);
    }

    function testUpgradePolygon() public {
        vm.selectFork(polygonForkId);
        super.setUp();
        ILensHub oldHub = ILensHub(POLYGON_HUB_PROXY);
        TransparentUpgradeableProxy oldHubAsProxy = TransparentUpgradeableProxy(
            payable(POLYGON_HUB_PROXY)
        );

        // First, get the previous data.
        address gov = oldHub.getGovernance();
        address proxyAdmin = address(uint160(uint256(vm.load(POLYGON_HUB_PROXY, ADMIN_SLOT))));

        // Create a profile on the old hub, set the default profile.
        uint256 profileId = _fullCreateProfileSequence(gov, oldHub);

        // Post, comment, mirror.
        _fullPublishSequence(profileId, gov, oldHub);

        // Second, upgrade the hub.
        vm.prank(proxyAdmin);
        oldHubAsProxy.upgradeTo(address(hubImpl));

        // Third, get the data and ensure it's equal to the old data (getters access the same slots).
        assertEq(oldHub.getGovernance(), gov);

        // Fourth, set new data and ensure getters return the new data (proper slots set).
        vm.prank(gov);
        oldHub.setGovernance(me);
        assertEq(oldHub.getGovernance(), me);
    }

    function _fullPublishSequence(
        uint256 profileId,
        address gov,
        ILensHub hub
    ) private {
        // In order to make this test suite evergreen, we must try publishing with a modern collect and reference
        // module since we don't know which version of the hub we're working with. If this fails, then we should
        // use deprecated modules.
        address mockReferenceModule = address(new MockReferenceModule());

        vm.startPrank(gov);
        hub.whitelistCollectModule(address(mockCollectModule), true);
        hub.whitelistReferenceModule(mockReferenceModule, true);
        vm.stopPrank();

        // Set the proper profile ID, reference module data, and profile ID pointed.
        mockPostData.profileId = profileId;
        mockPostData.referenceModuleInitData = abi.encode(1);
        mockCommentData.profileId = profileId;
        mockCommentData.profileIdPointed = profileId;
        mockCommentData.referenceModuleInitData = abi.encode(1);
        mockMirrorData.profileId = profileId;
        mockMirrorData.profileIdPointed = profileId;
        mockMirrorData.referenceModuleInitData = abi.encode(1);

        // Set the modern reference module, the modern collect module is already set by default.
        mockPostData.referenceModule = mockReferenceModule;

        try hub.post(mockPostData) returns (uint256 retPubId) {
            console2.log('Post published with modern collect and reference module.');
            uint256 postId = retPubId;
            assertEq(postId, 1);
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

    function _fullCreateProfileSequence(address gov, ILensHub hub) private returns (uint256) {
        // In order to make this test suite evergreen, we must try setting a modern follow module since we don't know
        // which version of the hub we're working with, if this fails, then we should use a deprecated one.

        address mockFollowModule = address(new MockFollowModule());
        vm.startPrank(gov);
        hub.whitelistProfileCreator(me, true);
        hub.whitelistFollowModule(mockFollowModule, true);
        vm.stopPrank();

        mockCreateProfileData.to = me;
        mockCreateProfileData.handle = vm.toString(IERC721Enumerable(address(hub)).totalSupply());
        mockCreateProfileData.followModule = mockFollowModule;
        mockCreateProfileData.followModuleInitData = abi.encode(1);
        uint256 profileId;

        try hub.createProfile(mockCreateProfileData) returns (uint256 retProfileId) {
            profileId = retProfileId;
            console2.log('Profile created with modern follow module.');
        } catch {
            console2.log(
                'Profile creation with modern follow module failed. Attempting with deprecated module.'
            );
            address mockDeprecatedFollowModule = address(new MockDeprecatedFollowModule());
            vm.prank(gov);
            hub.whitelistFollowModule(mockDeprecatedFollowModule, true);

            mockCreateProfileData.followModule = mockDeprecatedFollowModule;
            profileId = hub.createProfile(mockCreateProfileData);
        }

        IOldHub(address(hub)).setDefaultProfile(profileId);

        return profileId;
    }
}
