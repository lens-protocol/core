// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import '../libraries/Constants.sol';
import {DataTypes} from '../libraries/DataTypes.sol';
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
    uint160 follower;
    uint96 followTimestamp;
    uint256 recoverableBy;
}

contract FollowNFT is HubRestricted, LensNFTBase, IFollowNFT {
    using Strings for uint256;

    bytes32 internal constant DELEGATE_BY_SIG_TYPEHASH =
        keccak256(
            'DelegateBySig(address delegator,address delegatee,uint256 nonce,uint256 deadline)'
        );
    uint16 internal constant BASIS_POINTS = 10000;

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
    uint16 internal _royaltyBasisPoints;

    mapping(uint256 => FollowData) internal _followDataByFollowId;
    mapping(uint256 => uint256) internal _followIdByFollowerId;
    mapping(uint256 => uint256) internal _approvedFollowWithTokenByFollowerId;
    mapping(uint256 => address) internal _approvedSetFollowerInTokenByFollowId;

    event SetFollowerInTokenApproved(uint256 indexed followId, address approved);
    event FollowWithTokenApproved(uint256 indexed follower, uint256 followId);

    constructor(address hub) HubRestricted(hub) {
        _initialized = true;
    }

    /// @inheritdoc IFollowNFT
    function initialize(uint256 profileId) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        _followedProfileId = profileId;
        _royaltyBasisPoints = 1000; // 10% of royalties
        emit Events.FollowNFTInitialized(profileId, block.timestamp);
    }

    /**
     * @param follower The ID of the profile acting as the follower.
     * @param executor The address executing the operation.
     * @param followerOwner The address holding the follower profile.
     * @param followId The follow token ID to be used for this follow operation. Use zero if a new follow token should
     * be minted.
     */
    function follow(
        uint256 follower,
        address executor,
        address followerOwner,
        uint256 followId
    ) external override onlyHub returns (uint256) {
        if (_followIdByFollowerId[follower] != 0) {
            revert AlreadyFollowing();
        }
        uint256 followIdAssigned = followId;
        address tokenOwner;
        uint256 currentFollower;
        if (followId == 0) {
            followIdAssigned = _followMintingNewToken(follower, executor, 0, followerOwner);
        } else if ((tokenOwner = _tokenData[followId].owner) != address(0)) {
            _followWithWrappedToken(follower, executor, followId, followerOwner, tokenOwner);
        } else if ((currentFollower = _followDataByFollowId[followId].follower) != 0) {
            _followWithUnwrappedToken(
                follower,
                executor,
                followId,
                followerOwner,
                tokenOwner,
                currentFollower
            );
        } else if (_followDataByFollowId[followId].recoverableBy == follower) {
            _followMintingNewToken(follower, executor, followId, followerOwner);
        } else {
            revert FollowTokenDoesNotExist();
        }
        return followIdAssigned;
    }

    function _followMintingNewToken(
        uint256 follower,
        address executor,
        uint256 followId,
        address followerOwner
    ) internal returns (uint256) {
        if (
            followerOwner == executor ||
            ILensHub(HUB).isDelegatedExecutorApproved(followerOwner, executor)
        ) {
            uint256 followIdAssigned;
            unchecked {
                followIdAssigned = followId == 0 ? ++_lastFollowId : followId;
                ++_followers;
            }
            _tokenData[followIdAssigned].mintTimestamp = uint96(block.timestamp);
            _follow(follower, followIdAssigned);
            return followIdAssigned;
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
        bool approvedTetFollowerInToken;
        if (
            followerOwner == tokenOwner ||
            executor == tokenOwner ||
            _operatorApprovals[tokenOwner][executor] ||
            (approvedTetFollowerInToken = (_approvedSetFollowerInTokenByFollowId[followId] ==
                executor))
        ) {
            // The executor is allowed to write the follower in that wrapped token.
            if (approvedTetFollowerInToken) {
                // The `_approvedSetFollowerInTokenByFollowId` was used, now needs to be cleared.
                _approveSetFollowerInToken(address(0), followId);
            }
            bool approvedFollowWithTokenUsed;
            if (
                executor == followerOwner ||
                ILensHub(HUB).isDelegatedExecutorApproved(followerOwner, executor) ||
                (approvedFollowWithTokenUsed = (_approvedFollowWithTokenByFollowerId[follower] ==
                    followId))
            ) {
                // The executor is allowed to follow on behalf.
                if (approvedFollowWithTokenUsed) {
                    // The `_approvedFollowWithTokenByFollowerId` was used, now needs to be cleared.
                    _approveFollowWithToken(follower, 0);
                }
                uint256 currentFollower = _followDataByFollowId[followId].follower;
                if (currentFollower != 0) {
                    // As it has a follower, unfollow first.
                    _followIdByFollowerId[currentFollower] = 0;
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
                _follow(follower, followId);
            } else {
                revert DoesNotHavePermissions();
            }
        }
    }

    function _follow(uint256 follower, uint256 followId) internal {
        _followIdByFollowerId[follower] = followId;
        _followDataByFollowId[followId] = FollowData(uint160(follower), uint96(block.timestamp), 0);
    }

    function _followWithUnwrappedToken(
        uint256 follower,
        address executor,
        uint256 followId,
        address followerOwner,
        address tokenOwner,
        uint256 currentFollower
    ) internal {
        bool tokenApproved;
        address currentFollowerOwner = IERC721(HUB).ownerOf(currentFollower);
        if (
            currentFollowerOwner == executor ||
            _operatorApprovals[tokenOwner][executor] ||
            (tokenApproved = (_tokenApprovals[followId] == executor))
        ) {
            // The executor is allowed to transfer the follow.
            if (tokenApproved) {
                // `_tokenApprovals` used, now needs to be cleared.
                _tokenApprovals[followId] = address(0);
                emit Approval(currentFollowerOwner, address(0), followId);
            }
            bool approvedFollowWithTokenUsed;
            if (
                executor == followerOwner ||
                ILensHub(HUB).isDelegatedExecutorApproved(followerOwner, executor) ||
                (approvedFollowWithTokenUsed = (_approvedFollowWithTokenByFollowerId[follower] ==
                    followId))
            ) {
                // The executor is allowed to follow on behalf.
                if (approvedFollowWithTokenUsed) {
                    // The `_approvedFollowWithTokenByFollowerId` was used, now needs to be cleared.
                    _approveFollowWithToken(follower, 0);
                }
                // Perform the unfollow.
                _followIdByFollowerId[currentFollower] = 0;
                ILensHub(HUB).emitUnfollowedEvent(currentFollower, _followedProfileId, followId);
                // Perform the follow.
                _follow(follower, followId);
            } else {
                revert DoesNotHavePermissions();
            }
        }
    }

    /**
     * @param unfollower The ID of the profile that is perfrorming the unfollow operation.
     * @param executor The address executing the operation.
     * @param unfollowerOwner The address holding the unfollower profile.
     */
    function unfollow(
        uint256 unfollower,
        address executor,
        address unfollowerOwner
    ) external override onlyHub {
        uint256 followId = _followIdByFollowerId[unfollower];
        if (followId == 0) {
            revert NotFollowing();
        }
        address tokenOwner = _tokenData[followId].owner;
        if (
            unfollowerOwner != executor &&
            !ILensHub(HUB).isDelegatedExecutorApproved(unfollowerOwner, executor) &&
            tokenOwner != executor &&
            !_operatorApprovals[tokenOwner][executor]
        ) {
            revert DoesNotHavePermissions();
        }
        _unfollow(unfollower, followId);
        if (tokenOwner == address(0)) {
            _followDataByFollowId[followId].recoverableBy = unfollower;
        }
    }

    // Get the follower profile from a given follow token.
    // Zero if not being used as a follow.
    function getFollower(uint256 followId) external view override returns (uint256) {
        if (_tokenData[followId].mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        return _followDataByFollowId[followId].follower;
    }

    function isFollowing(uint256 follower) external view override returns (bool) {
        return _followIdByFollowerId[follower] != 0;
    }

    function getFollowId(uint256 follower) external view override returns (uint256) {
        return _followIdByFollowerId[follower];
    }

    // Approve someone to set me as follower on a specific asset.
    // For any asset you must use delegated execution feature with a contract adding restrictions.
    function approveFollowWithToken(uint256 follower, uint256 followId) external {
        if (_tokenData[followId].mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        if (IERC721(HUB).ownerOf(follower) != msg.sender) {
            revert DoesNotHavePermissions();
        }
        _approveFollowWithToken(follower, followId);
    }

    function _approveFollowWithToken(uint256 follower, uint256 followId) internal {
        _approvedFollowWithTokenByFollowerId[follower] = followId;
        emit FollowWithTokenApproved(follower, followId);
    }

    // Approve someone to set any follower on one of my wrapped tokens.
    function approveSetFollowerInToken(address operator, uint256 followId) external {
        TokenData memory tokenData = _tokenData[followId];
        if (tokenData.mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        if (tokenData.owner == address(0)) {
            revert OnlyWrappedFollows();
        }
        if (msg.sender != tokenData.owner) {
            revert OnlyFollowOwner();
        }
        _approveSetFollowerInToken(operator, followId);
    }

    /**
     * @dev Unties the follow token from the follower's profile token, and wrapps it into the ERC-721 untied follow
     * collection.
     */
    function untieAndWrap(uint256 followId) external {
        TokenData memory tokenData = _tokenData[followId];
        if (tokenData.mintTimestamp == 0) {
            revert FollowTokenDoesNotExist();
        }
        if (tokenData.owner != address(0)) {
            revert AlreadyUntied();
        }
        _mint(IERC721(HUB).ownerOf(_followDataByFollowId[followId].follower), followId);
    }

    /**
     * @dev Unwrapps the follow token from the ERC-721 untied follow collection, and ties it to the follower's profile
     * token.
     */
    function unwrapAndTie(uint256 follower) external {
        uint256 followId = _followIdByFollowerId[follower];
        if (followId == 0) {
            revert NotFollowing();
        }
        if (_tokenData[followId].owner == address(0)) {
            revert AlreadyTied();
        }
        _burnWithoutClearingApprovals(followId);
    }

    function burnWithSig(uint256 followId, DataTypes.EIP712Signature calldata sig) public override {
        _unfollowIfHasFollower(followId);
        super.burnWithSig(followId, sig);
    }

    function burn(uint256 followId) public override {
        _unfollowIfHasFollower(followId);
        super.burn(followId);
    }

    function block(uint256 follower) external override onlyHub {
        uint256 followId = _followIdByFollowerId[follower];
        if (followId != 0) {
            if (_tokenData[followId].owner != address(0)) {
                // Wrap it first, so the user stops following but does not lose the token when being blocked.
                _mint(IERC721(HUB).ownerOf(_followDataByFollowId[followId].follower), followId);
            }
            _unfollow(follower, followId);
            ILensHub(HUB).emitUnfollowedEvent(follower, _followedProfileId, followId);
        }
    }

    /**
     * @notice Changes the royalty percentage for secondary sales. Can only be called publication's
     *         profile owner.
     *
     * @param royaltyBasisPoints The royalty percentage meassured in basis points. Each basis point
     *                           represents 0.01%.
     */
    // TODO: We can move this to a base contract and share logic between Follow and Collect NFTs
    function setRoyalty(uint256 royaltyBasisPoints) external {
        if (IERC721(HUB).ownerOf(_followedProfileId) == msg.sender) {
            if (royaltyBasisPoints > BASIS_POINTS) {
                revert Errors.InvalidParameter();
            } else {
                _royaltyBasisPoints = uint16(royaltyBasisPoints);
            }
        } else {
            revert Errors.NotProfileOwner();
        }
    }

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     *
     * @param followId The ID of the follow token queried for royalty information.
     * @param salePrice The sale price of the token specified.
     * @return A tuple with the address who should receive the royalties and the royalty
     * payment amount for the given sale price.
     */
    // TODO: We can move this to a base contract and share logic between Follow and Collect NFTs
    function royaltyInfo(uint256 followId, uint256 salePrice)
        external
        view
        returns (address, uint256)
    {
        return (
            IERC721(HUB).ownerOf(_followedProfileId),
            (salePrice * _royaltyBasisPoints) / BASIS_POINTS
        );
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
        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) {
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
    function delegate(uint256 delegatorProfile, address delegatee) external override {
        if (_followIdByFollowerId[delegatorProfile] == 0) {
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
        if (_followIdByFollowerId[delegatorProfile] == 0) {
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

    function name() public view override returns (string memory) {
        return string(abi.encodePacked(_followedProfileId.toString(), FOLLOW_NFT_NAME_SUFFIX));
    }

    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked(_followedProfileId.toString(), FOLLOW_NFT_SYMBOL_SUFFIX));
    }

    /**
     * @dev This returns the follow NFT URI fetched from the hub.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert Errors.TokenDoesNotExist();
        return ILensHub(HUB).getFollowNFTURI(_followedProfileId);
    }

    function _unfollowIfHasFollower(uint256 followId) internal {
        uint256 follower = _followDataByFollowId[followId].follower;
        if (follower != 0) {
            _unfollow(follower, followId);
            ILensHub(HUB).emitUnfollowedEvent(follower, _followedProfileId, followId);
        }
    }

    function _unfollow(uint256 unfollower, uint256 followId) internal {
        _delegate(unfollower, address(0));
        delete _followIdByFollowerId[unfollower];
        delete _followDataByFollowId[followId];
        unchecked {
            --_followers;
        }
    }

    function _mint(address to, uint256 tokenId) internal override {
        if (to == address(0)) {
            revert Errors.ERC721Time_MintToZeroAddress();
        }
        if (_exists(tokenId)) {
            revert Errors.ERC721Time_TokenAlreadyMinted();
        }
        _beforeTokenTransfer(address(0), to, tokenId);
        unchecked {
            ++_balances[to];
        }
        _tokenData[tokenId].owner = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal override {
        _burnWithoutClearingApprovals(tokenId);
        _clearApprovals(tokenId);
    }

    function _burnWithoutClearingApprovals(uint256 tokenId) internal {
        address owner = ERC721Time.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        unchecked {
            --_balances[owner];
        }
        delete _tokenData[tokenId];
        emit Transfer(owner, address(0), tokenId);
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
        uint256 tokenId
    ) internal override {
        address followModule = ILensHub(HUB).getFollowModule(_followedProfileId);
        super._beforeTokenTransfer(from, to, tokenId);
        ILensHub(HUB).emitFollowNFTTransferEvent(_followedProfileId, tokenId, from, to);
        if (followModule != address(0)) {
            IFollowModule(followModule).followModuleTransferHook(
                _followedProfileId,
                from,
                to,
                tokenId
            );
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
