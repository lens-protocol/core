// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {BaseFeeCollectModuleBase} from 'test/modules/act/collect/BaseFeeCollectModule.base.t.sol';
import {IBaseFeeCollectModule, BaseProfilePublicationData} from 'contracts/modules/interfaces/IBaseFeeCollectModule.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {ModuleTypes} from 'contracts/modules/libraries/constants/ModuleTypes.sol';
import {Errors as ModuleErrors} from 'contracts/modules/constants/Errors.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {MockCurrency} from 'test/mocks/MockCurrency.sol';

uint16 constant BPS_MAX = 10000;

/////////
// Initialization with BaseFeeCollectModule
//
contract BaseFeeCollectModule_Initialization is BaseFeeCollectModuleBase {
    // Negatives
    function testCannotInitializeWithReferralFeeGreaterThanMaxBPS(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        uint16 referralFee
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));

        exampleInitData.referralFee = uint16(bound(referralFee, TREASURY_FEE_MAX_BPS + 1, type(uint16).max));

        vm.expectRevert(ModuleErrors.InitParamsInvalid.selector);
        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );
    }

    function testCannotInitializeWithPastNonzeroTimestamp(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        uint72 currentTimestamp,
        uint72 endTimestamp
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(currentTimestamp > 1);
        endTimestamp = uint72(bound(endTimestamp, 1, currentTimestamp - 1));

        vm.warp(currentTimestamp);
        exampleInitData.endTimestamp = endTimestamp;

        vm.expectRevert(ModuleErrors.InitParamsInvalid.selector);
        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );
    }

    function testCannotInitializeIfCalledFromNonActionModuleAddress(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        address nonActionModule
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(nonActionModule != collectPublicationAction);

        vm.expectRevert(ModuleErrors.NotActionModule.selector);

        vm.prank(nonActionModule);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );
    }

    function testCannotInitializeWithWrongInitDataFormat(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));

        vm.expectRevert();
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            ''
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
    ) public virtual {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));

        vm.assume(
            (amount != 0 && whitelistedCurrency != address(0) && uint160(whitelistedCurrency) > 10) ||
                (amount == 0 && whitelistedCurrency == address(0))
        );

        vm.assume(whitelistedCurrency != address(baseFeeCollectModule));

        if (whitelistedCurrency != address(0)) {
            vm.etch(whitelistedCurrency, address(new MockCurrency()).code);
        }

        if (endTimestamp > 0) {
            currentTimestamp = uint72(bound(uint256(currentTimestamp), 0, uint256(endTimestamp) - 1));
        }
        vm.warp(currentTimestamp);

        exampleInitData.amount = amount;
        exampleInitData.collectLimit = collectLimit;
        exampleInitData.currency = whitelistedCurrency;
        exampleInitData.referralFee = uint16(bound(uint256(referralFee), 0, BPS_MAX));
        exampleInitData.followerOnly = followerOnly;
        exampleInitData.endTimestamp = endTimestamp;
        exampleInitData.recipient = recipient;

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );

        BaseProfilePublicationData memory fetchedData = IBaseFeeCollectModule(baseFeeCollectModule)
            .getBasePublicationData(profileId, pubId);
        assertEq(fetchedData.currency, exampleInitData.currency, 'MockCurrency initialization mismatch');
        assertEq(fetchedData.amount, exampleInitData.amount, 'Amount initialization mismatch');
        assertEq(fetchedData.referralFee, exampleInitData.referralFee, 'Referral fee initialization mismatch');
        assertEq(fetchedData.followerOnly, exampleInitData.followerOnly, 'Follower only initialization mismatch');
        assertEq(fetchedData.endTimestamp, exampleInitData.endTimestamp, 'End timestamp initialization mismatch');
        assertEq(fetchedData.collectLimit, exampleInitData.collectLimit, 'Collect limit initialization mismatch');
        assertEq(fetchedData.recipient, exampleInitData.recipient, 'Recipient initialization mismatch');
    }
}

