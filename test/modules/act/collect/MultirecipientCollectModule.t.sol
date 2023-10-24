// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {MultirecipientCollectModuleBase} from 'test/modules/act/collect/MultirecipientCollectModule.base.t.sol';
import {IBaseFeeCollectModule} from 'contracts/modules/interfaces/IBaseFeeCollectModule.sol';
import {RecipientSplitCannotBeZero, TooManyRecipients, InvalidRecipientSplits, MultirecipientFeeCollectProfilePublicationData, MultirecipientFeeCollectModuleInitData, RecipientData, MultirecipientFeeCollectModule} from 'contracts/modules/act/collect/MultirecipientFeeCollectModule.sol';
import {BaseFeeCollectModule_Initialization, BaseFeeCollectModule_ProcessCollect, BaseFeeCollectModule_FeeDistribution} from 'test/modules/act/collect/BaseFeeCollectModule.t.sol';
import {BaseFeeCollectModuleBase} from 'test/modules/act/collect/BaseFeeCollectModule.base.t.sol';
import {Errors as ModuleErrors} from 'contracts/modules/constants/Errors.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {ModuleTypes} from 'contracts/modules/libraries/constants/ModuleTypes.sol';

/////////
// Publication Creation with InheritedFeeCollectModule
//
contract MultirecipientCollectModule_Initialization is
    MultirecipientCollectModuleBase,
    BaseFeeCollectModule_Initialization
{
    function setUp() public override(MultirecipientCollectModuleBase, BaseFeeCollectModuleBase) {
        MultirecipientCollectModuleBase.setUp();
    }

    function getEncodedInitData()
        internal
        override(MultirecipientCollectModuleBase, BaseFeeCollectModuleBase)
        returns (bytes memory)
    {
        return MultirecipientCollectModuleBase.getEncodedInitData();
    }

    function testCannotInitializeWithNonWhitelistedCurrency(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));

        exampleInitData.amount = 0;

        vm.expectRevert(ModuleErrors.InitParamsInvalid.selector);
        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );
    }

    function testCannotPostWithoutRecipients(uint256 profileId, uint256 pubId, address transactionExecutor) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        delete multirecipientExampleInitData.recipients;

        vm.expectRevert(ModuleErrors.InitParamsInvalid.selector);
        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            abi.encode(multirecipientExampleInitData)
        );
    }

    function testCannotPostWithOneRecipient(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        address recipient,
        uint16 split
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(recipient != address(0));
        split = uint16(bound(split, 0, BPS_MAX));

        delete multirecipientExampleInitData.recipients;
        multirecipientExampleInitData.recipients.push(RecipientData({recipient: recipient, split: split}));

        vm.expectRevert(ModuleErrors.InitParamsInvalid.selector);
        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );
    }

    function testCannotPostWithRecipientSplitsSumNotEqualToBPS_MAX(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        address recipient,
        uint256 recipientsNumber,
        uint16 split1,
        uint16 split2,
        uint16 split3,
        uint16 split4,
        uint16 split5
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(recipient != address(0));
        recipientsNumber = bound(recipientsNumber, 2, MAX_RECIPIENTS);
        split1 = uint16(bound(split1, 1, BPS_MAX - recipientsNumber));
        split2 = uint16(bound(split2, 1, BPS_MAX - recipientsNumber));
        split3 = uint16(bound(split3, 1, BPS_MAX - recipientsNumber));
        split4 = uint16(bound(split4, 1, BPS_MAX - recipientsNumber));
        split5 = uint16(bound(split5, 1, BPS_MAX - recipientsNumber));

        vm.assume(split1 + split2 + split3 + split4 + split5 < BPS_MAX);

        delete multirecipientExampleInitData.recipients;
        assertEq(multirecipientExampleInitData.recipients.length, 0);

        uint16[] memory splits = new uint16[](5);
        splits[0] = split1;
        splits[1] = split2;
        splits[2] = split3;
        splits[3] = split4;
        splits[4] = split5;

        uint16 splitUsed;
        for (uint256 i = 0; i < MAX_RECIPIENTS; i++) {
            splitUsed += splits[i];
            multirecipientExampleInitData.recipients.push(RecipientData({recipient: recipient, split: splits[i]}));
        }
        assert(splitUsed < BPS_MAX);

        vm.expectRevert(InvalidRecipientSplits.selector);
        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );
    }

    function testCannotPostWithZeroRecipientSplit(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        uint256 recipientsNumber,
        address recipient,
        bool splitIsZero1,
        bool splitIsZero2,
        bool splitIsZero3,
        bool splitIsZero4,
        bool splitIsZero5
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(recipient != address(0));
        recipientsNumber = bound(recipientsNumber, 1, MAX_RECIPIENTS);

        bool[] memory splitsAreZero = new bool[](5);
        splitsAreZero[0] = splitIsZero1;
        splitsAreZero[1] = splitIsZero2;
        splitsAreZero[2] = splitIsZero3;
        splitsAreZero[3] = splitIsZero4;
        splitsAreZero[4] = splitIsZero5;

        delete multirecipientExampleInitData.recipients;
        assertEq(multirecipientExampleInitData.recipients.length, 0);

        uint16 splitUsed;
        for (uint256 i = 0; i < MAX_RECIPIENTS; i++) {
            multirecipientExampleInitData.recipients.push(
                RecipientData({recipient: recipient, split: splitsAreZero[i] ? 0 : 2000})
            );
            splitUsed += splitsAreZero[i] ? 0 : 2000;
        }
        vm.assume(splitUsed < BPS_MAX);

        vm.expectRevert(RecipientSplitCannotBeZero.selector);
        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );
    }

    // Scenarios

    function testInitializeWithCorrectInitData(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        uint160 amount,
        uint96 collectLimit,
        address whitelistedCurrency,
        uint16 referralFee,
        bool followerOnly,
        uint72 currentTimestamp,
        uint72 endTimestamp,
        address recipient
    ) public override {}

    function testInitializeWithCorrectInitData(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        uint160 amount,
        uint96 collectLimit,
        address whitelistedCurrency,
        uint16 referralFee,
        bool followerOnly,
        uint72 currentTimestamp,
        uint72 endTimestamp
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(amount != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(whitelistedCurrency != address(0));

        if (endTimestamp > 0) {
            currentTimestamp = uint72(bound(uint256(currentTimestamp), 0, uint256(endTimestamp) - 1));
        }
        vm.warp(currentTimestamp);

        multirecipientExampleInitData.amount = amount;
        multirecipientExampleInitData.collectLimit = collectLimit;
        multirecipientExampleInitData.currency = whitelistedCurrency;
        multirecipientExampleInitData.referralFee = uint16(bound(uint256(referralFee), 0, BPS_MAX));
        multirecipientExampleInitData.followerOnly = followerOnly;
        multirecipientExampleInitData.endTimestamp = endTimestamp;

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );

        MultirecipientFeeCollectProfilePublicationData memory fetchedData = MultirecipientFeeCollectModule(
            baseFeeCollectModule
        ).getPublicationData(profileId, pubId);
        assertEq(fetchedData.currency, multirecipientExampleInitData.currency, 'MockCurrency initialization mismatch');
        assertEq(fetchedData.amount, multirecipientExampleInitData.amount, 'Amount initialization mismatch');
        assertEq(
            fetchedData.referralFee,
            multirecipientExampleInitData.referralFee,
            'Referral fee initialization mismatch'
        );
        assertEq(
            fetchedData.followerOnly,
            multirecipientExampleInitData.followerOnly,
            'Follower only initialization mismatch'
        );
        assertEq(
            fetchedData.endTimestamp,
            multirecipientExampleInitData.endTimestamp,
            'End timestamp initialization mismatch'
        );
        assertEq(
            fetchedData.collectLimit,
            multirecipientExampleInitData.collectLimit,
            'Collect limit initialization mismatch'
        );
        assertEq(
            fetchedData.recipients.length,
            multirecipientExampleInitData.recipients.length,
            'Recipient length initialization mismatch'
        );

        for (uint256 i = 0; i < fetchedData.recipients.length; i++) {
            assertEq(
                fetchedData.recipients[i].recipient,
                multirecipientExampleInitData.recipients[i].recipient,
                'Recipient address initialization mismatch'
            );
            assertEq(
                fetchedData.recipients[i].split,
                multirecipientExampleInitData.recipients[i].split,
                'Recipient split initialization mismatch'
            );
        }
    }
}

