// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './MetaTxNegatives.t.sol';
import './helpers/AssumptionHelpers.sol';

contract SetBlockStatusTest is BaseTest, AssumptionHelpers {
    address constant PROFILE_OWNER = address(0);

    uint256 constant statusSetterProfileOwnerPk = 0x7357;
    address statusSetterProfileOwner;
    uint256 statusSetterProfileId;

    uint256 constant blockeeProfileOwnerPk = 0xF01108;
    address blockeeProfileOwner;
    uint256 blockeeProfileId;

    uint256 constant anotherBlockeeProfileOwnerPk = 0xF01109;
    address anotherBlockeeProfileOwner;
    uint256 anotherBlockeeProfileId;

    address followNFTAddress;

    function setUp() public virtual override {
        super.setUp();

        statusSetterProfileOwner = vm.addr(statusSetterProfileOwnerPk);
        statusSetterProfileId = _createProfile(statusSetterProfileOwner);

        blockeeProfileOwner = vm.addr(blockeeProfileOwnerPk);
        blockeeProfileId = _createProfile(blockeeProfileOwner);

        anotherBlockeeProfileOwner = vm.addr(anotherBlockeeProfileOwnerPk);
        anotherBlockeeProfileId = _createProfile(anotherBlockeeProfileOwner);

        _follow(blockeeProfileOwner, blockeeProfileId, statusSetterProfileId, 0, '');

        followNFTAddress = hub.getFollowNFT(statusSetterProfileId);
        followNFT = FollowNFT(followNFTAddress);
    }

    //////////////////////////////////////////////////////////
    // Set block status - Negatives
    //////////////////////////////////////////////////////////
    function testCannotSetBlockStatusIfPaused() public {
        vm.prank(governance);
        hub.setState(DataTypes.ProtocolState.Paused);

        vm.expectRevert(Errors.Paused.selector);

        _setBlockStatus({
            pk: statusSetterProfileOwnerPk,
            isStatusSetterProfileOwner: true,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(blockeeProfileId),
            blockStatus: _toBoolArray(true)
        });
    }

    function testCannotSetBlockStatusIfSetterProfileDoesNotExist() public virtual {
        vm.prank(statusSetterProfileOwner);
        hub.burn(statusSetterProfileId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _setBlockStatus({
            pk: statusSetterProfileOwnerPk,
            isStatusSetterProfileOwner: true,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(blockeeProfileId),
            blockStatus: _toBoolArray(true)
        });
    }

    function testCannotSetBlockStatusIfNotOwnerOrApprovedDelegatedExecutorOfSetterProfile(
        uint256 nonOwnerNorDelegatedExecutorPk
    ) public virtual {
        vm.assume(_isValidPk(nonOwnerNorDelegatedExecutorPk));
        address nonOwnerNorDelegatedExecutor = vm.addr(nonOwnerNorDelegatedExecutorPk);
        vm.assume(nonOwnerNorDelegatedExecutor != address(0));
        vm.assume(nonOwnerNorDelegatedExecutor != statusSetterProfileOwner);
        vm.assume(
            !hub.isDelegatedExecutorApproved(statusSetterProfileOwner, nonOwnerNorDelegatedExecutor)
        );

        vm.expectRevert(Errors.ExecutorInvalid.selector);

        _setBlockStatus({
            pk: nonOwnerNorDelegatedExecutorPk,
            isStatusSetterProfileOwner: true,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(blockeeProfileId),
            blockStatus: _toBoolArray(true)
        });

        vm.expectRevert(Errors.ExecutorInvalid.selector);

        _setBlockStatus({
            pk: nonOwnerNorDelegatedExecutorPk,
            isStatusSetterProfileOwner: false,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(blockeeProfileId),
            blockStatus: _toBoolArray(true)
        });
    }

    function testCannotSetBlockStatusIfProfilesAndStatusArrayLengthMismatches() public virtual {
        vm.expectRevert(Errors.ArrayMismatch.selector);

        _setBlockStatus({
            pk: statusSetterProfileOwnerPk,
            isStatusSetterProfileOwner: true,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(
                blockeeProfileId,
                anotherBlockeeProfileId
            ),
            blockStatus: _toBoolArray(true)
        });
    }

    function testCannotSetBlockStatusIfBlockeeProfileDoesNotExist() public virtual {
        vm.prank(blockeeProfileOwner);
        hub.burn(blockeeProfileId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _setBlockStatus({
            pk: statusSetterProfileOwnerPk,
            isStatusSetterProfileOwner: true,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(blockeeProfileId),
            blockStatus: _toBoolArray(true)
        });
    }

    function testCannotBlockItself() public virtual {
        vm.expectRevert(Errors.SelfBlock.selector);

        _setBlockStatus({
            pk: statusSetterProfileOwnerPk,
            isStatusSetterProfileOwner: true,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(statusSetterProfileId),
            blockStatus: _toBoolArray(true)
        });
    }

    //////////////////////////////////////////////////////////
    // Set block status - Scenarios
    //////////////////////////////////////////////////////////
    function testSetBlockStatusEmitExpectedEventsAndSetExpectedStatus() public {
        assertFalse(hub.isBlocked(blockeeProfileId, statusSetterProfileId));
        assertFalse(hub.isBlocked(anotherBlockeeProfileId, statusSetterProfileId));

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Blocked(statusSetterProfileId, blockeeProfileId, block.timestamp);

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Blocked(statusSetterProfileId, anotherBlockeeProfileId, block.timestamp);

        vm.expectCall(followNFTAddress, abi.encodeCall(followNFT.processBlock, (blockeeProfileId)));
        vm.expectCall(
            followNFTAddress,
            abi.encodeCall(followNFT.processBlock, (anotherBlockeeProfileId))
        );

        _setBlockStatus({
            pk: statusSetterProfileOwnerPk,
            isStatusSetterProfileOwner: true,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(
                blockeeProfileId,
                anotherBlockeeProfileId
            ),
            blockStatus: _toBoolArray(true, true)
        });

        assertTrue(hub.isBlocked(blockeeProfileId, statusSetterProfileId));
        assertTrue(hub.isBlocked(anotherBlockeeProfileId, statusSetterProfileId));

        _refreshCachedNonces();

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Blocked(statusSetterProfileId, blockeeProfileId, block.timestamp);

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Unblocked(statusSetterProfileId, anotherBlockeeProfileId, block.timestamp);

        vm.expectCall(followNFTAddress, abi.encodeCall(followNFT.processBlock, (blockeeProfileId)));

        _setBlockStatus({
            pk: statusSetterProfileOwnerPk,
            isStatusSetterProfileOwner: true,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(
                blockeeProfileId,
                anotherBlockeeProfileId
            ),
            blockStatus: _toBoolArray(true, false)
        });

        assertTrue(hub.isBlocked(blockeeProfileId, statusSetterProfileId));
        assertFalse(hub.isBlocked(anotherBlockeeProfileId, statusSetterProfileId));
    }

    function testSetBlockStatusAsBlockedForFollowerMakesHimUnfollowFirst() public {
        assertTrue(hub.isFollowing(blockeeProfileId, statusSetterProfileId));

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Unfollowed(blockeeProfileId, statusSetterProfileId, block.timestamp);

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Blocked(statusSetterProfileId, blockeeProfileId, block.timestamp);

        vm.expectCall(followNFTAddress, abi.encodeCall(followNFT.processBlock, (blockeeProfileId)));

        _setBlockStatus({
            pk: statusSetterProfileOwnerPk,
            isStatusSetterProfileOwner: true,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(blockeeProfileId),
            blockStatus: _toBoolArray(true)
        });

        assertTrue(hub.isBlocked(blockeeProfileId, statusSetterProfileId));
        assertFalse(hub.isFollowing(blockeeProfileId, statusSetterProfileId));
    }

    function testSetBlockStatusAsBlockedDoesNotCallFollowNFTIfNotDeployed() public {
        // Creates a fresh profile so it doesn't have a Follow NFT collection deployed yet.
        statusSetterProfileId = _createProfile(statusSetterProfileOwner);

        // As the Follow NFT has not been deployed yet, the address is zero, so if a `followNFT.processBlock(...)` call
        // is performed to it, this test must revert.
        assertEq(hub.getFollowNFT(statusSetterProfileId), address(0));

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Blocked(statusSetterProfileId, blockeeProfileId, block.timestamp);

        _setBlockStatus({
            pk: statusSetterProfileOwnerPk,
            isStatusSetterProfileOwner: true,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(blockeeProfileId),
            blockStatus: _toBoolArray(true)
        });

        assertTrue(hub.isBlocked(blockeeProfileId, statusSetterProfileId));
    }

    function _refreshCachedNonces() internal virtual {
        // Nothing to do there.
    }

    function _setBlockStatus(
        uint256 pk,
        bool isStatusSetterProfileOwner,
        uint256 byProfileId,
        uint256[] memory idsOfProfilesToSetBlockStatus,
        bool[] memory blockStatus
    ) internal virtual {
        vm.prank(vm.addr(pk));
        hub.setBlockStatus(byProfileId, idsOfProfilesToSetBlockStatus, blockStatus);
    }
}

contract SetBlockStatusMetaTxTest is SetBlockStatusTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function setUp() public override(SetBlockStatusTest, MetaTxNegatives) {
        SetBlockStatusTest.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[statusSetterProfileOwner] = _getSigNonce(statusSetterProfileOwner);
    }

    function _refreshCachedNonces() internal override {
        cachedNonceByAddress[statusSetterProfileOwner] = _getSigNonce(statusSetterProfileOwner);
    }

    function _setBlockStatus(
        uint256 pk,
        bool isStatusSetterProfileOwner,
        uint256 byProfileId,
        uint256[] memory idsOfProfilesToSetBlockStatus,
        bool[] memory blockStatus
    ) internal override {
        address signer = vm.addr(pk);
        hub.setBlockStatusWithSig(
            _getSignedData({
                signerPk: pk,
                delegatedSigner: isStatusSetterProfileOwner ? PROFILE_OWNER : signer,
                byProfileId: byProfileId,
                idsOfProfilesToSetBlockStatus: idsOfProfilesToSetBlockStatus,
                blockStatus: blockStatus,
                nonce: cachedNonceByAddress[signer],
                deadline: type(uint256).max
            })
        );
    }

    function _executeMetaTx(
        uint256 signerPk,
        uint256 nonce,
        uint256 deadline
    ) internal override {
        hub.setBlockStatusWithSig(
            _getSignedData({
                signerPk: signerPk,
                delegatedSigner: PROFILE_OWNER,
                byProfileId: statusSetterProfileId,
                idsOfProfilesToSetBlockStatus: _toUint256Array(blockeeProfileId),
                blockStatus: _toBoolArray(true),
                nonce: nonce,
                deadline: deadline
            })
        );
    }

    function _getDefaultMetaTxSignerPk() internal override returns (uint256) {
        return blockeeProfileOwnerPk;
    }

    function _calculateSetBlockStatusWithSigDigest(
        uint256 byProfileId,
        uint256[] memory idsOfProfilesToSetBlockStatus,
        bool[] memory blockStatus,
        uint256 nonce,
        uint256 deadline
    ) internal returns (bytes32) {
        return
            _calculateDigest(
                keccak256(
                    abi.encode(
                        SET_BLOCK_STATUS_WITH_SIG_TYPEHASH,
                        byProfileId,
                        keccak256(abi.encodePacked(idsOfProfilesToSetBlockStatus)),
                        keccak256(abi.encodePacked(blockStatus)),
                        nonce,
                        deadline
                    )
                )
            );
    }

    function _getSignedData(
        uint256 signerPk,
        address delegatedSigner,
        uint256 byProfileId,
        uint256[] memory idsOfProfilesToSetBlockStatus,
        bool[] memory blockStatus,
        uint256 nonce,
        uint256 deadline
    ) internal returns (DataTypes.SetBlockStatusWithSigData memory) {
        return
            DataTypes.SetBlockStatusWithSigData({
                delegatedSigner: delegatedSigner,
                byProfileId: byProfileId,
                idsOfProfilesToSetBlockStatus: idsOfProfilesToSetBlockStatus,
                blockStatus: blockStatus,
                sig: _getSigStruct({
                    pKey: signerPk,
                    digest: _calculateSetBlockStatusWithSigDigest(
                        byProfileId,
                        idsOfProfilesToSetBlockStatus,
                        blockStatus,
                        nonce,
                        deadline
                    ),
                    deadline: deadline
                })
            });
    }

    function testCannotSetBlockStatusIfNotOwnerOrApprovedDelegatedExecutorOfSetterProfile(
        uint256 nonOwnerNorDelegatedExecutorPk
    ) public override {
        vm.assume(_isValidPk(nonOwnerNorDelegatedExecutorPk));
        address nonOwnerNorDelegatedExecutor = vm.addr(nonOwnerNorDelegatedExecutorPk);
        vm.assume(nonOwnerNorDelegatedExecutor != address(0));
        vm.assume(nonOwnerNorDelegatedExecutor != statusSetterProfileOwner);
        vm.assume(
            !hub.isDelegatedExecutorApproved(statusSetterProfileOwner, nonOwnerNorDelegatedExecutor)
        );

        vm.expectRevert(Errors.SignatureInvalid.selector);

        _setBlockStatus({
            pk: nonOwnerNorDelegatedExecutorPk,
            isStatusSetterProfileOwner: true,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(blockeeProfileId),
            blockStatus: _toBoolArray(true)
        });

        vm.expectRevert(Errors.ExecutorInvalid.selector);

        _setBlockStatus({
            pk: nonOwnerNorDelegatedExecutorPk,
            isStatusSetterProfileOwner: false,
            byProfileId: statusSetterProfileId,
            idsOfProfilesToSetBlockStatus: _toUint256Array(blockeeProfileId),
            blockStatus: _toBoolArray(true)
        });
    }
}
