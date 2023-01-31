// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract ModuleGlobalsTest is BaseTest {
    function setUp() public override {
        super.setUp();
        assertFalse(me == hub.getGovernance(), 'address(this) should not be governance');
    }

    // Negatives - non Gov caller
    function testCannotSetGovernanceAddress_ifNotGovernance() public {
        vm.expectRevert(Errors.NotGovernance.selector);
        moduleGlobals.setGovernance(address(42));
    }

    function testCannotSetTreasuryAddress_ifNotGovernance() public {
        vm.expectRevert(Errors.NotGovernance.selector);
        moduleGlobals.setTreasury(address(42));
    }

    function testCannotSetTreasuryFee_ifNotGovernance() public {
        vm.expectRevert(Errors.NotGovernance.selector);
        moduleGlobals.setTreasuryFee(0);
    }

    // Negatives - Gov caller
    function testCannotSetGovernanceToZeroAddress() public {
        vm.prank(governance);
        vm.expectRevert(Errors.InitParamsInvalid.selector);
        moduleGlobals.setGovernance(address(0));
    }

    function testCannotSetTreasuryToZeroAddress() public {
        vm.prank(governance);
        vm.expectRevert(Errors.InitParamsInvalid.selector);
        moduleGlobals.setTreasury(address(0));
    }

    function testCannotWhitelistZeroAddressAsCurrency() public {
        vm.prank(governance);
        vm.expectRevert(Errors.InitParamsInvalid.selector);
        moduleGlobals.whitelistCurrency(address(0), true);
    }

    function testCannotSetTreasuryFee_largerOrEqualThanHalfOfBPS_MAX() public {
        vm.prank(governance);
        vm.expectRevert(Errors.InitParamsInvalid.selector);
        moduleGlobals.setTreasuryFee(TREASURY_FEE_MAX_BPS / 2);
    }

    // Scenarios
    function testSetGovernanceAddress_ifGovernance() public {
        address governanceBefore = moduleGlobals.getGovernance();
        address newGovernance = address(uint160(governanceBefore) + 1);

        assertEq(governanceBefore, governance, 'ModuleGlobals Governance is not Governance');

        vm.prank(governance);
        moduleGlobals.setGovernance(newGovernance);

        address governanceAfter = moduleGlobals.getGovernance();

        assertEq(
            governanceAfter,
            newGovernance,
            "ModuleGlobals Governance didn't change to newGovernance"
        );
        assertFalse(governanceBefore == governanceAfter, "ModuleGlobals Governance didn't change");
    }

    function testSetTreasuryAddress_ifGovernance() public {
        address treasuryBefore = moduleGlobals.getTreasury();
        address newTreasury = address(uint160(treasuryBefore) + 1);

        vm.prank(governance);
        moduleGlobals.setTreasury(newTreasury);

        address treasuryAfter = moduleGlobals.getTreasury();

        assertEq(treasuryAfter, newTreasury, "ModuleGlobals Treasury didn't change to newTreasury");
        assertFalse(treasuryBefore == treasuryAfter, "ModuleGlobals Treasury didn't change");
    }

    function testSetTreasuryFee_ifGovernance() public {
        uint16 treasuryFeeBefore = moduleGlobals.getTreasuryFee();
        uint16 newTreasuryFee = treasuryFeeBefore + 1;
        if (newTreasuryFee == TREASURY_FEE_MAX_BPS / 2) newTreasuryFee = 0;

        vm.prank(governance);
        moduleGlobals.setTreasuryFee(newTreasuryFee);

        uint16 treasuryFeeAfter = moduleGlobals.getTreasuryFee();

        assertEq(
            treasuryFeeAfter,
            newTreasuryFee,
            "ModuleGlobals TreasuryFee didn't change to newTreasuryFee"
        );
        assertFalse(
            treasuryFeeBefore == treasuryFeeAfter,
            "ModuleGlobals TreasuryFee didn't change"
        );
    }

    function testGetGovernance() public {
        vm.prank(governance);
        moduleGlobals.setGovernance(address(42));
        assertEq(
            moduleGlobals.getGovernance(),
            address(42),
            'ModuleGlobals Governance does not match set value'
        );
    }

    function testGetTreasury() public {
        vm.prank(governance);
        moduleGlobals.setTreasury(address(42));
        assertEq(
            moduleGlobals.getTreasury(),
            address(42),
            'ModuleGlobals Treasury does not match set value'
        );
    }

    function testGetTreasuryFee() public {
        vm.prank(governance);
        moduleGlobals.setTreasuryFee(42);
        assertEq(
            moduleGlobals.getTreasuryFee(),
            42,
            'ModuleGlobals TreasuryFee does not match set value'
        );
    }
}
