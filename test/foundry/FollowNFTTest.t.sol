// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './helpers/SignatureHelpers.sol';
import './ERC721Test.t.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {FollowNFT} from 'contracts/core/FollowNFT.sol';

contract FollowNFTTest is BaseTest, ERC721Test, SignatureHelpers {
    address targetProfileOwner;
    uint256 targetProfileId;
    address followerProfileOwner;
    uint256 followerProfileId;
    address alreadyFollowingProfileOwner;
    uint256 alreadyFollowingProfileId;
    address targetFollowNFT;

    function setUp() public override {
        super.setUp();

        targetProfileOwner = address(0xC0FFEE);
        targetProfileId = _createProfile(targetProfileOwner);
        followerProfileOwner = me;
        followerProfileId = _createProfile(followerProfileOwner);

        alreadyFollowingProfileOwner = me;
        alreadyFollowingProfileId = _createProfile(alreadyFollowingProfileOwner);
        _follow(alreadyFollowingProfileOwner, alreadyFollowingProfileId, targetProfileId, 0, '');

        targetFollowNFT = hub.getFollowNFT(targetProfileId);
    }

    function _mintERC721(address to) internal virtual override returns (uint256) {
        uint256 tokenId = _follow(to, _createProfile(to), targetProfileId, 0, '')[0];
        vm.prank(to);
        FollowNFT(targetFollowNFT).untieAndWrap(tokenId);
        return tokenId;
    }

    function _burnERC721(uint256 tokenId) internal virtual override {
        return FollowNFT(targetFollowNFT).burn(tokenId);
    }

    function _getERC721TokenAddress() internal view virtual override returns (address) {
        return targetFollowNFT;
    }
}