//////////////
// Collect with BaseFeeCollectModule
//
contract BaseFeeCollectModule_ProcessCollect is BaseFeeCollectModuleBase {
    // Negatives

    function testCannotProcessCollect_IfCalledFrom_NonActionModuleAddress(
        uint256 publicationCollectedProfileId,
        uint256 publicationCollectedId,
        uint256 collectorProfileId,
        address collectorProfileOwner,
        address transactionExecutor,
        address nonActionModule
    ) public {
        vm.assume(publicationCollectedProfileId != 0);
        vm.assume(publicationCollectedId != 0);
        vm.assume(collectorProfileId != 0);
        vm.assume(collectorProfileOwner != address(0));
        vm.assume(transactionExecutor != address(0));
        vm.assume(nonActionModule != collectPublicationAction);

        vm.expectRevert(ModuleErrors.NotActionModule.selector);

        vm.prank(nonActionModule);
        IBaseFeeCollectModule(baseFeeCollectModule).processCollect(
            ModuleTypes.ProcessCollectParams({
                publicationCollectedProfileId: publicationCollectedProfileId,
                publicationCollectedId: publicationCollectedId,
                collectorProfileId: collectorProfileId,
                collectorProfileOwner: collectorProfileOwner,
                transactionExecutor: collectorProfileOwner,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: ''
            })
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
    ) public virtual {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(passedAmount != amount);
        vm.assume(collectorProfileId != 0);
        vm.assume(collectorProfileOwner != address(0));
        vm.assume(amount != 0); // TODO: Have a test for zero case also

        exampleInitData.amount = amount;

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );

        vm.expectRevert(ModuleErrors.ModuleDataMismatch.selector);

        vm.prank(address(collectPublicationAction));
        IBaseFeeCollectModule(baseFeeCollectModule).processCollect(
            ModuleTypes.ProcessCollectParams({
                publicationCollectedProfileId: profileId,
                publicationCollectedId: pubId,
                collectorProfileId: collectorProfileId,
                collectorProfileOwner: collectorProfileOwner,
                transactionExecutor: collectorProfileOwner,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(currency, passedAmount)
            })
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
    ) public virtual {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        // vm.assume(!moduleGlobals.isCurrencyWhitelisted(passedCurrency)); // TODO: Verify that's right
        vm.assume(passedCurrency != exampleInitData.currency);
        vm.assume(collectorProfileId != 0);
        vm.assume(collectorProfileOwner != address(0));
        vm.assume(amount != 0);

        exampleInitData.amount = amount;

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );

        vm.expectRevert(ModuleErrors.ModuleDataMismatch.selector);

        vm.prank(address(collectPublicationAction));
        IBaseFeeCollectModule(baseFeeCollectModule).processCollect(
            ModuleTypes.ProcessCollectParams({
                publicationCollectedProfileId: profileId,
                publicationCollectedId: pubId,
                collectorProfileId: collectorProfileId,
                collectorProfileOwner: collectorProfileOwner,
                transactionExecutor: collectorProfileOwner,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(passedCurrency, amount)
            })
        );
    }

    function testCannotCollectIfNotAFollower(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        address collectorProfileOwner
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(collectorProfileOwner != address(0));

        uint256 notFollowerProfileId = _createProfile(collectorProfileOwner);
        vm.assume(notFollowerProfileId != profileId);
        vm.assume(!hub.isFollowing(notFollowerProfileId, profileId));

        exampleInitData.followerOnly = true;

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );

        vm.expectRevert(Errors.NotFollowing.selector);

        vm.prank(address(collectPublicationAction));
        IBaseFeeCollectModule(baseFeeCollectModule).processCollect(
            ModuleTypes.ProcessCollectParams({
                publicationCollectedProfileId: profileId,
                publicationCollectedId: pubId,
                collectorProfileId: notFollowerProfileId,
                collectorProfileOwner: collectorProfileOwner,
                transactionExecutor: collectorProfileOwner,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(currency, exampleInitData.amount)
            })
        );
    }

    function testCannotProcessCollect_AfterEndTimestamp(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        uint256 collectorProfileId,
        address collectorProfileOwner,
        uint72 currentTimestamp,
        uint72 endTimestamp
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(endTimestamp > block.timestamp && endTimestamp < type(uint72).max);

        exampleInitData.endTimestamp = endTimestamp;

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );

        currentTimestamp = uint72(bound(currentTimestamp, endTimestamp + 1, type(uint72).max));
        vm.warp(currentTimestamp);

        vm.startPrank(collectPublicationAction);
        vm.expectRevert(ModuleErrors.CollectExpired.selector);
        IBaseFeeCollectModule(baseFeeCollectModule).processCollect(
            ModuleTypes.ProcessCollectParams({
                publicationCollectedProfileId: profileId,
                publicationCollectedId: pubId,
                collectorProfileId: collectorProfileId,
                collectorProfileOwner: collectorProfileOwner,
                transactionExecutor: collectorProfileOwner,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(currency, exampleInitData.amount)
            })
        );
    }

    function testCannotCollectMoreThanLimit(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        uint256 collectorProfileId,
        address collectorProfileOwner
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(collectorProfileId != 0);
        vm.assume(collectorProfileOwner != address(0));

        currency.mint(collectorProfileOwner, type(uint256).max);
        vm.prank(collectorProfileOwner);
        currency.approve(baseFeeCollectModule, type(uint256).max);

        exampleInitData.collectLimit = 3;

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );

        for (uint256 i = 0; i < exampleInitData.collectLimit; i++) {
            vm.prank(collectPublicationAction);
            IBaseFeeCollectModule(baseFeeCollectModule).processCollect(
                ModuleTypes.ProcessCollectParams({
                    publicationCollectedProfileId: profileId,
                    publicationCollectedId: pubId,
                    collectorProfileId: collectorProfileId,
                    collectorProfileOwner: collectorProfileOwner,
                    transactionExecutor: collectorProfileOwner,
                    referrerProfileIds: _emptyUint256Array(),
                    referrerPubIds: _emptyUint256Array(),
                    referrerPubTypes: _emptyPubTypesArray(),
                    data: abi.encode(currency, exampleInitData.amount)
                })
            );
        }

        vm.expectRevert(ModuleErrors.MintLimitExceeded.selector);
        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).processCollect(
            ModuleTypes.ProcessCollectParams({
                publicationCollectedProfileId: profileId,
                publicationCollectedId: pubId,
                collectorProfileId: collectorProfileId,
                collectorProfileOwner: collectorProfileOwner,
                transactionExecutor: collectorProfileOwner,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(currency, exampleInitData.amount)
            })
        );
    }

    //Scenarios

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
    ) public virtual {
        uint256 profileId = defaultAccount.profileId;
        {
            vm.assume(pubId != 0);
            vm.assume(transactionExecutor != address(0));
            vm.assume(collectorProfileOwner != address(0));
            vm.assume(recipient != address(0));
            vm.assume(!_isLensHubProxyAdmin(collectorProfileOwner));
            vm.assume(endTimestamp == 0 || endTimestamp >= block.timestamp);
        }

        exampleInitData.amount = amount;
        exampleInitData.collectLimit = collectLimit;
        exampleInitData.referralFee = uint16(bound(uint256(referralFee), 0, BPS_MAX));
        exampleInitData.followerOnly = followerOnly;
        exampleInitData.endTimestamp = endTimestamp;
        exampleInitData.recipient = recipient;

        if (amount == 0) {
            exampleInitData.currency = address(0);
            currency = MockCurrency(address(0));
        }

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );

        if (endTimestamp > 0) {
            currentTimestamp = uint72(bound(uint256(currentTimestamp), 0, uint256(endTimestamp) - 1));
        }
        vm.warp(currentTimestamp);

        uint256 collectorProfileId = _createProfile(collectorProfileOwner);

        if (amount > 0) {
            currency.mint(collectorProfileOwner, amount);
            vm.prank(collectorProfileOwner);
            currency.approve(baseFeeCollectModule, amount);
        }

        if (followerOnly) {
            vm.prank(collectorProfileOwner);
            hub.follow(collectorProfileId, _toUint256Array(profileId), _toUint256Array(0), _toBytesArray(''));
        }

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).processCollect(
            ModuleTypes.ProcessCollectParams({
                publicationCollectedProfileId: profileId,
                publicationCollectedId: pubId,
                collectorProfileId: collectorProfileId,
                collectorProfileOwner: collectorProfileOwner,
                transactionExecutor: collectorProfileOwner,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                data: abi.encode(currency, amount)
            })
        );
    }

    function testCurrentCollectsIncreaseProperlyWhenCollecting(
        uint256 profileId,
        uint256 pubId,
        uint256 collectorProfileId,
        address collectorProfileOwner,
        address transactionExecutor
    ) public virtual {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(collectorProfileOwner != address(0));
        vm.assume(collectorProfileId != 0);

        currency.mint(collectorProfileOwner, type(uint256).max);
        vm.prank(collectorProfileOwner);
        currency.approve(baseFeeCollectModule, type(uint256).max);

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );

        BaseProfilePublicationData memory fetchedData = IBaseFeeCollectModule(baseFeeCollectModule)
            .getBasePublicationData(profileId, pubId);
        assertEq(fetchedData.currentCollects, 0);

        for (uint256 collects = 1; collects < 5; collects++) {
            vm.prank(collectPublicationAction);
            IBaseFeeCollectModule(baseFeeCollectModule).processCollect(
                ModuleTypes.ProcessCollectParams({
                    publicationCollectedProfileId: profileId,
                    publicationCollectedId: pubId,
                    collectorProfileId: collectorProfileId,
                    collectorProfileOwner: collectorProfileOwner,
                    transactionExecutor: collectorProfileOwner,
                    referrerProfileIds: _emptyUint256Array(),
                    referrerPubIds: _emptyUint256Array(),
                    referrerPubTypes: _emptyPubTypesArray(),
                    data: abi.encode(currency, exampleInitData.amount)
                })
            );

            fetchedData = IBaseFeeCollectModule(baseFeeCollectModule).getBasePublicationData(profileId, pubId);
            assertEq(fetchedData.currentCollects, collects);
        }
    }
}

