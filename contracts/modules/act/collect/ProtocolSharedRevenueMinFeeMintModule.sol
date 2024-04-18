// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {BaseFeeCollectModule} from 'contracts/modules/act/collect/base/BaseFeeCollectModule.sol';
import {BaseFeeCollectModuleInitData, BaseProfilePublicationData} from 'contracts/modules/interfaces/IBaseFeeCollectModule.sol';
import {ICollectModule} from 'contracts/modules/interfaces/ICollectModule.sol';
import {LensModuleMetadataInitializable} from 'contracts/modules/LensModuleMetadataInitializable.sol';
import {LensModule} from 'contracts/modules/LensModule.sol';
import {ModuleTypes} from 'contracts/modules/libraries/constants/ModuleTypes.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Errors} from 'contracts/modules/constants/Errors.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

struct ProtocolSharedRevenueMinFeeMintModuleInitData {
    uint160 amount;
    uint96 collectLimit;
    address currency;
    uint96 currentCollects;
    address recipient;
    uint16 referralFee;
    bool followerOnly;
    uint72 endTimestamp;
    address creatorClient;
}

struct ProtocolSharedRevenueMinFeeMintModulePublicationData {
    uint160 amount;
    uint96 collectLimit;
    address currency;
    uint96 currentCollects;
    address recipient;
    uint16 referralFee;
    bool followerOnly;
    uint72 endTimestamp;
    address creatorClient;
}

// Splits (in BPS)
struct ProtocolSharedRevenueDistribution {
    uint16 creatorSplit;
    uint16 protocolSplit;
    uint16 creatorClientSplit;
    uint16 executorClientSplit;
}

/**
 * @title ProtocolSharedRevenueMinFeeMint
 * @author Lens Protocol
 *
 * @notice This is a simple Lens CollectModule implementation, allowing customization of time to collect,
 * number of collects and whether only followers can collect.
 *
 * You can build your own collect modules by inheriting from BaseFeeCollectModule and adding your
 * functionality along with getPublicationData function.
 */
