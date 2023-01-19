// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './MetaTxNegatives.t.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import './helpers/AssumptionHelpers.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';
import '../../contracts/mocks/MockFollowModuleWithRevertFlag.sol';

contract FollowTest is BaseTest, AssumptionHelpers {
    using Strings for uint256;

    uint256 constant MINT_NEW_TOKEN = 0;

    address constant PROFILE_OWNER = address(0);

    uint256 constant targetProfileOwnerPk = 0xC0FFEE;
    address targetProfileOwner;
    uint256 targetProfileId;

    uint256 constant followerProfileOwnerPk = 0x7357;
    address followerProfileOwner;
    uint256 followerProfileId;

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

        followerProfileOwner = vm.addr(followerProfileOwnerPk);
        followerProfileId = _createProfile(followerProfileOwner);

        alreadyFollowingProfileOwner = vm.addr(alreadyFollowingProfileOwnerPk);
        alreadyFollowingProfileId = _createProfile(alreadyFollowingProfileOwner);

        followTokenId = _follow(
            alreadyFollowingProfileOwner,
            alreadyFollowingProfileId,
            targetProfileId,
            0,
            ''
        )[0];

        targetFollowNFTAddress = hub.getFollowNFT(targetProfileId);
        followNFT = FollowNFT(targetFollowNFTAddress);

        followModuleWithRevertFlag = address(new MockFollowModuleWithRevertFlag());
        vm.prank(governance);
        hub.whitelistFollowModule(followModuleWithRevertFlag, true);
    }

    // Negatives

    function testCannotFollowIfPaused() public {
        vm.prank(governance);
        hub.setState(DataTypes.ProtocolState.Paused);

        vm.expectRevert(Errors.Paused.selector);

        _follow({
            pk: followerProfileOwnerPk,
            isFollowerProfileOwner: true,
            followerProfileId: followerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    function testCannotFollowIfBlocked() public {
        vm.prank(targetProfileOwner);
        hub.setBlockStatus(targetProfileId, _toUint256Array(followerProfileId), _toBoolArray(true));

        vm.expectRevert(Errors.Blocked.selector);

        _follow({
            pk: followerProfileOwnerPk,
            isFollowerProfileOwner: true,
            followerProfileId: followerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    function testCannotFollowIfExecutorIsNotTheProfileOwnerOrHisApprovedExecutor(uint256 executorPk)
        public
    {
        vm.assume(_isValidPk(executorPk));
        address executor = vm.addr(executorPk);
        vm.assume(executor != address(0));
        vm.assume(executor != followerProfileOwner);
        vm.assume(!hub.isDelegatedExecutorApproved(followerProfileOwner, executor));

        vm.expectRevert(Errors.ExecutorInvalid.selector);

        _follow({
            pk: executorPk,
            isFollowerProfileOwner: false,
            followerProfileId: followerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('', '')
        });
    }

    function testCannotFollowIfAmountOfTokenIdsPassedDiffersFromAmountOfProfilesToFollow() public {
        vm.expectRevert(Errors.ArrayMismatch.selector);

        _follow({
            pk: followerProfileOwnerPk,
            isFollowerProfileOwner: true,
            followerProfileId: followerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId, alreadyFollowingProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('', '')
        });
    }

    function testCannotFollowIfAmountOfDataForFollowModulePassedDiffersFromAmountOfProfilesToFollow()
        public
    {
        vm.expectRevert(Errors.ArrayMismatch.selector);

        _follow({
            pk: followerProfileOwnerPk,
            isFollowerProfileOwner: true,
            followerProfileId: followerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('', '')
        });
    }

    function testCannotFollowIfFollowerProfileDoesNotExist() public {
        vm.prank(followerProfileOwner);
        hub.burn(followerProfileId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _follow({
            pk: followerProfileOwnerPk,
            isFollowerProfileOwner: true,
            followerProfileId: followerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    function testCannotFollowIfFollowedProfileHaveIdZero() public {
        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _follow({
            pk: followerProfileOwnerPk,
            isFollowerProfileOwner: true,
            followerProfileId: followerProfileId,
            idsOfProfilesToFollow: _toUint256Array(0),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    function testCannotFollowIfProfileBeingFollowedDoesNotExist() public {
        vm.prank(targetProfileOwner);
        hub.burn(targetProfileId);

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _follow({
            pk: followerProfileOwnerPk,
            isFollowerProfileOwner: true,
            followerProfileId: followerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray('')
        });
    }

    function testCannotFollowIfAlreadyFollowing() public {
        vm.expectRevert(IFollowNFT.AlreadyFollowing.selector);

        _follow({
            pk: alreadyFollowingProfileOwnerPk,
            isFollowerProfileOwner: true,
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
            pk: followerProfileOwnerPk,
            isFollowerProfileOwner: true,
            followerProfileId: followerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray(abi.encode(revertWhileProcessingFollow))
        });
    }

    function testCannotSelfFollow() public {
        vm.expectRevert(Errors.SelfFollow.selector);

        _follow({
            pk: targetProfileOwnerPk,
            isFollowerProfileOwner: true,
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
            followerProfileId,
            targetProfileId,
            expectedFollowTokenIdAssigned,
            followModuleData,
            block.timestamp
        );

        vm.expectCall(
            targetFollowNFTAddress,
            abi.encodeCall(
                followNFT.follow,
                (followerProfileId, followerProfileOwner, followerProfileOwner, MINT_NEW_TOKEN)
            )
        );

        vm.expectCall(
            followModuleWithRevertFlag,
            abi.encodeCall(
                IFollowModule.processFollow,
                (
                    followerProfileId,
                    MINT_NEW_TOKEN,
                    followerProfileOwner,
                    targetProfileId,
                    followModuleData
                )
            )
        );

        uint256[] memory assignedFollowTokenIds = _follow({
            pk: followerProfileOwnerPk,
            isFollowerProfileOwner: true,
            followerProfileId: followerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray(followModuleData)
        });

        assertEq(assignedFollowTokenIds.length, 1);
        assertEq(assignedFollowTokenIds[0], expectedFollowTokenIdAssigned);
        assertTrue(hub.isFollowing(followerProfileId, targetProfileId));
    }

    function testFollowAsFollowerApprovedDelegatedExecutor(uint256 approvedDelegatedExecutorPk)
        public
    {
        vm.assume(_isValidPk(approvedDelegatedExecutorPk));
        address approvedDelegatedExecutor = vm.addr(approvedDelegatedExecutorPk);
        vm.assume(approvedDelegatedExecutor != address(0));
        vm.assume(approvedDelegatedExecutor != followerProfileOwner);

        vm.prank(followerProfileOwner);
        hub.setDelegatedExecutorApproval(approvedDelegatedExecutor, true);

        vm.prank(targetProfileOwner);
        hub.setFollowModule(targetProfileId, followModuleWithRevertFlag, '');

        bytes memory followModuleData = abi.encode(false);

        uint256 expectedFollowTokenIdAssigned = followTokenId + 1;

        vm.expectEmit(true, false, false, true, address(hub));
        emit Events.Followed(
            followerProfileId,
            targetProfileId,
            expectedFollowTokenIdAssigned,
            followModuleData,
            block.timestamp
        );

        vm.expectCall(
            targetFollowNFTAddress,
            abi.encodeCall(
                followNFT.follow,
                (followerProfileId, approvedDelegatedExecutor, followerProfileOwner, MINT_NEW_TOKEN)
            )
        );

        vm.expectCall(
            followModuleWithRevertFlag,
            abi.encodeCall(
                IFollowModule.processFollow,
                (
                    followerProfileId,
                    MINT_NEW_TOKEN,
                    approvedDelegatedExecutor,
                    targetProfileId,
                    followModuleData
                )
            )
        );

        uint256[] memory assignedFollowTokenIds = _follow({
            pk: approvedDelegatedExecutorPk,
            isFollowerProfileOwner: false,
            followerProfileId: followerProfileId,
            idsOfProfilesToFollow: _toUint256Array(targetProfileId),
            followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
            datas: _toBytesArray(followModuleData)
        });

        assertEq(assignedFollowTokenIds.length, 1);
        assertEq(assignedFollowTokenIds[0], expectedFollowTokenIdAssigned);
        assertTrue(hub.isFollowing(followerProfileId, targetProfileId));
    }

    function _follow(
        uint256 pk,
        bool isFollowerProfileOwner,
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

    function setUp() public override(FollowTest, MetaTxNegatives) {
        FollowTest.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[followerProfileOwner] = _getSigNonce(followerProfileOwner);
        cachedNonceByAddress[alreadyFollowingProfileOwner] = _getSigNonce(
            alreadyFollowingProfileOwner
        );
    }

    function _follow(
        uint256 pk,
        bool isFollowerProfileOwner,
        uint256 followerProfileId,
        uint256[] memory idsOfProfilesToFollow,
        uint256[] memory followTokenIds,
        bytes[] memory datas
    ) internal override returns (uint256[] memory) {
        address signer = vm.addr(pk);
        return
            hub.followWithSig(
                _getSignedData({
                    signerPk: pk,
                    delegatedSigner: isFollowerProfileOwner ? PROFILE_OWNER : signer,
                    followerProfileId: followerProfileId,
                    idsOfProfilesToFollow: idsOfProfilesToFollow,
                    followTokenIds: followTokenIds,
                    datas: datas,
                    nonce: cachedNonceByAddress[signer],
                    deadline: type(uint256).max
                })
            );
    }

    function _executeMetaTx(
        uint256 signerPk,
        uint256 nonce,
        uint256 deadline
    ) internal virtual override {
        hub.followWithSig(
            _getSignedData({
                signerPk: signerPk,
                delegatedSigner: PROFILE_OWNER,
                followerProfileId: followerProfileId,
                idsOfProfilesToFollow: _toUint256Array(targetProfileId),
                followTokenIds: _toUint256Array(MINT_NEW_TOKEN),
                datas: _toBytesArray(''),
                nonce: nonce,
                deadline: deadline
            })
        );
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return followerProfileOwnerPk;
    }

    function _calculateFollowWithSigDigest(
        uint256 followerProfileId,
        uint256[] memory idsOfProfilesToFollow,
        uint256[] memory followTokenIds,
        bytes[] memory datas,
        uint256 nonce,
        uint256 deadline
    ) internal returns (bytes32) {
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
                        FOLLOW_WITH_SIG_TYPEHASH,
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

    function _getSignedData(
        uint256 signerPk,
        address delegatedSigner,
        uint256 followerProfileId,
        uint256[] memory idsOfProfilesToFollow,
        uint256[] memory followTokenIds,
        bytes[] memory datas,
        uint256 nonce,
        uint256 deadline
    ) internal returns (DataTypes.FollowWithSigData memory) {
        return
            DataTypes.FollowWithSigData({
                delegatedSigner: delegatedSigner,
                followerProfileId: followerProfileId,
                idsOfProfilesToFollow: idsOfProfilesToFollow,
                followTokenIds: followTokenIds,
                datas: datas,
                sig: _getSigStruct({
                    pKey: signerPk,
                    digest: _calculateFollowWithSigDigest(
                        followerProfileId,
                        idsOfProfilesToFollow,
                        followTokenIds,
                        datas,
                        nonce,
                        deadline
                    ),
                    deadline: deadline
                })
            });
    }

    function _refreshCachedNonces() internal override {
        cachedNonceByAddress[followerProfileOwner] = _getSigNonce(followerProfileOwner);
        cachedNonceByAddress[alreadyFollowingProfileOwner] = _getSigNonce(
            alreadyFollowingProfileOwner
        );
    }
}
