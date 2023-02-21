// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './../FollowNFTTest.t.sol';

contract FollowNFTInitialConditionsTest is FollowNFTTest {
    function testFirstFollowTokenHasIdOne() public {
        uint256 profileIdToFollow = _createProfile(me);

        uint256 assignedTokenId = _follow(followerProfileOwner, followerProfileId, profileIdToFollow, 0, '')[0];

        assertEq(assignedTokenId, 1);
    }
}
