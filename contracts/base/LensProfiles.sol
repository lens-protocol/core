// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {ILensProfiles} from 'contracts/interfaces/ILensProfiles.sol';
import {IERC721Burnable} from 'contracts/interfaces/IERC721Burnable.sol';

import {LensBaseERC721} from 'contracts/base/LensBaseERC721.sol';
import {ProfileLib} from 'contracts/libraries/ProfileLib.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';
import {IProfileTokenURI} from 'contracts/interfaces/IProfileTokenURI.sol';

import {ERC2981CollectionRoyalties} from 'contracts/base/ERC2981CollectionRoyalties.sol';

import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';

import {Address} from '@openzeppelin/contracts/utils/Address.sol';

abstract contract LensProfiles is LensBaseERC721, ERC2981CollectionRoyalties, ILensProfiles {
    using Address for address;

    uint256 public immutable TOKEN_GUARDIAN_COOLDOWN;

    constructor(uint256 tokenGuardianCooldown) {
        TOKEN_GUARDIAN_COOLDOWN = tokenGuardianCooldown;
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

    /// @inheritdoc ILensProfiles
    function getTokenGuardianDisablingTimestamp(address wallet) external view returns (uint256) {
        return StorageLib.tokenGuardianDisablingTimestamp()[wallet];
    }

    /// @inheritdoc ILensProfiles
    function DANGER__disableTokenGuardian() external onlyEOA {
        if (StorageLib.tokenGuardianDisablingTimestamp()[msg.sender] != 0) {
            revert Errors.DisablingAlreadyTriggered();
        }
        StorageLib.tokenGuardianDisablingTimestamp()[msg.sender] = block.timestamp + TOKEN_GUARDIAN_COOLDOWN;
        emit Events.TokenGuardianStateChanged({
            wallet: msg.sender,
            enabled: false,
            tokenGuardianDisablingTimestamp: block.timestamp + TOKEN_GUARDIAN_COOLDOWN,
            timestamp: block.timestamp
        });
    }

    /// @inheritdoc ILensProfiles
    function enableTokenGuardian() external onlyEOA {
        if (StorageLib.tokenGuardianDisablingTimestamp()[msg.sender] == 0) {
            revert Errors.AlreadyEnabled();
        }
        StorageLib.tokenGuardianDisablingTimestamp()[msg.sender] = 0;
        emit Events.TokenGuardianStateChanged({
            wallet: msg.sender,
            enabled: true,
            tokenGuardianDisablingTimestamp: 0,
            timestamp: block.timestamp
        });
    }

    /**
     * @notice Burns a profile, this maintains the profile data struct.
     */
    function burn(
        uint256 tokenId
    ) public override(LensBaseERC721, IERC721Burnable) whenNotPaused onlyProfileOwner(msg.sender, tokenId) {
        _burn(tokenId);
    }

    /**
     * @dev Overrides the ERC721 tokenURI function to return the associated URI with a given profile.
     */
    function tokenURI(uint256 tokenId) public view override(LensBaseERC721, IERC721Metadata) returns (string memory) {
        if (!_exists(tokenId)) {
            revert Errors.TokenDoesNotExist();
        }
        uint256 mintTimestamp = StorageLib.getTokenData(tokenId).mintTimestamp;
        return IProfileTokenURI(StorageLib.getProfileTokenURIContract()).getTokenURI(tokenId, mintTimestamp);
    }

    function approve(address to, uint256 tokenId) public override(LensBaseERC721, IERC721) {
        // We allow removing approvals even if the wallet has the token guardian enabled
        if (to != address(0) && _hasTokenGuardianEnabled(ownerOf(tokenId))) {
            revert Errors.GuardianEnabled();
        }
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(LensBaseERC721, IERC721) {
        // We allow removing approvals even if the wallet has the token guardian enabled
        if (approved && _hasTokenGuardianEnabled(msg.sender)) {
            revert Errors.GuardianEnabled();
        }
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(LensBaseERC721, ERC2981CollectionRoyalties, IERC165) returns (bool) {
        return
            LensBaseERC721.supportsInterface(interfaceId) || ERC2981CollectionRoyalties.supportsInterface(interfaceId);
    }

    function transferFromKeepingDelegates(address from, address to, uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Errors.NotOwnerOrApproved();
        }

        if (!StorageLib.profileCreatorWhitelisted()[msg.sender]) {
            // Delegates can be maintained on transfers only when executed by whitelisted profile creators, which are
            // trusted entities, for the sake of a better onboarding UX.
            revert Errors.NotAllowed();
        }

        if (ownerOf(tokenId) != from) {
            revert Errors.InvalidOwner();
        }

        if (to == address(0)) {
            revert Errors.InvalidParameter();
        }

        _beforeTokenTransferWithoutClearingDelegates(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        unchecked {
            --StorageLib.balances()[from];
            ++StorageLib.balances()[to];
        }

        StorageLib.getTokenData(tokenId).owner = to;

        emit Transfer(from, to, tokenId);
    }

    function _hasTokenGuardianEnabled(address wallet) internal view returns (bool) {
        return
            !wallet.isContract() &&
            (StorageLib.tokenGuardianDisablingTimestamp()[wallet] == 0 ||
                block.timestamp < StorageLib.tokenGuardianDisablingTimestamp()[wallet]);
    }

    function _getRoyaltiesInBasisPointsSlot() internal pure override returns (uint256) {
        return StorageLib.PROFILE_ROYALTIES_BPS_SLOT;
    }

    function _getReceiver(uint256 /* tokenId */) internal view override returns (address) {
        return StorageLib.getTreasuryData().treasury;
    }

    function _beforeRoyaltiesSet(uint256 /* royaltiesInBasisPoints */) internal view override {
        ValidationLib.validateCallerIsGovernance();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        if (from != address(0) && _hasTokenGuardianEnabled(from)) {
            // Cannot transfer profile if the guardian is enabled, except at minting time.
            revert Errors.GuardianEnabled();
        }
        // Switches to new fresh delegated executors configuration (except on minting, as it already has a fresh setup).
        if (from != address(0)) {
            ProfileLib.switchToNewFreshDelegatedExecutorsConfig(tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _beforeTokenTransferWithoutClearingDelegates(
        address from,
        address to,
        uint256 tokenId
    ) internal whenNotPaused {
        if (from != address(0) && _hasTokenGuardianEnabled(from)) {
            // Cannot transfer profile if the guardian is enabled, except at minting time.
            revert Errors.GuardianEnabled();
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
