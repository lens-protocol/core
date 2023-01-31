// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './MetaTxNegatives.t.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';

contract UnfollowTest is BaseTest {
    uint256 constant MINT_NEW_TOKEN = 0;
    address constant PROFILE_OWNER = address(0);
    address targetProfileOwner = address(0xC0FFEE);
    uint256 targetProfileId;
    uint256 constant nonFollowingProfileOwnerPk = 0x7357;
    address nonFollowingProfileOwner;
    uint256 nonFollowingProfileId;
    uint256 constant unfollowerProfileOwnerPk = 0xF01108;
    address unfollowerProfileOwner;
    uint256 unfollowerProfileId;
    address targetFollowNFT;
    uint256 followTokenId;

    function setUp() public virtual override {
        super.setUp();

        targetProfileId = _createProfile(targetProfileOwner);
        nonFollowingProfileOwner = vm.addr(nonFollowingProfileOwnerPk);
        nonFollowingProfileId = _createProfile(nonFollowingProfileOwner);
        unfollowerProfileOwnerPk;
        unfollowerProfileOwner = vm.addr(unfollowerProfileOwnerPk);
        unfollowerProfileId = _createProfile(unfollowerProfileOwner);
        followTokenId = _follow(
            unfollowerProfileOwner,
            unfollowerProfileId,
            targetProfileId,
            0,
            ''
        )[0];

        targetFollowNFT = hub.getFollowNFT(targetProfileId);
        followNFT = FollowNFT(targetFollowNFT);
    }

    //////////////////////////////////////////////////////////
    // Unfollow - Negatives
    //////////////////////////////////////////////////////////

    function testCannotUnfollowIfPaused() public {
        vm.prank(governance);
        hub.setState(DataTypes.ProtocolState.Paused);

        vm.expectRevert(Errors.Paused.selector);

        _unfollow({
            pk: unfollowerProfileOwnerPk,
            isUnfollowerProfileOwner: true,
            unfollowerProfileId: unfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });
    }

    function testCannotUnfollowIfUnfollowerProfileDoesNotExist() public {
        vm.prank(unfollowerProfileOwner);
        hub.burn(unfollowerProfileId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _unfollow({
            pk: unfollowerProfileOwnerPk,
            isUnfollowerProfileOwner: true,
            unfollowerProfileId: unfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });
    }

    function testCannotUnfollowIfSomeOfTheProfilesToUnfollowDoNotExist(uint256 unexistentProfileId)
        public
    {
        vm.assume(!hub.exists(unexistentProfileId));

        assertTrue(hub.isFollowing(unfollowerProfileId, targetProfileId));

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _unfollow({
            pk: unfollowerProfileOwnerPk,
            isUnfollowerProfileOwner: true,
            unfollowerProfileId: unfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId, unexistentProfileId)
        });

        // Asserts that the unfollow operation has been completely reverted after one of the unfollow's failed.
        assertTrue(hub.isFollowing(unfollowerProfileId, targetProfileId));
    }

    function testCannotUnfollowIfTheProfileHasNeverBeenFollowedBefore() public {
        uint256 hasNeverBeenFollowedProfileId = _createProfile(targetProfileOwner);

        vm.expectRevert(Errors.NotFollowing.selector);

        _unfollow({
            pk: unfollowerProfileOwnerPk,
            isUnfollowerProfileOwner: true,
            unfollowerProfileId: unfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(hasNeverBeenFollowedProfileId)
        });
    }

    function testCannotUnfollowIfNotFollowingTheTargetProfile() public {
        vm.expectRevert(Errors.NotFollowing.selector);

        _unfollow({
            pk: nonFollowingProfileOwnerPk,
            isUnfollowerProfileOwner: true,
            unfollowerProfileId: nonFollowingProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });
    }

    function testCannotUnfollowIfNotProfileOwnerOrDelegatedExecutor(uint256 executorPk) public {
        executorPk = bound(
            executorPk,
            1,
            115792089237316195423570985008687907852837564279074904382605163141518161494337 - 1
        );
        address executor = vm.addr(executorPk);
        vm.assume(executor != unfollowerProfileOwner);
        vm.assume(!hub.isDelegatedExecutorApproved(unfollowerProfileOwner, executor));
        vm.assume(!followNFT.isApprovedForAll(unfollowerProfileOwner, executor));

        uint256 followTokenId = followNFT.getFollowTokenId(unfollowerProfileId);
        vm.prank(unfollowerProfileOwner);
        followNFT.wrap(followTokenId);

        vm.expectRevert(Errors.ExecutorInvalid.selector);

        _unfollow({
            pk: executorPk,
            isUnfollowerProfileOwner: false,
            unfollowerProfileId: unfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });
    }

    //////////////////////////////////////////////////////////
    // Unfollow - Scenarios
    //////////////////////////////////////////////////////////

    function testUnfollowAsUnfollowerOwner() public {
        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Unfollowed(unfollowerProfileId, targetProfileId, block.timestamp);

        vm.expectCall(
            targetFollowNFT,
            abi.encodeCall(followNFT.unfollow, (unfollowerProfileId, unfollowerProfileOwner))
        );

        _unfollow({
            pk: unfollowerProfileOwnerPk,
            isUnfollowerProfileOwner: true,
            unfollowerProfileId: unfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });

        assertFalse(hub.isFollowing(unfollowerProfileId, targetProfileId));
    }

    function testUnfollowAsUnfollowerApprovedDelegatedExecutor(uint256 approvedDelegatedExecutorPk)
        public
    {
        approvedDelegatedExecutorPk = bound(
            approvedDelegatedExecutorPk,
            1,
            ISSECP256K1_CURVE_ORDER - 1
        );
        address approvedDelegatedExecutor = vm.addr(approvedDelegatedExecutorPk);
        vm.assume(approvedDelegatedExecutor != address(0));
        vm.assume(approvedDelegatedExecutor != unfollowerProfileOwner);

        vm.prank(unfollowerProfileOwner);
        hub.setDelegatedExecutorApproval(approvedDelegatedExecutor, true);

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Unfollowed(unfollowerProfileId, targetProfileId, block.timestamp);

        vm.expectCall(
            targetFollowNFT,
            abi.encodeCall(followNFT.unfollow, (unfollowerProfileId, approvedDelegatedExecutor))
        );

        _unfollow({
            pk: approvedDelegatedExecutorPk,
            isUnfollowerProfileOwner: false,
            unfollowerProfileId: unfollowerProfileId,
            idsOfProfilesToUnfollow: _toUint256Array(targetProfileId)
        });

        assertFalse(hub.isFollowing(unfollowerProfileId, targetProfileId));
    }

    function _unfollow(
        uint256 pk,
        bool isUnfollowerProfileOwner,
        uint256 unfollowerProfileId,
        uint256[] memory idsOfProfilesToUnfollow
    ) internal virtual {
        vm.prank(vm.addr(pk));
        hub.unfollow(unfollowerProfileId, idsOfProfilesToUnfollow);
    }
}

