// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import '../base/BaseTest.t.sol';

contract CollectTest is BaseTest {
    function setUp() public override {
        super.setUp();
        vm.prank(profileOwner);
        hub.post(mockPostData);
    }

    // negatives
    function testCollectNonexistantPublicationFails() public {
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        hub.collect(me, firstProfileId, 2, '');
    }

    function testCollectZeroPublicationFails() public {
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        hub.collect(me, 0, 0, '');
    }

    function testCollectNotExecutorFails() public {
        vm.prank(otherUser);
        vm.expectRevert(Errors.CallerInvalid.selector);
        hub.collect(me, firstProfileId, 1, '');
    }

    // positives
    function testCollect() public {
        assertEq(hub.getCollectNFT(firstProfileId, 1), address(0));

        uint256 nftId = hub.collect(me, firstProfileId, 1, '');
        CollectNFT nft = CollectNFT(hub.getCollectNFT(firstProfileId, 1));
        assertEq(nftId, 1);
        assertEq(nft.ownerOf(1), me);

        string memory expectedName = string(
            abi.encodePacked(mockHandle, COLLECT_NFT_NAME_INFIX, '1')
        );
        string memory expectedSymbol = string(
            abi.encodePacked(bytes4(bytes(mockHandle)), COLLECT_NFT_SYMBOL_INFIX, '1')
        );

        assertEq(nft.name(), expectedName);
        assertEq(nft.symbol(), expectedSymbol);
    }

    function testExecutorCollect() public {
        hub.setDelegatedExecutorApproval(otherUser, true);

        vm.prank(otherUser);
        uint256 nftId = hub.collect(me, firstProfileId, 1, '');

        CollectNFT nft = CollectNFT(hub.getCollectNFT(firstProfileId, 1));
        assertEq(nftId, 1);
        assertEq(nft.ownerOf(1), me);
    }

    function testCollectMirror() public {
        vm.prank(profileOwner);
        hub.mirror(
            DataTypes.MirrorData({
                profileId: firstProfileId,
                profileIdPointed: firstProfileId,
                pubIdPointed: 1,
                referenceModuleData: '',
                referenceModule: address(0),
                referenceModuleInitData: ''
            })
        );

        uint256 nftId = hub.collect(me, firstProfileId, 2, '');

        // Ensure the mirror doesn't have an associated collect NFT.
        assertEq(hub.getCollectNFT(firstProfileId, 2), address(0));

        // Ensure the original publication does have an associated collect NFT.
        CollectNFT nft = CollectNFT(hub.getCollectNFT(firstProfileId, 1));
        assertEq(nftId, 1);
        assertEq(nft.ownerOf(1), me);
    }
}
