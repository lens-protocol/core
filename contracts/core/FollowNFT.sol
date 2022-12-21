// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import '../libraries/Constants.sol';
import {DataTypes} from '../libraries/DataTypes.sol';
import {ERC2981CollectionRoyalties} from './base/ERC2981CollectionRoyalties.sol';
import {ERC721Enumerable} from './base/ERC721Enumerable.sol';
import {ERC721Time} from './base/ERC721Time.sol';
import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';
import {HubRestricted} from './base/HubRestricted.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {IFollowNFT} from '../interfaces/IFollowNFT.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';
import {LensNFTBase} from './base/LensNFTBase.sol';
import {MetaTxHelpers} from '../libraries/helpers/MetaTxHelpers.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

struct Snapshot {
    uint128 blockNumber;
    uint128 value;
}

contract FollowNFT is HubRestricted, LensNFTBase, ERC2981CollectionRoyalties, IFollowNFT {
    using Strings for uint256;

    bytes32 internal constant DELEGATE_BY_SIG_TYPEHASH =
        keccak256(
            'DelegateBySig(uint256 delegatorProfileId,address delegatee,uint256 nonce,uint256 deadline)'
        );

    mapping(address => mapping(uint256 => Snapshot)) internal _snapshots;
    // TODO: Check that nobody has used this feature before doing this mapping modifiation, otherwise use new slot.
    mapping(uint256 => address) internal _delegates;
    mapping(address => uint256) internal _snapshotCount;
    mapping(uint256 => Snapshot) internal _delSupplySnapshots;
    uint256 internal _delSupplySnapshotCount;
    uint256 internal _followedProfileId;
    uint128 internal _lastFollowTokenId;
    uint128 internal _followers;

    bool private _initialized;

    mapping(uint256 => FollowData) internal _followDataByFollowTokenId;
    mapping(uint256 => uint256) internal _followTokenIdByFollowerProfileId;
    mapping(uint256 => uint256) internal _followApprovalByFollowTokenId;
    uint256 internal _royaltiesInBasisPoints;

    event FollowApproval(uint256 indexed followerProfileId, uint256 indexed followTokenId);

    constructor(address hub) HubRestricted(hub) {
        _initialized = true;
    }

    /// @inheritdoc IFollowNFT
    function initialize(uint256 profileId) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        _followedProfileId = profileId;
        _setRoyalty(1000); // 10% of royalties
        emit Events.FollowNFTInitialized(profileId, block.timestamp);
    }

    /// @inheritdoc IFollowNFT
    function follow(
        uint256 followerProfileId,
        address executor,
        address followerProfileOwner,
        bool isExecutorApproved,
        uint256 followTokenId
    ) external override onlyHub returns (uint256) {
        if (_followTokenIdByFollowerProfileId[followerProfileId] != 0) {
            revert AlreadyFollowing();
        }
        uint256 followTokenIdAssigned = followTokenId;
        address followTokenOwner;
        uint256 currentFollowerProfileId;
        if (followTokenId == 0) {
            followTokenIdAssigned = _followMintingNewToken(
                followerProfileId,
                executor,
                isExecutorApproved,
                0,
                followerProfileOwner
            );
        } else if ((followTokenOwner = _unsafeOwnerOf(followTokenId)) != address(0)) {
            _followWithWrappedToken(
                followerProfileId,
                executor,
                isExecutorApproved,
                followTokenId,
                followerProfileOwner,
                followTokenOwner
            );
        } else if (
            (currentFollowerProfileId = _followDataByFollowTokenId[followTokenId]
                .followerProfileId) != 0
        ) {
            _followWithUnwrappedToken(
                followerProfileId,
                executor,
                isExecutorApproved,
                followTokenId,
                followerProfileOwner,
                currentFollowerProfileId
            );
        } else if (
            _followDataByFollowTokenId[followTokenId].profileIdAllowedToRecover == followerProfileId
        ) {
            _followMintingNewToken(
                followerProfileId,
                executor,
                isExecutorApproved,
                followTokenId,
                followerProfileOwner
            );
        } else {
            revert FollowTokenDoesNotExist();
        }
        return followTokenIdAssigned;
    }

    /// @inheritdoc IFollowNFT
    function unfollow(
        uint256 unfollowerProfileId,
        address executor,
        bool isExecutorApproved,
        address unfollowerProfileOwner
    ) external override onlyHub {
        uint256 followTokenId = _followTokenIdByFollowerProfileId[unfollowerProfileId];
        if (followTokenId == 0) {
            revert NotFollowing();
        }
        address followTokenOwner = _unsafeOwnerOf(followTokenId);
        if (
            unfollowerProfileOwner != executor &&
            !isExecutorApproved &&
            followTokenOwner != executor &&
            !isApprovedForAll(followTokenOwner, executor)
        ) {
            revert DoesNotHavePermissions();
        }
        _unfollow(unfollowerProfileId, followTokenId);
        if (followTokenOwner == address(0)) {
            _followDataByFollowTokenId[followTokenId]
                .profileIdAllowedToRecover = unfollowerProfileId;
        }
    }

    /// @inheritdoc IFollowNFT
    function getFollowers() external view override returns (uint256) {
        return _followers;
    }

    /// @inheritdoc IFollowNFT
    function getFollowerProfileId(uint256 followTokenId) external view override returns (uint256) {
        return _followDataByFollowTokenId[followTokenId].followerProfileId;
    }

    /// @inheritdoc IFollowNFT
    function isFollowing(uint256 followerProfileId) external view override returns (bool) {
        return _followTokenIdByFollowerProfileId[followerProfileId] != 0;
    }

    /// @inheritdoc IFollowNFT
    function getFollowTokenId(uint256 followerProfileId) external view override returns (uint256) {
        return _followTokenIdByFollowerProfileId[followerProfileId];
    }

    /// @inheritdoc IFollowNFT
    function getOriginalFollowTimestamp(uint256 followTokenId)
        external
        view
        override
        returns (uint256)
    {
        return _followDataByFollowTokenId[followTokenId].originalFollowTimestamp;
    }

    /// @inheritdoc IFollowNFT
    function getFollowTimestamp(uint256 followTokenId) external view override returns (uint256) {
        return _followDataByFollowTokenId[followTokenId].followTimestamp;
    }

    /// @inheritdoc IFollowNFT
    function getProfileIdAllowedToRecover(uint256 followTokenId)
        external
        view
        override
        returns (uint256)
    {
        return _followDataByFollowTokenId[followTokenId].profileIdAllowedToRecover;
    }

    /// @inheritdoc IFollowNFT
    function getFollowData(uint256 followTokenId)
        external
        view
        override
        returns (FollowData memory)
    {
        return _followDataByFollowTokenId[followTokenId];
    }

    /// @inheritdoc IFollowNFT
    function getFollowApproved(uint256 followTokenId) external view override returns (uint256) {
        return _followApprovalByFollowTokenId[followTokenId];
    }

    /// @inheritdoc IFollowNFT
    function approveFollow(uint256 followerProfileId, uint256 followTokenId) external override {
        uint256 currentFollowerProfileId;
        address followTokenOwner = _unsafeOwnerOf(followTokenId);
        if (followTokenOwner != address(0)) {
            // Follow token is wrapped, sender must be the follow token's owner or be approved-for-all by him.
            if (followTokenOwner == msg.sender || isApprovedForAll(followTokenOwner, msg.sender)) {
                _approveFollow(followerProfileId, followTokenId);
            } else {
                revert DoesNotHavePermissions();
            }
        } else if (
            (currentFollowerProfileId = _followDataByFollowTokenId[followTokenId]
                .followerProfileId) != 0
        ) {
            // Follow token is unwrapped, sender must be the current follower's owner or be approved by him.
            address currentFollowerOwner = IERC721(HUB).ownerOf(currentFollowerProfileId);
            if (
                currentFollowerOwner == msg.sender ||
                isApprovedForAll(currentFollowerOwner, msg.sender)
            ) {
                _approveFollow(followerProfileId, followTokenId);
            } else {
                revert DoesNotHavePermissions();
            }
        } else {
            revert FollowTokenDoesNotExist();
        }
    }

    /// @inheritdoc IFollowNFT
    function untieAndWrap(uint256 followTokenId) external override {
        if (_followTokenIsWrapped(followTokenId)) {
            revert AlreadyUntiedAndWrapped();
        }
        uint256 followerProfileId = _followDataByFollowTokenId[followTokenId].followerProfileId;
        if (followerProfileId == 0) {
            revert FollowTokenDoesNotExist();
        }
        address followerProfileOwner = IERC721(HUB).ownerOf(followerProfileId);
        if (
            msg.sender != followerProfileOwner &&
            !isApprovedForAll(followerProfileOwner, msg.sender)
        ) {
            revert DoesNotHavePermissions();
        }
        _mint(followerProfileOwner, followTokenId);
    }

    /// @inheritdoc IFollowNFT
    function unwrapAndTie(uint256 followerProfileId) external override {
        uint256 followTokenId = _followTokenIdByFollowerProfileId[followerProfileId];
        if (followTokenId == 0) {
            revert NotFollowing();
        }
        super.burn(followTokenId);
    }

    /// @inheritdoc IFollowNFT
    function block(uint256 followerProfileId) external override onlyHub {
        uint256 followTokenId = _followTokenIdByFollowerProfileId[followerProfileId];
        if (followTokenId != 0) {
            if (!_followTokenIsWrapped(followTokenId)) {
                // Wrap it first, so the user stops following but does not lose the token when being blocked.
                _mint(IERC721(HUB).ownerOf(followerProfileId), followTokenId);
            }
            _unfollow(followerProfileId, followTokenId);
            ILensHub(HUB).emitUnfollowedEvent(followerProfileId, _followedProfileId, followTokenId);
        }
    }

    /// @inheritdoc IFollowNFT
    function delegate(uint256 delegatorProfileId, address delegatee) external override {
        if (_followTokenIdByFollowerProfileId[delegatorProfileId] == 0) {
            revert NotFollowing();
        }
        if (msg.sender != IERC721(HUB).ownerOf(delegatorProfileId)) {
            revert Errors.NotProfileOwner();
        }
        _delegate(delegatorProfileId, delegatee);
    }

    /// @inheritdoc IFollowNFT
    function delegateBySig(
        uint256 delegatorProfileId,
        address delegatee,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (_followTokenIdByFollowerProfileId[delegatorProfileId] == 0) {
            revert NotFollowing();
        }
        address delegatorOwner = IERC721(HUB).ownerOf(delegatorProfileId);
        unchecked {
            MetaTxHelpers._validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            DELEGATE_BY_SIG_TYPEHASH,
                            delegatorProfileId,
                            delegatee,
                            sigNonces[delegatorOwner]++,
                            sig.deadline
                        )
                    )
                ),
                delegatorOwner,
                sig
            );
        }
        _delegate(delegatorProfileId, delegatee);
    }

    /// @inheritdoc IFollowNFT
    function getPowerByBlockNumber(address user, uint256 blockNumber)
        external
        view
        override
        returns (uint256)
    {
        if (blockNumber > block.number) revert Errors.BlockNumberInvalid();
        uint256 snapshotCount = _snapshotCount[user];
        if (snapshotCount == 0) return 0; // Returning zero since this means the user never delegated and has no power
        return _getSnapshotValueByBlockNumber(_snapshots[user], blockNumber, snapshotCount);
    }

    /// @inheritdoc IFollowNFT
    function getDelegatedSupplyByBlockNumber(uint256 blockNumber)
        external
        view
        override
        returns (uint256)
    {
        if (blockNumber > block.number) revert Errors.BlockNumberInvalid();
        uint256 snapshotCount = _delSupplySnapshotCount;
        if (snapshotCount == 0) return 0; // Returning zero since this means a delegation has never occurred
        return _getSnapshotValueByBlockNumber(_delSupplySnapshots, blockNumber, snapshotCount);
    }

    function burnWithSig(uint256 followTokenId, DataTypes.EIP712Signature calldata sig)
        public
        override
    {
        _unfollowIfHasFollower(followTokenId);
        super.burnWithSig(followTokenId, sig);
    }

    function burn(uint256 followTokenId) public override {
        _unfollowIfHasFollower(followTokenId);
        super.burn(followTokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981CollectionRoyalties, ERC721Enumerable)
        returns (bool)
    {
        return
            ERC2981CollectionRoyalties.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }

    function name() public view override returns (string memory) {
        return string(abi.encodePacked(_followedProfileId.toString(), FOLLOW_NFT_NAME_SUFFIX));
    }

    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked(_followedProfileId.toString(), FOLLOW_NFT_SYMBOL_SUFFIX));
    }

    /**
     * @dev This returns the follow NFT URI fetched from the hub.
     */
    function tokenURI(uint256 followTokenId) public view override returns (string memory) {
        if (!_exists(followTokenId)) revert Errors.TokenDoesNotExist();
        return ILensHub(HUB).getFollowNFTURI(_followedProfileId);
    }

    function _followMintingNewToken(
        uint256 followerProfileId,
        address executor,
        bool isExecutorApproved,
        uint256 followTokenId,
        address followerProfileOwner
    ) internal returns (uint256) {
        if (followerProfileOwner == executor || isExecutorApproved) {
            uint256 followTokenIdAssigned;
            unchecked {
                followTokenIdAssigned = followTokenId == 0 ? ++_lastFollowTokenId : followTokenId;
                ++_followers;
            }
            _follow(followerProfileId, followTokenIdAssigned, true);
            return followTokenIdAssigned;
        } else {
            revert DoesNotHavePermissions();
        }
    }

    function _followWithWrappedToken(
        uint256 followerProfileId,
        address executor,
        bool isExecutorApproved,
        uint256 followTokenId,
        address followerProfileOwner,
        address followTokenOwner
    ) internal {
        bool approvedFollow;
        if (
            followerProfileOwner == followTokenOwner ||
            executor == followTokenOwner ||
            isApprovedForAll(followTokenOwner, executor) ||
            (approvedFollow = (_followApprovalByFollowTokenId[followTokenId] == followerProfileId))
        ) {
            // The executor is allowed to write the follower in that wrapped token.
            if (approvedFollow) {
                // The `_followApprovalByFollowTokenId` was used, now needs to be cleared.
                _approveFollow(0, followTokenId);
            }
            if (executor == followerProfileOwner || isExecutorApproved) {
                // The executor is allowed to follow on behalf.
                _replaceFollower(
                    _followDataByFollowTokenId[followTokenId].followerProfileId,
                    followerProfileId,
                    followTokenId
                );
            } else {
                revert DoesNotHavePermissions();
            }
        }
    }

    function _followWithUnwrappedToken(
        uint256 followerProfileId,
        address executor,
        bool isExecutorApproved,
        uint256 followTokenId,
        address followerProfileOwner,
        uint256 currentFollowerProfileId
    ) internal {
        bool followApproved;
        address currentFollowerProfileOwner = IERC721(HUB).ownerOf(currentFollowerProfileId);
        if (
            currentFollowerProfileOwner == executor ||
            isApprovedForAll(currentFollowerProfileOwner, executor) ||
            (followApproved = (_followApprovalByFollowTokenId[followTokenId] == followerProfileId))
        ) {
            // The profile attempting to follow is allowed to pull the unwrapped token from current follower profile.
            if (followApproved) {
                // `_followApprovalByFollowTokenId` was used, now needs to be cleared.
                _approveFollow(0, followTokenId);
            }
            if (executor == followerProfileOwner || isExecutorApproved) {
                // The executor is allowed to follow on behalf.
                _replaceFollower(currentFollowerProfileId, followerProfileId, followTokenId);
            } else {
                revert DoesNotHavePermissions();
            }
        }
    }

    function _replaceFollower(
        uint256 currentFollowerProfileId,
        uint256 newFollowerProfileId,
        uint256 followTokenId
    ) internal {
        if (currentFollowerProfileId != 0) {
            // As it has a follower, unfollow first, removing current follower.
            delete _followTokenIdByFollowerProfileId[currentFollowerProfileId];
            _delegate(currentFollowerProfileId, address(0));
            ILensHub(HUB).emitUnfollowedEvent(
                currentFollowerProfileId,
                _followedProfileId,
                followTokenId
            );
        } else {
            unchecked {
                ++_followers;
            }
        }
        // Perform the follow, setting new follower.
        _follow(newFollowerProfileId, followTokenId, false);
    }

    function _follow(
        uint256 followerProfileId,
        uint256 followTokenId,
        bool isOriginalFollow
    ) internal {
        _followTokenIdByFollowerProfileId[followerProfileId] = followTokenId;
        _followDataByFollowTokenId[followTokenId].followerProfileId = uint160(followerProfileId);
        _followDataByFollowTokenId[followTokenId].followTimestamp = uint48(block.timestamp);
        _followDataByFollowTokenId[followTokenId].profileIdAllowedToRecover = 0;
        if (isOriginalFollow) {
            _followDataByFollowTokenId[followTokenId].originalFollowTimestamp = uint48(
                block.timestamp
            );
        }
    }

    function _getReceiver(uint256 followTokenId) internal view override returns (address) {
        return IERC721(HUB).ownerOf(_followedProfileId);
    }

    function _beforeRoyaltiesSet(uint256 royaltiesInBasisPoints) internal view override {
        if (IERC721(HUB).ownerOf(_followedProfileId) != msg.sender) {
            revert Errors.NotProfileOwner();
        }
    }

    function _getRoyaltiesInBasisPointsSlot() internal pure override returns (uint256) {
        uint256 slot;
        assembly {
            slot := _royaltiesInBasisPoints.slot
        }
        return slot;
    }

    function _unfollowIfHasFollower(uint256 followTokenId) internal {
        uint256 followerProfileId = _followDataByFollowTokenId[followTokenId].followerProfileId;
        if (followerProfileId != 0) {
            _unfollow(followerProfileId, followTokenId);
            ILensHub(HUB).emitUnfollowedEvent(followerProfileId, _followedProfileId, followTokenId);
        }
    }

    function _unfollow(uint256 unfollower, uint256 followTokenId) internal {
        _delegate(unfollower, address(0));
        delete _followTokenIdByFollowerProfileId[unfollower];
        delete _followDataByFollowTokenId[followTokenId].followerProfileId;
        delete _followDataByFollowTokenId[followTokenId].followTimestamp;
        delete _followDataByFollowTokenId[followTokenId].profileIdAllowedToRecover;
        unchecked {
            --_followers;
        }
    }

    function _approveFollow(uint256 followerProfileId, uint256 followTokenId) internal {
        _followApprovalByFollowTokenId[followTokenId] = followerProfileId;
        emit FollowApproval(followerProfileId, followTokenId);
    }

    function _followTokenIsWrapped(uint256 followTokenId) internal view returns (bool) {
        return _exists(followTokenId);
    }

    function _followTokenExists(uint256 followTokenId) internal view returns (bool) {
        return
            _followDataByFollowTokenId[followTokenId].followerProfileId != 0 ||
            _followTokenIsWrapped(followTokenId);
    }

    /**
     * @dev Upon transfers, we move the appropriate delegations, and emit the transfer event in the hub.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 followTokenId
    ) internal override {
        _approveFollow(0, followTokenId);
        super._beforeTokenTransfer(from, to, followTokenId);
        ILensHub(HUB).emitFollowNFTTransferEvent(_followedProfileId, followTokenId, from, to);
    }

    function _getSnapshotValueByBlockNumber(
        mapping(uint256 => Snapshot) storage _shots,
        uint256 blockNumber,
        uint256 snapshotCount
    ) internal view returns (uint256) {
        unchecked {
            uint256 lower = 0;
            uint256 upper = snapshotCount - 1;

            // First check most recent snapshot
            if (_shots[upper].blockNumber <= blockNumber) return _shots[upper].value;

            // Next check implicit zero balance
            if (_shots[lower].blockNumber > blockNumber) return 0;

            while (upper > lower) {
                uint256 center = upper - (upper - lower) / 2;
                Snapshot memory snapshot = _shots[center];
                if (snapshot.blockNumber == blockNumber) {
                    return snapshot.value;
                } else if (snapshot.blockNumber < blockNumber) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }
            return _shots[lower].value;
        }
    }

    function _delegate(uint256 delegatorProfileId, address delegatee) internal {
        address previousDelegate = _delegates[delegatorProfileId];
        if (previousDelegate != delegatee) {
            _delegates[delegatorProfileId] = delegatee;
            _moveDelegate(previousDelegate, delegatee);
        }
    }

    function _moveDelegate(address from, address to) internal {
        unchecked {
            bool fromZero = from == address(0);
            if (!fromZero) {
                uint256 fromSnapshotCount = _snapshotCount[from];
                // Underflow is impossible since, if from != address(0), then a delegation must have occurred (at least 1 snapshot)
                uint128 newValue = _snapshots[from][fromSnapshotCount - 1].value + 1;
                _writeSnapshot(from, newValue, fromSnapshotCount);
                emit Events.FollowNFTDelegatedPowerChanged(from, newValue, block.timestamp);
            }
            if (to != address(0)) {
                // if from == address(0) then this is an initial delegation, increment supply.
                if (fromZero) {
                    // It is expected behavior that the `previousDelSupply` underflows upon the first delegation,
                    // returning the expected value of zero
                    uint256 delSupplySnapshotCount = _delSupplySnapshotCount;
                    _writeSupplySnapshot(
                        _delSupplySnapshots[delSupplySnapshotCount - 1].value + 1,
                        delSupplySnapshotCount
                    );
                }
                // It is expected behavior that `previous` underflows upon the first delegation to an address,
                // returning the expected value of zero
                uint256 toSnapshotCount = _snapshotCount[to];
                uint128 newValue = _snapshots[to][toSnapshotCount - 1].value + 1;
                _writeSnapshot(to, newValue, toSnapshotCount);
                emit Events.FollowNFTDelegatedPowerChanged(to, newValue, block.timestamp);
            } else {
                // If from != address(0) then this is removing a delegation, otherwise we're dealing with a
                // non-delegated burn of tokens and don't need to take any action
                if (!fromZero) {
                    // Upon removing delegation (from != address(0) && to == address(0)), supply calculations cannot
                    // underflow because if from != address(0), then a delegation must have previously occurred, so
                    // the snapshot count must be >= 1 and the previous delegated supply must be >= amount
                    uint256 delSupplySnapshotCount = _delSupplySnapshotCount;
                    uint128 newDelSupply = _delSupplySnapshots[delSupplySnapshotCount - 1].value -
                        1;
                    _writeSupplySnapshot(newDelSupply, delSupplySnapshotCount);
                }
            }
        }
    }

    function _writeSnapshot(
        address owner,
        uint128 newValue,
        uint256 ownerSnapshotCount
    ) internal {
        unchecked {
            uint128 currentBlock = uint128(block.number);
            mapping(uint256 => Snapshot) storage ownerSnapshots = _snapshots[owner];

            // Doing multiple operations in the same block
            if (
                ownerSnapshotCount != 0 &&
                ownerSnapshots[ownerSnapshotCount - 1].blockNumber == currentBlock
            ) {
                ownerSnapshots[ownerSnapshotCount - 1].value = newValue;
            } else {
                ownerSnapshots[ownerSnapshotCount] = Snapshot(currentBlock, newValue);
                _snapshotCount[owner] = ownerSnapshotCount + 1;
            }
        }
    }

    function _writeSupplySnapshot(uint128 newValue, uint256 supplySnapshotCount) internal {
        unchecked {
            uint128 currentBlock = uint128(block.number);

            // Doing multiple operations in the same block
            if (
                supplySnapshotCount != 0 &&
                _delSupplySnapshots[supplySnapshotCount - 1].blockNumber == currentBlock
            ) {
                _delSupplySnapshots[supplySnapshotCount - 1].value = newValue;
            } else {
                _delSupplySnapshots[supplySnapshotCount] = Snapshot(currentBlock, newValue);
                _delSupplySnapshotCount = supplySnapshotCount + 1;
            }
        }
    }
}
