// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721SeaDropCloneable} from '@seadrop/clones/ERC721SeaDropCloneable.sol';
import {ISeaDrop} from '@seadrop/interfaces/ISeaDrop.sol';
import {PublicDrop} from '@seadrop/lib/SeaDropStructs.sol';
import {IModuleGlobals} from 'contracts/interfaces/IModuleGlobals.sol';
import {ERC721SeaDropStructsErrorsAndEvents} from '@seadrop/lib/ERC721SeaDropStructsErrorsAndEvents.sol';

// TODO: Maybe also check that SeaDropMintPublicationModule is allowed as payer and as fee recipient.
contract LensSeaDropCollection is ERC721SeaDropCloneable {
    error OnlySeaDropActionModule();
    error FeesDoNotCoverLensTreasury();
    error InvalidParams();

    IModuleGlobals immutable MODULE_GLOBALS;

    address immutable SEADROP_ACTION_MODULE;

    ISeaDrop immutable SEADROP_IMPL;

    modifier onlySeaDropActionModule() {
        if (msg.sender != SEADROP_ACTION_MODULE) {
            revert OnlySeaDropActionModule();
        }
        _;
    }

    /**
     * @dev Reverts if the sender is not the owner or the contract itself or predefined LensSeaDropActionModule.
     *      This function is inlined instead of being a modifier
     *      to save contract space from being inlined N times.
     */
    function _onlyOwnerOrSelfOrLensActionModule() internal view {
        if (msg.sender == owner() || msg.sender == address(this) || msg.sender == SEADROP_ACTION_MODULE) {
            revert OnlyOwner();
        }
    }

    constructor(address seaDropActionModule, address moduleGlobals, address seaDropImpl) {
        SEADROP_ACTION_MODULE = seaDropActionModule;
        MODULE_GLOBALS = IModuleGlobals(moduleGlobals);
        SEADROP_IMPL = ISeaDrop(seaDropImpl);
    }

    function initialize(
        address owner,
        string calldata name,
        string calldata symbol,
        address[] calldata allowedSeaDrops,
        MultiConfigureStruct calldata config
    ) external onlySeaDropActionModule {
        if (allowedSeaDrops.length == 0 || allowedSeaDrops[0] != address(SEADROP_IMPL)) {
            revert InvalidParams();
        }
        super.initialize({
            __name: name,
            __symbol: symbol,
            allowedSeaDrop: allowedSeaDrops,
            initialOwner: address(this)
        });
        ERC721SeaDropCloneable(address(this)).multiConfigure(config);
        _initializeValidActionModuleValues(config);
        ERC721SeaDropCloneable(address(this)).setRoyaltyInfo(RoyaltyInfo({royaltyAddress: owner, royaltyBps: 1000}));
        _transferOwnership(owner);
    }

    function _initializeValidActionModuleValues(MultiConfigureStruct calldata config) internal {
        // Make sure the feeBps is at lest the same as the LensTreasury fee.
        uint16 treasuryFee = MODULE_GLOBALS.getTreasuryFee();
        if (config.publicDrop.feeBps < treasuryFee) {
            PublicDrop memory publicDrop = config.publicDrop;
            publicDrop.feeBps = treasuryFee;
            SEADROP_IMPL.updatePublicDrop(publicDrop);
        }
        // Make sure the LensSeaDropActionModule is allowed as a fee recipient.
        SEADROP_IMPL.updateAllowedFeeRecipient(SEADROP_ACTION_MODULE, true);
        // Make sure the LensSeaDropActionModule is allowed as a payer.
        SEADROP_IMPL.updatePayer(SEADROP_ACTION_MODULE, true);
    }

    function updatePublicDrop(PublicDrop calldata publicDrop) external virtual {
        updatePublicDrop(address(SEADROP_IMPL), publicDrop);
    }

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner or predefined LensSeaDropActionModule can use this function.
     *
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(address seaDropImpl, PublicDrop calldata publicDrop) public virtual override {
        _onlyOwnerOrSelfOrLensActionModule();

        _verifyFeesAreStillCoveringLensTreasury(publicDrop);

        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the public drop data on SeaDrop.
        ISeaDrop(seaDropImpl).updatePublicDrop(publicDrop);
    }

    // TODO: Discuss if we want to keep this enforcing. Maybe yes to force fees for when we mint through Lens.
    function _verifyFeesAreStillCoveringLensTreasury(PublicDrop calldata publicDrop) internal view {
        if (publicDrop.feeBps < MODULE_GLOBALS.getTreasuryFee()) {
            revert FeesDoNotCoverLensTreasury();
        }
    }
}
