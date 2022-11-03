// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IFollowNFT} from '../interfaces/IFollowNFT.sol';
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';
import {MetaTxHelpers} from '../libraries/helpers/MetaTxHelpers.sol';
import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';
import {DataTypes} from '../libraries/DataTypes.sol';
import {LensNFTBase} from './base/LensNFTBase.sol';
import {ModuleBase} from './modules/ModuleBase.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ERC721Time} from './base/ERC721Time.sol';
import '../libraries/Constants.sol';

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
    uint160 follower;
    uint96 followTimestamp;
}

contract FollowNFT is ModuleBase, LensNFTBase, IFollowNFT {
    bytes32 internal constant DELEGATE_BY_SIG_TYPEHASH =
        keccak256(
            'DelegateBySig(address delegator,address delegatee,uint256 nonce,uint256 deadline)'
        );

    mapping(address => mapping(uint256 => Snapshot)) internal _snapshots;
    mapping(address => address) internal _delegates;
    mapping(address => uint256) internal _snapshotCount;
    mapping(uint256 => Snapshot) internal _delSupplySnapshots;
    uint256 internal _delSupplySnapshotCount;
    uint256 internal _profileId;
    uint128 internal _lastFollowId;
    uint128 internal _followers;

    bool private _initialized;

    mapping(uint256 => FollowData) internal _followDataByFollowId;
    mapping(uint256 => uint256) internal _followIdByFollowerId;
    mapping(uint256 => uint256) internal _approvedToFollowByFollowerId;
    mapping(uint256 => address) internal _approvedToSetFollowerByFollowId;

    constructor(address hub) ModuleBase(hub) {
        _initialized = true;
    }

    /// @inheritdoc IFollowNFT
    function initialize(uint256 profileId) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        _profileId = profileId;
        emit Events.FollowNFTInitialized(profileId, block.timestamp);
    }

    /**
     * @param follower The ID of the profile acting as the follower.
     * @param executor The address executing the operation.
     * @param followId The follow token ID to be used for this follow operation. Use zero if a new follow token should
     * be minted.
     * @param data Custom data for processing the follow.
     */
    function follow(
        uint256 follower,
        address executor,
        uint256 followId,
        bytes calldata data
    ) external onlyHub returns (uint256) {
        if (_followIdByFollowerId[follower] != 0) {
            revert AlreadyFollowing();
        }

        uint256 followIdUsed = followId;
        address followerOwner = IERC721(HUB).ownerOf(follower);
        address tokenOwner;
        uint256 currentFollower;

        if (followId == 0) {
            followIdUsed = _followWithoutToken(follower, executor, followerOwner);
        } else if ((tokenOwner = _tokenData[followId].owner) != address(0)) {
            _followWithWrappedToken(follower, executor, followId, followerOwner, tokenOwner);
        } else if ((currentFollower = _followDataByFollowId[followId].follower) != 0) {
            _followWithUnwrappedToken(follower, executor, followId, followerOwner, currentFollower);
        } else {
            revert FollowTokenDoesNotExist();
        }

        // `Followed` event will be emitted by the hub itself after finishing this execution

        // TODO: This is probably the biggest question. Should follwing with followId != 0 call processFollow again?
        // If not, means the follow NFT works as a "right to follow", no matter which follow module you have now.
        // If yes, means you can customize it. It could make the follow NFT useless, for example rejecting all follows
        // with followId != 0, or having a module with a followId blacklist.

        // The processFollow call passes the followId, so then the follow module decides if allows follows
        // automatically when using a followId, or if it will re-process the conditions

        // processFollow(...); <-- This call is actually in the Hub after this execution finishes

        return followIdUsed;
    }

    function _followWithoutToken(
        uint256 follower,
        address executor,
        address followerOwner
    ) internal returns (uint256) {
        if (
            followerOwner == executor ||
            ILensHub(HUB).isDelegatedExecutorApproved(followerOwner, executor)
        ) {
            uint256 followId;
            unchecked {
                followId = ++_lastFollowId;
                ++_followers;
            }
            _followIdByFollowerId[follower] = followId;
            _followDataByFollowId[followId] = FollowData(
                uint160(follower),
                uint96(block.timestamp)
            );
            return followId;
        } else {
            revert DoesNotHavePermissions();
        }
    }

    function _followWithWrappedToken(
        uint256 follower,
        address executor,
        uint256 followId,
        address followerOwner,
        address tokenOwner
    ) internal {
        if (
            followerOwner == tokenOwner ||
            executor == tokenOwner ||
            _approvedToSetFollowerByFollowId[followId] == executor
        ) {
            // The executor is allowed to write the follower in that wrapped token.
            // TODO: Allow approvedForAll operators of tokenOwner?
            if (followerOwner != tokenOwner && executor != tokenOwner) {
                // The `_approvedToSetFollowerByFollowId` was used, now needs to be cleared.
                _approvedToSetFollowerByFollowId[followId] = address(0);
            }
            bool approvedToFollowUsed;
            if (
                executor == followerOwner ||
                ILensHub(HUB).isDelegatedExecutorApproved(followerOwner, executor) ||
                (approvedToFollowUsed = (_approvedToFollowByFollowerId[follower] == followId))
            ) {
                // The executor is allowed to follow on behalf.
                if (approvedToFollowUsed) {
                    // The `_approvedToFollowByFollowerId` was used, now needs to be cleared.
                    _approvedToFollowByFollowerId[follower] = 0;
                }
                uint256 currentFollower = _followDataByFollowId[followId].follower;
                if (currentFollower != 0) {
                    // As it has a follower, unfollow first.
                    _followIdByFollowerId[currentFollower] = 0;
                    // TODO: Call hub to emit event.
                    // ILensHub(HUB).emitUnfollowedEvent(...);
                } else {
                    unchecked {
                        ++_followers;
                    }
                }
                // Perform the follow.
                _followIdByFollowerId[follower] = followId;
                _followDataByFollowId[followId].follower = uint160(follower);
                _followDataByFollowId[followId].followTimestamp = uint96(block.timestamp);
            } else {
                revert DoesNotHavePermissions();
            }
        }
    }

    function _followWithUnwrappedToken(
        uint256 follower,
        address executor,
        uint256 followId,
        address followerOwner,
        uint256 currentFollower
    ) internal {
        address currentFollowerOwner = IERC721(HUB).ownerOf(currentFollower);
        if (currentFollowerOwner == executor || _tokenApprovals[followId] == executor) {
            // The executor is allowed to transfer the follow.
            // TODO: Allow approvedForAll operators of currentFollowerOwner?
            if (currentFollowerOwner != executor) {
                // `_tokenApprovals` used, now needs to be cleared.
                _tokenApprovals[followId] = address(0);
                emit Approval(currentFollowerOwner, address(0), followId);
            }
            bool approvedToFollowUsed;
            if (
                executor == followerOwner ||
                ILensHub(HUB).isDelegatedExecutorApproved(followerOwner, executor) ||
                (approvedToFollowUsed = (_approvedToFollowByFollowerId[follower] == followId))
            ) {
                // The executor is allowed to follow on behalf.
                if (approvedToFollowUsed) {
                    // The `_approvedToFollowByFollowerId` was used, now needs to be cleared.
                    _approvedToFollowByFollowerId[follower] = 0;
                }
                // Perform the unfollow.
                _followIdByFollowerId[currentFollower] = 0;
                // TODO: Call hub to emit event.
                // ILensHub(HUB).emitUnfollowedEvent(...);

                // Perform the follow.
                _followIdByFollowerId[follower] = followId;
                _followDataByFollowId[followId].follower = uint160(follower);
                _followDataByFollowId[followId].followTimestamp = uint96(block.timestamp);
            } else {
                revert DoesNotHavePermissions();
            }
        }
    }

    function mint(address to) external returns (uint256) {
        // TODO: Remove me after fixing IFollowNFT interface
    }

    /**
     * @param follower The ID of the profile that is perfrorming the unfollow operation.
     * @param executor The address executing the operation.
     */
    function unfollow(uint256 follower, address executor) external onlyHub {
        uint256 followId = _followIdByFollowerId[follower];
        if (followId == 0) {
            revert NotFollowing();
        }
        address followerOwner = IERC721(HUB).ownerOf(follower);

        address owner = _tokenData[followId].owner;
        _followIdByFollowerId[follower] = 0;
        _followDataByFollowId[followId].follower = 0;
        unchecked {
            --_followers;
        }
    }

    function _burn(uint256 followId, address owner) external {
        _followDataByFollowId[followId].follower = 0;
        _tokenData[followId].owner = address(0);
        emit Transfer(owner, address(0), followId);
    }

    // Get the follower profile from a given follow token.
    // Zero if not being used as a follow.
    function getFollower(uint256 followId) external view returns (uint256) {
        if (_tokenData[followId].mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        return _followDataByFollowId[followId].follower;
    }

    function isFollowing(uint256 follower) external returns (bool) {
        return _followIdByFollowerId[follower] != 0;
    }

    // TODO: Consider renaming
    function isUnwrappedAndTied(uint256 followId) external returns (bool) {
        if (_tokenData[followId].mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        return !_exists(followId);
    }

    // Approve someone to set me as follower on a specific asset.
    // For any asset you must use delegated execution feature with a contract adding restrictions.
    function approveFollow(uint256 follower, uint256 followId) external {
        // TODO: followId exists, and verify msg.sender owns the follower.
        _approvedToFollowByFollowerId[follower] = followId;
    }

    // Approve someone to set any follower on one of my wrapped tokens.
    // To get the follow you can use `approve`.
    function approveSetFollower(address operator, uint256 followId) external {
        address owner;
        if (
            _followDataByFollowId[followId].follower == 0 &&
            (owner = _tokenData[followId].owner) == address(0)
        ) {
            revert FollowTokenDoesNotExist();
        }
        if (owner == address(0)) {
            revert OnlyWrappedFollows();
        }
        if (msg.sender != owner) {
            revert OnlyFollowOwner();
        }
        _approvedToSetFollowerByFollowId[followId] = operator;
    }

    // TODO
    function _transferHook(uint256 followId) internal {
        _approvedToSetFollowerByFollowId[followId] = address(0);
    }

    /**
     * @dev Unties the follow token from the follower's profile token, and wrapps it into the ERC-721 untied follow
     * collection.
     */
    // TODO: Add a recipient of the wrapped token? so it works like an atomic wrap and transferFrom?
    function untieAndWrap(uint256 followId) external {
        // TODO: Optimize
        if (_tokenData[followId].mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        if (_tokenData[followId].owner != address(0)) {
            revert AlreadyUntied();
        }
        address followerOwner = IERC721(HUB).ownerOf(_followDataByFollowId[followId].follower);
        _tokenData[followId].owner = followerOwner;
        // Mint IERC721 untied collection
        _mint(IERC721(HUB).ownerOf(_followDataByFollowId[followId].follower), followId);
    }

    /**
     * @dev Unwrapps the follow token from the ERC-721 untied follow collection, and ties it to the follower's profile
     * token.
     */
    // TODO: Add the profile to which should be tied to? or it has to be following already?
    function unwrapAndTie() external {
        //
    }

    // Burns the NFT
    function burn() external {
        // Burns
        //
        // if has follower...
        // ILensHub(HUB).emitUnfollowEvent();
    }

    // Blocks follow but not having the asset!
    // Maybe this should be in the lenshub? So we don't allow to comment/mirror if blocked
    // But should collect be allowed?
    // And this function should be called by the hub when blockling, so the follow nft is aware of it
    function block(uint256 follower, bool blocked) external onlyHub {
        // if (isFollowing[follower]) {
        //     // Unfollows
        //     // Wraps and unties
        // }
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        //
    }

    /// NOTE: We allow approve for unwrapped assets to, which is not supposed to be part of ERC-721.
    function approve(address operator, uint256 followId) public override(ERC721Time, IERC721) {
        uint256 follower;
        address owner;
        if (
            (follower = _followDataByFollowId[followId].follower) == 0 &&
            (owner = _tokenData[followId].owner) == address(0)
        ) {
            revert FollowTokenDoesNotExist();
        }
        if (operator == owner) {
            revert Errors.ERC721Time_ApprovalToCurrentOwner();
        }
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert Errors.ERC721Time_ApproveCallerNotOwnerOrApprovedForAll();
        }
        _tokenApprovals[followId] = operator;
        emit Approval(
            owner == address(0) ? IERC721(HUB).ownerOf(follower) : owner,
            operator,
            followId
        );
    }

    /// @inheritdoc IFollowNFT
    function delegate(address delegatee) external override {
        _delegate(msg.sender, delegatee);
    }

    /// @inheritdoc IFollowNFT
    function delegateBySig(
        address delegator,
        address delegatee,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        unchecked {
            MetaTxHelpers._validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            DELEGATE_BY_SIG_TYPEHASH,
                            delegator,
                            delegatee,
                            sigNonces[delegator]++,
                            sig.deadline
                        )
                    )
                ),
                delegator,
                sig
            );
        }
        _delegate(delegator, delegatee);
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

    function name() public view override returns (string memory) {
        string memory handle = ILensHub(HUB).getHandle(_profileId);
        return string(abi.encodePacked(handle, FOLLOW_NFT_NAME_SUFFIX));
    }

    function symbol() public view override returns (string memory) {
        string memory handle = ILensHub(HUB).getHandle(_profileId);
        bytes4 firstBytes = bytes4(bytes(handle));
        return string(abi.encodePacked(firstBytes, FOLLOW_NFT_SYMBOL_SUFFIX));
    }

    /**
     * @dev This returns the follow NFT URI fetched from the hub.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert Errors.TokenDoesNotExist();
        return ILensHub(HUB).getFollowNFTURI(_profileId);
    }

    /**
     * @dev Upon transfers, we move the appropriate delegations, and emit the transfer event in the hub.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        address fromDelegatee = _delegates[from];
        address toDelegatee = _delegates[to];
        address followModule = ILensHub(HUB).getFollowModule(_profileId);

        _moveDelegate(fromDelegatee, toDelegatee, 1);

        super._beforeTokenTransfer(from, to, tokenId);
        ILensHub(HUB).emitFollowNFTTransferEvent(_profileId, tokenId, from, to);
        if (followModule != address(0)) {
            IFollowModule(followModule).followModuleTransferHook(_profileId, from, to, tokenId);
        }
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

    function _delegate(address delegator, address delegatee) internal {
        uint256 delegatorBalance = balanceOf(delegator);
        address previousDelegate = _delegates[delegator];
        _delegates[delegator] = delegatee;
        _moveDelegate(previousDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegate(
        address from,
        address to,
        uint256 amount
    ) internal {
        unchecked {
            bool fromZero = from == address(0);
            if (!fromZero) {
                uint256 fromSnapshotCount = _snapshotCount[from];

                // Underflow is impossible since, if from != address(0), then a delegation must have occurred (at least 1 snapshot)
                uint256 previous = _snapshots[from][fromSnapshotCount - 1].value;
                uint128 newValue = uint128(previous - amount);

                _writeSnapshot(from, newValue, fromSnapshotCount);
                emit Events.FollowNFTDelegatedPowerChanged(from, newValue, block.timestamp);
            }

            if (to != address(0)) {
                // if from == address(0) then this is an initial delegation (add amount to supply)
                if (fromZero) {
                    // It is expected behavior that the `previousDelSupply` underflows upon the first delegation,
                    // returning the expected value of zero
                    uint256 delSupplySnapshotCount = _delSupplySnapshotCount;
                    uint128 previousDelSupply = _delSupplySnapshots[delSupplySnapshotCount - 1]
                        .value;
                    uint128 newDelSupply = uint128(previousDelSupply + amount);
                    _writeSupplySnapshot(newDelSupply, delSupplySnapshotCount);
                }

                // It is expected behavior that `previous` underflows upon the first delegation to an address,
                // returning the expected value of zero
                uint256 toSnapshotCount = _snapshotCount[to];
                uint128 previous = _snapshots[to][toSnapshotCount - 1].value;
                uint128 newValue = uint128(previous + amount);
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
                    uint128 previousDelSupply = _delSupplySnapshots[delSupplySnapshotCount - 1]
                        .value;
                    uint128 newDelSupply = uint128(previousDelSupply - amount);
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
