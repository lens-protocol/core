// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'forge-std/Test.sol';
import {ProtocolSharedRevenueMinFeeMintModuleBase} from 'test/modules/act/collect/ProtocolSharedRevenueMinFeeMintModule.base.t.sol';
import {IBaseFeeCollectModule} from 'contracts/modules/interfaces/IBaseFeeCollectModule.sol';
import {BaseFeeCollectModule_Initialization, BaseFeeCollectModule_ProcessCollect, BaseFeeCollectModule_FeeDistribution} from 'test/modules/act/collect/BaseFeeCollectModule.t.sol';
import {BaseFeeCollectModuleBase} from 'test/modules/act/collect/BaseFeeCollectModule.base.t.sol';
import {ProtocolSharedRevenueDistribution, ProtocolSharedRevenueMinFeeMintModule, ProtocolSharedRevenueMinFeeMintModulePublicationData} from 'contracts/modules/act/collect/ProtocolSharedRevenueMinFeeMintModule.sol';
import {Errors as ModuleErrors} from 'contracts/modules/constants/Errors.sol';
import {MockCurrency} from 'test/mocks/MockCurrency.sol';
import {ModuleTypes} from 'contracts/modules/libraries/constants/ModuleTypes.sol';

/////////
// Publication Creation with ProtocolSharedRevenueMinFeeMintModule
//
contract ProtocolSharedRevenueMinFeeMintModule_Initialization is
    ProtocolSharedRevenueMinFeeMintModuleBase,
    BaseFeeCollectModule_Initialization
{
    function setUp() public override(ProtocolSharedRevenueMinFeeMintModuleBase, BaseFeeCollectModuleBase) {
        ProtocolSharedRevenueMinFeeMintModuleBase.setUp();
    }

    function getEncodedInitData()
        internal
        override(ProtocolSharedRevenueMinFeeMintModuleBase, BaseFeeCollectModuleBase)
        returns (bytes memory)
    {
        return ProtocolSharedRevenueMinFeeMintModuleBase.getEncodedInitData();
    }

    // Negatives

    // TODO: WTF?
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
        uint72 endTimestamp,
        address recipient,
        address creatorFrontend
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

        mintFeeModuleExampleInitData.amount = amount;
        mintFeeModuleExampleInitData.collectLimit = collectLimit;
        mintFeeModuleExampleInitData.currency = whitelistedCurrency;
        mintFeeModuleExampleInitData.referralFee = uint16(bound(uint256(referralFee), 0, BPS_MAX));
        mintFeeModuleExampleInitData.followerOnly = followerOnly;
        mintFeeModuleExampleInitData.endTimestamp = endTimestamp;
        mintFeeModuleExampleInitData.recipient = recipient;
        mintFeeModuleExampleInitData.creatorFrontend = creatorFrontend;

        vm.prank(collectPublicationAction);
        IBaseFeeCollectModule(baseFeeCollectModule).initializePublicationCollectModule(
            profileId,
            pubId,
            transactionExecutor,
            getEncodedInitData()
        );

        ProtocolSharedRevenueMinFeeMintModulePublicationData memory fetchedData = ProtocolSharedRevenueMinFeeMintModule(
            baseFeeCollectModule
        ).getPublicationData(profileId, pubId);
        assertEq(fetchedData.currency, mintFeeModuleExampleInitData.currency, 'MockCurrency initialization mismatch');
        assertEq(fetchedData.amount, mintFeeModuleExampleInitData.amount, 'Amount initialization mismatch');
        assertEq(
            fetchedData.referralFee,
            mintFeeModuleExampleInitData.referralFee,
            'Referral fee initialization mismatch'
        );
        assertEq(
            fetchedData.followerOnly,
            mintFeeModuleExampleInitData.followerOnly,
            'Follower only initialization mismatch'
        );
        assertEq(
            fetchedData.endTimestamp,
            mintFeeModuleExampleInitData.endTimestamp,
            'End timestamp initialization mismatch'
        );
        assertEq(
            fetchedData.collectLimit,
            mintFeeModuleExampleInitData.collectLimit,
            'Collect limit initialization mismatch'
        );
        assertEq(
            fetchedData.creatorFrontend,
            mintFeeModuleExampleInitData.creatorFrontend,
            'CreatorFrontend initialization mismatch'
        );
    }
}

