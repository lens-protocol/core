// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract DelegatedExecutorTest is BaseTest {
    // Mismatching size from executors and approvals
    // Caller is not the profile owner
    // Unexistent delegator profile
    // Config gets cleared after profile transfer
    // Using 0 in the first time sets to config 1 and switches
    // Can not switch to non-used or prepared config
    // Can prepare max used config + 1
    // Can switch to max used config + 1
    // Can switch to previous one, even if it is not the max used
}

contract DelegatedExecutorMetaTxTest {}
