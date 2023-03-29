// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title LensHubStorage
 * @author Lens Protocol
 *
 * @notice This is an abstract contract that *only* contains storage for the LensHub contract. This
 * *must* be inherited last (bar interfaces) to preserve the LensHub storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract LensHubStorage {
    mapping(address => bool) internal _profileCreatorWhitelisted; // Slot 13
    mapping(address => bool) internal _followModuleWhitelisted; // Slot 14

    // `_collectModuleWhitelisted` slot replaced by `_actionModuleWhitelistData` in Lens V2.
    // All the old modules need to be unwhitelisted before V2 upgrade to avoid dirty storage.
    // mapping(address => bool) internal __DEPRECATED__collectModuleWhitelisted;
    mapping(address => Types.ActionModuleWhitelistData) internal _actionModuleWhitelistData; // Slot 15

    mapping(address => bool) internal _referenceModuleWhitelisted; // Slot 16

    mapping(uint256 => address) internal __DEPRECATED__dispatcherByProfile; // Slot 17, deprecated, old _dispatcherByProfile
    mapping(bytes32 => uint256) internal _profileIdByHandleHash; // Slot 18
    mapping(uint256 => Types.Profile) internal _profileById; // Slot 19
    mapping(uint256 => mapping(uint256 => Types.Publication)) internal _pubByIdByProfile; // Slot 20

    mapping(address => uint256) internal _defaultProfileByAddress; // Slot 21, deprecated but needed for V2 migration

    uint256 internal _profileCounter; // Slot 22 - this is different from TotalSupply, as TotalSupply is decreased when the Profile is burned
    address internal _governance; // Slot 23
    address internal _emergencyAdmin; // Slot 24

    // Slots introduced by Lens V2 upgrade.

    mapping(uint256 => Types.DelegatedExecutorsConfig) internal _delegatedExecutorsConfigByProfileId; // Slot 25
    mapping(uint256 => mapping(uint256 => bool)) internal _blockedStatus; // Slot 26, _blockedStatus[byProfile][profile]
    mapping(uint256 id => address actionModule) internal _actionModuleById; // Slot 27
    uint256 _maxActionModuleIdUsed; // Slot 28
}
