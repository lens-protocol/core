// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title LensHubStorage
 * @author Lens Protocol
 *
 * @notice This is an abstract contract that ONLY contains storage for the LensHub contract. This MUST be inherited last
 * to preserve the LensHub storage layout. Adding storage variables should be done ONLY at the bottom of this contract.
 */
abstract contract LensHubStorage {
    // For upgradeability purposes, used at `VersionedInitializable` file, which needs to be included if the LensHub
    // has an initializer function.
    uint256 private _lastInitializedRevision; // Slot 11.

    Types.ProtocolState internal _state; // Slot 12

    mapping(address profileCreator => bool isWhitelisted) internal _profileCreatorWhitelisted; // Slot 13

    mapping(address => bool isWhitelisted) internal _followModuleWhitelisted; // Slot 14

    // `_collectModuleWhitelisted` slot replaced by `_actionModuleWhitelistData` in Lens V2.
    // All the old modules need to be unwhitelisted before V2 upgrade to avoid dirty storage.
    // mapping(address collectModule => bool isWhitelisted) internal __DEPRECATED__collectModuleWhitelisted;
    mapping(address actionModule => Types.ActionModuleWhitelistData whitelistData) internal _actionModuleWhitelistData; // Slot 15

    mapping(address referenceModule => bool isWhitelisted) internal _referenceModuleWhitelisted; // Slot 16

    mapping(uint256 profileId => address dispatcher) internal __DEPRECATED__dispatcherByProfile; // Slot 17

    mapping(bytes32 handleHash => uint256 profileId) internal __DEPRECATED__profileIdByHandleHash; // Slot 18

    mapping(uint256 profileId => Types.Profile profile) internal _profiles; // Slot 19

    mapping(uint256 profileId => mapping(uint256 pubId => Types.Publication publication)) internal _publications; // Slot 20

    mapping(address userAddress => uint256 profileId) internal __DEPRECATED__defaultProfiles; // Slot 21

    uint256 internal _profileCounter; // Slot 22 - different from totalSupply, as this is not decreased when burning profiles

    address internal _governance; // Slot 23

    address internal _emergencyAdmin; // Slot 24

    ////////////////////////////////////////////
    // Slots introduced by Lens V1.3 upgrade. //
    ////////////////////////////////////////////
    mapping(address => uint256) internal _tokenGuardianDisablingTimestamp; // Slot 25

    ////////////////////////////////////////////
    //  Slots introduced by Lens V2 upgrade.  //
    ////////////////////////////////////////////

    mapping(uint256 profileId => Types.DelegatedExecutorsConfig config) internal _delegatedExecutorsConfigs; // Slot 26

    mapping(uint256 blockerProfileId => mapping(uint256 blockedProfileId => bool isBlocked)) internal _blockedStatus; // Slot 27

    mapping(uint256 id => address actionModule) internal _actionModules; // Slot 28

    uint256 internal _maxActionModuleIdUsed; // Slot 29

    uint256 internal _profileRoyaltiesBps; // Slot 30
}
