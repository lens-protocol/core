// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract GovernanceFunctionsTest is BaseTest {
    function setUp() public virtual override {
        TestSetup.setUp();
    }

    function testUserCannotCallGovernanceFunctions() public {}

    function testGovernanceCanWhitelistModules() public {}

    function testGovernanceCanUnwhitelistModules() public {}

    function testGovernanceCanChangeGovernanceAddress() public {}
}
