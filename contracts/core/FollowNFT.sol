// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {IFollowNFT} from '../interfaces/IFollowNFT.sol';
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';
import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';
import {DataTypes} from '../libraries/DataTypes.sol';
import {LensNFTBase} from './base/LensNFTBase.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @title FollowNFT
 * @author Lens
 *
 * @notice This contract is the NFT that is minted upon following a given profile. It is cloned upon first follow for a
 * given profile, and includes built-in governance power and delegation mechanisms.
 */
contract FollowNFT is LensNFTBase, IFollowNFT {
    struct Snapshot {
        uint128 blockNumber;
        uint128 value;
    }

    address public immutable HUB;

    bytes32 internal constant DELEGATE_BY_SIG_TYPEHASH =
        0xb8f190a57772800093f4e2b186099eb4f1df0ed7f5e2791e89a4a07678e0aeff;
    // keccak256(
    // 'DelegateBySig(address delegator,address delegatee,uint256 nonce,uint256 deadline)'
    // );

    mapping(address => mapping(uint256 => Snapshot)) internal _snapshots;
    mapping(address => address) internal _delegates;
    mapping(address => uint256) internal _snapshotCount;
    uint256 internal _profileId;
    uint256 internal _tokenIdCounter;

    bool private _initialized;

    // We create the FollowNFT with the pre-computed HUB address before deploying the hub.
    constructor(address hub) {
        HUB = hub;
    }

    /// @inheritdoc IFollowNFT
    function initialize(
        uint256 profileId,
        string calldata name,
        string calldata symbol
    ) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        _profileId = profileId;
        super._initialize(name, symbol);
        emit Events.FollowNFTInitialized(profileId, block.timestamp);
    }

    /// @inheritdoc IFollowNFT
    function mint(address to) external override {
        if (msg.sender != HUB) revert Errors.NotHub();
        uint256 tokenId = ++_tokenIdCounter;
        _mint(to, tokenId);
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
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    _calculateDomainSeparator(),
                    keccak256(
                        abi.encode(
                            DELEGATE_BY_SIG_TYPEHASH,
                            delegator,
                            delegatee,
                            sigNonces[delegator]++,
                            sig.deadline
                        )
                    )
                )
            );
        }
        _validateRecoveredAddress(digest, delegator, sig);
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

        if (snapshotCount == 0) {
            return 0; //balanceOf(user); // Returning zero since this means the user never delegated and has no power
        }

        uint256 lower = 0;
        uint256 upper = snapshotCount - 1;

        // First check most recent balance
        if (_snapshots[user][upper].blockNumber <= blockNumber) {
            return _snapshots[user][upper].value;
        }

        // Next check implicit zero balance
        if (_snapshots[user][lower].blockNumber > blockNumber) {
            return 0;
        }

        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Snapshot memory snapshot = _snapshots[user][center];
            if (snapshot.blockNumber == blockNumber) {
                return snapshot.value;
            } else if (snapshot.blockNumber < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return _snapshots[user][lower].value;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // NOTE: This is *temporary* and will change.
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
        address fromDelegatee = from != address(0) ? _delegates[from] : address(0);
        address toDelegatee = to != address(0) ? _delegates[to] : address(0);

        address followModule = ILensHub(HUB).getFollowModule(_profileId);
        _moveDelegate(fromDelegatee, toDelegatee, 1);
        super._beforeTokenTransfer(from, to, tokenId);
        ILensHub(HUB).emitFollowNFTTransferEvent(_profileId, tokenId, from, to);
        if (followModule != address(0)) {
            IFollowModule(followModule).followModuleTransferHook(_profileId, from, to, tokenId);
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
        // NOTE: Since we start with no delegate, this condition is only fulfilled if a delegation occurred
        if (from != address(0)) {
            uint256 previous = 0;
            uint256 fromSnapshotCount = _snapshotCount[from];

            previous = _snapshots[from][fromSnapshotCount - 1].value;

            _writeSnapshot(from, uint128(previous - amount), fromSnapshotCount);
            emit Events.FollowNFTDelegatedPowerChanged(from, previous - amount, block.timestamp);
        }

        if (to != address(0)) {
            uint256 previous = 0;
            uint256 toSnapshotCount = _snapshotCount[to];

            if (toSnapshotCount != 0) {
                previous = _snapshots[to][toSnapshotCount - 1].value;
            }
            _writeSnapshot(to, uint128(previous + amount), toSnapshotCount);
            emit Events.FollowNFTDelegatedPowerChanged(to, previous + amount, block.timestamp);
        }
    }

    // Passing the snapshot count to prevent reading from storage to fetch it again in case of multiple operations
    function _writeSnapshot(
        address owner,
        uint128 newValue,
        uint256 ownerSnapshotCount
    ) internal {
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
