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
 *      Take into account that bid balances can be withdrawn by any bidder as long as he is not winning the auction.
 * @param referrerProfileIdOf Maps a given bidder's address to its referrer profile ID. The referrer is set through,
 * and only through, the first bid of each bidder.
 *      Zero value represents no referral but, as bidders can withdraw funds when they are not winning the auction,
 * bidBalanceOf can't be used to determine if an address has already bidded or not (remember, we are setting the
 * referrer only through the first bid).
 *      Thus, a special case of referrerProfileIdOf matching publication's profileId means that there is no referral but
 * first bid was already done. Having this special case allows us to avoid an extra struct field saving storage costs.
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
    bool feeProcessed;
    mapping(address => uint256) bidBalanceOf;
    mapping(address => uint256) referrerProfileIdOf;
}

/**
 * @title AuctionCollectModule
 * @author Lens Protocol
 *
 * @notice This module works by creating an auction for the underlying publication. After the auction ends, only the
 * auction winner is allowed to collect the publication.
 *
 */
contract AuctionCollectModule is ICollectModule, FeeModuleBase, FollowValidationModuleBase {
    using SafeERC20 for IERC20;

    error ActiveAuction();
    error AuctionWinnerCanNotWithdraw();
    error EndedAuction();
    error FeeAlreadyProcessed();
    error InsufficientBidAmount();
    error InvalidBidder();
    error NothingToWithdraw();

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
    event FeeProcessed(uint256 profileId, uint256 pubId, uint256 timestamp);

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

    /**
     * @dev See `AuctionData` struct's natspec in order to understand `data` decoded values.
     *
     * @inheritdoc ICollectModule
     */
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
        AuctionData storage auction = _dataByPublicationByProfile[profileId][pubId];
        auction.reservePrice = reservePrice;
        auction.endTimestamp = endTimestamp;
        auction.minTimeAfterBid = minTimeAfterBid;
        auction.minBidIncrement = minBidIncrement;
        auction.currency = currency;
        auction.recipient = recipient;
        auction.referralFee = referralFee;
        auction.onlyFollowers = onlyFollowers;
        return data;
    }

    /**
     * @notice Processes a collect action for the given publication, this can only be called by the hub.
     *
     * @dev Process the collect by ensuring:
     *  1. Underlying publication's auction has finished and has a winner.
     *  2. Parameters passed matches expected values (collector is the winner, correct referral info & no custom data).
     *  3. Publication has not been collected yet.
     * Processing collect fees here depends on if they were executed through `processCollectFee` function or not.
     *
     * @inheritdoc ICollectModule
     */
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
            referrerProfileId != _getReferrerProfileIdOf(auction, profileId, collector) ||
            data.length != 0
        ) {
            // Prevent LensHub from emiting `Collected` event with wrong parameters
            revert Errors.ModuleDataMismatch();
        }
        if (auction.collected || auction.winner == address(0)) {
            revert Errors.CollectNotAllowed();
        }
        auction.collected = true;
        if (!auction.feeProcessed) {
            _processCollectFee(profileId, pubId);
        }
    }

    /**
     * @notice Processes the collect fees using the auction winning bid funds and taking into account referrer and
     * treasury fees if necessary.
     *
     * @dev This function allows anyone to process the collect fees, not needing to wait for `processCollect` to be
     * called, as long as the auction has finished, has a winner and the publication has not been collected yet.
     * Why is this function necessary? Suppose someone wins the auction, but for some reason never calls the LensHub's
     * `collect`. That would make `processCollect` of this module never been called and, consequently, collect wouldn't
     * be processed, locking the fees in this contract forever.
     *
     * @param profileId The token ID of the profile associated with the underlying publication.
     * @param pubId The publication ID associated with the underlying publication.
     */
    function processCollectFee(uint256 profileId, uint256 pubId) external {
        AuctionData storage auction = _dataByPublicationByProfile[profileId][pubId];
        if (block.timestamp <= auction.endTimestamp) {
            revert ActiveAuction();
        }
        address winner = auction.winner;
        if (auction.feeProcessed || winner == address(0)) {
            revert FeeAlreadyProcessed();
        }
        _processCollectFee(profileId, pubId);
    }

    /**
     * @notice Offers a bid by the given amount on the given publication's auction. If the publication is a mirror,
     * the pointed publication auction will be used, setting the mirror's profileId as referrer if it's the first bid
     * in the auction.
     * Transaction will fail if the bid offered is below auction's current best price.
     *
     * @dev It will pull the tokens from the bidder to ensure the collect fees can be processed if the bidder ends up
     * being the winner after auction ended. If a better bid appears in the future, funds can be withdrawn through the
     * `withdraw` function.
     * If the bidder has already bidded before and tokens are still in the contract, only the difference will be pulled.
     *
     * @param profileId The token ID of the profile associated with the publication, could be a mirror.
     * @param pubId The publication ID associated with the publication, could be a mirror.
     * @param amount The bid amount to offer.
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
     * @notice Using EIP-712 signatures, offers a bid by the given amount on the given publication's auction.
     * If the publication is a mirror, the pointed publication auction will be used, setting the mirror's profileId
     * as referrer if it's the first bid in the auction.
     * Transaction will fail if the bid offered is below auction's current best price.
     *
     * @dev It will pull the tokens from the bidder to ensure the collect fees can be processed if the bidder ends up
     * being the winner after auction ended. If a better bid appears in the future, funds can be withdrawn through the
     * `withdraw` function.
     * If the bidder has already bidded before and tokens are still in the contract, only the difference will be pulled.
     *
     * @param profileId The token ID of the profile associated with the publication, could be a mirror.
     * @param pubId The publication ID associated with the publication, could be a mirror.
     * @param amount The bid amount to offer.
     */
    function bidWithSig(
        uint256 profileId,
        uint256 pubId,
        uint256 amount,
        address bidder,
        DataTypes.EIP712Signature calldata sig
    ) external {
        _validateBidSignature(profileId, pubId, amount, bidder, sig, BID_WITH_SIG_TYPEHASH);
        (uint256 profileIdPointed, uint256 pubIdPointed) = _getRootPublication(profileId, pubId);
        _bid(profileId, profileIdPointed, pubIdPointed, amount, msg.sender);
    }

    /**
     * @notice Offers a bid by the auction's curreny best price plus the given increment, ensuring the bidder will
     * become the auction's winner after this transaction execution.
     * If the publication is a mirror, the pointed publication auction will be used, setting the mirror's profileId as
     * referrer if it's the first bid in the auction.
     *
     * @dev It will pull the tokens from the bidder to ensure the collect fees can be processed if the bidder ends up
     * being the winner after auction ended. If a better bid appears in the future, funds can be withdrawn through the
     * `withdraw` function.
     * If the bidder has already bidded before and tokens are still in the contract, only the difference will be pulled.
     *
     * @param profileId The token ID of the profile associated with the publication, could be a mirror.
     * @param pubId The publication ID associated with the publication, could be a mirror.
     * @param increment The amount to be incremented over the auction's current best price when offering the bid.
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
     * @notice Using EIP-712 signatures, offers a bid by the auction's curreny best price plus the given increment,
     * ensuring the bidder will become the auction's winner after this transaction execution.
     * If the publication is a mirror, the pointed publication auction will be used, setting the mirror's profileId as
     * referrer if it's the first bid in the auction.
     *
     * @dev It will pull the tokens from the bidder to ensure the collect fees can be processed if the bidder ends up
     * being the winner after auction ended. If a better bid appears in the future, funds can be withdrawn through the
     * `withdraw` function.
     * If the bidder has already bidded before and tokens are still in the contract, only the difference will be pulled.
     *
     * @param profileId The token ID of the profile associated with the publication, could be a mirror.
     * @param pubId The publication ID associated with the publication, could be a mirror.
     * @param increment The amount to be incremented over the auction's current best price when offering the bid.
     * @param bidder The bidder address, who must be the signer of the EIP-712 signature.
     * @param sig The EIP-712 signature data.
     */
    function bidWithIncrementWithSig(
        uint256 profileId,
        uint256 pubId,
        uint256 increment,
        address bidder,
        DataTypes.EIP712Signature calldata sig
    ) external {
        _validateBidSignature(
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
     * @notice Withdraws the amount deposited through bids if the sender is not the auction's current winner.
     *
     * @param profileId The token ID of the profile associated with the underlying publication.
     * @param pubId The publication ID associated with the underlying publication.
     */
    function withdraw(uint256 profileId, uint256 pubId) external {
        _withdraw(profileId, pubId, msg.sender);
    }

    /**
     * @notice Using EIP-712 signatures, withdraws the amount deposited through bids if the sender is not the auction's
     * current winner.
     *
     * @param profileId The token ID of the profile associated with the underlying publication.
     * @param pubId The publication ID associated with the underlying publication.
     * @param bidder The bidder address willing to withdraw funds, who must be the signer of the EIP-712 signature.
     * @param sig The EIP-712 signature data.
     */
    function withdrawWithSig(
        uint256 profileId,
        uint256 pubId,
        address bidder,
        DataTypes.EIP712Signature calldata sig
    ) external {
        _validateRecoveredAddress(
            _calculateDigest(
                abi.encode(
                    WITHDRAW_WITH_SIG_TYPEHASH,
                    profileId,
                    pubId,
                    bidder,
                    nonces[bidder]++,
                    sig.deadline
                )
            ),
            bidder,
            sig
        );
        _withdraw(profileId, pubId, bidder);
    }

    /**
     * @notice Returns the auction data associated with the given publication.
     *
     * @param profileId The token ID of the profile associated with the underlying publication.
     * @param pubId The publication ID associated with the underlying publication.
     *
     * @return A tuple with `AuctionData` struct's fields excepting `bidBalanceOf` and `referrerProfileIdOf` mappings.
     */
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

    /**
     * @notice Returns the amount of tokens held in the contract, deposited by the given bidder through bids in the
     * given publication's auction.
     *
     * @param profileId The token ID of the profile associated with the underlying publication.
     * @param pubId The publication ID associated with the underlying publication.
     * @param bidder The address which the bid balance should be returned.
     */
    function getBidBalanceOf(
        uint256 profileId,
        uint256 pubId,
        address bidder
    ) external view returns (uint256) {
        return _dataByPublicationByProfile[profileId][pubId].bidBalanceOf[bidder];
    }

    /**
     * @notice Returns the referrer profile in the given publication's auction.
     *
     * @param profileId The token ID of the profile associated with the underlying publication.
     * @param pubId The publication ID associated with the underlying publication.
     * @param bidder The address which the referrer profile should be returned.
     */
    function getReferrerProfileIdOf(
        uint256 profileId,
        uint256 pubId,
        address bidder
    ) external view returns (uint256) {
        return
            _getReferrerProfileIdOf(
                _dataByPublicationByProfile[profileId][pubId],
                profileId,
                bidder
            );
    }

    /**
     * See `AuctionData` struct's referrerProfileIdOf param natspec to understand the motivation behind this function.
     */
    function _getReferrerProfileIdOf(
        AuctionData storage auction,
        uint256 profileId,
        address bidder
    ) internal view returns (uint256) {
        uint256 referrerProfileId = auction.referrerProfileIdOf[bidder];
        return referrerProfileId == profileId ? 0 : referrerProfileId;
    }

    function _processCollectFee(uint256 profileId, uint256 pubId) internal {
        AuctionData storage auction = _dataByPublicationByProfile[profileId][pubId];
        address winner = auction.winner;
        auction.feeProcessed = true;
        uint256 referrerProfileId = _getReferrerProfileIdOf(auction, profileId, winner);
        if (referrerProfileId == 0) {
            _processCollectFeeWithoutReferral(auction);
        } else {
            _processCollectFeeWithReferral(auction);
        }
        emit FeeProcessed(profileId, pubId, block.timestamp);
    }

    function _processCollectFeeWithoutReferral(AuctionData storage auction) internal {
        uint256 amount = auction.bidBalanceOf[auction.winner];
        address currency = auction.currency;
        (address treasury, uint16 treasuryFee) = _treasuryData();
        uint256 treasuryAmount = (amount * treasuryFee) / BPS_MAX;
        uint256 adjustedAmount = amount - treasuryAmount;
        IERC20(currency).safeTransferFrom(address(this), auction.recipient, adjustedAmount);
        IERC20(currency).safeTransferFrom(address(this), treasury, treasuryAmount);
    }

    function _processCollectFeeWithReferral(AuctionData storage auction) internal {
        address collector = auction.winner;
        uint256 amount = auction.bidBalanceOf[collector];
        address currency = auction.currency;
        uint256 referralFee = auction.referralFee;
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
            address referralRecipient = IERC721(HUB).ownerOf(
                auction.referrerProfileIdOf[collector]
            );
            IERC20(currency).safeTransferFrom(address(this), referralRecipient, referralAmount);
        }
        address recipient = auction.recipient;
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
        if (
            bidder == address(0) ||
            bidder == auction.recipient ||
            bidder == IERC721(HUB).ownerOf(profileId)
        ) {
            revert InvalidBidder();
        }
        _validateBidAmount(auction, amount);
        if (auction.onlyFollowers) {
            _checkFollowValidity(profileId, msg.sender);
        }
        if (auction.referrerProfileIdOf[bidder] == 0) {
            _setReferrerProfileId(auction, referrerProfileId, profileId, bidder);
        }
        if (auction.endTimestamp - block.timestamp < auction.minTimeAfterBid) {
            auction.endTimestamp = block.timestamp + auction.minTimeAfterBid;
        }
        uint256 amountToPull = amount - auction.bidBalanceOf[bidder];
        auction.bidBalanceOf[bidder] = amount;
        auction.winner = bidder;
        IERC20(auction.currency).safeTransferFrom(bidder, address(this), amountToPull);
        emit BidPlaced(
            _getReferrerProfileIdOf(auction, profileId, bidder),
            profileId,
            pubId,
            amount,
            bidder,
            auction.endTimestamp,
            block.timestamp
        );
    }

    function _setReferrerProfileId(
        AuctionData storage auction,
        uint256 referrerProfileId,
        uint256 profileId,
        address bidder
    ) internal {
        if (
            referrerProfileId != 0 &&
            referrerProfileId != profileId &&
            bidder != IERC721(HUB).ownerOf(referrerProfileId)
        ) {
            auction.referrerProfileIdOf[bidder] = referrerProfileId;
        } else {
            // Special case to set no referral but signaling that first bid was already done.
            // See `referrerProfileIdOf` param description at `AuctionData` struct's natspec.
            auction.referrerProfileIdOf[bidder] = profileId;
        }
    }

    function _validateBidAmount(AuctionData storage auction, uint256 amount) internal view {
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

    function _validateBidSignature(
        uint256 profileId,
        uint256 pubId,
        uint256 value,
        address bidder,
        DataTypes.EIP712Signature calldata sig,
        bytes32 typehash
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                abi.encode(typehash, profileId, pubId, value, nonces[bidder]++, sig.deadline)
            ),
            bidder,
            sig
        );
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

    function _calculateDigest(bytes memory message) internal view returns (bytes32) {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked('\x19\x01', _calculateDomainSeparator(), keccak256(message))
            );
        }
        return digest;
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
