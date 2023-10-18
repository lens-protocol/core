// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/MetaTxNegatives.t.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';

contract UnfollowTest is BaseTest {
    uint256 constant MINT_NEW_TOKEN = 0;
    address constant PROFILE_OWNER = address(0);
    address targetProfileOwner = address(0xC0FFEE);
    uint256 targetProfileId;
    uint256 constant nonFollowingProfileOwnerPk = 0x7357;
    address nonFollowingProfileOwner;
    uint256 nonFollowingProfileId;
    uint256 constant testUnfollowerProfileOwnerPk = 0xF01108;
    address testUnfollowerProfileOwner;
    uint256 testUnfollowerProfileId;
    address targetFollowNFT;
    uint256 followTokenId;

    function setUp() public virtual override {
        super.setUp();

        targetProfileId = _createProfile(targetProfileOwner);
        nonFollowingProfileOwner = vm.addr(nonFollowingProfileOwnerPk);
        nonFollowingProfileId = _createProfile(nonFollowingProfileOwner);
        testUnfollowerProfileOwner = vm.addr(testUnfollowerProfileOwnerPk);
        testUnfollowerProfileId = _createProfile(testUnfollowerProfileOwner);
        vm.prank(testUnfollowerProfileOwner);
        followTokenId = hub.follow(
            testUnfollowerProfileId,
            _toUint256Array(targetProfileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];

        targetFollowNFT = hub.getProfile(targetProfileId).followNFT;
        followNFT = FollowNFT(targetFollowNFT);
    }

    //////////////////////////////////////////////////////////
    // Unfollow - Negatives
    //////////////////////////////////////////////////////////

    function testCannotUnfollowIfPaused() public {
        vm.prank(governance);
        hub.setState(Types.ProtocolState.Paused);

        vm.expectRevert(Errors.Paused.selector);

        _unfollow({
            pk: testUnfollowerProfileOwnerPk,
            unfollowerProfileId: testUnfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });
    }

    function testCannotUnfollowIfUnfollowerProfileDoesNotExist() public {
        _effectivelyDisableProfileGuardian(testUnfollowerProfileOwner);

        vm.prank(testUnfollowerProfileOwner);
        hub.burn(testUnfollowerProfileId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _unfollow({
            pk: testUnfollowerProfileOwnerPk,
            unfollowerProfileId: testUnfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });
    }

    function testCannotUnfollowIfSomeOfTheProfilesToUnfollowDoNotExist(uint256 unexistentProfileId) public {
        vm.assume(!hub.exists(unexistentProfileId));

        assertTrue(hub.isFollowing(testUnfollowerProfileId, targetProfileId));

        vm.expectRevert(Errors.NotFollowing.selector);

        _unfollow({
            pk: testUnfollowerProfileOwnerPk,
            unfollowerProfileId: testUnfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId, unexistentProfileId)
        });

        // Asserts that the unfollow operation has been completely reverted after one of the unfollows failed.
        assertTrue(hub.isFollowing(testUnfollowerProfileId, targetProfileId));
    }

    function testCannotUnfollowIfTheProfileHasNeverBeenFollowedBefore() public {
        uint256 hasNeverBeenFollowedProfileId = _createProfile(targetProfileOwner);

        vm.expectRevert(Errors.NotFollowing.selector);

        _unfollow({
            pk: testUnfollowerProfileOwnerPk,
            unfollowerProfileId: testUnfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(hasNeverBeenFollowedProfileId)
        });
    }

    function testCannotUnfollowIfNotFollowingTheTargetProfile() public {
        vm.expectRevert(Errors.NotFollowing.selector);

        _unfollow({
            pk: nonFollowingProfileOwnerPk,
            unfollowerProfileId: nonFollowingProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });
    }

    function testCannotUnfollowIfNotProfileOwnerOrDelegatedExecutor(uint256 transactionExecutorPk) public {
        transactionExecutorPk = bound(
            transactionExecutorPk,
            1,
            115792089237316195423570985008687907852837564279074904382605163141518161494337 - 1
        );
        address transactionExecutor = vm.addr(transactionExecutorPk);
        vm.assume(transactionExecutor != testUnfollowerProfileOwner);
        vm.assume(!hub.isDelegatedExecutorApproved(testUnfollowerProfileId, transactionExecutor));
        vm.assume(!followNFT.isApprovedForAll(testUnfollowerProfileOwner, transactionExecutor));

        followTokenId = followNFT.getFollowTokenId(testUnfollowerProfileId);
        vm.prank(testUnfollowerProfileOwner);
        followNFT.wrap(followTokenId);

        vm.expectRevert(Errors.ExecutorInvalid.selector);

        _unfollow({
            pk: transactionExecutorPk,
            unfollowerProfileId: testUnfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });
    }

    //////////////////////////////////////////////////////////
    // Unfollow - Scenarios
    //////////////////////////////////////////////////////////

    function testUnfollowAsUnfollowerOwner() public {
        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Unfollowed(testUnfollowerProfileId, targetProfileId, testUnfollowerProfileOwner, block.timestamp);

        vm.expectCall(targetFollowNFT, abi.encodeCall(followNFT.unfollow, (testUnfollowerProfileId)), 1);

        _unfollow({
            pk: testUnfollowerProfileOwnerPk,
            unfollowerProfileId: testUnfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });

        assertFalse(hub.isFollowing(testUnfollowerProfileId, targetProfileId));
    }

    function testUnfollowAsUnfollowerApprovedDelegatedExecutor(uint256 approvedDelegatedExecutorPk) public {
        approvedDelegatedExecutorPk = _boundPk(approvedDelegatedExecutorPk);
        address approvedDelegatedExecutor = vm.addr(approvedDelegatedExecutorPk);
        vm.assume(approvedDelegatedExecutor != address(0));
        vm.assume(approvedDelegatedExecutor != testUnfollowerProfileOwner);

        vm.prank(testUnfollowerProfileOwner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: testUnfollowerProfileId,
            delegatedExecutors: _toAddressArray(approvedDelegatedExecutor),
            approvals: _toBoolArray(true)
        });

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Unfollowed(testUnfollowerProfileId, targetProfileId, approvedDelegatedExecutor, block.timestamp);

        vm.expectCall(targetFollowNFT, abi.encodeCall(followNFT.unfollow, (testUnfollowerProfileId)), 1);

        _unfollow({
            pk: approvedDelegatedExecutorPk,
            unfollowerProfileId: testUnfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });

        assertFalse(hub.isFollowing(testUnfollowerProfileId, targetProfileId));
    }

    function testUnfollowIfTargetProfileWasBurned() public {
        assertTrue(hub.isFollowing(testUnfollowerProfileId, targetProfileId));

        _effectivelyDisableProfileGuardian(targetProfileOwner);
        vm.prank(targetProfileOwner);
        hub.burn(targetProfileId);

        _unfollow({
            pk: testUnfollowerProfileOwnerPk,
            unfollowerProfileId: testUnfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });

        // Asserts that the unfollow operation was still a success.
        assertFalse(hub.isFollowing(testUnfollowerProfileId, targetProfileId));
    }

    function _unfollow(
        uint256 pk,
        uint256 unfollowerProfileId,
        uint256[] memory idsOfProfilesToUnfollow
    ) internal virtual {
        vm.prank(vm.addr(pk));
        hub.unfollow(unfollowerProfileId, idsOfProfilesToUnfollow);
    }
}