//////////////
// Collect with ProtocolSharedRevenueMinFeeMintModule
//
contract ProtocolSharedRevenueMinFeeMintModule_ProcessCollect is
    ProtocolSharedRevenueMinFeeMintModuleBase,
    BaseFeeCollectModule_ProcessCollect
{
    function testProtocolSharedRevenueMinFeeMintModule_Collect() public {
        // Prevents being counted in Foundry Coverage
    }

    address exampleExecutorFrontend = executorFrontendAddress;

    function setUp() public override(ProtocolSharedRevenueMinFeeMintModuleBase, BaseFeeCollectModuleBase) {
        ProtocolSharedRevenueMinFeeMintModuleBase.setUp();
    }

    function getEncodedInitData()
        internal
        override(ProtocolSharedRevenueMinFeeMintModuleBase, BaseFeeCollectModuleBase)
        returns (bytes memory)
    {
        return ProtocolSharedRevenueMinFeeMintModuleBase.getEncodedInitData();
    }

    function _getCollectParamsData(address currency, uint160 amount) internal override returns (bytes memory) {
        return abi.encode(currency, amount, exampleExecutorFrontend);
    }

    // Scenarios

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
    ) public override {}

    function testCanCollectIfAllConditionsAreMet(
        uint256 pubId,
        address transactionExecutor,
        uint160 amount,
        uint96 collectLimit,
        uint16 referralFee,
        bool followerOnly,
        uint72 currentTimestamp,
        uint72 endTimestamp,
        address recipient
    ) public {
        address collectorProfileOwner = makeAddr('COLLECTOR_PROFILE_OWNER');
        address executorFrontend = makeAddr('EXECUTOR_FRONTEND');
        exampleExecutorFrontend = executorFrontend;

        bonsai.mint(collectorProfileOwner, 10 ether);

        vm.prank(collectorProfileOwner);
        bonsai.approve(baseFeeCollectModule, 10 ether);

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

    struct Balances {
        uint256 creator;
        uint256 protocol;
        uint256 creatorFrontend;
        uint256 executorFrontend;
        uint256 collector;
    }

    Balances balancesBefore;
    Balances balancesAfter;
    Balances balancesChange;

    function testMintFeeDistribution_FreePost(
        uint256 pubId,
        address transactionExecutor,
        uint96 collectLimit,
        uint16 referralFee,
        bool followerOnly,
        uint72 currentTimestamp,
        uint72 endTimestamp,
        address recipient
    ) public {
        address collectorProfileOwner = makeAddr('COLLECTOR_PROFILE_OWNER');
        address executorFrontend = makeAddr('EXECUTOR_FRONTEND');

        bonsai.mint(collectorProfileOwner, 10 ether);

        vm.prank(collectorProfileOwner);
        bonsai.approve(baseFeeCollectModule, 10 ether);

        balancesBefore = Balances({
            creator: bonsai.balanceOf(defaultAccount.owner),
            protocol: bonsai.balanceOf(hub.getTreasury()),
            creatorFrontend: bonsai.balanceOf(creatorFrontendAddress),
            executorFrontend: bonsai.balanceOf(executorFrontend),
            collector: bonsai.balanceOf(collectorProfileOwner)
        });

        exampleExecutorFrontend = executorFrontend;
        super.testCanCollectIfAllConditionsAreMet(
            pubId,
            transactionExecutor,
            0,
            collectLimit,
            referralFee,
            followerOnly,
            currentTimestamp,
            endTimestamp,
            recipient,
            collectorProfileOwner
        );

        balancesAfter = Balances({
            creator: bonsai.balanceOf(defaultAccount.owner),
            protocol: bonsai.balanceOf(hub.getTreasury()),
            creatorFrontend: bonsai.balanceOf(creatorFrontendAddress),
            executorFrontend: bonsai.balanceOf(executorFrontend),
            collector: bonsai.balanceOf(collectorProfileOwner)
        });

        balancesChange = Balances({
            creator: balancesAfter.creator - balancesBefore.creator,
            protocol: balancesAfter.protocol - balancesBefore.protocol,
            creatorFrontend: balancesAfter.creatorFrontend - balancesBefore.creatorFrontend,
            executorFrontend: balancesAfter.executorFrontend - balancesBefore.executorFrontend,
            collector: balancesBefore.collector - balancesAfter.collector
        });

        uint256 expectedCreatorFee = (mintFee * mintFeeModule.getProtocolSharedRevenueDistribution().creatorSplit) /
            BPS_MAX;
        uint256 expectedProtocolFee = (mintFee * mintFeeModule.getProtocolSharedRevenueDistribution().protocolSplit) /
            BPS_MAX;
        uint256 expectedCreatorFrontendFee = (mintFee *
            mintFeeModule.getProtocolSharedRevenueDistribution().creatorFrontendSplit) / BPS_MAX;
        uint256 expectedExecutorFrontendFee = (mintFee *
            mintFeeModule.getProtocolSharedRevenueDistribution().executorFrontendSplit) / BPS_MAX;

        assertEq(balancesChange.creator, expectedCreatorFee, 'Creator balance change wrong');
        assertEq(balancesChange.protocol, expectedProtocolFee, 'Protocol balance change wrong');
        assertEq(balancesChange.creatorFrontend, expectedCreatorFrontendFee, 'CreatorFrontend balance change wrong');
        assertEq(balancesChange.executorFrontend, expectedExecutorFrontendFee, 'ExecutorFrontend balance change wrong');
        assertEq(balancesChange.collector, mintFee, 'Collector balance change wrong');
    }

    function testMintFeeDistribution_FreePost_WithoutFrontends(
        uint256 pubId,
        address transactionExecutor,
        uint96 collectLimit,
        uint16 referralFee,
        bool followerOnly,
        uint72 currentTimestamp,
        uint72 endTimestamp,
        address recipient
    ) public {
        address collectorProfileOwner = makeAddr('COLLECTOR_PROFILE_OWNER');

        address executorFrontend = address(0);
        creatorFrontendAddress = address(0);

        bonsai.mint(collectorProfileOwner, 10 ether);

        vm.prank(collectorProfileOwner);
        bonsai.approve(baseFeeCollectModule, 10 ether);

        balancesBefore = Balances({
            creator: bonsai.balanceOf(defaultAccount.owner),
            protocol: bonsai.balanceOf(hub.getTreasury()),
            creatorFrontend: bonsai.balanceOf(creatorFrontendAddress),
            executorFrontend: bonsai.balanceOf(executorFrontend),
            collector: bonsai.balanceOf(collectorProfileOwner)
        });

        console.log('creatorFrontend balance before: %s', balancesBefore.creatorFrontend);

        exampleExecutorFrontend = executorFrontend;
        super.testCanCollectIfAllConditionsAreMet(
            pubId,
            transactionExecutor,
            0,
            collectLimit,
            referralFee,
            followerOnly,
            currentTimestamp,
            endTimestamp,
            recipient,
            collectorProfileOwner
        );

        balancesAfter = Balances({
            creator: bonsai.balanceOf(defaultAccount.owner),
            protocol: bonsai.balanceOf(hub.getTreasury()),
            creatorFrontend: bonsai.balanceOf(creatorFrontendAddress),
            executorFrontend: bonsai.balanceOf(executorFrontend),
            collector: bonsai.balanceOf(collectorProfileOwner)
        });

        balancesChange = Balances({
            creator: balancesAfter.creator - balancesBefore.creator,
            protocol: balancesAfter.protocol - balancesBefore.protocol,
            creatorFrontend: balancesAfter.creatorFrontend - balancesBefore.creatorFrontend,
            executorFrontend: balancesAfter.executorFrontend - balancesBefore.executorFrontend,
            collector: balancesBefore.collector - balancesAfter.collector
        });

        uint256 expectedCreatorFee = (mintFee * mintFeeModule.getProtocolSharedRevenueDistribution().creatorSplit) /
            BPS_MAX;
        uint256 expectedProtocolFee = (mintFee * mintFeeModule.getProtocolSharedRevenueDistribution().protocolSplit) /
            BPS_MAX;
        uint256 expectedCreatorFrontendFee = (mintFee *
            mintFeeModule.getProtocolSharedRevenueDistribution().creatorFrontendSplit) / BPS_MAX;
        uint256 expectedExecutorFrontendFee = (mintFee *
            mintFeeModule.getProtocolSharedRevenueDistribution().executorFrontendSplit) / BPS_MAX;

        assertEq(
            balancesChange.creator,
            expectedCreatorFee + expectedCreatorFrontendFee + expectedExecutorFrontendFee,
            'Creator balance change wrong'
        );
        assertEq(balancesChange.protocol, expectedProtocolFee, 'Protocol balance change wrong');
        assertEq(balancesChange.creatorFrontend, 0, 'CreatorFrontend balance change wrong');
        assertEq(balancesChange.executorFrontend, 0, 'ExecutorFrontend balance change wrong');
        assertEq(balancesChange.collector, mintFee, 'Collector balance change wrong');
    }

    function testMintFeeDistribution_PaidPost(
        uint256 pubId,
        address transactionExecutor,
        uint160 amount,
        uint96 collectLimit,
        uint16 referralFee,
        bool followerOnly,
        uint72 currentTimestamp,
        uint72 endTimestamp,
        address recipient
    ) public {
        vm.assume(amount > 0);
        address collectorProfileOwner = makeAddr('COLLECTOR_PROFILE_OWNER');
        address executorFrontend = makeAddr('EXECUTOR_FRONTEND');

        balancesBefore = Balances({
            creator: bonsai.balanceOf(defaultAccount.owner),
            protocol: bonsai.balanceOf(hub.getTreasury()),
            creatorFrontend: bonsai.balanceOf(creatorFrontendAddress),
            executorFrontend: bonsai.balanceOf(executorFrontend),
            collector: bonsai.balanceOf(collectorProfileOwner)
        });

        exampleExecutorFrontend = executorFrontend;
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

        balancesAfter = Balances({
            creator: bonsai.balanceOf(defaultAccount.owner),
            protocol: bonsai.balanceOf(hub.getTreasury()),
            creatorFrontend: bonsai.balanceOf(creatorFrontendAddress),
            executorFrontend: bonsai.balanceOf(executorFrontend),
            collector: bonsai.balanceOf(collectorProfileOwner)
        });

        balancesChange = Balances({
            creator: balancesAfter.creator - balancesBefore.creator,
            protocol: balancesAfter.protocol - balancesBefore.protocol,
            creatorFrontend: balancesAfter.creatorFrontend - balancesBefore.creatorFrontend,
            executorFrontend: balancesAfter.executorFrontend - balancesBefore.executorFrontend,
            collector: balancesBefore.collector - balancesAfter.collector
        });

        assertEq(balancesChange.creator, 0, 'Creator balance change wrong');
        assertEq(balancesChange.protocol, 0, 'Protocol balance change wrong');
        assertEq(balancesChange.creatorFrontend, 0, 'CreatorFrontend balance change wrong');
        assertEq(balancesChange.executorFrontend, 0, 'ExecutorFrontend balance change wrong');
        assertEq(balancesChange.collector, 0, 'Collector balance change wrong');
    }
}