contract BaseFeeCollectModule_FeeDistribution is BaseFeeCollectModuleBase {
    struct Balances {
        uint256 treasury;
        mapping(uint256 => uint256) referrals;
        uint256 publisher;
        uint256 collector;
    }

    function setUp() public virtual override {
        super.setUp();
    }

    mapping(uint256 => address) referralProfileOwners;
    mapping(uint256 => uint256) referralProfileIds;

    Balances balancesBefore;
    Balances balancesAfter;
    Balances balancesChange;

    function testVerifyFeesSplit(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        uint160 amount,
        uint16 referralFee,
        address recipient,
        uint16 treasuryFee,
        address collectorProfileOwner,
        uint256 numberOfReferrals
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(collectorProfileOwner != address(0));
        vm.assume(recipient != address(0));
        vm.assume(collectorProfileOwner != recipient);
        vm.assume(collectorProfileOwner != treasury);
        vm.assume(recipient != treasury);
        vm.assume(amount != 0); // TODO: Maybe have a proper test with amount 0

        numberOfReferrals = bound(numberOfReferrals, 0, 5);

        treasuryFee = uint16(bound(uint256(treasuryFee), 0, (BPS_MAX / 2) - 1));
        vm.prank(governance);
        hub.setTreasuryFee(treasuryFee);

        referralFee = uint16(bound(referralFee, 0, BPS_MAX));

        exampleInitData.amount = amount;
        exampleInitData.referralFee = referralFee;
        exampleInitData.recipient = recipient;

        vm.label(recipient, 'recipient');
        vm.label(collectorProfileOwner, 'collectorProfileOwner');
        vm.label(treasury, 'treasury');

        for (uint256 i = 0; i < numberOfReferrals; i++) {
            referralProfileOwners[i] = address(uint160(uint256(keccak256(abi.encodePacked(i, recipient)))));
            vm.assume(recipient != referralProfileOwners[i]);
            vm.assume(collectorProfileOwner != referralProfileOwners[i]);
            referralProfileIds[i] = _createProfile(referralProfileOwners[i]);
        }

        currency.mint(collectorProfileOwner, type(uint256).max);
        vm.prank(collectorProfileOwner);
        currency.approve(baseFeeCollectModule, type(uint256).max);

        uint256 collectorProfileId = _createProfile(collectorProfileOwner);

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );

        balancesBefore.treasury = currency.balanceOf(treasury);
        balancesBefore.publisher = currency.balanceOf(recipient);
        for (uint256 i = 0; i < numberOfReferrals; i++) {
            balancesBefore.referrals[i] = currency.balanceOf(referralProfileOwners[i]);
        }
        balancesBefore.collector = currency.balanceOf(collectorProfileOwner);

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).processCollect(
            ModuleTypes.ProcessCollectParams({
                publicationCollectedProfileId: profileId,
                publicationCollectedId: pubId,
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
        balancesAfter.publisher = currency.balanceOf(recipient);
        for (uint256 i = 0; i < numberOfReferrals; i++) {
            balancesAfter.referrals[i] = currency.balanceOf(referralProfileOwners[i]);
        }
        balancesAfter.collector = currency.balanceOf(collectorProfileOwner);

        balancesChange.treasury = balancesAfter.treasury - balancesBefore.treasury;
        balancesChange.publisher = balancesAfter.publisher - balancesBefore.publisher;
        for (uint256 i = 0; i < numberOfReferrals; i++) {
            balancesChange.referrals[i] = balancesAfter.referrals[i] - balancesBefore.referrals[i];
        }
        balancesChange.collector = balancesBefore.collector - balancesAfter.collector;

        uint256 totalReferralFeeChange = 0;
        for (uint256 i = 0; i < numberOfReferrals; i++) {
            totalReferralFeeChange += balancesChange.referrals[i];
        }

        assertEq(
            balancesChange.treasury + balancesChange.publisher + (numberOfReferrals > 0 ? totalReferralFeeChange : 0),
            balancesChange.collector,
            'Total Fees mismatch'
        );

        uint256 treasuryAmount = (uint256(amount) * treasuryFee) / BPS_MAX;
        uint256 adjustedAmount = amount - treasuryAmount;
        uint256 totalReferralAmount = numberOfReferrals > 0 ? (uint256(adjustedAmount) * referralFee) / BPS_MAX : 0;
        uint256 amountPerReferral = numberOfReferrals > 0 ? totalReferralAmount / numberOfReferrals : 0;
        uint256 totalReferralAmountRounded = amountPerReferral * numberOfReferrals;

        if (numberOfReferrals > 0) {
            assertTrue(
                _diff(totalReferralAmount, totalReferralAmountRounded) < numberOfReferrals,
                'Total Referral Fees Rounding too big'
            );
        }

        for (uint256 i = 0; i < numberOfReferrals; i++) {
            assertEq(balancesChange.referrals[i], amountPerReferral, 'Referral Fees mismatch');
        }

        if (numberOfReferrals > 0) {
            assertEq(totalReferralFeeChange, totalReferralAmountRounded, 'Total Referral Fees mismatch');
        }

        assertEq(balancesChange.treasury, treasuryAmount, 'Treasury Fees mismatch');
        assertEq(balancesChange.publisher, adjustedAmount - totalReferralAmount, 'Publisher Fees mismatch');
        assertEq(
            balancesChange.collector,
            (adjustedAmount - totalReferralAmount) + totalReferralAmountRounded + treasuryAmount,
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
