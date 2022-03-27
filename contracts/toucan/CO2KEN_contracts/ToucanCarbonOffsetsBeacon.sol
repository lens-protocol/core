// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol';

/// @dev Beacon contract that tracks the implementation logic of TCO2 contracts
contract ToucanCarbonOffsetsBeacon is UpgradeableBeacon {
    constructor(address implementation_) UpgradeableBeacon(implementation_) {}
}