//////////////
// Collect with InheritedFeeCollectModule
//
contract MultirecipientCollectModule_ProcessCollect is
    MultirecipientCollectModuleBase,
    BaseFeeCollectModule_ProcessCollect
{
    function testMultirecipientCollectModule_Collect() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public override(MultirecipientCollectModuleBase, BaseFeeCollectModuleBase) {
        MultirecipientCollectModuleBase.setUp();
    }

    function getEncodedInitData()
        internal
        override(MultirecipientCollectModuleBase, BaseFeeCollectModuleBase)
        returns (bytes memory)
    {
        return MultirecipientCollectModuleBase.getEncodedInitData();
    }

    function testCanCollectIfAllConditionsAreMet(
        uint256 pubId,
        address transactionExecutor,
        uint160 amount,
        uint96 collectLimit,
        uint16 referralFee,
        bool followerOnly,
        uint72 currentTimestamp,
        uint72 endTimestamp,
        address recipient,
        address collectorProfileOwner
    ) public override {
        vm.assume(amount > 0);
        super.testCanCollectIfAllConditionsAreMet(
            pubId,
            transactionExecutor,
            amount,
            collectLimit,
            referralFee,
            followerOnly,
            currentTimestamp,
            endTimestamp,
            recipient,
            collectorProfileOwner
        );
    }

    function testCannotProcessCollect_PassingWrongAmountInData(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        uint160 amount,
        uint160 passedAmount,
        uint256 collectorProfileId,
        address collectorProfileOwner
    ) public override {
        vm.assume(amount > 0);
        super.testCannotProcessCollect_PassingWrongAmountInData(
            profileId,
            pubId,
            transactionExecutor,
            amount,
            passedAmount,
            collectorProfileId,
            collectorProfileOwner
        );
    }

    function testCannotProcessCollect_PassingWrongCurrencyInData(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        uint160 amount,
        address passedCurrency,
        uint256 collectorProfileId,
        address collectorProfileOwner
    ) public override {
        vm.assume(amount > 0);
        super.testCannotProcessCollect_PassingWrongCurrencyInData(
            profileId,
            pubId,
            transactionExecutor,
            amount,
            passedCurrency,
            collectorProfileId,
            collectorProfileOwner
        );
    }
}