//////////////
// Fee Distribution of ProtocolSharedRevenueMinFeeMintModule
//
contract ProtocolSharedRevenueMinFeeMintModule_FeeDistribution is ProtocolSharedRevenueMinFeeMintModuleBase {
    function setUp() public override(ProtocolSharedRevenueMinFeeMintModuleBase) {
        ProtocolSharedRevenueMinFeeMintModuleBase.setUp();
    }

    function getEncodedInitData() internal override(ProtocolSharedRevenueMinFeeMintModuleBase) returns (bytes memory) {
        return ProtocolSharedRevenueMinFeeMintModuleBase.getEncodedInitData();
    }
}

//////////////
// Fee Distribution of ProtocolSharedRevenueMinFeeMintModule
//
contract ProtocolSharedRevenueMinFeeMintModule_OwnerMethods is ProtocolSharedRevenueMinFeeMintModuleBase {
    function setUp() public override(ProtocolSharedRevenueMinFeeMintModuleBase) {
        ProtocolSharedRevenueMinFeeMintModuleBase.setUp();
    }

    // Negatives

    function testCannotSetMintFeeParams_ifNotOwner(address currency, uint256 mintFee, address notOwner) public {
        if (mintFee == 0) currency = address(0);
        if (currency == address(0)) mintFee = 0;

        vm.assume(notOwner != mintFeeModule.owner());

        vm.expectRevert('Ownable: caller is not the owner');

        vm.prank(notOwner);
        mintFeeModule.setMintFeeParams(currency, mintFee);
    }

    function testCannotSetProtocolSharedRevenueDistribution_ifNotOwner(
        uint16 creatorSplit,
        uint16 protocolSplit,
        uint16 creatorFrontendSplit,
        address notOwner
    ) public {
        vm.assume(notOwner != mintFeeModule.owner());
        creatorSplit = uint16(bound(uint256(creatorSplit), 0, BPS_MAX));
        protocolSplit = uint16(bound(uint256(protocolSplit), 0, BPS_MAX - creatorSplit));
        creatorFrontendSplit = uint16(bound(uint256(creatorFrontendSplit), 0, BPS_MAX - creatorSplit - protocolSplit));
        uint16 executorFrontendSplit = BPS_MAX - creatorSplit - protocolSplit - creatorFrontendSplit;

        vm.expectRevert('Ownable: caller is not the owner');

        vm.prank(notOwner);
        mintFeeModule.setProtocolSharedRevenueDistribution(
            ProtocolSharedRevenueDistribution({
                creatorSplit: creatorSplit,
                protocolSplit: protocolSplit,
                creatorFrontendSplit: creatorFrontendSplit,
                executorFrontendSplit: executorFrontendSplit
            })
        );
    }

    function testCannotSetMintFeeParams_ifCurrencyZero_and_amountNotZero(uint256 mintFee) public {
        vm.assume(mintFee > 0);

        vm.prank(mintFeeModule.owner());
        vm.expectRevert(ModuleErrors.InvalidParams.selector);
        mintFeeModule.setMintFeeParams(address(0), mintFee);
    }

    function testCannotSetProtocolSharedRevenueDistribution_ifSplitsDontAddUpToBPS_MAX(
        uint16 creatorSplit,
        uint16 protocolSplit,
        uint16 creatorFrontendSplit,
        uint16 executorFrontendSplit
    ) public {
        vm.assume(
            uint256(creatorSplit) +
                uint256(protocolSplit) +
                uint256(creatorFrontendSplit) +
                uint256(executorFrontendSplit) !=
                BPS_MAX
        );

        vm.startPrank(mintFeeModule.owner());
        if (
            uint256(creatorSplit) +
                uint256(protocolSplit) +
                uint256(creatorFrontendSplit) +
                uint256(executorFrontendSplit) >
            type(uint16).max
        ) {
            vm.expectRevert(stdError.arithmeticError);
        } else {
            vm.expectRevert(ModuleErrors.InvalidParams.selector);
        }

        mintFeeModule.setProtocolSharedRevenueDistribution(
            ProtocolSharedRevenueDistribution({
                creatorSplit: creatorSplit,
                protocolSplit: protocolSplit,
                creatorFrontendSplit: creatorFrontendSplit,
                executorFrontendSplit: executorFrontendSplit
            })
        );
        vm.stopPrank();
    }

    // Scenarios

    function testSetMintFeeParams(uint256 mintFee, address currency) public {
        if (mintFee > 0) {
            vm.assume(currency != address(0));
        } else {
            currency = address(0);
        }

        vm.prank(mintFeeModule.owner());
        mintFeeModule.setMintFeeParams(currency, mintFee);

        (address actualCurrency, uint256 actualMintFee) = mintFeeModule.getMintFeeParams();

        assertEq(actualCurrency, currency, 'Currency mismatch');
        assertEq(actualMintFee, mintFee, 'Mint fee mismatch');
    }

    function testSetProtocolSharedRevenueDistribution(
        uint16 creatorSplit,
        uint16 protocolSplit,
        uint16 creatorFrontendSplit,
        uint16 executorFrontendSplit
    ) public {
        creatorSplit = uint16(bound(uint256(creatorSplit), 0, BPS_MAX));
        protocolSplit = uint16(bound(uint256(protocolSplit), 0, BPS_MAX - creatorSplit));
        creatorFrontendSplit = uint16(bound(uint256(creatorFrontendSplit), 0, BPS_MAX - creatorSplit - protocolSplit));
        uint16 executorFrontendSplit = BPS_MAX - creatorSplit - protocolSplit - creatorFrontendSplit;

        ProtocolSharedRevenueDistribution memory expectedDistribution = ProtocolSharedRevenueDistribution({
            creatorSplit: creatorSplit,
            protocolSplit: protocolSplit,
            creatorFrontendSplit: creatorFrontendSplit,
            executorFrontendSplit: executorFrontendSplit
        });

        vm.prank(mintFeeModule.owner());
        mintFeeModule.setProtocolSharedRevenueDistribution(expectedDistribution);

        ProtocolSharedRevenueDistribution memory actualDistribution = mintFeeModule
            .getProtocolSharedRevenueDistribution();

        assertEq(actualDistribution.creatorSplit, expectedDistribution.creatorSplit, 'Creator split mismatch');
        assertEq(actualDistribution.protocolSplit, expectedDistribution.protocolSplit, 'Protocol split mismatch');
        assertEq(
            actualDistribution.creatorFrontendSplit,
            expectedDistribution.creatorFrontendSplit,
            'CreatorFrontend split mismatch'
        );
        assertEq(
            actualDistribution.executorFrontendSplit,
            expectedDistribution.executorFrontendSplit,
            'ExecutorFrontend split mismatch'
        );
    }
}
