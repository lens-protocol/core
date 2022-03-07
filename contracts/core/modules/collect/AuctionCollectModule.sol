// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {DataTypes} from '../../../libraries/DataTypes.sol';
import {Errors} from '../../../libraries/Errors.sol';
import {FeeModuleBase} from '../FeeModuleBase.sol';
import {FollowValidationModuleBase} from '../FollowValidationModuleBase.sol';
import {ICollectModule} from '../../../interfaces/ICollectModule.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ILensHub} from '../../../interfaces/ILensHub.sol';
import {IModuleGlobals} from '../../../interfaces/IModuleGlobals.sol';
import {ModuleBase} from '../ModuleBase.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @notice A struct containing the necessary data to execute collect auctions.
 *
 * @param reservePrice The minimum bid price accepted.
 * @param endTimestamp The UNIX timestamp after which bidding is impossible.
 * @param minTimeAfterBid The minimum time, in seconds, that must always remain between a new bid's timestamp
 * and `endTimestamp`.
 * @param minBidIncrement The minimum amount by which a new bid must overcome the last bid.
 * @param currency The currency in which the bids are denominated.
 * @param winner The current auction's winner.
 * @param recipient The auction's winner bid recipient.
 * @param referralFee The percentage of the fee that will be transferred to the referrer in case of having one.
 * Measured in basis points, each basis point represents 0.01%.
 * @param onlyFollowers Indicates whether followers are the only allowed to bid and collect or not.
 * @param collected Indicates whether the publication has been collected or not.
 * @param bidBalanceOf Maps a given bidder's address to its balance, as a consequence of bidding, held in the module.
 * @param referrerProfileIdOf Maps a given bidder's address to its referrer profile ID. Zero if none. The referrer is
 * set through, and only through, the first bid of each bidder.
 */
struct AuctionData {
    uint256 reservePrice;
    uint256 endTimestamp;
    uint256 minTimeAfterBid;
    uint256 minBidIncrement;
    address currency;
    address winner;
    address recipient;
    uint16 referralFee;
    bool onlyFollowers;
    bool collected;
    mapping(address => uint256) bidBalanceOf;
    mapping(address => uint256) referrerProfileIdOf;
}

