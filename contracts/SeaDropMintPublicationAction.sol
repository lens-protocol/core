// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IPublicationActionModule} from 'contracts/interfaces/IPublicationActionModule.sol';
import {IModuleGlobals} from 'contracts/interfaces/IModuleGlobals.sol';
import {HubRestricted} from 'contracts/base/HubRestricted.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

// TODO: Move this to Interface file
interface ISeaDrop {
    /**
     * @notice A struct defining public drop data.
     *         Designed to fit efficiently in one storage slot.
     *
     * @param mintPrice                The mint price per token. (Up to 1.2m
     *                                 of native token, e.g. ETH, MATIC)
     * @param startTime                The start time, ensure this is not zero.
     * @param endTIme                  The end time, ensure this is not zero.
     * @param maxTotalMintableByWallet Maximum total number of mints a user is
     *                                 allowed. (The limit for this field is
     *                                 2^16 - 1)
     * @param feeBps                   Fee out of 10_000 basis points to be
     *                                 collected.
     * @param restrictFeeRecipients    If false, allow any fee recipient;
     *                                 if true, check fee recipient is allowed.
     */
    struct PublicDrop {
        uint80 mintPrice;
        uint48 startTime;
        uint48 endTime;
        uint16 maxTotalMintableByWallet;
        uint16 feeBps;
        bool restrictFeeRecipients;
    }

    /**
     * @notice Mint a public drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param feeRecipient     The fee recipient.
     * @param minterIfNotPayer The mint recipient if different than the payer.
     * @param quantity         The number of tokens to mint.
     */
    function mintPublic(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        uint256 quantity
    ) external payable;

    /**
     * @notice Returns the public drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicDrop(address nftContract) external view returns (PublicDrop memory);
}

// TODO: Move this to Interface file
interface IWMATIC is IERC20 {
    function withdraw(uint amountToUnwrap) external;

    function deposit() external payable;
}

contract SeaDropMintPublicationAction is HubRestricted, IPublicationActionModule {
    uint256 constant MAX_BPS = 10_000;

    ISeaDrop public immutable SEADROP;
    IWMATIC public immutable WMATIC;

    IModuleGlobals public immutable MODULE_GLOBALS;

    // TODO: Move this to `Types` when this action is moved to modules repository.
    struct CollectionData {
        address nftCollectionAddress;
        uint16 referrersFeeBps;
    }

    // TODO: Move these to `Errors` when this action is moved to modules repository.
    error WrongMintPaymentAmount();
    error SeaDropFeesNotReceived();
    error FeesDoNotMatch();

    mapping(uint256 profileId => mapping(uint256 pubId => CollectionData collectionData)) internal _collectionDataByPub;

    constructor(address hub, address moduleGlobals, address seaDrop, address wmatic) HubRestricted(hub) {
        MODULE_GLOBALS = IModuleGlobals(moduleGlobals);
        if (!MODULE_GLOBALS.isCurrencyWhitelisted(wmatic)) {
            revert Errors.InitParamsInvalid();
        }
        WMATIC = IWMATIC(wmatic);
        SEADROP = ISeaDrop(seaDrop);
    }

    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address /* transactionExecutor */,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (, uint16 lensTreasuryFeeBps) = MODULE_GLOBALS.getTreasuryData();
        CollectionData memory collectionData = abi.decode(data, (CollectionData));

        _validateFees(
            SEADROP.getPublicDrop(collectionData.nftCollectionAddress),
            lensTreasuryFeeBps,
            collectionData.referrersFeeBps
        );