contract UnfollowMetaTxTest is UnfollowTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function testUnfollowMetaTxTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public override(UnfollowTest, MetaTxNegatives) {
        UnfollowTest.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[nonFollowingProfileOwner] = hub.nonces(nonFollowingProfileOwner);
        cachedNonceByAddress[testUnfollowerProfileOwner] = hub.nonces(testUnfollowerProfileOwner);
    }

    function _unfollow(
        uint256 pk,
        uint256 unfollowerProfileId,
        uint256[] memory idsOfProfilesToUnfollow
    ) internal virtual override {
        address signer = vm.addr(pk);
        uint256 nonce = cachedNonceByAddress[signer];
        hub.unfollowWithSig({
            unfollowerProfileId: unfollowerProfileId,
            idsOfProfilesToUnfollow: idsOfProfilesToUnfollow,
            signature: _getSigStruct({
                pKey: pk,
                digest: _calculateUnfollowWithSigDigest(
                    unfollowerProfileId,
                    idsOfProfilesToUnfollow,
                    nonce,
                    type(uint256).max
                ),
                deadline: type(uint256).max
            })
        });
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        hub.unfollowWithSig({
            unfollowerProfileId: testUnfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId),
            signature: _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _calculateUnfollowWithSigDigest(
                    testUnfollowerProfileId,
                    _toUint256Array(targetProfileId),
                    nonce,
                    deadline
                ),
                deadline: deadline
            })
        });
    }

    function _incrementNonce(uint8 increment) internal override {
        vm.prank(vm.addr(_getDefaultMetaTxSignerPk()));
        hub.incrementNonce(increment);
        cachedNonceByAddress[vm.addr(_getDefaultMetaTxSignerPk())] = hub.nonces(vm.addr(_getDefaultMetaTxSignerPk()));
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return testUnfollowerProfileOwnerPk;
    }

    function _calculateUnfollowWithSigDigest(
        uint256 unfollowerProfileId,
        uint256[] memory idsOfProfilesToUnfollow,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        return
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.UNFOLLOW,
                        unfollowerProfileId,
                        keccak256(abi.encodePacked(idsOfProfilesToUnfollow)),
                        nonce,
                        deadline
                    )
                )
            );
    }
}
