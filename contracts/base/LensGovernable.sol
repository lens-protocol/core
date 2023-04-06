// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILensGovernable} from 'contracts/interfaces/ILensGovernable.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {GovernanceLib} from 'contracts/libraries/GovernanceLib.sol';
import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

abstract contract LensGovernable is ILensGovernable {
    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        ValidationLib.validateCallerIsGovernance();
        _;
    }

    /////////////////////////////////
    ///        GOV FUNCTIONS      ///
    /////////////////////////////////

    /// @inheritdoc ILensGovernable
    function setGovernance(address newGovernance) external override onlyGov {
        GovernanceLib.setGovernance(newGovernance);
    }

    /// @inheritdoc ILensGovernable
    function setEmergencyAdmin(address newEmergencyAdmin) external override onlyGov {
        GovernanceLib.setEmergencyAdmin(newEmergencyAdmin);
    }

    function setState(Types.ProtocolState newState) external override {
        GovernanceLib.setState(newState);
    }

    ///@inheritdoc ILensGovernable
    function whitelistProfileCreator(address profileCreator, bool whitelist) external override onlyGov {
        GovernanceLib.whitelistProfileCreator(profileCreator, whitelist);
    }

    /// @inheritdoc ILensGovernable
    function whitelistFollowModule(address followModule, bool whitelist) external override onlyGov {
        GovernanceLib.whitelistFollowModule(followModule, whitelist);
    }

    /// @inheritdoc ILensGovernable
    function whitelistReferenceModule(address referenceModule, bool whitelist) external override onlyGov {
        GovernanceLib.whitelistReferenceModule(referenceModule, whitelist);
    }

    /// @inheritdoc ILensGovernable
    function whitelistActionModule(address actionModule, bool whitelist) external override onlyGov {
        GovernanceLib.whitelistActionModule(actionModule, whitelist);
    }

    ///////////////////////////////////////////
    ///        EXTERNAL VIEW FUNCTIONS      ///
    ///////////////////////////////////////////

    /// @inheritdoc ILensGovernable
    function getGovernance() external view override returns (address) {
        return StorageLib.getGovernance();
    }

    /**
     * @notice Returns the current protocol state.
     *
     * @return ProtocolState The Protocol state, an enum, where:
     *      0: Unpaused
     *      1: PublishingPaused
     *      2: Paused
     */
    function getState() external view override returns (Types.ProtocolState) {
        return StorageLib.getState();
    }

    /// @inheritdoc ILensGovernable
    function isProfileCreatorWhitelisted(address profileCreator) external view override returns (bool) {
        return StorageLib.profileCreatorWhitelisted()[profileCreator];
    }

    /// @inheritdoc ILensGovernable
    function isFollowModuleWhitelisted(address followModule) external view override returns (bool) {
        return StorageLib.followModuleWhitelisted()[followModule];
    }

    /// @inheritdoc ILensGovernable
    function isReferenceModuleWhitelisted(address referenceModule) external view override returns (bool) {
        return StorageLib.referenceModuleWhitelisted()[referenceModule];
    }

    /// @inheritdoc ILensGovernable
    function getActionModuleWhitelistData(
        address actionModule
    ) external view override returns (Types.ActionModuleWhitelistData memory) {
        return StorageLib.actionModuleWhitelistData()[actionModule];
    }
}
