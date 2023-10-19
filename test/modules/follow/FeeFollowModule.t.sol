// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'test/base/BaseTest.t.sol';
import {FeeConfig, FeeFollowModule} from 'contracts/modules/follow/FeeFollowModule.sol';
import {Errors as ModuleErrors} from 'contracts/modules/constants/Errors.sol';
import {MockCurrency} from 'test/mocks/MockCurrency.sol';

contract FeeFollowModuleTest is BaseTest {
    using stdJson for string;
    FeeFollowModule feeFollowModule;
    MockCurrency currency;

    function setUp() public override {
        super.setUp();

        feeFollowModule = FeeFollowModule(loadOrDeploy_FeeFollowModule());

        // Create & Whitelist mock currency
        currency = new MockCurrency();
    }

    // Initialization - Negatives

    function testCannotInitialize_NotHub(address from, uint256 profileId, uint256 amount, address recipient) public {
        vm.assume(profileId != 0);
        vm.assume(amount != 0);
        vm.assume(from != address(hub));

        vm.expectRevert(Errors.NotHub.selector);
        vm.prank(from);
        feeFollowModule.initializeFollowModule(
            profileId,
            address(0),
            abi.encode(FeeConfig({currency: address(currency), amount: amount, recipient: recipient}))
        );
    }

    function testCannotInitialize_ZeroAmount(uint256 profileId, address recipient) public {
        vm.assume(profileId != 0);

        vm.expectRevert(Errors.InitParamsInvalid.selector);
        vm.prank(address(hub));
        feeFollowModule.initializeFollowModule(
            profileId,
            address(0),
            abi.encode(FeeConfig({currency: address(currency), amount: 0, recipient: recipient}))
        );
    }

    // Initialization - Scenarios

    function testInitialize(uint256 profileId, uint256 amount, address recipient) public {
        vm.assume(profileId != 0);
        vm.assume(amount != 0);

        FeeConfig memory feeConfig = FeeConfig({currency: address(currency), amount: amount, recipient: recipient});

        vm.prank(address(hub));
        feeFollowModule.initializeFollowModule(profileId, address(0), abi.encode(feeConfig));

        assertEq(abi.encode(feeFollowModule.getFeeConfig(profileId)), abi.encode(feeConfig));
    }

    // ProcessFollow - Negatives
    function testCannotProcessFollow_WrongCurrencyPassed_FreshFollow(
        uint256 followerProfileId,
        uint256 targetProfileId,
        uint256 amount,
        address passedCurrency,
        address recipient,
        address transactionExecutor
    ) public {
        vm.assume(followerProfileId != 0);
        vm.assume(targetProfileId != 0);
        (, uint16 treasuryFee) = hub.getTreasuryData();
        // Overflow protection (because treasuryAmount = amount * treasuryFee / BPS_MAX)
        vm.assume(
            amount != 0 && amount <= (treasuryFee == 0 ? type(uint256).max : type(uint256).max / uint256(treasuryFee))
        );
        vm.assume(transactionExecutor != address(0));

        FeeConfig memory feeConfig = FeeConfig({currency: address(currency), amount: amount, recipient: recipient});
        vm.prank(address(hub));
        feeFollowModule.initializeFollowModule(targetProfileId, address(0), abi.encode(feeConfig));

        if (passedCurrency != address(currency)) {
            vm.expectRevert(ModuleErrors.ModuleDataMismatch.selector);
        } else {
            currency.mint(transactionExecutor, amount);
            vm.prank(transactionExecutor);
            currency.approve(address(feeFollowModule), amount);
        }
        vm.prank(address(hub));
        feeFollowModule.processFollow(
            followerProfileId,
            0,
            transactionExecutor,
            targetProfileId,
            abi.encode(passedCurrency, amount)
        );
    }

    // ProcessFollow - Negatives
    function testCannotProcessFollow_WrongAmountPassed_FreshFollow(
        uint256 followerProfileId,
        uint256 targetProfileId,
        uint256 amount,
        uint256 passedAmount,
        address recipient,
        address transactionExecutor
    ) public {
        vm.assume(followerProfileId != 0);
        vm.assume(targetProfileId != 0);
        (, uint16 treasuryFee) = hub.getTreasuryData();
        // Overflow protection (because treasuryAmount = amount * treasuryFee / BPS_MAX)
        vm.assume(
            amount != 0 && amount <= (treasuryFee == 0 ? type(uint256).max : type(uint256).max / uint256(treasuryFee))
        );

        vm.assume(transactionExecutor != address(0));

        FeeConfig memory feeConfig = FeeConfig({currency: address(currency), amount: amount, recipient: recipient});
        vm.prank(address(hub));
        feeFollowModule.initializeFollowModule(targetProfileId, address(0), abi.encode(feeConfig));

        if (passedAmount != amount) {
            vm.expectRevert(ModuleErrors.ModuleDataMismatch.selector);
        } else {
            currency.mint(transactionExecutor, passedAmount);
            vm.prank(transactionExecutor);
            currency.approve(address(feeFollowModule), passedAmount);
        }
        vm.prank(address(hub));
        feeFollowModule.processFollow(
            followerProfileId,
            0,
            transactionExecutor,
            targetProfileId,
            abi.encode(address(currency), passedAmount)
        );
    }

    // ProcessFollow - Negatives
    function testCannotProcessFollow_WrongAmountPassed_ReusingFollow(
        uint256 followerProfileId,
        uint256 targetProfileId,
        uint256 amount,
        uint256 passedAmount,
        address recipient,
        address transactionExecutor,
        uint256 followTokenId
    ) public {
        vm.assume(followerProfileId != 0);
        vm.assume(targetProfileId != 0);
        vm.assume(amount != 0);
        vm.assume(followTokenId != 0);
        vm.assume(transactionExecutor != address(0));

        FeeConfig memory feeConfig = FeeConfig({currency: address(currency), amount: amount, recipient: recipient});
        vm.prank(address(hub));
        feeFollowModule.initializeFollowModule(targetProfileId, address(0), abi.encode(feeConfig));

        if (passedAmount != 0) {
            vm.expectRevert(ModuleErrors.InvalidParams.selector);
        }
        vm.prank(address(hub));
        feeFollowModule.processFollow(
            followerProfileId,
            followTokenId,
            transactionExecutor,
            targetProfileId,
            abi.encode(address(currency), passedAmount)
        );
    }

    function testCanStillProcessFollow_ZeroCurrency(
        uint256 followerProfileId,
        uint256 targetProfileId,
        address recipient,
        address transactionExecutor
    ) public {
        vm.assume(followerProfileId != 0);
        vm.assume(targetProfileId != 0);
        vm.assume(transactionExecutor != address(0));

        FeeConfig memory feeConfig = FeeConfig({currency: address(0), amount: 0, recipient: recipient});
        vm.prank(address(hub));
        feeFollowModule.initializeFollowModule(targetProfileId, address(0), abi.encode(feeConfig));

        vm.prank(address(hub));
        feeFollowModule.processFollow(
            followerProfileId,
            0,
            transactionExecutor,
            targetProfileId,
            abi.encode(address(0), 0) // @audit-info currency, amount
        );
    }

    struct Balances {
        uint256 treasury;
        uint256 follower;
        uint256 recipient;
    }

    uint16 constant BPS_MAX = 10000; // TODO: Move to constants?

    // ProcessFollow - Scenarios
    function testCanProcessFollow(
        uint256 followerProfileId,
        uint256 targetProfileId,
        uint256 amount,
        address recipient,
        address transactionExecutor,
        uint256 followTokenId,
        uint16 treasuryFee
    ) public {
        vm.assume(followerProfileId != 0);
        vm.assume(targetProfileId != 0);
        vm.assume(transactionExecutor != treasury);
        treasuryFee = uint16(bound(uint256(treasuryFee), 0, (BPS_MAX / 2) - 1));
        vm.prank(governance);
        hub.setTreasuryFee(treasuryFee);

        // Overflow protection (because treasuryAmount = amount * treasuryFee / BPS_MAX)
        vm.assume(
            amount != 0 && amount <= (treasuryFee == 0 ? type(uint256).max : type(uint256).max / uint256(treasuryFee))
        );
        vm.assume(transactionExecutor != address(0));

        // TODO: Figure out how to deal with burning
        vm.assume(recipient != address(0));

        FeeConfig memory feeConfig = FeeConfig({currency: address(currency), amount: amount, recipient: recipient});
        vm.prank(address(hub));
        feeFollowModule.initializeFollowModule(targetProfileId, address(0), abi.encode(feeConfig));

        uint256 passedAmount;

        if (followTokenId == 0) {
            // Fresh follow
            passedAmount = amount;
            currency.mint(transactionExecutor, passedAmount);
            vm.prank(transactionExecutor);
            currency.approve(address(feeFollowModule), passedAmount);
        }

        Balances memory balancesBefore;
        Balances memory balancesAfter;
        Balances memory balancesChange;

        {
            balancesBefore.treasury = currency.balanceOf(treasury);
            balancesBefore.recipient = currency.balanceOf(recipient);
            balancesBefore.follower = currency.balanceOf(transactionExecutor);

            vm.prank(address(hub));
            feeFollowModule.processFollow(
                followerProfileId,
                followTokenId,
                transactionExecutor,
                targetProfileId,
                abi.encode(address(currency), passedAmount)
            );

            balancesAfter.treasury = currency.balanceOf(treasury);
            balancesAfter.recipient = currency.balanceOf(recipient);
            balancesAfter.follower = currency.balanceOf(transactionExecutor);

            balancesChange.treasury = balancesAfter.treasury - balancesBefore.treasury;
            balancesChange.recipient = balancesAfter.recipient - balancesBefore.recipient;
            balancesChange.follower = balancesBefore.follower - balancesAfter.follower;
        }

        if (followTokenId == 0) {
            // Fresh follow
            assertEq(
                balancesChange.treasury + balancesChange.recipient,
                balancesChange.follower,
                'Amounts transfers are not equal'
            );

            uint256 treasuryAmount = (amount * uint256(treasuryFee)) / BPS_MAX;
            uint256 adjustedAmount = amount - treasuryAmount;

            assertEq(balancesChange.treasury, treasuryAmount, 'Treasury amount change is incorrect');
            assertEq(balancesChange.recipient, adjustedAmount, 'Target profile amount change is incorrect');
            assertEq(balancesChange.follower, amount, 'Follower amount change is incorrect');
        } else {
            // Reusing follow
            assertEq(balancesChange.treasury, 0, 'Treasury amount change is incorrect');
            assertEq(balancesChange.recipient, 0, 'Target profile amount change is incorrect');
            assertEq(balancesChange.follower, 0, 'Follower amount change is incorrect');
        }
    }
}
