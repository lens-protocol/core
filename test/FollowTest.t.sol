// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/MetaTxNegatives.t.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';
import 'test/mocks/MockFollowModuleWithRevertFlag.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';

contract FollowTest is BaseTest {
    using Strings for uint256;

    uint256 constant MINT_NEW_TOKEN = 0;

    address constant PROFILE_OWNER = address(0);

    // TODO: Replace these with Profile structs everywhere
    uint256 constant targetProfileOwnerPk = 0xC0FFEE;
    address targetProfileOwner;
    uint256 targetProfileId;

    uint256 constant testFollowerProfileOwnerPk = 0x7357;
    address testFollowerProfileOwner;
    uint256 testFollowerProfileId;

    uint256 constant alreadyFollowingProfileOwnerPk = 0xF01108;
    address alreadyFollowingProfileOwner;
    uint256 alreadyFollowingProfileId;

    address targetFollowNFTAddress;

    uint256 followTokenId;

    address followModuleWithRevertFlag;

    function setUp() public virtual override {
        super.setUp();

        targetProfileOwner = vm.addr(targetProfileOwnerPk);
        targetProfileId = _createProfile(targetProfileOwner);

        testFollowerProfileOwner = vm.addr(testFollowerProfileOwnerPk);
        testFollowerProfileId = _createProfile(testFollowerProfileOwner);

        alreadyFollowingProfileOwner = vm.addr(alreadyFollowingProfileOwnerPk);
        alreadyFollowingProfileId = _createProfile(alreadyFollowingProfileOwner);

        vm.prank(alreadyFollowingProfileOwner);
        followTokenId = hub.follow(
            alreadyFollowingProfileId,
            _toUint256Array(targetProfileId),
            _toUint256Array(0),
            _toBytesArray('')
        )[0];

        targetFollowNFTAddress = hub.getProfile(targetProfileId).followNFT;
        followNFT = FollowNFT(targetFollowNFTAddress);

        followModuleWithRevertFlag = address(new MockFollowModuleWithRevertFlag(address(this)));
    }

    // Negatives

    function testCannotFollowIfPaused() public {
        vm.prank(governance);
        hub.setState(Types.ProtocolState.Paused);

        vm.expectRevert(Errors.Paused.selector);

        _follow({
            pk: testFollowerProfileOwnerPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    function testCannotFollowIfBlocked() public {
        vm.prank(targetProfileOwner);
        hub.setBlockStatus(targetProfileId, _toUint256Array(testFollowerProfileId), _toBoolArray(true));

        vm.expectRevert(Errors.Blocked.selector);

        _follow({
            pk: testFollowerProfileOwnerPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    function testCannotFollowIfTransactionExecutorIsNotTheProfileOwnerOrApprovedExecutor(
        uint256 transactionExecutorPk
    ) public {
        transactionExecutorPk = _boundPk(transactionExecutorPk);
        address transactionExecutor = vm.addr(transactionExecutorPk);
        vm.assume(transactionExecutor != address(0));
        vm.assume(transactionExecutor != testFollowerProfileOwner);
        vm.assume(!hub.isDelegatedExecutorApproved(testFollowerProfileId, transactionExecutor));

        vm.expectRevert(Errors.ExecutorInvalid.selector);

        _follow({
            pk: transactionExecutorPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('', '')
        });
    }

    function testCannotFollowWithUnwrappedTokenIfTransactionExecutorIsNotTheProfileOwnerOrApprovedExecutor(
        uint256 transactionExecutorPk
    ) public {
        transactionExecutorPk = _boundPk(transactionExecutorPk);
        address transactionExecutor = vm.addr(transactionExecutorPk);
        vm.assume(transactionExecutor != address(0));
        vm.assume(transactionExecutor != testFollowerProfileOwner);
        vm.assume(!hub.isDelegatedExecutorApproved(testFollowerProfileId, transactionExecutor));

        followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        assertFalse(followNFT.exists(followTokenId));

        vm.expectRevert(Errors.ExecutorInvalid.selector);

        _follow({
            pk: transactionExecutorPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(followTokenId),
            datas: _toBytesArray('', '')
        });
    }

    function testCannotFollowWithWrappedTokenIfTransactionExecutorIsNotTheProfileOwnerOrApprovedExecutor(
        uint256 transactionExecutorPk
    ) public {
        transactionExecutorPk = _boundPk(transactionExecutorPk);
        address transactionExecutor = vm.addr(transactionExecutorPk);
        vm.assume(transactionExecutor != address(0));
        vm.assume(transactionExecutor != testFollowerProfileOwner);
        vm.assume(!hub.isDelegatedExecutorApproved(testFollowerProfileId, transactionExecutor));

        followTokenId = followNFT.getFollowTokenId(alreadyFollowingProfileId);
        vm.prank(alreadyFollowingProfileOwner);
        followNFT.wrap(followTokenId);

        vm.expectRevert(Errors.ExecutorInvalid.selector);

        _follow({
            pk: transactionExecutorPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(followTokenId),
            datas: _toBytesArray('', '')
        });
    }

    function testCannotFollowIfAmountOfTokenIdsPassedDiffersFromAmountOfProfilesToFollow() public {
        vm.expectRevert(Errors.ArrayMismatch.selector);

        _follow({
            pk: testFollowerProfileOwnerPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId, alreadyFollowingProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('', '')
        });
    }

    function testCannotFollowIfAmountOfDataForFollowModulePassedDiffersFromAmountOfProfilesToFollow() public {
        vm.expectRevert(Errors.ArrayMismatch.selector);

        _follow({
            pk: testFollowerProfileOwnerPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('', '')
        });
    }

    function testCannotFollowIfFollowerProfileDoesNotExist() public {
        _effectivelyDisableProfileGuardian(testFollowerProfileOwner);

        vm.prank(testFollowerProfileOwner);
        hub.burn(testFollowerProfileId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _follow({
            pk: testFollowerProfileOwnerPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    function testCannotFollowIfFollowedProfileHaveIdZero() public {
        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _follow({
            pk: testFollowerProfileOwnerPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(0),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    function testCannotFollowIfProfileBeingFollowedDoesNotExist() public {
        _effectivelyDisableProfileGuardian(targetProfileOwner);

        vm.prank(targetProfileOwner);
        hub.burn(targetProfileId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _follow({
            pk: testFollowerProfileOwnerPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    function testCannotFollowIfAlreadyFollowing() public {
        vm.expectRevert(IFollowNFT.AlreadyFollowing.selector);

        _follow({
            pk: alreadyFollowingProfileOwnerPk,
            followerProfileId: alreadyFollowingProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    function testCannotFollowIfFollowModuleRevertsWhileProcessingTheFollow() public {
        vm.prank(targetProfileOwner);
        hub.setFollowModule(targetProfileId, followModuleWithRevertFlag, '');

        bool revertWhileProcessingFollow = true;

        vm.expectRevert(MockFollowModuleWithRevertFlag.MockFollowModuleReverted.selector);

        _follow({
            pk: testFollowerProfileOwnerPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray(abi.encode(revertWhileProcessingFollow))
        });
    }

    function testCannotSelfFollow() public {
        vm.expectRevert(Errors.SelfFollow.selector);

        _follow({
            pk: targetProfileOwnerPk,
            followerProfileId: targetProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    // Positives

    function testFollowAsFollowerOwner() public {
        vm.prank(targetProfileOwner);
        hub.setFollowModule(targetProfileId, followModuleWithRevertFlag, '');

        bytes memory followModuleData = abi.encode(false);

        uint256 expectedFollowTokenIdAssigned = followTokenId + 1;

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Followed(
            testFollowerProfileId,
            targetProfileId,
            expectedFollowTokenIdAssigned,
            followModuleData,
            '',
            testFollowerProfileOwner,
            block.timestamp
        );

        vm.expectCall(
            targetFollowNFTAddress,
            abi.encodeCall(followNFT.follow, (testFollowerProfileId, testFollowerProfileOwner, MINT_NEW_TOKEN)),
            1
        );

        vm.expectCall(
            followModuleWithRevertFlag,
            abi.encodeCall(
                IFollowModule.processFollow,
                (testFollowerProfileId, MINT_NEW_TOKEN, testFollowerProfileOwner, targetProfileId, followModuleData)
            ),
            1
        );

        uint256[] memory assignedFollowTokenIds = _follow({
            pk: testFollowerProfileOwnerPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray(followModuleData)
        });

        assertEq(assignedFollowTokenIds.length, 1);
        assertEq(assignedFollowTokenIds[0], expectedFollowTokenIdAssigned);
        assertTrue(hub.isFollowing(testFollowerProfileId, targetProfileId));
    }

    function testFollowAsFollowerApprovedDelegatedExecutor(uint256 approvedDelegatedExecutorPk) public {
        approvedDelegatedExecutorPk = _boundPk(approvedDelegatedExecutorPk);
        address approvedDelegatedExecutor = vm.addr(approvedDelegatedExecutorPk);
        vm.assume(approvedDelegatedExecutor != address(0));
        vm.assume(approvedDelegatedExecutor != testFollowerProfileOwner);

        vm.prank(testFollowerProfileOwner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: testFollowerProfileId,
            delegatedExecutors: _toAddressArray(approvedDelegatedExecutor),
            approvals: _toBoolArray(true)
        });

        vm.prank(targetProfileOwner);
        hub.setFollowModule(targetProfileId, followModuleWithRevertFlag, '');

        bytes memory followModuleData = abi.encode(false);

        uint256 expectedFollowTokenIdAssigned = followTokenId + 1;

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Followed(
            testFollowerProfileId,
            targetProfileId,
            expectedFollowTokenIdAssigned,
            followModuleData,
            '',
            approvedDelegatedExecutor,
            block.timestamp
        );

        vm.expectCall(
            targetFollowNFTAddress,
            abi.encodeCall(followNFT.follow, (testFollowerProfileId, approvedDelegatedExecutor, MINT_NEW_TOKEN)),
            1
        );

        vm.expectCall(
            followModuleWithRevertFlag,
            abi.encodeCall(
                IFollowModule.processFollow,
                (testFollowerProfileId, MINT_NEW_TOKEN, approvedDelegatedExecutor, targetProfileId, followModuleData)
            ),
            1
        );

        uint256[] memory assignedFollowTokenIds = _follow({
            pk: approvedDelegatedExecutorPk,
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray(followModuleData)
        });

        assertEq(assignedFollowTokenIds.length, 1);
        assertEq(assignedFollowTokenIds[0], expectedFollowTokenIdAssigned);
        assertTrue(hub.isFollowing(testFollowerProfileId, targetProfileId));
    }

    function _follow(
        uint256 pk,
        uint256 followerProfileId,
        uint256[] memory idsOfProfilesToFollow,
        uint256[] memory followTokenIds,
        bytes[] memory datas
    ) internal virtual returns (uint256[] memory) {
        vm.prank(vm.addr(pk));
        return hub.follow(followerProfileId, idsOfProfilesToFollow, followTokenIds, datas);
    }

    function _refreshCachedNonces() internal virtual {
        // Nothing to do there.
    }
}

contract FollowMetaTxTest is FollowTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function testFollowMetaTxTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public override(FollowTest, MetaTxNegatives) {
        FollowTest.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[testFollowerProfileOwner] = hub.nonces(testFollowerProfileOwner);
        cachedNonceByAddress[alreadyFollowingProfileOwner] = hub.nonces(alreadyFollowingProfileOwner);
    }

    function _follow(
        uint256 pk,
        uint256 followerProfileId,
        uint256[] memory idsOfProfilesToFollow,
        uint256[] memory followTokenIds,
        bytes[] memory datas
    ) internal override returns (uint256[] memory) {
        address signer = vm.addr(pk);
        return
            hub.followWithSig({
                followerProfileId: followerProfileId,
                idsOfProfilesToFollow: idsOfProfilesToFollow,
                followTokenIds: followTokenIds,
                datas: datas,
                signature: _getSigStruct({
                    pKey: pk,
                    digest: _calculateFollowWithSigDigest(
                        followerProfileId,
                        idsOfProfilesToFollow,
                        followTokenIds,
                        datas,
                        cachedNonceByAddress[signer],
                        type(uint256).max
                    ),
                    deadline: type(uint256).max
                })
            });
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        hub.followWithSig({
            followerProfileId: testFollowerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray(''),
            signature: _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _calculateFollowWithSigDigest(
                    testFollowerProfileId,
                    _toUint256Array(targetProfileId),
                    _toUint256Array(MINT_NEW_TOKEN),
                    _toBytesArray(''),
                    nonce,
                    deadline
                ),
                deadline: deadline
            })
        });
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return testFollowerProfileOwnerPk;
    }

    function _calculateFollowWithSigDigest(
        uint256 followerProfileId,
        uint256[] memory idsOfProfilesToFollow,
        uint256[] memory followTokenIds,
        bytes[] memory datas,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32[] memory dataHashes = new bytes32[](datas.length);
        for (uint256 i = 0; i < datas.length; ) {
            dataHashes[i] = keccak256(datas[i]);
            unchecked {
                ++i;
            }
        }
        return
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.FOLLOW,
                        followerProfileId,
                        keccak256(abi.encodePacked(idsOfProfilesToFollow)),
                        keccak256(abi.encodePacked(followTokenIds)),
                        keccak256(abi.encodePacked(dataHashes)),
                        nonce,
                        deadline
                    )
                )
            );
    }

    function _incrementNonce(uint8 increment) internal override {
        vm.prank(vm.addr(_getDefaultMetaTxSignerPk()));
        hub.incrementNonce(increment);
        _refreshCachedNonces();
    }

    function _refreshCachedNonces() internal override {
        cachedNonceByAddress[testFollowerProfileOwner] = hub.nonces(testFollowerProfileOwner);
        cachedNonceByAddress[alreadyFollowingProfileOwner] = hub.nonces(alreadyFollowingProfileOwner);
    }
}
