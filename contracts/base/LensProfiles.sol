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

abstract contract LensProfiles is LensBaseERC721, ERC2981CollectionRoyalties {
    IModuleGlobals immutable MODULE_GLOBALS;

    constructor(address moduleGlobals) {
        MODULE_GLOBALS = IModuleGlobals(moduleGlobals);
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
}