contract AuctionCollectModule is ICollectModule, FeeModuleBase, FollowValidationModuleBase {
    using SafeERC20 for IERC20;

    error EndedAuction();
    error ActiveAuction();
    error AuctionWinnerCanNotWithdraw();
    error NothingToWithdraw();
    error InsufficientBidAmount();

    event BidPlaced(
        uint256 referrerProfileId,
        uint256 profileId,
        uint256 pubId,
        uint256 amount,
        address bidder,
        uint256 endTimestamp,
        uint256 timestamp
    );
    event Withdrawn(
        uint256 profileId,
        uint256 pubId,
        uint256 amount,
        address bidder,
        uint256 timestamp
    );

    // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // keccak256('1');
    bytes32 internal constant EIP712_VERSION_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    // keccak256('AuctionCollectModule');
    bytes32 internal constant EIP712_NAME_HASH =
        0xba22081bc5c1d1ec869a162d29727734a7f22077aed8b8d52bc9a23e7c5ed6ef;

    // keccak256('BidWithSig(uint256 profileId,uint256 pubId,uint256 amount,uint256 nonce,uint256 deadline)');
    bytes32 internal constant BID_WITH_SIG_TYPEHASH =
        0x6787ef5fb2ac5e44122548b1bcf4c59afc7bb9c5765aaecc8466ab9f7b5fb63c;

    // keccak256(
    // 'BidWithIncrementWithSig(uint256 profileId,uint256 pubId,uint256 increment,uint256 nonce,uint256 deadline)'
    // );
    bytes32 internal constant BID_WITH_INCREMENT_WITH_SIG_TYPEHASH =
        0xc0719c4adfe9f76d2b91bda41124cb613ea2376a5f853285fb7d54bb6e2505b7;

    // keccak256('WithdrawWithSig(uint256 profileId,uint256 pubId,address bidder,uint256 nonce,uint256 deadline)');
    bytes32 internal constant WITHDRAW_WITH_SIG_TYPEHASH =
        0xefd716178a36bd0583976101fa5e83a249e27de97767f7195cd8d269bdcae8e8;

    mapping(address => uint256) public nonces;

    mapping(uint256 => mapping(uint256 => AuctionData)) internal _dataByPublicationByProfile;

    constructor(address hub, address moduleGlobals) ModuleBase(hub) FeeModuleBase(moduleGlobals) {}

    function initializePublicationCollectModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (
            uint256 reservePrice,
            uint256 endTimestamp,
            uint256 minTimeAfterBid,
            uint256 minBidIncrement,
            address currency,
            address recipient,
            uint16 referralFee,
            bool onlyFollowers
        ) = abi.decode(data, (uint256, uint256, uint256, uint256, address, address, uint16, bool));
        if (
            endTimestamp <= block.timestamp + minTimeAfterBid ||
            !IModuleGlobals(MODULE_GLOBALS).isCurrencyWhitelisted(currency) ||
            recipient == address(0) ||
            referralFee > BPS_MAX ||
            reservePrice < BPS_MAX
        ) revert Errors.InitParamsInvalid();
        _dataByPublicationByProfile[profileId][pubId].reservePrice = reservePrice;
        _dataByPublicationByProfile[profileId][pubId].endTimestamp = endTimestamp;
        _dataByPublicationByProfile[profileId][pubId].minTimeAfterBid = minTimeAfterBid;
        _dataByPublicationByProfile[profileId][pubId].minBidIncrement = minBidIncrement;
        _dataByPublicationByProfile[profileId][pubId].currency = currency;
        _dataByPublicationByProfile[profileId][pubId].recipient = recipient;
        _dataByPublicationByProfile[profileId][pubId].referralFee = referralFee;
        _dataByPublicationByProfile[profileId][pubId].onlyFollowers = onlyFollowers;
        return data;
    }

    function processCollect(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external override onlyHub {
        AuctionData storage auction = _dataByPublicationByProfile[profileId][pubId];
        if (block.timestamp <= auction.endTimestamp) {
            revert ActiveAuction();
        }
        if (
            collector != auction.winner ||
            referrerProfileId != auction.referrerProfileIdOf[collector] ||
            data.length != 0
        ) {
            // Prevent LensHub from emiting `Collected` event with wrong parameters
            revert Errors.ModuleDataMismatch();
        }
        if (auction.collected || auction.winner == address(0)) {
            revert Errors.CollectNotAllowed();
        }
        auction.collected = true;
        if (auction.referrerProfileIdOf[collector] == 0) {
            _processCollect(collector, profileId, pubId);
        } else {
            _processCollectWithReferral(
                auction.referrerProfileIdOf[collector],
                collector,
                profileId,
                pubId
            );
        }
    }

    /**
     * Bids the given amount.
     */
    function bid(
        uint256 profileId,
        uint256 pubId,
        uint256 amount
    ) external {
        (uint256 profileIdPointed, uint256 pubIdPointed) = _getRootPublication(profileId, pubId);
        _bid(profileId, profileIdPointed, pubIdPointed, amount, msg.sender);
    }

    /**
     * Bids the given amount with signature.
     */
    function bidWithSig(
        uint256 profileId,
        uint256 pubId,
        uint256 amount,
        address bidder,
        DataTypes.EIP712Signature calldata sig
    ) external {
        _checkBidSignatureValidity(profileId, pubId, amount, bidder, sig, BID_WITH_SIG_TYPEHASH);
        (uint256 profileIdPointed, uint256 pubIdPointed) = _getRootPublication(profileId, pubId);
        _bid(profileId, profileIdPointed, pubIdPointed, amount, msg.sender);
    }

    /**
     * Bids current price plus an increment to ensure being the new winner after transaction execution.
     */
    function bidWithIncrement(
        uint256 profileId,
        uint256 pubId,
        uint256 increment
    ) external {
        (uint256 profileIdPointed, uint256 pubIdPointed) = _getRootPublication(profileId, pubId);
        AuctionData storage auction = _dataByPublicationByProfile[profileIdPointed][pubIdPointed];
        uint256 currentPrice = auction.winner == address(0)
            ? auction.reservePrice
            : auction.bidBalanceOf[auction.winner];
        _bid(profileId, profileIdPointed, pubIdPointed, currentPrice + increment, msg.sender);
    }

    /**
     * Bids current price plus an increment to ensure being the new winner after transaction execution with signature.
     */
    function bidWithIncrementWithSig(
        uint256 profileId,
        uint256 pubId,
        uint256 increment,
        address bidder,
        DataTypes.EIP712Signature calldata sig
    ) external {
        _checkBidSignatureValidity(
            profileId,
            pubId,
            increment,
            bidder,
            sig,
            BID_WITH_INCREMENT_WITH_SIG_TYPEHASH
        );
        (uint256 profileIdPointed, uint256 pubIdPointed) = _getRootPublication(profileId, pubId);
        AuctionData storage auction = _dataByPublicationByProfile[profileIdPointed][pubIdPointed];
        uint256 currentPrice = auction.winner == address(0)
            ? auction.reservePrice
            : auction.bidBalanceOf[auction.winner];
        _bid(profileId, profileIdPointed, pubIdPointed, currentPrice + increment, msg.sender);
    }

    /**
     * Withdraw the amount deposited through bids if sender is not the auction winner.
     */
    function withdraw(uint256 profileId, uint256 pubId) external {
        _withdraw(profileId, pubId, msg.sender);
    }

    /**
     * Withdraw the amount deposited through bids if sender is not the auction winner; with signature.
     */
    function withdrawWithSig(
        uint256 profileId,
        uint256 pubId,
        address bidder,
        DataTypes.EIP712Signature calldata sig
    ) external {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    _calculateDomainSeparator(),
                    keccak256(
                        abi.encode(
                            WITHDRAW_WITH_SIG_TYPEHASH,
                            profileId,
                            pubId,
                            bidder,
                            nonces[bidder]++,
                            sig.deadline
                        )
                    )
                )
            );
        }
        _validateRecoveredAddress(digest, bidder, sig);
        _withdraw(profileId, pubId, bidder);
    }

    function getAuctionData(uint256 profileId, uint256 pubId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            address,
            address,
            uint16,
            bool,
            bool
        )
    {
        AuctionData storage auction = _dataByPublicationByProfile[profileId][pubId];
        return (
            auction.reservePrice,
            auction.endTimestamp,
            auction.minTimeAfterBid,
            auction.minBidIncrement,
            auction.currency,
            auction.winner,
            auction.recipient,
            auction.referralFee,
            auction.onlyFollowers,
            auction.collected
        );
    }

    function getBidBalanceOf(
        uint256 profileId,
        uint256 pubId,
        address bidder
    ) external view returns (uint256) {
        return _dataByPublicationByProfile[profileId][pubId].bidBalanceOf[bidder];
    }

    function getReferrerProfileIdOf(
        uint256 profileId,
        uint256 pubId,
        address bidder
    ) external view returns (uint256) {
        return _dataByPublicationByProfile[profileId][pubId].referrerProfileIdOf[bidder];
    }

    function _processCollect(
        address collector,
        uint256 profileId,
        uint256 pubId
    ) internal {
        uint256 amount = _dataByPublicationByProfile[profileId][pubId].bidBalanceOf[collector];
        address currency = _dataByPublicationByProfile[profileId][pubId].currency;
        (address treasury, uint16 treasuryFee) = _treasuryData();
        address recipient = _dataByPublicationByProfile[profileId][pubId].recipient;
        uint256 treasuryAmount = (amount * treasuryFee) / BPS_MAX;
        uint256 adjustedAmount = amount - treasuryAmount;
        IERC20(currency).safeTransferFrom(address(this), recipient, adjustedAmount);
        IERC20(currency).safeTransferFrom(address(this), treasury, treasuryAmount);
    }

    function _processCollectWithReferral(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId
    ) internal {
        uint256 amount = _dataByPublicationByProfile[profileId][pubId].bidBalanceOf[collector];
        address currency = _dataByPublicationByProfile[profileId][pubId].currency;
        uint256 referralFee = _dataByPublicationByProfile[profileId][pubId].referralFee;
        address treasury;
        uint256 treasuryAmount;
        // Avoids stack too deep
        {
            uint16 treasuryFee;
            (treasury, treasuryFee) = _treasuryData();
            treasuryAmount = (amount * treasuryFee) / BPS_MAX;
        }
        uint256 adjustedAmount = amount - treasuryAmount;
        if (referralFee != 0) {
            // The reason we levy the referral fee on the adjusted amount is so that referral fees
            // don't bypass the treasury fee, in essence referrals pay their fair share to the treasury.
            uint256 referralAmount = (adjustedAmount * referralFee) / BPS_MAX;
            adjustedAmount = adjustedAmount - referralAmount;
            address referralRecipient = IERC721(HUB).ownerOf(referrerProfileId);
            IERC20(currency).safeTransferFrom(address(this), referralRecipient, referralAmount);
        }
        address recipient = _dataByPublicationByProfile[profileId][pubId].recipient;
        IERC20(currency).safeTransferFrom(address(this), recipient, adjustedAmount);
        IERC20(currency).safeTransferFrom(address(this), treasury, treasuryAmount);
    }

    function _bid(
        uint256 referrerProfileId,
        uint256 profileId,
        uint256 pubId,
        uint256 amount,
        address bidder
    ) internal {
        AuctionData storage auction = _dataByPublicationByProfile[profileId][pubId];
        if (block.timestamp > auction.endTimestamp) {
            revert EndedAuction();
        }
        _checkBidAmountValidity(profileId, pubId, amount);
        if (auction.onlyFollowers) {
            _checkFollowValidity(profileId, msg.sender);
        }
        if (
            auction.referrerProfileIdOf[bidder] == 0 &&
            referrerProfileId != 0 &&
            referrerProfileId != profileId
        ) {
            auction.referrerProfileIdOf[bidder] = referrerProfileId;
        }
        if (auction.endTimestamp - block.timestamp < auction.minTimeAfterBid) {
            auction.endTimestamp = block.timestamp + auction.minTimeAfterBid;
        }
        uint256 amountToPull = amount - auction.bidBalanceOf[bidder];
        auction.bidBalanceOf[bidder] = amount;
        auction.winner = bidder;
        IERC20(auction.currency).safeTransferFrom(bidder, address(this), amountToPull);
        emit BidPlaced(
            auction.referrerProfileIdOf[bidder],
            profileId,
            pubId,
            amount,
            bidder,
            auction.endTimestamp,
            block.timestamp
        );
    }

    function _checkBidAmountValidity(
        uint256 profileId,
        uint256 pubId,
        uint256 amount
    ) internal view {
        AuctionData storage auction = _dataByPublicationByProfile[profileId][pubId];
        bool hasWinner = auction.winner != address(0);
        if (
            (!hasWinner && amount < auction.reservePrice) ||
            (hasWinner &&
                (amount <= auction.bidBalanceOf[auction.winner] ||
                    (auction.minBidIncrement > 0 &&
                        amount - auction.bidBalanceOf[auction.winner] < auction.minBidIncrement)))
        ) {
            revert InsufficientBidAmount();
        }
    }

    function _checkBidSignatureValidity(
        uint256 profileId,
        uint256 pubId,
        uint256 value,
        address bidder,
        DataTypes.EIP712Signature calldata sig,
        bytes32 typehash
    ) internal {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    _calculateDomainSeparator(),
                    keccak256(
                        abi.encode(
                            typehash,
                            profileId,
                            pubId,
                            value,
                            nonces[bidder]++,
                            sig.deadline
                        )
                    )
                )
            );
        }
        _validateRecoveredAddress(digest, bidder, sig);
    }

    function _withdraw(
        uint256 profileId,
        uint256 pubId,
        address bidder
    ) internal {
        AuctionData storage auction = _dataByPublicationByProfile[profileId][pubId];
        if (bidder == auction.winner) {
            revert AuctionWinnerCanNotWithdraw();
        }
        uint256 amountToWithdraw = auction.bidBalanceOf[bidder];
        if (amountToWithdraw == 0) {
            // Avoid sending a zero-amount `Withdrawn` event
            revert NothingToWithdraw();
        }
        auction.bidBalanceOf[bidder] = 0;
        IERC20(auction.currency).safeTransferFrom(address(this), bidder, amountToWithdraw);
        emit Withdrawn(profileId, pubId, amountToWithdraw, bidder, block.timestamp);
    }

    function _getRootPublication(uint256 profileId, uint256 pubId)
        internal
        view
        returns (uint256, uint256)
    {
        DataTypes.PublicationStruct memory publication = ILensHub(HUB).getPub(profileId, pubId);
        if (publication.collectModule != address(0)) {
            return (profileId, pubId);
        } else {
            if (publication.profileIdPointed == 0) {
                revert Errors.PublicationDoesNotExist();
            }
            return (publication.profileIdPointed, publication.pubIdPointed);
        }
    }

    function _validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        if (sig.deadline < block.timestamp) {
            revert Errors.SignatureExpired();
        }
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        if (recoveredAddress == address(0) || recoveredAddress != expectedAddress) {
            revert Errors.SignatureInvalid();
        }
    }

    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    EIP712_NAME_HASH,
                    EIP712_VERSION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }
}