contract UnfollowMetaTxTest is UnfollowTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function setUp() public override(UnfollowTest, MetaTxNegatives) {
        UnfollowTest.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[nonFollowingProfileOwner] = _getSigNonce(nonFollowingProfileOwner);
        cachedNonceByAddress[unfollowerProfileOwner] = _getSigNonce(unfollowerProfileOwner);
    }

    function _unfollow(
        uint256 pk,
        bool isUnfollowerProfileOwner,
        uint256 unfollowerProfileId,
        uint256[] memory idsOfProfilesToUnfollow
    ) internal virtual override {
        address signer = vm.addr(pk);
        uint256 nonce = cachedNonceByAddress[signer];
        hub.unfollowWithSig(
            _getSignedData({
                signerPk: pk,
                delegatedSigner: isUnfollowerProfileOwner ? PROFILE_OWNER : signer,
                unfollowerProfileId: unfollowerProfileId,
                idsOfProfilesToUnfollow: idsOfProfilesToUnfollow,
                nonce: nonce,
                deadline: type(uint256).max
            })
        );
    }

    function _executeMetaTx(
        uint256 signerPk,
        uint256 nonce,
        uint256 deadline
    ) internal virtual override {
        hub.unfollowWithSig(
            _getSignedData({
                signerPk: signerPk,
                delegatedSigner: PROFILE_OWNER,
                unfollowerProfileId: unfollowerProfileId,
                idsOfProfilesToUnfollow: _toUint256Array(targetProfileId),
                nonce: nonce,
                deadline: deadline
            })
        );
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return unfollowerProfileOwnerPk;
    }

    function _calculateUnfollowWithSigDigest(
        uint256 unfollowerProfileId,
        uint256[] memory idsOfProfilesToUnfollow,
        uint256 nonce,
        uint256 deadline
    ) internal returns (bytes32) {
        return
            _calculateDigest(
                keccak256(
                    abi.encode(
                        UNFOLLOW_WITH_SIG_TYPEHASH,
                        unfollowerProfileId,
                        keccak256(abi.encodePacked(idsOfProfilesToUnfollow)),
                        nonce,
                        deadline
                    )
                )
            );
    }

    function _getSignedData(
        uint256 signerPk,
        address delegatedSigner,
        uint256 unfollowerProfileId,
        uint256[] memory idsOfProfilesToUnfollow,
        uint256 nonce,
        uint256 deadline
    ) internal returns (DataTypes.UnfollowWithSigData memory) {
        return
            DataTypes.UnfollowWithSigData({
                delegatedSigner: delegatedSigner,
                unfollowerProfileId: unfollowerProfileId,
                idsOfProfilesToUnfollow: idsOfProfilesToUnfollow,
                sig: _getSigStruct({
                    pKey: signerPk,
                    digest: _calculateUnfollowWithSigDigest(
                        unfollowerProfileId,
                        idsOfProfilesToUnfollow,
                        nonce,
                        deadline
                    ),
                    deadline: deadline
                })
            });
    }
}
