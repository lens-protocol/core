// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IERC721Timestamped} from 'contracts/interfaces/IERC721Timestamped.sol';
import {IModuleGlobals} from 'contracts/interfaces/IModuleGlobals.sol';

import {LensBaseERC721} from 'contracts/base/LensBaseERC721.sol';

import {ProfileLib} from 'contracts/libraries/ProfileLib.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {ProfileTokenURILib} from 'contracts/libraries/token-uris/ProfileTokenURILib.sol';
import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';

import {ERC2981CollectionRoyalties} from 'contracts/base/ERC2981CollectionRoyalties.sol';

import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';

import {Address} from '@openzeppelin/contracts/utils/Address.sol';

abstract contract LensProfiles is LensBaseERC721, ERC2981CollectionRoyalties {
    using Address for address;

    IModuleGlobals immutable MODULE_GLOBALS;

    uint256 internal immutable PROFILE_GUARDIAN_COOLDOWN;

    constructor(address moduleGlobals, uint256 profileGuardianCooldown) {
        MODULE_GLOBALS = IModuleGlobals(moduleGlobals);
        PROFILE_GUARDIAN_COOLDOWN = profileGuardianCooldown;
    }

    modifier whenNotPaused() {
        if (StorageLib.getState() == Types.ProtocolState.Paused) {
            revert Errors.Paused();
        }
        _;
    }

    modifier onlyProfileOwner(address expectedOwner, uint256 profileId) {
        ValidationLib.validateAddressIsProfileOwner(expectedOwner, profileId);
        _;
    }

    modifier onlyEOA() {
        if (msg.sender.isContract()) {
            revert Errors.NotEOA();
        }
        _;
    }

    /**
     * @notice Burns a profile, this maintains the profile data struct.
     */
    function burn(uint256 tokenId) public override whenNotPaused onlyProfileOwner(msg.sender, tokenId) {
        _burn(tokenId);
    }

    /**
     * @dev Overrides the ERC721 tokenURI function to return the associated URI with a given profile.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert Errors.TokenDoesNotExist();
        }
        return ProfileTokenURILib.getTokenURI(tokenId);
    }

    function _getRoyaltiesInBasisPointsSlot() internal pure override returns (uint256) {
        return StorageLib.PROFILE_ROYALTIES_BPS_SLOT;
    }

    function _getReceiver(uint256 /* tokenId */) internal view override returns (address) {
        return MODULE_GLOBALS.getTreasury();
    }

    function _beforeRoyaltiesSet(uint256 /* royaltiesInBasisPoints */) internal view override {
        ValidationLib.validateCallerIsGovernance();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        if (from != address(0) && _hasProfileGuardianEnabled(from)) {
            // Cannot transfer profile if the guardian is enabled, except at minting time.
            revert Errors.GuardianEnabled();
        }
        // Switches to new fresh delegated executors configuration (except on minting, as it already has a fresh setup).
        if (from != address(0)) {
            ProfileLib.switchToNewFreshDelegatedExecutorsConfig(tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(LensBaseERC721, ERC2981CollectionRoyalties) returns (bool) {
        return
            LensBaseERC721.supportsInterface(interfaceId) || ERC2981CollectionRoyalties.supportsInterface(interfaceId);
    }

    // TODO: We cannot do inheritdoc here, can we?
    /**
     * @notice Returns the timestamp at which the Profile Guardian will become effectively disabled.
     *
     * @param wallet The address to check the timestamp for.
     *
     * @return uint256 The timestamp at which the Profile Guardian will become effectively disabled. Zero if enabled.
     */
    function getProfileGuardianDisablingTimestamp(address wallet) external view returns (uint256) {
        return StorageLib.profileGuardianDisablingTimestamp()[wallet];
    }

    /// ************************************
    /// ****PROFILE PROTECTION FUNCTIONS****
    /// ************************************

    // TODO: @inheritdoc ILensHub
    function DANGER__disableProfileGuardian() external onlyEOA {
        if (StorageLib.profileGuardianDisablingTimestamp()[msg.sender] != 0) {
            revert Errors.DisablingAlreadyTriggered();
        }
        StorageLib.profileGuardianDisablingTimestamp()[msg.sender] = block.timestamp + PROFILE_GUARDIAN_COOLDOWN;
        emit Events.ProfileGuardianStateChanged({
            wallet: msg.sender,
            enabled: false,
            profileGuardianDisablingTimestamp: block.timestamp + PROFILE_GUARDIAN_COOLDOWN,
            timestamp: block.timestamp
        });
    }

    // TODO: @inheritdoc ILensHub
    function enableProfileGuardian() external onlyEOA {
        if (StorageLib.profileGuardianDisablingTimestamp()[msg.sender] == 0) {
            revert Errors.AlreadyEnabled();
        }
        StorageLib.profileGuardianDisablingTimestamp()[msg.sender] = 0;
        emit Events.ProfileGuardianStateChanged({
            wallet: msg.sender,
            enabled: true,
            profileGuardianDisablingTimestamp: 0,
            timestamp: block.timestamp
        });
    }

    function approve(address to, uint256 tokenId) public override {
        // We allow removing approvals even if the wallet has the profile guardian enabled
        if (to != address(0) && _hasProfileGuardianEnabled(msg.sender)) {
            revert Errors.GuardianEnabled();
        }
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        // We allow removing approvals even if the wallet has the profile guardian enabled
        if (approved && _hasProfileGuardianEnabled(msg.sender)) {
            revert Errors.GuardianEnabled();
        }
        super.setApprovalForAll(operator, approved);
    }

    function _hasProfileGuardianEnabled(address wallet) internal view returns (bool) {
        return
            !wallet.isContract() &&
            (StorageLib.profileGuardianDisablingTimestamp()[wallet] == 0 ||
                block.timestamp < StorageLib.profileGuardianDisablingTimestamp()[wallet]);
    }
}