//////////////
// Fee Distribution of InheritedFeeCollectModule
//
contract MultirecipientCollectModule_FeeDistribution is MultirecipientCollectModuleBase {
    struct Balances {
        uint256 treasury;
        mapping(uint256 => uint256) referrals;
        mapping(uint256 => uint256) recipients;
        uint256 collector;
    }

    mapping(uint256 => address) referralProfileOwners;
    mapping(uint256 => uint256) referralProfileIds;
    mapping(uint256 => address) recipients;
    mapping(uint256 => uint16) splits;

    Balances balancesBefore;
    Balances balancesAfter;
    Balances balancesChange;

    function setUp() public override(MultirecipientCollectModuleBase) {
        MultirecipientCollectModuleBase.setUp();
    }

    function getEncodedInitData() internal override(MultirecipientCollectModuleBase) returns (bytes memory) {
        return MultirecipientCollectModuleBase.getEncodedInitData();
    }

    function testVerifyFeesSplit(
        uint160 amount,
        uint16 referralFee,
        uint16 treasuryFee,
        address collectorProfileOwner,
        uint16 split1,
        uint16 split2,
        uint16 split3,
        uint16 split4,
        uint256 numberOfRecipients,
        uint256 numberOfReferrals
    ) public {
        vm.assume(amount > 0);
        vm.assume(collectorProfileOwner != address(0));
        vm.assume(collectorProfileOwner != treasury);

        delete multirecipientExampleInitData.recipients;
        assertEq(multirecipientExampleInitData.recipients.length, 0);

        numberOfRecipients = bound(numberOfRecipients, 2, MAX_RECIPIENTS);
        // console.log('Number of recipients: %s', numberOfRecipients);
        split1 = uint16(bound(split1, 1, BPS_MAX - numberOfRecipients));
        split2 = uint16(bound(split2, 1, BPS_MAX - numberOfRecipients));
        split3 = uint16(bound(split3, 1, BPS_MAX - numberOfRecipients));
        split4 = uint16(bound(split4, 1, BPS_MAX - numberOfRecipients));

        vm.assume(split1 + split2 + split3 + split4 < BPS_MAX / 2);

        for (uint256 i = 0; i < numberOfRecipients; i++) {
            recipients[i] = address(uint160(uint256(keccak256(abi.encodePacked(i, collectorProfileOwner)))));
            vm.label(recipients[i], string(abi.encodePacked('recipient', i + 49)));
        }

        {
            splits[0] = split1;
            splits[1] = split2;
            splits[2] = split3;
            splits[3] = split4;

            uint16 splitUsed;
            for (uint256 i = 0; i < numberOfRecipients - 1; i++) {
                splitUsed += splits[i];
                multirecipientExampleInitData.recipients.push(
                    RecipientData({recipient: recipients[i], split: splits[i]})
                );
                // console.log('split %s: %s', i, splits[i]);
            }
            vm.assume(splitUsed < BPS_MAX);
            multirecipientExampleInitData.recipients.push(
                RecipientData({recipient: recipients[numberOfRecipients - 1], split: BPS_MAX - splitUsed})
            );
            splits[numberOfRecipients - 1] = BPS_MAX - splitUsed;
            // console.log('split %s: %s', numberOfRecipients - 1, BPS_MAX - splitUsed);
        }

        numberOfReferrals = bound(numberOfReferrals, 0, 5);

        treasuryFee = uint16(bound(uint256(treasuryFee), 0, (BPS_MAX / 2) - 1));
        // console.log('Treasury fee: %s', treasuryFee);

        vm.prank(governance);
        hub.setTreasuryFee(treasuryFee);

        referralFee = uint16(bound(referralFee, 0, BPS_MAX));
        // console.log('Referral fee: %s', referralFee);

        exampleInitData.amount = amount;
        // console.log('Amount: %s', amount);

        exampleInitData.referralFee = referralFee;
        // console.log('Referral fee: %s', referralFee);

        vm.label(collectorProfileOwner, 'collectorProfileOwner');
        vm.label(treasury, 'treasury');

        for (uint256 i = 0; i < numberOfReferrals; i++) {
            referralProfileOwners[i] = address(
                uint160(uint256(keccak256(abi.encodePacked(i, collectorProfileOwner, i))))
            );
            referralProfileIds[i] = _createProfile(referralProfileOwners[i]);
        }

        currency.mint(collectorProfileOwner, type(uint256).max);
        vm.prank(collectorProfileOwner);
        currency.approve(baseFeeCollectModule, type(uint256).max);

        uint256 collectorProfileId = _createProfile(collectorProfileOwner);

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            1,
            1,
            address(0),
            getEncodedInitData()
        );

        balancesBefore.treasury = currency.balanceOf(treasury);

        for (uint256 i = 0; i < numberOfRecipients; i++) {
            balancesBefore.recipients[i] = currency.balanceOf(recipients[i]);
        }

        for (uint256 i = 0; i < numberOfReferrals; i++) {
            balancesBefore.referrals[i] = currency.balanceOf(referralProfileOwners[i]);
        }
        balancesBefore.collector = currency.balanceOf(collectorProfileOwner);
        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).processCollect(
            ModuleTypes.ProcessCollectParams({
                publicationCollectedProfileId: 1,
                publicationCollectedId: 1,
                collectorProfileId: collectorProfileId,
                collectorProfileOwner: collectorProfileOwner,
                transactionExecutor: collectorProfileOwner,
                referrerProfileIds: _referralProfileIdsToMemoryArray(numberOfReferrals),
                referrerPubIds: _referralPubIdsToMemoryArray(numberOfReferrals),
                referrerPubTypes: _referralPubTypesToMemoryArray(numberOfReferrals),
                data: abi.encode(currency, exampleInitData.amount)
            })
        );
        balancesAfter.treasury = currency.balanceOf(treasury);

        for (uint256 i = 0; i < numberOfRecipients; i++) {
            balancesAfter.recipients[i] = currency.balanceOf(recipients[i]);
        }

        for (uint256 i = 0; i < numberOfReferrals; i++) {
            balancesAfter.referrals[i] = currency.balanceOf(referralProfileOwners[i]);
        }
        balancesAfter.collector = currency.balanceOf(collectorProfileOwner);

        balancesChange.treasury = balancesAfter.treasury - balancesBefore.treasury;

        for (uint256 i = 0; i < numberOfRecipients; i++) {
            balancesChange.recipients[i] = balancesAfter.recipients[i] - balancesBefore.recipients[i];
        }

        for (uint256 i = 0; i < numberOfReferrals; i++) {
            balancesChange.referrals[i] = balancesAfter.referrals[i] - balancesBefore.referrals[i];
        }
        balancesChange.collector = balancesBefore.collector - balancesAfter.collector;

        uint256 totalReferralFeeChange = 0;
        for (uint256 i = 0; i < numberOfReferrals; i++) {
            totalReferralFeeChange += balancesChange.referrals[i];
        }

        uint256 totalRecipientsChange = 0;
        for (uint256 i = 0; i < numberOfRecipients; i++) {
            totalRecipientsChange += balancesChange.recipients[i];
        }

        assertEq(
            balancesChange.treasury + totalRecipientsChange + (numberOfReferrals > 0 ? totalReferralFeeChange : 0),
            balancesChange.collector,
            'Total Fees mismatch'
        );

        uint256 treasuryAmount = (uint256(amount) * treasuryFee) / BPS_MAX;
        // console.log('Treasury amount: %s', treasuryAmount);
        uint256 adjustedAmount = amount - treasuryAmount;
        // console.log('Adjusted amount: %s', adjustedAmount);
        uint256 totalReferralAmount = numberOfReferrals > 0 ? (uint256(adjustedAmount) * referralFee) / BPS_MAX : 0;
        // console.log('Total referral amount: %s', totalReferralAmount);
        uint256 amountPerReferral = numberOfReferrals > 0 ? totalReferralAmount / numberOfReferrals : 0;
        // console.log('Amount per referral: %s', amountPerReferral);
        uint256 totalReferralAmountRounded = amountPerReferral * numberOfReferrals;
        // console.log('Total referral amount rounded: %s', totalReferralAmountRounded);

        if (numberOfReferrals > 0) {
            assertTrue(
                _diff(totalReferralAmount, totalReferralAmountRounded) < numberOfReferrals,
                'Total Referral Fees Rounding too big'
            );
        }

        for (uint256 i = 0; i < numberOfReferrals; i++) {
            assertEq(balancesChange.referrals[i], amountPerReferral, 'Referral Fees mismatch');
        }

        for (uint256 i = 0; i < numberOfRecipients; i++) {
            // console.log(
            //     'recipient %s expected amount (with split %s):',
            //     i,
            //     splits[i],
            //     ((adjustedAmount - totalReferralAmount) * splits[i]) / BPS_MAX
            // );
            assertEq(
                balancesChange.recipients[i],
                ((adjustedAmount - totalReferralAmount) * splits[i]) / BPS_MAX,
                'Recipient Fees mismatch'
            );
        }

        if (numberOfReferrals > 0) {
            assertEq(totalReferralFeeChange, totalReferralAmountRounded, 'Total Referral Fees mismatch');
        }

        assertEq(balancesChange.treasury, treasuryAmount, 'Treasury Fees mismatch');

        // assertEq(balancesChange.publisher, adjustedAmount - totalReferralAmount, 'Recipients Fees mismatch');

        assertEq(
            balancesChange.collector,
            (adjustedAmount - totalReferralAmount) +
                totalReferralAmountRounded +
                treasuryAmount -
                (adjustedAmount - totalReferralAmount - totalRecipientsChange),
            'Collector Fees mismatch'
        );
    }

    function _referralProfileIdsToMemoryArray(uint256 numberOfReferrals) private view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](numberOfReferrals);
        for (uint256 i = 0; i < numberOfReferrals; i++) {
            result[i] = referralProfileIds[i];
        }
        return result;
    }

    function _referralPubIdsToMemoryArray(uint256 numberOfReferrals) private pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](numberOfReferrals);
        for (uint256 i = 0; i < numberOfReferrals; i++) {
            result[i] = i + 1;
        }
        return result;
    }

    function _referralPubTypesToMemoryArray(
        uint256 numberOfReferrals
    ) private pure returns (Types.PublicationType[] memory) {
        Types.PublicationType[] memory result = new Types.PublicationType[](numberOfReferrals);
        for (uint256 i = 0; i < numberOfReferrals; i++) {
            result[i] = Types.PublicationType.Comment;
        }
        return result;
    }

    function _diff(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a - b : b - a;
    }
}
