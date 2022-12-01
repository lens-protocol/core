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

error AlreadyFollowing();
error NotFollowing();
error FollowTokenDoesNotExist();
error AlreadyUntied();
error AlreadyTied();
error Blocked();
error OnlyFollowOwner();
error OnlyWrappedFollows();
error DoesNotHavePermissions();

struct Snapshot {
    uint128 blockNumber;
    uint128 value;
}

struct FollowData {
    uint160 followerProfileId;
    uint96 followTimestamp;
    uint256 profileIdAllowedToRecover;
}

contract FollowNFT is HubRestricted, LensNFTBase, ERC2981CollectionRoyalties, IFollowNFT {
    using Strings for uint256;

    bytes32 internal constant DELEGATE_BY_SIG_TYPEHASH =
        keccak256(
            'DelegateBySig(address delegator,address delegatee,uint256 nonce,uint256 deadline)'
        );

    mapping(address => mapping(uint256 => Snapshot)) internal _snapshots;
    // TODO: Check that nobody has used this feature before doing this mapping modifiation, otherwise use new slot.
    mapping(uint256 => address) internal _delegates;
    mapping(address => uint256) internal _snapshotCount;
    mapping(uint256 => Snapshot) internal _delSupplySnapshots;
    uint256 internal _delSupplySnapshotCount;
    uint256 internal _followedProfileId;
    uint128 internal _lastFollowId;
    uint128 internal _followers;

    bool private _initialized;

    mapping(uint256 => FollowData) internal _followDataByFollowId;
    mapping(uint256 => uint256) internal _followIdByFollowerProfileId;
    mapping(uint256 => uint256) internal _approvedFollowWithTokenByFollowerProfileId;
    mapping(uint256 => address) internal _approvedSetFollowerInTokenByFollowId;
    uint256 internal _royaltiesInBasisPoints;

    event SetFollowerInTokenApproved(uint256 indexed followId, address approved);
    event FollowWithTokenApproved(uint256 indexed followerProfileId, uint256 followId);

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

    /**
     * @param followerProfileId The ID of the profile acting as the follower.
     * @param executor The address executing the operation.
     * @param followerProfileOwner The address holding the follower profile.
     * @param isExecutorApproved A boolean indicading whether the executor is an approved delegated executor of the
     * follower profile's owner.
     * @param followId The follow token ID to be used for this follow operation. Use zero if a new follow token should
     * be minted.
     */
    function follow(
        uint256 followerProfileId,
        address executor,
        address followerProfileOwner,
        bool isExecutorApproved,
        uint256 followId
    ) external override onlyHub returns (uint256) {
        if (_followIdByFollowerProfileId[followerProfileId] != 0) {
            revert AlreadyFollowing();
        }
        uint256 followIdAssigned = followId;
        address followTokenOwner;
        uint256 currentFollower;
        if (followId == 0) {
            followIdAssigned = _followMintingNewToken(
                followerProfileId,
                executor,
                isExecutorApproved,
                0,
                followerProfileOwner
            );
        } else if ((followTokenOwner = _tokenData[followId].owner) != address(0)) {
            _followWithWrappedToken(
                followerProfileId,
                executor,
                isExecutorApproved,
                followId,
                followerProfileOwner,
                followTokenOwner
            );
        } else if ((currentFollower = _followDataByFollowId[followId].followerProfileId) != 0) {
            _followWithUnwrappedToken(
                followerProfileId,
                executor,
                isExecutorApproved,
                followId,
                followerProfileOwner,
                currentFollower
            );
        } else if (_followDataByFollowId[followId].profileIdAllowedToRecover == followerProfileId) {
            _followMintingNewToken(
                followerProfileId,
                executor,
                isExecutorApproved,
                followId,
                followerProfileOwner
            );
        } else {
            revert FollowTokenDoesNotExist();
        }
        return followIdAssigned;
    }

    /**
     * @param unfollowerProfileId The ID of the profile that is perfrorming the unfollow operation.
     * @param executor The address executing the operation.
     * @param isExecutorApproved A boolean indicading whether the executor is an approved delegated executor of the
     * unfollower profile's owner.
     * @param unfollowerProfileOwner The address holding the unfollower profile.
     */
    function unfollow(
        uint256 unfollowerProfileId,
        address executor,
        bool isExecutorApproved,
        address unfollowerProfileOwner
    ) external override onlyHub {
        uint256 followId = _followIdByFollowerProfileId[unfollowerProfileId];
        if (followId == 0) {
            revert NotFollowing();
        }
        address followTokenOwner = _tokenData[followId].owner;
        if (
            unfollowerProfileOwner != executor &&
            !isExecutorApproved &&
            followTokenOwner != executor &&
            !isApprovedForAll(followTokenOwner, executor)
        ) {
            revert DoesNotHavePermissions();
        }
        _unfollow(unfollowerProfileId, followId);
        if (followTokenOwner == address(0)) {
            _followDataByFollowId[followId].profileIdAllowedToRecover = unfollowerProfileId;
        }
    }

    // Get the follower profile from a given follow token.
    // Zero if not being used as a follow.
    function getFollowerProfileId(uint256 followId) external view override returns (uint256) {
        if (_tokenData[followId].mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        return _followDataByFollowId[followId].followerProfileId;
    }

    function isFollowing(uint256 followerProfileId) external view override returns (bool) {
        return _followIdByFollowerProfileId[followerProfileId] != 0;
    }

    function getFollowId(uint256 followerProfileId) external view override returns (uint256) {
        return _followIdByFollowerProfileId[followerProfileId];
    }

    // Approve someone to set me as follower on a specific asset.
    // For any asset you must use delegated execution feature with a contract adding restrictions.
    function approveFollowWithToken(uint256 followerProfileId, uint256 followId) external {
        if (_tokenData[followId].mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        if (IERC721(HUB).ownerOf(followerProfileId) != msg.sender) {
            revert DoesNotHavePermissions();
        }
        _approveFollowWithToken(followerProfileId, followId);
    }

    // Approve someone to set any follower on one of my wrapped tokens.
    function approveSetFollowerInToken(address operator, uint256 followId) external {
        TokenData memory followToken = _tokenData[followId];
        if (followToken.mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        if (followToken.owner == address(0)) {
            revert OnlyWrappedFollows();
        }
        if (msg.sender != followToken.owner) {
            revert OnlyFollowOwner();
        }
        _approveSetFollowerInToken(operator, followId);
    }

    /**
     * @dev Unties the follow token from the follower's profile token, and wrapps it into the ERC-721 untied follow
     * collection.
     */
    function untieAndWrap(uint256 followId) external {
        TokenData memory followToken = _tokenData[followId];
        if (followToken.mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        if (followToken.owner != address(0)) {
            revert AlreadyUntied();
        }
        _mint(IERC721(HUB).ownerOf(_followDataByFollowId[followId].followerProfileId), followId);
    }

    /**
     * @dev Unwrapps the follow token from the ERC-721 untied follow collection, and ties it to the follower's profile
     * token.
     */
    function unwrapAndTie(uint256 followerProfileId) external {
        uint256 followId = _followIdByFollowerProfileId[followerProfileId];
        if (followId == 0) {
            revert NotFollowing();
        }
        if (_tokenData[followId].owner == address(0)) {
            revert AlreadyTied();
        }
        _burnWithoutClearingApprovals(followId);
    }

    function block(uint256 followerProfileId) external override onlyHub {
        uint256 followId = _followIdByFollowerProfileId[followerProfileId];
        if (followId != 0) {
            if (_tokenData[followId].owner != address(0)) {
                // Wrap it first, so the user stops following but does not lose the token when being blocked.
                _mint(
                    IERC721(HUB).ownerOf(_followDataByFollowId[followId].followerProfileId),
                    followId
                );
            }
            _unfollow(followerProfileId, followId);
            ILensHub(HUB).emitUnfollowedEvent(followerProfileId, _followedProfileId, followId);
        }
    }

    /// @inheritdoc IFollowNFT
    function delegate(uint256 delegatorProfile, address delegatee) external override {
        if (_followIdByFollowerProfileId[delegatorProfile] == 0) {
            revert NotFollowing();
        }
        if (msg.sender != IERC721(HUB).ownerOf(delegatorProfile)) {
            revert Errors.NotProfileOwner();
        }
        _delegate(delegatorProfile, delegatee);
    }

    /// @inheritdoc IFollowNFT
    function delegateBySig(
        uint256 delegatorProfile,
        address delegatee,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (_followIdByFollowerProfileId[delegatorProfile] == 0) {
            revert NotFollowing();
        }
        address delegatorOwner = IERC721(HUB).ownerOf(delegatorProfile);
        unchecked {
            MetaTxHelpers._validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            DELEGATE_BY_SIG_TYPEHASH,
                            delegatorProfile,
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
        _delegate(delegatorProfile, delegatee);
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

    function burnWithSig(uint256 followId, DataTypes.EIP712Signature calldata sig) public override {
        _unfollowIfHasFollower(followId);
        super.burnWithSig(followId, sig);
    }

    function burn(uint256 followId) public override {
        _unfollowIfHasFollower(followId);
        super.burn(followId);
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

    /// NOTE: We allow approve for unwrapped assets to, which is not supposed to be part of ERC-721.
    function approve(address operator, uint256 followId) public override(ERC721Time, IERC721) {
        uint256 followerProfileId;
        address owner;
        if (
            (followerProfileId = _followDataByFollowId[followId].followerProfileId) == 0 &&
            (owner = _tokenData[followId].owner) == address(0)
        ) {
            revert FollowTokenDoesNotExist();
        }
        if (operator == owner) {
            revert Errors.ERC721Time_ApprovalToCurrentOwner();
        }
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert Errors.ERC721Time_ApproveCallerNotOwnerOrApprovedForAll();
        }
        _tokenApprovals[followId] = operator;
        emit Approval(
            owner == address(0) ? IERC721(HUB).ownerOf(followerProfileId) : owner,
            operator,
            followId
        );
    }

    function getApproved(uint256 followId)
        public
        view
        override(ERC721Time, IERC721)
        returns (address)
    {
        return _tokenApprovals[followId];
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
    function tokenURI(uint256 followId) public view override returns (string memory) {
        if (!_exists(followId)) revert Errors.TokenDoesNotExist();
        return ILensHub(HUB).getFollowNFTURI(_followedProfileId);
    }

    function _followMintingNewToken(
        uint256 followerProfileId,
        address executor,
        bool isExecutorApproved,
        uint256 followId,
        address followerProfileOwner
    ) internal returns (uint256) {
        if (followerProfileOwner == executor || isExecutorApproved) {
            uint256 followIdAssigned;
            unchecked {
                followIdAssigned = followId == 0 ? ++_lastFollowId : followId;
                ++_followers;
            }
            _tokenData[followIdAssigned].mintTimestamp = uint96(block.timestamp);
            _follow(followerProfileId, followIdAssigned);
            return followIdAssigned;
        } else {
            revert DoesNotHavePermissions();
        }
    }

    function _followWithWrappedToken(
        uint256 followerProfileId,
        address executor,
        bool isExecutorApproved,
        uint256 followId,
        address followerProfileOwner,
        address followTokenOwner
    ) internal {
        bool approvedSetFollowerInToken;
        if (
            followerProfileOwner == followTokenOwner ||
            executor == followTokenOwner ||
            isApprovedForAll(followTokenOwner, executor) ||
            (approvedSetFollowerInToken = (_approvedSetFollowerInTokenByFollowId[followId] ==
                executor))
        ) {
            // The executor is allowed to write the follower in that wrapped token.
            if (approvedSetFollowerInToken) {
                // The `_approvedSetFollowerInTokenByFollowId` was used, now needs to be cleared.
                _approveSetFollowerInToken(address(0), followId);
            }
            bool approvedFollowWithTokenUsed;
            if (
                executor == followerProfileOwner ||
                isExecutorApproved ||
                (approvedFollowWithTokenUsed = (_approvedFollowWithTokenByFollowerProfileId[
                    followerProfileId
                ] == followId))
            ) {
                // The executor is allowed to follow on behalf.
                if (approvedFollowWithTokenUsed) {
                    // The `_approvedFollowWithTokenByFollowerProfileId` was used, now needs to be cleared.
                    _approveFollowWithToken(followerProfileId, 0);
                }
                uint256 currentFollower = _followDataByFollowId[followId].followerProfileId;
                if (currentFollower != 0) {
                    // As it has a follower, unfollow first.
                    _followIdByFollowerProfileId[currentFollower] = 0;
                    _delegate(currentFollower, address(0));
                    ILensHub(HUB).emitUnfollowedEvent(
                        currentFollower,
                        _followedProfileId,
                        followId
                    );
                } else {
                    unchecked {
                        ++_followers;
                    }
                }
                // Perform the follow.
                _follow(followerProfileId, followId);
            } else {
                revert DoesNotHavePermissions();
            }
        }
    }

    function _followWithUnwrappedToken(
        uint256 followerProfileId,
        address executor,
        bool isExecutorApproved,
        uint256 followId,
        address followerProfileOwner,
        uint256 currentFollower
    ) internal {
        bool tokenApproved;
        address currentFollowerOwner = IERC721(HUB).ownerOf(currentFollower);
        if (
            currentFollowerOwner == executor ||
            isApprovedForAll(currentFollowerOwner, executor) ||
            (tokenApproved = (getApproved(followId) == executor))
        ) {
            // The executor is allowed to transfer the follow.
            if (tokenApproved) {
                // `_tokenApprovals` used, now needs to be cleared.
                _tokenApprovals[followId] = address(0);
                emit Approval(currentFollowerOwner, address(0), followId);
            }
            bool approvedFollowWithTokenUsed;
            if (
                executor == followerProfileOwner ||
                isExecutorApproved ||
                (approvedFollowWithTokenUsed = (_approvedFollowWithTokenByFollowerProfileId[
                    followerProfileId
                ] == followId))
            ) {
                // The executor is allowed to follow on behalf.
                if (approvedFollowWithTokenUsed) {
                    // The `_approvedFollowWithTokenByFollowerProfileId` was used, now needs to be cleared.
                    _approveFollowWithToken(followerProfileId, 0);
                }
                // Perform the unfollow.
                _followIdByFollowerProfileId[currentFollower] = 0;
                ILensHub(HUB).emitUnfollowedEvent(currentFollower, _followedProfileId, followId);
                // Perform the follow.
                _follow(followerProfileId, followId);
            } else {
                revert DoesNotHavePermissions();
            }
        }
    }

    function _follow(uint256 followerProfileId, uint256 followId) internal {
        _followIdByFollowerProfileId[followerProfileId] = followId;
        _followDataByFollowId[followId] = FollowData(
            uint160(followerProfileId),
            uint96(block.timestamp),
            0
        );
    }

    function _approveFollowWithToken(uint256 followerProfileId, uint256 followId) internal {
        _approvedFollowWithTokenByFollowerProfileId[followerProfileId] = followId;
        emit FollowWithTokenApproved(followerProfileId, followId);
    }

    function _getReceiver(uint256 followId) internal view override returns (address) {
        return IERC721(HUB).ownerOf(_followedProfileId);
    }

    function _beforeRoyaltiesSet(uint256 royaltiesInBasisPoints) internal override {
        if (IERC721(HUB).ownerOf(_followedProfileId) != msg.sender) {
            revert Errors.NotProfileOwner();
        }
    }

    function _getRoyaltiesInBasisPointsSlot() internal view override returns (uint256) {
        uint256 slot;
        assembly {
            slot := _royaltiesInBasisPoints.slot
        }
        return slot;
    }

    function _unfollowIfHasFollower(uint256 followId) internal {
        uint256 followerProfileId = _followDataByFollowId[followId].followerProfileId;
        if (followerProfileId != 0) {
            _unfollow(followerProfileId, followId);
            ILensHub(HUB).emitUnfollowedEvent(followerProfileId, _followedProfileId, followId);
        }
    }

    function _unfollow(uint256 unfollower, uint256 followId) internal {
        _delegate(unfollower, address(0));
        delete _followIdByFollowerProfileId[unfollower];
        delete _followDataByFollowId[followId];
        unchecked {
            --_followers;
        }
    }

    function _mint(address to, uint256 followId) internal override {
        if (to == address(0)) {
            revert Errors.ERC721Time_MintToZeroAddress();
        }
        if (_exists(followId)) {
            revert Errors.ERC721Time_TokenAlreadyMinted();
        }
        _beforeTokenTransfer(address(0), to, followId);
        unchecked {
            ++_balances[to];
        }
        _tokenData[followId].owner = to;
        emit Transfer(address(0), to, followId);
    }

    function _burn(uint256 followId) internal override {
        _burnWithoutClearingApprovals(followId);
        _clearApprovals(followId);
    }

    function _burnWithoutClearingApprovals(uint256 followId) internal {
        address owner = ERC721Time.ownerOf(followId);
        _beforeTokenTransfer(owner, address(0), followId);
        unchecked {
            --_balances[owner];
        }
        delete _tokenData[followId];
        emit Transfer(owner, address(0), followId);
    }

    function _clearApprovals(uint256 followId) internal {
        _approveSetFollowerInToken(address(0), followId);
        _approve(address(0), followId);
    }

    function _approveSetFollowerInToken(address operator, uint256 followId) internal {
        _approvedSetFollowerInTokenByFollowId[followId] = operator;
        emit SetFollowerInTokenApproved(followId, operator);
    }

    /**
     * @dev Upon transfers, we move the appropriate delegations, and emit the transfer event in the hub.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 followId
    ) internal override {
        if (from != address(0) && to != address(0)) {
            // It is not necessary to clear approvals when minting. And the approvals should not be cleared here for the
            // burn case, as it could be a token unwrap instead of a regular burn.
            _clearApprovals(followId);
        }
        super._beforeTokenTransfer(from, to, followId);
        ILensHub(HUB).emitFollowNFTTransferEvent(_followedProfileId, followId, from, to);
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

    function _delegate(uint256 delegatorProfile, address delegatee) internal {
        address previousDelegate = _delegates[delegatorProfile];
        if (previousDelegate != delegatee) {
            _delegates[delegatorProfile] = delegatee;
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