        _collectionDataByPub[profileId][pubId] = collectionData;
        return data;
    }

    // Function to allow receiving MATIC native currency.
    receive() external payable {}

    function rescaleFees(uint256 profileId, uint256 pubId) external {
        (, uint16 lensTreasuryFeeBps) = MODULE_GLOBALS.getTreasuryData();
        CollectionData storage _collectionData = _collectionDataByPub[profileId][pubId];
        ISeaDrop.PublicDrop memory publicDrop = SEADROP.getPublicDrop(_collectionData.nftCollectionAddress);
        if (publicDrop.feeBps >= lensTreasuryFeeBps) {
            _collectionData.referrersFeeBps = publicDrop.feeBps - lensTreasuryFeeBps;
        }
        // event?
    }

    // A function to allow withdrawing dust and rogue native currency and ERC20 tokens left in this contract to treasury.
    function withdrawToTreasury(address currency) external {
        address lensTreasuryAddress = MODULE_GLOBALS.getTreasury();
        if (currency == address(0)) {
            payable(lensTreasuryAddress).transfer(address(this).balance);
        } else {
            IERC20 erc20Token = IERC20(currency);
            erc20Token.transfer(lensTreasuryAddress, erc20Token.balanceOf(address(this)));
        }
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata processActionParams
    ) external override onlyHub returns (bytes memory) {
        CollectionData memory collectionData = _collectionDataByPub[processActionParams.publicationActedProfileId][
            processActionParams.publicationActedId
        ];

        uint256 quantityToMint = abi.decode(processActionParams.actionModuleData, (uint256));

        ISeaDrop.PublicDrop memory publicDrop = SEADROP.getPublicDrop(collectionData.nftCollectionAddress);

        (address lensTreasuryAddress, uint16 lensTreasuryFeeBps) = MODULE_GLOBALS.getTreasuryData();
        _validateFees(publicDrop, lensTreasuryFeeBps, collectionData.referrersFeeBps);

        uint256 mintPaymentAmount = publicDrop.mintPrice * quantityToMint;
        uint256 expectedFees = (mintPaymentAmount * publicDrop.feeBps) / MAX_BPS;

        uint256 balanceBeforeMinting = address(this).balance;

        // Get the WMATIC to perform the mint payment from the transaction executor.
        WMATIC.transferFrom(processActionParams.executor, address(this), mintPaymentAmount);
        // Unwrap WMATIC into MATIC.
        WMATIC.withdraw(mintPaymentAmount);

        // Now this module holds the mint payment amount in MATIC. Proceeds to perform the mint.
        SEADROP.mintPublic{value: mintPaymentAmount}({
            nftContract: collectionData.nftCollectionAddress,
            feeRecipient: address(this),
            minterIfNotPayer: processActionParams.actorProfileOwner,
            quantity: quantityToMint
        });

        if (expectedFees > 0) {
            uint256 balanceAfterMinting = address(this).balance;

            // We expect the fees to be sent back to this contract.
            if (balanceAfterMinting != balanceBeforeMinting + expectedFees) {
                revert SeaDropFeesNotReceived();
            }

            _distributeFees(expectedFees, mintPaymentAmount, lensTreasuryAddress, collectionData, processActionParams);
        }

        return '';
    }

    function _distributeFees(
        uint256 feesToDistribute,
        uint256 mintPaymentAmount,
        address lensTreasuryAddress,
        CollectionData memory collectionData,
        Types.ProcessActionParams calldata processActionParams
    ) internal {
        // Wrap MATIC back into WMATIC.
        WMATIC.deposit{value: feesToDistribute}();

        uint256 referrersCut = (mintPaymentAmount * collectionData.referrersFeeBps) / MAX_BPS;

        uint256 referrersQuantity = processActionParams.referrerProfileIds.length;
        uint256 feePerReferrer = referrersCut / referrersQuantity;

        if (feePerReferrer > 0) {
            uint256 i;
            // Execute fee payout to referrers (LensHub already validated them).
            while (i < referrersQuantity) {
                address referrer = IERC721(HUB).ownerOf(processActionParams.referrerProfileIds[i]);
                WMATIC.transfer(referrer, feePerReferrer);
                unchecked {
                    ++i;
                }
            }
        }

        // Because we already know that
        //     `publicDrop.feeBps >= lensTreasuryFeeBps + collectionData.referrersFeeBps`
        // then
        //     `feesToDistribute - referrersCut`
        // will be the Lens Treasury Fee plus any fee excess.
        uint256 lensTreasuryCutPlusExcess = feesToDistribute - referrersCut;
        if (lensTreasuryCutPlusExcess > 0) {
            WMATIC.transfer(lensTreasuryAddress, lensTreasuryCutPlusExcess);
        }
    }

    function _validateFees(
        ISeaDrop.PublicDrop memory publicDrop,
        uint256 lensTreasuryFeeBps,
        uint256 referrersFeeBps
    ) internal pure {
        if (publicDrop.mintPrice > 0 && publicDrop.feeBps < lensTreasuryFeeBps + referrersFeeBps) {
            revert FeesDoNotMatch();
        }
    }
}
