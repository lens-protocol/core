// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import '../base/BaseTest.t.sol';

contract CollectTest is BaseTest {
    // Negatives
    function testFollowNotExecutorFails() public {
        vm.prank(otherUser);
        vm.expectRevert(Errors.CallerInvalid.selector);
        hub.follow(me, _toUint256Array(firstProfileId), _toBytesArray(''));
    }

    // Positives
    function testFollow() public {
        assertEq(hub.getFollowNFT(firstProfileId), address(0));

        uint256[] memory nftIds = hub.follow(
            me,
            _toUint256Array(firstProfileId),
            _toBytesArray('')
        );
        FollowNFT nft = FollowNFT(hub.getFollowNFT(firstProfileId));
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.ownerOf(1), me);

        string memory expectedName = string(abi.encodePacked(mockHandle, FOLLOW_NFT_NAME_SUFFIX));
        string memory expectedSymbol = string(
            abi.encodePacked(bytes4(bytes(mockHandle)), FOLLOW_NFT_SYMBOL_SUFFIX)
        );
        assertEq(nft.name(), expectedName);
        assertEq(nft.symbol(), expectedSymbol);
    }

    function testExecutorFollow() public {
        hub.setDelegatedExecutorApproval(otherUser, true);

        vm.prank(otherUser);
        uint256[] memory nftIds = hub.follow(
            me,
            _toUint256Array(firstProfileId),
            _toBytesArray('')
        );
        FollowNFT nft = FollowNFT(hub.getFollowNFT(firstProfileId));
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.ownerOf(1), me);
    }
}
