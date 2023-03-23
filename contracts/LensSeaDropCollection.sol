// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721SeaDropCloneable} from '@seadrop/clones/ERC721SeaDropCloneable.sol';
import {ISeaDrop} from '@seadrop/interfaces/ISeaDrop.sol';
import {PublicDrop} from '@seadrop/lib/SeaDropStructs.sol';
import {IModuleGlobals} from 'contracts/interfaces/IModuleGlobals.sol';

contract LensSeaDropCollection is ERC721SeaDropCloneable {
    error OnlySeaDropActionModule();
    error FeesDoNotCoverLensTreasury();
    error InvalidParams();

    uint16 private constant ROYALTIES_BPS = 1_000;

    IModuleGlobals immutable MODULE_GLOBALS;

    address immutable SEADROP_ACTION_MODULE;

    address immutable DEFAULT_SEADROP;

    modifier onlySeaDropActionModule() {
        if (msg.sender != SEADROP_ACTION_MODULE) {
            revert OnlySeaDropActionModule();
        }
        _;
    }

    constructor(address seaDropActionModule, address moduleGlobals, address defaultSeaDrop) {
        SEADROP_ACTION_MODULE = seaDropActionModule;
        MODULE_GLOBALS = IModuleGlobals(moduleGlobals);
        DEFAULT_SEADROP = defaultSeaDrop;
    }

    function initialize(
        address owner,
        string calldata name,
        string calldata symbol,
        address[] calldata allowedSeaDrops,
        MultiConfigureStruct calldata config
    ) external onlySeaDropActionModule {
        _validateInitializationData(allowedSeaDrops, config);
        super.initialize({
            __name: name,
            __symbol: symbol,
            allowedSeaDrop: allowedSeaDrops,
            initialOwner: address(this)
        });
        this.multiConfigure(config);
        this.setRoyaltyInfo(RoyaltyInfo({royaltyAddress: owner, royaltyBps: ROYALTIES_BPS}));
        _transferOwnership(owner);
    }

    function _validateInitializationData(
        address[] calldata allowedSeaDrops,
        MultiConfigureStruct calldata config
    ) internal view {
        // Makes sure that the default used SeaDrop is allowed as the first element of the array.
        if (allowedSeaDrops.length == 0 || allowedSeaDrops[0] != DEFAULT_SEADROP) {
            revert InvalidParams();
        }
        // Makes sure that the SeaDropMintPublicationAction is allowed as a fee recipient.
        if (config.allowedFeeRecipients.length == 0 || config.allowedFeeRecipients[0] != SEADROP_ACTION_MODULE) {
            revert InvalidParams();
        }
        // Makes sure that the SeaDropMintPublicationAction is allowed as a payer.
        if (config.allowedPayers.length == 0 || config.allowedPayers[0] != SEADROP_ACTION_MODULE) {
            revert InvalidParams();
        }
        // NOTE: Validations of fee BPS, disallowed fee recipients or payers are done in the respective overriden
        // functions that will be called by the `multiConfigure` function afterwards.
    }

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop) external virtual override onlyOwner {
        // Makes sure that the default used SeaDrop is allowed as the first element of the array.
        if (allowedSeaDrop.length == 0 || allowedSeaDrop[0] != DEFAULT_SEADROP) {
            revert InvalidParams();
        }
        _updateAllowedSeaDrop(allowedSeaDrop);
    }

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(address seaDropImpl, PublicDrop calldata publicDrop) external virtual override {
        // We only enforce the fees to cover the Lens Treasury fees when using the default SeaDrop, as it is the SeaDrop
        // chosen by Lens.
        if (seaDropImpl == DEFAULT_SEADROP && publicDrop.feeBps < MODULE_GLOBALS.getTreasuryFee()) {
            revert FeesDoNotCoverLensTreasury();
        }
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the public drop data on SeaDrop.
        ISeaDrop(seaDropImpl).updatePublicDrop(publicDrop);
    }

    /**
     * @notice Update the allowed fee recipient for this nft contract
     *         on SeaDrop.
     *         Only the owner can set the allowed fee recipient.
     *
     * @param seaDropImpl  The allowed SeaDrop contract.
     * @param feeRecipient The new fee recipient.
     * @param allowed      If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(
        address seaDropImpl,
        address feeRecipient,
        bool allowed
    ) external virtual override {
        // We only enforce the SeaDropMintPublicationAction to be used as a fee recipient when using the default SeaDrop.
        if (seaDropImpl == DEFAULT_SEADROP && !allowed && feeRecipient == SEADROP_ACTION_MODULE) {
            revert InvalidParams();
        }
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the allowed fee recipient.
        ISeaDrop(seaDropImpl).updateAllowedFeeRecipient(feeRecipient, allowed);
    }

    /**
     * @notice Update the allowed payers for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param payer       The payer to update.
     * @param allowed     Whether the payer is allowed.
     */
    function updatePayer(address seaDropImpl, address payer, bool allowed) external virtual override {
        // We only enforce the SeaDropMintPublicationAction to be enabled as a payer when using the default SeaDrop.
        if (seaDropImpl == DEFAULT_SEADROP && !allowed && payer == SEADROP_ACTION_MODULE) {
            revert InvalidParams();
        }
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the payer.
        ISeaDrop(seaDropImpl).updatePayer(payer, allowed);
    }
}