contract ProtocolSharedRevenueMinFeeMintModule is BaseFeeCollectModule, LensModuleMetadataInitializable {
    using SafeERC20 for IERC20;

    address mintFeeToken;
    uint256 mintFeeAmount;
    ProtocolSharedRevenueDistribution protocolSharedRevenueDistribution;

    mapping(uint256 profileId => mapping(uint256 pubId => address creatorClient))
        internal _creatorClientByPublicationByProfile;

    constructor(
        address hub,
        address actionModule,
        address moduleRegistry,
        address moduleOwner
    ) BaseFeeCollectModule(hub, actionModule, moduleRegistry) LensModuleMetadataInitializable(moduleOwner) {}

    /**
     * @inheritdoc ICollectModule
     * @notice This collect module levies a fee on collects and supports referrals. Thus, we need to decode data.
     * @param data The arbitrary data parameter, decoded into BaseFeeCollectModuleInitData struct:
     *        amount: The collecting cost associated with this publication. 0 for free collect.
     *        collectLimit: The maximum number of collects for this publication. 0 for no limit.
     *        currency: The currency associated with this publication.
     *        referralFee: The referral fee associated with this publication.
     *        followerOnly: True if only followers of publisher may collect the post.
     *        endTimestamp: The end timestamp after which collecting is impossible. 0 for no expiry.
     *        recipient: Recipient of collect fees.
     *
     * @return An abi encoded bytes parameter, which is the same as the passed data parameter.
     */
    function initializePublicationCollectModule(
        uint256 profileId,
        uint256 pubId,
        address /* transactionExecutor */,
        bytes calldata data
    ) external override onlyActionModule returns (bytes memory) {
        ProtocolSharedRevenueMinFeeMintModuleInitData memory initData = abi.decode(
            data,
            (ProtocolSharedRevenueMinFeeMintModuleInitData)
        );

        BaseFeeCollectModuleInitData memory baseInitData = BaseFeeCollectModuleInitData({
            amount: initData.amount,
            collectLimit: initData.collectLimit,
            currency: initData.currency,
            referralFee: initData.referralFee,
            followerOnly: initData.followerOnly,
            endTimestamp: initData.endTimestamp,
            recipient: initData.recipient
        });

        if (initData.creatorClient != address(0)) {
            _creatorClientByPublicationByProfile[profileId][pubId] = initData.creatorClient;
        }

        _validateBaseInitData(baseInitData);
        _storeBasePublicationCollectParameters(profileId, pubId, baseInitData);
        return '';
    }

    function processCollect(
        ModuleTypes.ProcessCollectParams calldata processCollectParams
    ) external override onlyActionModule returns (bytes memory) {
        if (
            _dataByPublicationByProfile[processCollectParams.publicationCollectedProfileId][
                processCollectParams.publicationCollectedId
            ].amount == 0
        ) {
            _handleMintFee(processCollectParams);
        }

        // Regular processCollect:

        _validateAndStoreCollect(processCollectParams);

        if (processCollectParams.referrerProfileIds.length == 0) {
            _processCollect(processCollectParams);
        } else {
            _processCollectWithReferral(processCollectParams);
        }
        return '';
    }

    // Internal functions

    function _handleMintFee(ModuleTypes.ProcessCollectParams calldata processCollectParams) internal {
        if (mintFeeAmount == 0) {
            return;
        }
        address creator = ILensHub(HUB).ownerOf(processCollectParams.publicationCollectedProfileId);
        uint256 creatorAmount = (mintFeeAmount * protocolSharedRevenueDistribution.creatorSplit) / 10000;

        address protocol = ILensHub(HUB).getTreasury();
        uint256 protocolAmount = (mintFeeAmount * protocolSharedRevenueDistribution.protocolSplit) / 10000;

        address creatorClient = _creatorClientByPublicationByProfile[
            processCollectParams.publicationCollectedProfileId
        ][processCollectParams.publicationCollectedId];
        uint256 creatorClientAmount = (mintFeeAmount * protocolSharedRevenueDistribution.creatorClientSplit) / 10000;

        if (creatorClient != address(0)) {
            IERC20(mintFeeToken).safeTransferFrom(
                processCollectParams.transactionExecutor,
                creatorClient,
                creatorClientAmount
            );
        } else {
            // If there's no creatorClient specified - we give that amount to the publication creator
            creatorAmount += creatorClientAmount;
        }

        (, , address executorClient) = abi.decode(processCollectParams.data, (address, uint256, address));
        uint256 executorClientAmount = (mintFeeAmount * protocolSharedRevenueDistribution.executorClientSplit) / 10000;

        if (executorClient != address(0)) {
            IERC20(mintFeeToken).safeTransferFrom(
                processCollectParams.transactionExecutor,
                executorClient,
                executorClientAmount
            );
        } else {
            // If there's no creatorClient specified - we give that amount to the publication creator
            creatorAmount += executorClientAmount;
        }

        IERC20(mintFeeToken).safeTransferFrom(processCollectParams.transactionExecutor, creator, creatorAmount);
        IERC20(mintFeeToken).safeTransferFrom(processCollectParams.transactionExecutor, protocol, protocolAmount);
    }

    function _validateDataIsExpected(bytes calldata data, address currency, uint256 amount) internal pure override {
        (address decodedCurrency, uint256 decodedAmount, ) = abi.decode(data, (address, uint256, address));
        if (decodedAmount != amount || decodedCurrency != currency) {
            revert Errors.ModuleDataMismatch();
        }
    }

    // OnlyOwner functions

    function setMintFeeParams(address token, uint256 amount) external onlyOwner {
        if (amount > 0 && token == address(0)) {
            revert Errors.InvalidParams();
        }
        mintFeeToken = token;
        mintFeeAmount = amount;
    }

    function setProtocolSharedRevenueDistribution(
        ProtocolSharedRevenueDistribution memory distribution
    ) external onlyOwner {
        if (
            distribution.creatorSplit +
                distribution.protocolSplit +
                distribution.creatorClientSplit +
                distribution.executorClientSplit !=
            BPS_MAX
        ) {
            revert Errors.InvalidParams();
        }
        protocolSharedRevenueDistribution = distribution;
    }

    // Getters

    function getMintFeeParams() external view returns (address, uint256) {
        return (mintFeeToken, mintFeeAmount);
    }

    function getProtocolSharedRevenueDistribution() external view returns (ProtocolSharedRevenueDistribution memory) {
        return protocolSharedRevenueDistribution;
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param profileId The token ID of the profile mapped to the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return The BaseProfilePublicationData struct mapped to that publication.
     */
    function getPublicationData(
        uint256 profileId,
        uint256 pubId
    ) external view returns (ProtocolSharedRevenueMinFeeMintModulePublicationData memory) {
        BaseProfilePublicationData memory baseData = getBasePublicationData(profileId, pubId);
        address creatorClient = _creatorClientByPublicationByProfile[profileId][pubId];
        return
            ProtocolSharedRevenueMinFeeMintModulePublicationData({
                amount: baseData.amount,
                collectLimit: baseData.collectLimit,
                currency: baseData.currency,
                currentCollects: baseData.currentCollects,
                recipient: baseData.recipient,
                referralFee: baseData.referralFee,
                followerOnly: baseData.followerOnly,
                endTimestamp: baseData.endTimestamp,
                creatorClient: creatorClient
            });
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public pure override(BaseFeeCollectModule, LensModule) returns (bool) {
        return BaseFeeCollectModule.supportsInterface(interfaceID) || LensModule.supportsInterface(interfaceID);
    }
}
