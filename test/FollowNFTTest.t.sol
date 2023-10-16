// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/LensBaseERC721Test.t.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';
import {FollowNFT} from 'contracts/FollowNFT.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Base64} from 'solady/utils/Base64.sol';
import {LibString} from 'solady/utils/LibString.sol';
import {FollowTokenURILib} from 'contracts/libraries/token-uris/FollowTokenURILib.sol';

contract FollowTokenURILibMock {
    function testFollowTokenURILibMock() public {
        // Prevents being counted in Foundry Coverage
    }

    function getTokenURI(
        uint256 followTokenId,
        uint256 followedProfileId,
        uint256 originalFollowTimestamp
    ) external pure returns (string memory) {
        return FollowTokenURILib.getTokenURI(followTokenId, followedProfileId, originalFollowTimestamp);
    }
}

contract FollowNFTTest is BaseTest, LensBaseERC721Test {
    using stdJson for string;
    using Strings for uint256;

    uint256 constant MINT_NEW_TOKEN = 0;
    address targetProfileOwner;
    uint256 targetProfileId;
    address followerProfileOwner;
    uint256 followerProfileId;
    address alreadyFollowingProfileOwner;
    uint256 alreadyFollowingProfileId;
    address targetFollowNFT;
    uint256 lastAssignedTokenId;
    address followHolder;

    function setUp() public override {
        super.setUp();

        targetProfileOwner = address(0xC0FFEE);
        targetProfileId = _createProfile(targetProfileOwner);
        followerProfileOwner = address(this);
        followerProfileId = _createProfile(followerProfileOwner);

        followHolder = address(0xF0110111401DE2);

        alreadyFollowingProfileOwner = address(0xF01108);
        alreadyFollowingProfileId = _createProfile(alreadyFollowingProfileOwner);
        vm.prank(alreadyFollowingProfileOwner);
        lastAssignedTokenId = hub.follow(
            alreadyFollowingProfileId,
            _toUint256Array(targetProfileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];

        targetFollowNFT = hub.getProfile(targetProfileId).followNFT;
        followNFT = FollowNFT(targetFollowNFT);
    }

    function _mintERC721(address to) internal virtual override returns (uint256) {
        vm.assume(!_isLensHubProxyAdmin(to));
        followerProfileId = _createProfile(to);
        vm.prank(to);
        uint256 tokenId = hub.follow(
            followerProfileId,
            _toUint256Array(targetProfileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];

        vm.prank(to);
        followNFT.wrap(tokenId);
        return tokenId;
    }

    function _burnERC721(uint256 tokenId) internal virtual override {
        return followNFT.burn(tokenId);
    }

    function _getERC721TokenAddress() internal view virtual override returns (address) {
        return targetFollowNFT;
    }

    function testDoesNotSupportOtherThanTheExpectedInterfaces(uint32 interfaceId) public override {
        vm.assume(bytes4(interfaceId) != bytes4(keccak256('royaltyInfo(uint256,uint256)')));
        super.testDoesNotSupportOtherThanTheExpectedInterfaces(interfaceId);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Follow - General - Negatives
    //////////////////////////////////////////////////////////

    function testCannotCallFollowIfNotTheHub(address sender) public {
        vm.assume(sender != address(hub));
        vm.assume(sender != address(0));

        vm.prank(sender);

        vm.expectRevert(Errors.NotHub.selector);
        followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });
    }

    function testCannotFollowIfAlreadyFollowing() public {
        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.AlreadyFollowing.selector);
        followNFT.follow({
            followerProfileId: alreadyFollowingProfileId,
            transactionExecutor: alreadyFollowingProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });
    }

    function testCannotFollowWithTokenIfTheTokenDoesNotExist(uint256 unexistentTokenId) public {
        vm.assume(unexistentTokenId != MINT_NEW_TOKEN);
        vm.assume(followNFT.getFollowerProfileId(unexistentTokenId) == 0);
        vm.assume(!followNFT.exists(unexistentTokenId));
        vm.assume(followNFT.getProfileIdAllowedToRecover(unexistentTokenId) == 0);

        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.FollowTokenDoesNotExist.selector);

        followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: unexistentTokenId
        });
    }

    function testCannotCallInitialize_AfterCreation(address anyAddress, uint256 profileId) public {
        vm.expectRevert(Errors.Initialized.selector);
        vm.prank(anyAddress);
        followNFT.initialize(profileId);
    }

    function testOriginalAndGeneralFollowTimestamp(
        uint32 initialTimestamp,
        uint32 originalFollowTimestamp,
        uint32 timeAdded
    ) public {
        vm.assume(initialTimestamp != 0);
        originalFollowTimestamp = uint32(bound(originalFollowTimestamp, initialTimestamp, type(uint32).max));
        uint48 laterTimestamp = uint48(originalFollowTimestamp) + uint48(timeAdded);

        // Initial non-zero timestamp
        vm.warp(initialTimestamp);

        uint256 expectedTokenId = lastAssignedTokenId + 1;

        assertEq(followNFT.getOriginalFollowTimestamp(expectedTokenId), 0);
        assertEq(followNFT.getFollowTimestamp(expectedTokenId), 0);

        // Original follow timestamp
        vm.warp(originalFollowTimestamp);

        vm.prank(followerProfileOwner);
        uint256 assignedTokenId = hub.follow(
            followerProfileId,
            _toUint256Array(targetProfileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];
        assertEq(assignedTokenId, expectedTokenId);

        assertEq(followNFT.getOriginalFollowTimestamp(assignedTokenId), originalFollowTimestamp);
        assertEq(followNFT.getFollowTimestamp(assignedTokenId), originalFollowTimestamp);

        vm.prank(followerProfileOwner);
        followNFT.wrap(assignedTokenId);

        assertEq(followNFT.getOriginalFollowTimestamp(assignedTokenId), originalFollowTimestamp);
        assertEq(followNFT.getFollowTimestamp(assignedTokenId), originalFollowTimestamp);

        hub.unfollow(followerProfileId, _toUint256Array(targetProfileId));

        assertEq(followNFT.getOriginalFollowTimestamp(assignedTokenId), originalFollowTimestamp);
        assertEq(followNFT.getFollowTimestamp(assignedTokenId), 0);

        // Some later timestamp
        vm.warp(laterTimestamp);

        vm.prank(followerProfileOwner);
        uint256 repeatedAssignedTokenId = hub.follow(
            followerProfileId,
            _toUint256Array(targetProfileId),
            _toUint256Array(assignedTokenId),
            _toBytesArray('')
        )[0];

        assertEq(repeatedAssignedTokenId, assignedTokenId);

        assertEq(followNFT.getOriginalFollowTimestamp(assignedTokenId), originalFollowTimestamp);
        assertEq(followNFT.getFollowTimestamp(assignedTokenId), laterTimestamp);
    }

    function testFollowTimestampResetAfterFollowTokenIsBurned(uint32 initialTimestamp) public {
        vm.assume(initialTimestamp != 0);
        vm.warp(initialTimestamp);

        uint256 expectedTokenId = lastAssignedTokenId + 1;

        assertEq(followNFT.getOriginalFollowTimestamp(expectedTokenId), 0);
        assertEq(followNFT.getFollowTimestamp(expectedTokenId), 0);

        vm.prank(followerProfileOwner);
        uint256 assignedTokenId = hub.follow(
            followerProfileId,
            _toUint256Array(targetProfileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];
        assertEq(assignedTokenId, expectedTokenId);

        assertEq(followNFT.getOriginalFollowTimestamp(assignedTokenId), initialTimestamp);
        assertEq(followNFT.getFollowTimestamp(assignedTokenId), initialTimestamp);

        vm.prank(followerProfileOwner);
        followNFT.wrap(assignedTokenId);

        vm.prank(followerProfileOwner);
        followNFT.burn(assignedTokenId);

        console.log('followerProfileId', followNFT.getFollowData(assignedTokenId).followerProfileId);
        console.log('originalFollowTimestamp', followNFT.getFollowData(assignedTokenId).originalFollowTimestamp);
        console.log('followTimestamp', followNFT.getFollowData(assignedTokenId).followTimestamp);
        console.log('profileIdAllowedToRecover', followNFT.getFollowData(assignedTokenId).profileIdAllowedToRecover);

        assertEq(followNFT.getOriginalFollowTimestamp(assignedTokenId), initialTimestamp);
        assertEq(followNFT.getFollowTimestamp(assignedTokenId), 0);
    }

    function testGetTokenURI_Fuzz() public {
        FollowTokenURILibMock followTokenURILib = new FollowTokenURILibMock();
        for (uint256 tokenId = type(uint256).max; tokenId > 0; tokenId >>= 16) {
            for (
                uint256 originalFollowTimestamp = type(uint48).max;
                originalFollowTimestamp > 0;
                originalFollowTimestamp >>= 8
            ) {
                uint256 followedProfileId = type(uint256).max - tokenId;
                string memory tokenURI = followTokenURILib.getTokenURI(
                    tokenId,
                    followedProfileId,
                    originalFollowTimestamp
                );
                string memory base64prefix = 'data:application/json;base64,';
                string memory decodedTokenURI = string(
                    Base64.decode(LibString.slice(tokenURI, bytes(base64prefix).length))
                );

                string memory tokenIdAsString = vm.toString(tokenId);
                string memory followedProfileIdAsString = vm.toString(followedProfileId);
                assertEq(decodedTokenURI.readString('.name'), string.concat('Follower #', tokenIdAsString));
                assertEq(
                    decodedTokenURI.readString('.description'),
                    string.concat(
                        'Lens Protocol - Follower #',
                        tokenIdAsString,
                        ' of Profile #',
                        followedProfileIdAsString
                    )
                );
                assertEq(decodedTokenURI.readUint('.attributes[0].value'), tokenId, "Token ID doesn't match");
                assertEq(
                    decodedTokenURI.readUint('.attributes[1].value'),
                    bytes(tokenIdAsString).length,
                    "Token ID Digits doesn't match"
                );
                assertEq(
                    decodedTokenURI.readUint('.attributes[2].value'),
                    originalFollowTimestamp,
                    "Original Follow Timestamp doesn't match"
                );
            }
        }
    }

    function testGetTokenURI() public {
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(lastAssignedTokenId);

        uint256 tokenId = lastAssignedTokenId;
        string memory tokenURI = followNFT.tokenURI(tokenId);
        string memory base64prefix = 'data:application/json;base64,';
        string memory decodedTokenURI = string(Base64.decode(LibString.slice(tokenURI, bytes(base64prefix).length)));

        string memory tokenIdAsString = vm.toString(tokenId);
        assertEq(decodedTokenURI.readString('.name'), string.concat('Follower #', tokenIdAsString));
        assertEq(
            decodedTokenURI.readString('.description'),
            string.concat('Lens Protocol - Follower #', tokenIdAsString, ' of Profile #', vm.toString(targetProfileId))
        );
        assertEq(decodedTokenURI.readUint('.attributes[0].value'), tokenId, "Token ID doesn't match");
        assertEq(
            decodedTokenURI.readUint('.attributes[1].value'),
            bytes(tokenIdAsString).length,
            "Token ID Digits doesn't match"
        );
        assertEq(
            decodedTokenURI.readUint('.attributes[2].value'),
            followNFT.getOriginalFollowTimestamp(tokenId),
            "Original Follow Timestamp doesn't match"
        );
    }

    function testCannot_GetTokenURI_IfDoesNotExist_OrIsUnwrapped(uint256 tokenId) public {
        vm.assume(!followNFT.exists(tokenId));

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        followNFT.tokenURI(tokenId);
    }

    function testSymbol(uint256 followedProfileId) public {
        followNFT = FollowNFT(address(new TransparentUpgradeableProxy(hub.getFollowNFTImpl(), proxyAdmin, '')));
        followNFT.initialize(followedProfileId);

        string memory FOLLOW_NFT_SYMBOL_SUFFIX = '-Fl';
        string memory expectedSymbol = string.concat(vm.toString(followedProfileId), FOLLOW_NFT_SYMBOL_SUFFIX);
        assertEq(followNFT.symbol(), expectedSymbol);
    }

    // GetFollowerCount - we need to test all cases and see how it increases/decreases

    //////////////////////////////////////////////////////////
    // Follow - Minting new token - Negatives
    //////////////////////////////////////////////////////////

    // No negatives when minting a new token, all the failing cases will occur at LensHub level. See `FollowTest.t.sol`.

    //////////////////////////////////////////////////////////
    // Follow - Minting new token - Scenarios
    //////////////////////////////////////////////////////////

    // Initial condition
    function testFirstFollowTokenHasIdOne() public {
        uint256 profileIdToFollow = _createProfile(address(this));

        vm.prank(followerProfileOwner);
        uint256 assignedTokenId = hub.follow(
            followerProfileId,
            _toUint256Array(profileIdToFollow),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];

        assertEq(assignedTokenId, 1);
    }

    function testNewMintedTokenIdIsLastAssignedPlusOne() public {
        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        assertEq(assignedTokenId, lastAssignedTokenId + 1);
    }

    function testFollowingMintingNewTokenSetsFollowerStatusCorrectly() public {
        uint256 followerCountBefore = followNFT.getFollowerCount();

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        bool isFollowing = followNFT.isFollowing(followerProfileId);
        assertEq(isFollowing, true);

        uint256 followerProfileIdSet = followNFT.getFollowerProfileId(assignedTokenId);
        assertEq(followerProfileIdSet, followerProfileId);

        uint256 followIdByFollower = followNFT.getFollowTokenId(followerProfileId);
        assertEq(followIdByFollower, assignedTokenId);

        assertEq(followNFT.getFollowerCount(), followerCountBefore + 1);
    }

    function testExpectedFollowDataAfterMintingNewToken() public {
        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        Types.FollowData memory followData = followNFT.getFollowData(assignedTokenId);

        assertEq(followData.followerProfileId, followerProfileId);
        assertEq(followData.originalFollowTimestamp, block.timestamp);
        assertEq(followData.followTimestamp, block.timestamp);
        assertEq(followData.profileIdAllowedToRecover, 0);
    }

    function testFollowTokenIsByDefaultUnwrapped() public {
        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        assertTrue(followNFT.isFollowing(followerProfileId));

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        followNFT.ownerOf(assignedTokenId);
    }

    //////////////////////////////////////////////////////////
    // Follow - With unwrapped token - Negatives
    //////////////////////////////////////////////////////////

    function testCannot_FollowWithUnwrappedTokenFromBurnedProfile_IfTheProfileWasNotBurned() public {
        // Conditions to reach that state:
        // - followerProfileId must not be following the target profile
        assertFalse(followNFT.isFollowing(followerProfileId));
        // - follow token must be used before and followTokenId != 0
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        assertTrue(followTokenId != 0);
        // - token must be unwrapped (followTokenOwner == 0 and !exists)
        assertFalse(followNFT.exists(followTokenId));

        uint256 currentFollowerProfileId = followNFT.getFollowerProfileId(followTokenId);
        // - currentFollowerProfileId should != 0
        assertTrue(currentFollowerProfileId != 0);
        // - CurrentFollowerProfileId Profile should exist
        assertTrue(hub.exists(currentFollowerProfileId));

        vm.prank(followerProfileOwner);
        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        hub.follow(
            followerProfileId,
            _toUint256Array(targetProfileId),
            _toUint256Array(followTokenId),
            _toBytesArray('')
        );
    }

    //////////////////////////////////////////////////////////
    // Follow - With unwrapped token - Scenarios
    //////////////////////////////////////////////////////////

    function testFollowWithUnwrappedTokenWhenCurrentFollowerWasBurnedAndTransactionExecutorIsFollowerOwner() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        uint256 followerCountBefore = followNFT.getFollowerCount();

        _effectivelyDisableProfileGuardian(alreadyFollowingProfileOwner);

        vm.prank(alreadyFollowingProfileOwner);
        hub.burn(alreadyFollowingProfileId);
        assertFalse(hub.exists(alreadyFollowingProfileId));

        // NOTE: Follow NFT is not aware of Profile NFT burnings, follower count stays the same.
        assertEq(followNFT.getFollowerCount(), followerCountBefore);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
        assertEq(followNFT.getFollowerCount(), followerCountBefore);
    }

    function testFollowWithUnwrappedTokenWhenCurrentFollowerWasBurnedAndTransactionExecutorIsApprovedDelegatee(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != followerProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        uint256 followerCountBefore = followNFT.getFollowerCount();

        _effectivelyDisableProfileGuardian(alreadyFollowingProfileOwner);

        vm.prank(alreadyFollowingProfileOwner);
        hub.burn(alreadyFollowingProfileId);
        assertFalse(hub.exists(alreadyFollowingProfileId));

        // NOTE: Follow NFT is not aware of Profile NFT burnings, follower count stays the same.
        assertEq(followNFT.getFollowerCount(), followerCountBefore);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: executorAsApprovedDelegatee,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
        assertEq(followNFT.getFollowerCount(), followerCountBefore);
    }

    //////////////////////////////////////////////////////////
    // Follow - With wrapped token - Negatives
    //////////////////////////////////////////////////////////

    function testCannot_FollowWithWrappedToken_IfDoesNotHavePermissions(
        address newFollowTokenHolder,
        address delegatedExecutor
    ) public {
        vm.assume(newFollowTokenHolder != followerProfileOwner);
        vm.assume(newFollowTokenHolder != address(0));
        vm.assume(delegatedExecutor != followerProfileOwner);
        vm.assume(delegatedExecutor != address(0));
        vm.assume(delegatedExecutor != newFollowTokenHolder);

        vm.startPrank(followerProfileOwner);
        uint256 followTokenId = hub.follow(
            followerProfileId,
            _toUint256Array(targetProfileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];
        followNFT.wrap(followTokenId);
        hub.unfollow(followerProfileId, _toUint256Array(targetProfileId));
        followNFT.transferFrom(followerProfileOwner, newFollowTokenHolder, followTokenId);
        hub.changeDelegatedExecutorsConfig(followerProfileId, _toAddressArray(delegatedExecutor), _toBoolArray(true));
        vm.stopPrank();

        // Requirements to reach the needed state:
        // 1. Follower should not follow the target profile
        assertFalse(followNFT.isFollowing(followerProfileId));
        // 2. FollowTokenId != 0
        assertTrue(followTokenId != 0);
        // 3. FollowToken should be wrapped (have ownerOf != 0)
        assertTrue(followNFT.exists(followTokenId));
        address followTokenOwner = followNFT.ownerOf(followTokenId);
        // 4. FollowApproval of followTokenId should != followerProfileId
        assertTrue(followNFT.getFollowApproved(followTokenId) != followerProfileId);
        // 5. FollowerProfileOwner should != followTokenOwner
        assertTrue(followTokenOwner != followerProfileOwner);
        // 6. TransactionExecutor should != followTokenOwner
        assertTrue(followTokenOwner != delegatedExecutor);
        // 7. FollowerProfileOwner should NOT be approvedForAll by followerTokenOwner
        assertFalse(followNFT.isApprovedForAll(followTokenOwner, followerProfileOwner));
        // 8. TransactionExecutor should NOT be approvedForAll by followerTokenOwner
        assertFalse(followNFT.isApprovedForAll(followTokenOwner, delegatedExecutor));

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        vm.prank(address(hub));
        followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: followTokenId
        });

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        vm.prank(address(hub));
        followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: delegatedExecutor,
            followTokenId: followTokenId
        });
    }

    //////////////////////////////////////////////////////////
    // Follow - With wrapped token - Scenarios
    //////////////////////////////////////////////////////////

    function testFollowWithWrappedTokenWhen_FollowerOwnerOwnsFollowTokenAndIsActingAsTransactionExecutor() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        uint256 followerCountBefore = followNFT.getFollowerCount();

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followerProfileOwner, followTokenId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        // NOTE: It just replaces the follower in the wrapped token, follower count stays the same.
        assertEq(followNFT.getFollowerCount(), followerCountBefore);
    }

    function testFollowWithWrappedTokenWhen_FollowerOwnerOwnsFollowTokenAndIsActingAsTransactionExecutor_FollowerUnfollowFirst()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        uint256 followerCountBefore = followNFT.getFollowerCount();

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertEq(followNFT.getFollowerCount(), followerCountBefore - 1);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followerProfileOwner, followTokenId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowerCount(), followerCountBefore);
    }

    function testFollowWithWrappedTokenWhen_FollowerOwnerAlsoOwnsFollowTokenAndTransactionExecutorIsApprovedDelegatee(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != followerProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followerProfileOwner, followTokenId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: executorAsApprovedDelegatee,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
    }

    function testFollowWithWrappedTokenWhen_ExecutorOwnsFollowTokenAndTransactionExecutorIsApprovedDelegatee(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != followerProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, executorAsApprovedDelegatee, followTokenId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: executorAsApprovedDelegatee,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
    }

    function testFollowWithWrappedTokenWhen_ExecutorIsApprovedForAllAndTransactionExecutorIsFollowerOwner() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.setApprovalForAll(followerProfileOwner, true);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
    }

    function testFollowWithWrappedTokenWhen_ExecutorIsApprovedForAllAndTransactionExecutorIsApprovedDelegatee(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != followerProfileOwner);
        vm.assume(executorAsApprovedDelegatee != alreadyFollowingProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.setApprovalForAll(executorAsApprovedDelegatee, true);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: executorAsApprovedDelegatee,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
    }

    function testFollowWithWrappedTokenWhen_ProfileIsApprovedToFollowAndTransactionExecutorIsFollowerOwner() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    function testFollowWithWrappedTokenWhen_ProfileIsApprovedToFollowAndTransactionExecutorIsApprovedDelegatee(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != followerProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: executorAsApprovedDelegatee,
            followTokenId: followTokenId
        });

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(followerProfileId), followTokenId);
        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    //////////////////////////////////////////////////////////
    // Follow - Recovering token - Scenarios
    //////////////////////////////////////////////////////////

    function testFollowRecoveringToken() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        uint256 followerCountBefore = followNFT.getFollowerCount();

        vm.prank(address(hub));

        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);
        assertEq(followNFT.getFollowerCount(), followerCountBefore - 1);

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: alreadyFollowingProfileId,
            transactionExecutor: alreadyFollowingProfileOwner,
            followTokenId: followTokenId
        });

        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(assignedTokenId, followTokenId);
        assertEq(followNFT.getFollowTokenId(alreadyFollowingProfileId), followTokenId);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
        assertEq(followNFT.getFollowerCount(), followerCountBefore);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Unfollow - Negatives
    //////////////////////////////////////////////////////////

    function testCannotCallUnfollowIfNotTheHub(address sender) public {
        vm.assume(sender != address(hub));
        vm.assume(sender != address(0));

        vm.prank(sender);

        vm.expectRevert(Errors.NotHub.selector);
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});
    }

    function testCannotUnfollowIfNotAlreadyFollowing() public {
        assertFalse(followNFT.isFollowing(followerProfileId));

        vm.prank(address(hub));

        vm.expectRevert(IFollowNFT.NotFollowing.selector);
        followNFT.unfollow({unfollowerProfileId: followerProfileId});
    }

    // TODO: Move to positives, because now it's possible to unfollow even if the token is wrapped and not owned.
    function testCanUnfollowIfTokenIsWrappedAndUnfollowerOwnerOrTransactionExecutorDontHoldTheTokenOrApprovedForAll(
        address unrelatedAddress
    ) public {
        vm.assume(unrelatedAddress != address(0));
        vm.assume(unrelatedAddress != alreadyFollowingProfileOwner);
        vm.assume(!hub.isDelegatedExecutorApproved(alreadyFollowingProfileId, unrelatedAddress));
        vm.assume(!followNFT.isApprovedForAll(alreadyFollowingProfileOwner, unrelatedAddress));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, unrelatedAddress, followTokenId);

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});
    }

    function testCannotRemoveFollowerOnWrappedIfNotHolder(address unrelatedAddress) public {
        vm.assume(unrelatedAddress != address(0));
        vm.assume(unrelatedAddress != followHolder);

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followHolder, followTokenId);

        vm.prank(unrelatedAddress);

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        followNFT.removeFollower({followTokenId: followTokenId});
    }

    //////////////////////////////////////////////////////////
    // Unfollow - Scenarios
    //////////////////////////////////////////////////////////

    function testUnfollowAsFollowerProfileOwnerWhenTokenIsWrapped() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        uint256 followerCountBefore = followNFT.getFollowerCount();

        vm.prank(address(hub));

        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
        assertEq(followNFT.getFollowerCount(), followerCountBefore - 1);
    }

    function testUnfollowAsApprovedDelegatedExecutorOfFollowerOwnerWhenTokenIsWrapped(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != alreadyFollowingProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(address(hub));

        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    function testUnfollowAsFollowTokenOwnerWhenTokenIsWrapped(address followTokenOwner) public {
        vm.assume(followTokenOwner != alreadyFollowingProfileOwner);
        vm.assume(followTokenOwner != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followTokenOwner, followTokenId);

        vm.prank(address(hub));

        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    function testUnfollowAsApprovedForAllByTokenOwnerWhenTokenIsWrapped(address approvedForAll) public {
        vm.assume(approvedForAll != alreadyFollowingProfileOwner);
        vm.assume(approvedForAll != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.setApprovalForAll(approvedForAll, true);

        vm.prank(address(hub));

        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    function testUnfollowAsFollowerProfileOwnerWhenTokenIsUnwrapped() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));

        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);
    }

    function testUnfollowAsApprovedDelegatedExecutorOfFollowerOwnerWhenTokenIsUnwrapped(
        address executorAsApprovedDelegatee
    ) public {
        vm.assume(executorAsApprovedDelegatee != alreadyFollowingProfileOwner);
        vm.assume(executorAsApprovedDelegatee != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));

        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerProfileId(alreadyFollowingProfileId), 0);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);
    }

    function testRemoveFollower() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        uint256 followerCountBefore = followNFT.getFollowerCount();

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followHolder, followTokenId);

        vm.prank(followHolder);
        followNFT.removeFollower({followTokenId: followTokenId});

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.getFollowerCount(), followerCountBefore - 1);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Wrap (tokenId) - Negatives
    //////////////////////////////////////////////////////////

    function testCannotWrapIfAlreadyWrapped() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);

        vm.expectRevert(IFollowNFT.AlreadyWrapped.selector);
        followNFT.wrap(followTokenId);
    }

    function testCannotWrapIfTokenDoesNotExist(uint256 unexistentTokenId) public {
        vm.assume(followNFT.getFollowerProfileId(unexistentTokenId) == 0);
        vm.assume(!followNFT.exists(unexistentTokenId));

        vm.expectRevert(IFollowNFT.FollowTokenDoesNotExist.selector);
        followNFT.wrap(unexistentTokenId);
    }

    function testCannotWrapIfSenderIsNotFollowerOwner(address notFollowerOwner) public {
        vm.assume(notFollowerOwner != alreadyFollowingProfileOwner);
        vm.assume(notFollowerOwner != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(notFollowerOwner);

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        followNFT.wrap(followTokenId);
    }

    function testCannotWrapRecoveringWhenTheProfileAllowedToRecoverDoesNotExistAnymore() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);

        _effectivelyDisableProfileGuardian(alreadyFollowingProfileOwner);

        vm.prank(alreadyFollowingProfileOwner);
        hub.burn(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        followNFT.wrap(followTokenId);
    }

    function testCannotWrapRecoveringWhenTheSenderDoesNotOwnTheProfileAllowedToRecover(
        address unrelatedAddress
    ) public {
        vm.assume(unrelatedAddress != address(0));
        vm.assume(unrelatedAddress != alreadyFollowingProfileOwner);

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);

        _effectivelyDisableProfileGuardian(alreadyFollowingProfileOwner);

        vm.prank(alreadyFollowingProfileOwner);
        hub.transferFrom({
            from: alreadyFollowingProfileOwner,
            to: unrelatedAddress,
            tokenId: alreadyFollowingProfileId
        });

        vm.prank(alreadyFollowingProfileOwner);
        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        followNFT.wrap(followTokenId);
    }

    //////////////////////////////////////////////////////////
    // Wrap (tokenId) - Scenarios
    //////////////////////////////////////////////////////////

    function testWrappedTokenOwnerIsFollowerProfileOwnerAfterUntyingAndWrapping() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        assertEq(followNFT.ownerOf(followTokenId), alreadyFollowingProfileOwner);
    }

    function testWrappedTokenStillHeldByPreviousFollowerOwnerAfterAFollowerProfileTransfer(
        address newFollowerProfileOwner
    ) public {
        vm.assume(newFollowerProfileOwner != followerProfileOwner);
        vm.assume(newFollowerProfileOwner != address(0));

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        vm.prank(followerProfileOwner);
        followNFT.wrap(assignedTokenId);

        assertEq(followNFT.ownerOf(assignedTokenId), followerProfileOwner);

        assertTrue(followNFT.isFollowing(followerProfileId));
        uint256 followerProfileIdSet = followNFT.getFollowerProfileId(assignedTokenId);
        assertEq(followerProfileIdSet, followerProfileId);

        _effectivelyDisableProfileGuardian(followerProfileOwner);

        vm.prank(followerProfileOwner);
        hub.transferFrom(followerProfileOwner, newFollowerProfileOwner, followerProfileId);

        assertEq(hub.ownerOf(followerProfileId), newFollowerProfileOwner);
        assertEq(followNFT.ownerOf(assignedTokenId), followerProfileOwner);

        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(followerProfileIdSet, followNFT.getFollowerProfileId(assignedTokenId));
    }

    function testRecoveringTokenThroughWrappingIt() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        assertEq(followNFT.ownerOf(followTokenId), alreadyFollowingProfileOwner);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    function testRecoveringTokenThroughWrappingItAfterProfileAllowedToRecoverWasTransferred(
        address unrelatedAddress
    ) public {
        vm.assume(unrelatedAddress != address(0));
        vm.assume(unrelatedAddress != alreadyFollowingProfileOwner);

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);

        _effectivelyDisableProfileGuardian(alreadyFollowingProfileOwner);

        vm.prank(alreadyFollowingProfileOwner);
        hub.transferFrom({
            from: alreadyFollowingProfileOwner,
            to: unrelatedAddress,
            tokenId: alreadyFollowingProfileId
        });

        vm.prank(unrelatedAddress);
        followNFT.wrap(followTokenId);

        assertEq(followNFT.ownerOf(followTokenId), unrelatedAddress);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    //////////////////////////////////////////////////////////
    // Wrap (tokenId, receiver) - Negatives
    //////////////////////////////////////////////////////////

    function testCannotWrapIfTokenReceiverIsAddressZero() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.expectRevert(Errors.InvalidParameter.selector);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId, address(0));
    }

    function testCannotWrapIfAlreadyWrapped(address receiver) public {
        vm.assume(receiver != address(0));
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId, receiver);

        vm.prank(alreadyFollowingProfileOwner);

        vm.expectRevert(IFollowNFT.AlreadyWrapped.selector);
        followNFT.wrap(followTokenId, receiver);
    }

    function testCannotWrapIfTokenDoesNotExist(uint256 unexistentTokenId, address receiver) public {
        vm.assume(receiver != address(0));
        vm.assume(followNFT.getFollowerProfileId(unexistentTokenId) == 0);
        vm.assume(!followNFT.exists(unexistentTokenId));

        vm.expectRevert(IFollowNFT.FollowTokenDoesNotExist.selector);
        followNFT.wrap(unexistentTokenId, receiver);
    }

    function testCannotWrapIfSenderIsNotFollowerOwner(address notFollowerOwner, address receiver) public {
        vm.assume(receiver != address(0));
        vm.assume(notFollowerOwner != alreadyFollowingProfileOwner);
        vm.assume(notFollowerOwner != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(notFollowerOwner);

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        followNFT.wrap(followTokenId, receiver);
    }

    function testCannotWrapRecoveringWhenTheProfileAllowedToRecoverDoesNotExistAnymore(address receiver) public {
        vm.assume(receiver != address(0));
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);

        _effectivelyDisableProfileGuardian(alreadyFollowingProfileOwner);

        vm.prank(alreadyFollowingProfileOwner);
        hub.burn(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        followNFT.wrap(followTokenId, receiver);
    }

    function testCannotWrapRecoveringWhenTheSenderDoesNotOwnTheProfileAllowedToRecover(
        address unrelatedAddress,
        address receiver
    ) public {
        vm.assume(receiver != address(0));
        vm.assume(unrelatedAddress != address(0));
        vm.assume(unrelatedAddress != alreadyFollowingProfileOwner);

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);

        _effectivelyDisableProfileGuardian(alreadyFollowingProfileOwner);

        vm.prank(alreadyFollowingProfileOwner);
        hub.transferFrom({
            from: alreadyFollowingProfileOwner,
            to: unrelatedAddress,
            tokenId: alreadyFollowingProfileId
        });

        vm.prank(alreadyFollowingProfileOwner);
        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        followNFT.wrap(followTokenId, receiver);
    }

    //////////////////////////////////////////////////////////
    // Wrap (tokenId, receiver) - Scenarios
    //////////////////////////////////////////////////////////

    function testWrappedTokenOwnerIsReceiverProfileOwnerAfterUntyingAndWrapping(address receiver) public {
        vm.assume(receiver != address(0));
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId, receiver);

        assertEq(followNFT.ownerOf(followTokenId), receiver);
    }

    function testWrappedTokenStillHeldByPreviousFollowerOwnerAfterAFollowerProfileTransfer(
        address receiver,
        address newFollowerProfileOwner
    ) public {
        vm.assume(receiver != address(0));
        vm.assume(newFollowerProfileOwner != followerProfileOwner);
        vm.assume(newFollowerProfileOwner != address(0));

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        vm.prank(followerProfileOwner);
        followNFT.wrap(assignedTokenId, receiver);

        assertEq(followNFT.ownerOf(assignedTokenId), receiver);

        assertTrue(followNFT.isFollowing(followerProfileId));
        uint256 followerProfileIdSet = followNFT.getFollowerProfileId(assignedTokenId);
        assertEq(followerProfileIdSet, followerProfileId);

        vm.prank(followerProfileOwner);
        hub.transferFrom(followerProfileOwner, newFollowerProfileOwner, followerProfileId);

        assertEq(hub.ownerOf(followerProfileId), newFollowerProfileOwner);
        assertEq(followNFT.ownerOf(assignedTokenId), receiver);

        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(followerProfileIdSet, followNFT.getFollowerProfileId(assignedTokenId));
    }

    function testRecoveringTokenThroughWrappingIt(address receiver) public {
        vm.assume(receiver != address(0));
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId, receiver);

        assertEq(followNFT.ownerOf(followTokenId), receiver);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    function testRecoveringTokenThroughWrappingItAfterProfileAllowedToRecoverWasTransferred(
        address unrelatedAddress,
        address receiver
    ) public {
        vm.assume(receiver != address(0));
        vm.assume(unrelatedAddress != address(0));
        vm.assume(unrelatedAddress != alreadyFollowingProfileOwner);

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), alreadyFollowingProfileId);

        _effectivelyDisableProfileGuardian(alreadyFollowingProfileOwner);

        vm.prank(alreadyFollowingProfileOwner);
        hub.transferFrom({
            from: alreadyFollowingProfileOwner,
            to: unrelatedAddress,
            tokenId: alreadyFollowingProfileId
        });

        vm.prank(unrelatedAddress);
        followNFT.wrap(followTokenId, receiver);

        assertEq(followNFT.ownerOf(followTokenId), receiver);
        assertEq(followNFT.getProfileIdAllowedToRecover(followTokenId), 0);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Unwrap - Negatives
    //////////////////////////////////////////////////////////

    function testCannotUnwrapIfTokenDoesNotHaveAFollowerSet() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        vm.expectRevert(IFollowNFT.NotFollowing.selector);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.unwrap(followTokenId);
    }

    function testCannotUnwrapIfTokenIsAlreadyUnwrapped() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.unwrap(followTokenId);
    }

    function testCannotUnwrapIfSenderIsNotTokenOwnerOrApprovedOrApprovedForAll(address sender) public {
        // You can't approve a token that is not wrapped, so no need to check for `followNFT.getApproved(followTokenId)`
        vm.assume(sender != alreadyFollowingProfileOwner);
        vm.assume(sender != address(0));
        vm.assume(!followNFT.isApprovedForAll(alreadyFollowingProfileOwner, sender));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.expectRevert(Errors.NotOwnerOrApproved.selector);
        vm.prank(sender);
        followNFT.unwrap(followTokenId);
    }

    //////////////////////////////////////////////////////////
    // Unwrap - Scenarios
    //////////////////////////////////////////////////////////

    function testTokenOwnerCanUnwrapIt() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.unwrap(followTokenId);

        assertFalse(followNFT.exists(followTokenId));
    }

    function testApprovedForAllCanUnwrapAToken(address approvedForAll) public {
        vm.assume(approvedForAll != alreadyFollowingProfileOwner);
        vm.assume(approvedForAll != address(0));

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.setApprovalForAll(approvedForAll, true);

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(approvedForAll);
        followNFT.unwrap(followTokenId);

        assertFalse(followNFT.exists(followTokenId));
    }

    function testApprovedForATokenCanUnwrapIt(address approved) public {
        vm.assume(approved != alreadyFollowingProfileOwner);
        vm.assume(approved != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approve(approved, followTokenId);

        vm.prank(approved);
        followNFT.unwrap(followTokenId);

        assertFalse(followNFT.exists(followTokenId));
    }

    function testUnwrappedTokenStillTiedToFollowerProfileAfterAFollowerProfileTransfer(
        address newFollowerProfileOwner
    ) public {
        vm.assume(newFollowerProfileOwner != followerProfileOwner);
        vm.assume(newFollowerProfileOwner != address(0));

        vm.prank(address(hub));

        uint256 assignedTokenId = followNFT.follow({
            followerProfileId: followerProfileId,
            transactionExecutor: followerProfileOwner,
            followTokenId: MINT_NEW_TOKEN
        });

        assertTrue(followNFT.isFollowing(followerProfileId));
        uint256 followerProfileIdSet = followNFT.getFollowerProfileId(assignedTokenId);
        assertEq(followerProfileIdSet, followerProfileId);

        _effectivelyDisableProfileGuardian(followerProfileOwner);

        vm.prank(followerProfileOwner);
        hub.transferFrom(followerProfileOwner, newFollowerProfileOwner, followerProfileId);

        assertEq(hub.ownerOf(followerProfileId), newFollowerProfileOwner);

        assertTrue(followNFT.isFollowing(followerProfileId));
        assertEq(followerProfileIdSet, followNFT.getFollowerProfileId(assignedTokenId));

        vm.prank(newFollowerProfileOwner);
        followNFT.wrap(assignedTokenId);
        assertEq(followNFT.ownerOf(assignedTokenId), newFollowerProfileOwner);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Block - Negatives
    //////////////////////////////////////////////////////////

    function testCannotCallBlockIfNotTheHub(address sender) public {
        vm.assume(sender != address(hub));
        vm.assume(sender != address(0));

        vm.prank(sender);

        vm.expectRevert(Errors.NotHub.selector);
        followNFT.processBlock(followerProfileId);
    }

    //////////////////////////////////////////////////////////
    // Block - Scenarios
    //////////////////////////////////////////////////////////

    function testCanBlockSomeoneAlreadyBlocked() public {
        vm.prank(address(hub));
        followNFT.processBlock(followerProfileId);

        vm.prank(address(hub));
        followNFT.processBlock(followerProfileId);
    }

    function testBlockingFollowerThatWasFollowingWithWrappedTokenMakesHimUnfollowButKeepsTheWrappedToken() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));

        vm.prank(address(hub));
        followNFT.processBlock(alreadyFollowingProfileId);

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));

        assertEq(followNFT.ownerOf(followTokenId), alreadyFollowingProfileOwner);
    }

    function testBlockingFollowerThatWasFollowingWithUnwrappedFirstWrapsTokenAndThenMakesHimUnfollowKeepingItWrapped()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        assertFalse(followNFT.exists(followTokenId));
        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));

        vm.prank(address(hub));
        followNFT.processBlock(alreadyFollowingProfileId);

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.ownerOf(followTokenId), alreadyFollowingProfileOwner);
    }

    function testBlockingProfileThatWasNotFollowingButItsOwnerHoldsWrappedFollowTokenDoesNotChangeAnything() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(address(hub));
        followNFT.unfollow({unfollowerProfileId: alreadyFollowingProfileId});

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.ownerOf(followTokenId), alreadyFollowingProfileOwner);

        vm.prank(address(hub));
        followNFT.processBlock(alreadyFollowingProfileId);

        assertFalse(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.ownerOf(followTokenId), alreadyFollowingProfileOwner);
    }

    function testBlockingProfileThatWasNotFollowingButItsOwnerHoldsWrappedFollowTokenWithFollowerDoesNotChangeAnything()
        public
    {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followerProfileOwner, followTokenId);

        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.ownerOf(followTokenId), followerProfileOwner);

        vm.prank(address(hub));
        followNFT.processBlock(followerProfileId);

        assertTrue(followNFT.isFollowing(alreadyFollowingProfileId));
        assertEq(followNFT.ownerOf(followTokenId), followerProfileOwner);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // Approve follow - Negatives
    //////////////////////////////////////////////////////////

    function testCannotApproveFollowForUnexistentProfile(uint256 unexistentProfileId) public {
        vm.assume(!hub.exists(unexistentProfileId));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(unexistentProfileId, followTokenId);
    }

    function testCannotApproveFollowForUnexistentFollowToken(uint256 unexistentFollowTokenId) public {
        vm.assume(!followNFT.exists(unexistentFollowTokenId));
        vm.assume(followNFT.getFollowerProfileId(unexistentFollowTokenId) == 0);

        vm.expectRevert(IFollowNFT.OnlyWrappedFollowTokens.selector);
        followNFT.approveFollow(followerProfileId, unexistentFollowTokenId);
    }

    function testCannotApproveFollowForWrappedTokenIfCallerIsNotItsOwnerOrApprovedForAllByHim(address sender) public {
        vm.assume(sender != alreadyFollowingProfileOwner);
        vm.assume(sender != address(0));
        vm.assume(!followNFT.isApprovedForAll(alreadyFollowingProfileOwner, sender));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.expectRevert(IFollowNFT.DoesNotHavePermissions.selector);
        vm.prank(sender);
        followNFT.approveFollow(followerProfileId, followTokenId);
    }

    function testCannotApproveFollowIfTokenIsUnwrapped() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.expectRevert(IFollowNFT.OnlyWrappedFollowTokens.selector);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);
    }

    //////////////////////////////////////////////////////////
    // Approve follow - Scenarios
    //////////////////////////////////////////////////////////

    function testApproveFollowWhenTokenIsWrappedAndCallerIsItsOwner() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);
    }

    function testApproveFollowWhenTokenIsWrappedAndCallerIsApprovedForAllByItsOwner(address approvedForAll) public {
        vm.assume(approvedForAll != alreadyFollowingProfileOwner);
        vm.assume(approvedForAll != address(0));

        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.setApprovalForAll(approvedForAll, true);

        vm.prank(approvedForAll);
        followNFT.approveFollow(followerProfileId, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);
    }

    function testFollowApprovalIsClearedAfterUnwrapping() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.unwrap(followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), 0);

        // Wraps again and checks that it keeps being clear.

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    function testFollowApprovalIsClearedAfterTransfer() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.transferFrom(alreadyFollowingProfileOwner, followerProfileOwner, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), 0);

        // Transfers back to the previous owner and checks that it keeps being clear.

        vm.prank(followerProfileOwner);
        followNFT.transferFrom(followerProfileOwner, alreadyFollowingProfileOwner, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    function testFollowApprovalIsClearedAfterBurning() public {
        uint256 followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.approveFollow(followerProfileId, followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), followerProfileId);

        vm.prank(alreadyFollowingProfileOwner);
        followNFT.burn(followTokenId);

        assertEq(followNFT.getFollowApproved(followTokenId), 0);
    }

    //////////////////////////////////////////////////////////
    // ERC-2981 Royalties - Scenarios
    //////////////////////////////////////////////////////////

    function testSupportsErc2981Interface() public {
        assertTrue(followNFT.supportsInterface(bytes4(keccak256('royaltyInfo(uint256,uint256)'))));
    }

    function testDefaultRoyaltiesAreSetTo10Percent(uint256 tokenId) public {
        uint256 salePrice = 100;
        uint256 expectedRoyalties = 10;

        (address receiver, uint256 royalties) = followNFT.royaltyInfo(tokenId, salePrice);

        assertEq(receiver, targetProfileOwner);
        assertEq(royalties, expectedRoyalties);
    }

    function testSetRoyalties(uint256 royaltiesInBasisPoints, uint256 tokenId, uint256 salePrice) public {
        uint256 basisPoints = 10000;
        royaltiesInBasisPoints = bound(royaltiesInBasisPoints, 0, basisPoints);
        uint256 salePriceTimesRoyalties;
        unchecked {
            salePriceTimesRoyalties = salePrice * royaltiesInBasisPoints;
            // Fuzz prices that does not generate overflow, otherwise royaltyInfo will revert
            vm.assume(salePrice == 0 || salePriceTimesRoyalties / salePrice == royaltiesInBasisPoints);
        }

        vm.prank(targetProfileOwner);
        followNFT.setRoyalty(royaltiesInBasisPoints);

        (address receiver, uint256 royalties) = followNFT.royaltyInfo(tokenId, salePrice);

        assertEq(receiver, targetProfileOwner);
        assertEq(royalties, salePriceTimesRoyalties / basisPoints);
    }

    //////////////////////////////////////////////////////////
    // ERC-2981 Royalties - Negatives
    //////////////////////////////////////////////////////////

    function testCannotSetRoyaltiesIf_NotTargetProfileOwner(
        address nonTargetProfileOwner,
        uint256 royaltiesInBasisPoints
    ) public {
        uint256 basisPoints = 10000;
        royaltiesInBasisPoints = bound(royaltiesInBasisPoints, 0, basisPoints);
        vm.assume(nonTargetProfileOwner != targetProfileOwner);

        vm.prank(nonTargetProfileOwner);
        vm.expectRevert(Errors.NotProfileOwner.selector);
        followNFT.setRoyalty(royaltiesInBasisPoints);
    }

    function testCannotSetRoyaltiesIf_ExceedsBasisPoints(uint256 royaltiesInBasisPoints) public {
        uint256 basisPoints = 10000;
        vm.assume(royaltiesInBasisPoints > basisPoints);

        vm.prank(targetProfileOwner);
        vm.expectRevert(Errors.InvalidParameter.selector);
        followNFT.setRoyalty(royaltiesInBasisPoints);
    }
}
