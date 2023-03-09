// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';

contract Governance {
    error Unauthorized();

    ILensHub public immutable LENS_HUB;

    address public governanceOwner;
    address public upgradeContract;

    modifier onlyGovOwner() {
        if (msg.sender != governanceOwner) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyGovOwnerOrUpgradeContract() {
        if (msg.sender != governanceOwner && msg.sender != upgradeContract) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address lensHubAddress_, address governanceOwner_) {
        LENS_HUB = ILensHub(payable(lensHubAddress_));
        governanceOwner = governanceOwner_;
    }

    ///////////////////////////////////
    ///     Permissions setters     ///
    ///////////////////////////////////

    function clearUpgradeContract() external onlyGovOwnerOrUpgradeContract {
        delete upgradeContract;
    }

    function setUpgradeContract(address newUpgradeContract) external onlyGovOwner {
        upgradeContract = newUpgradeContract;
    }

    function transferGovernanceOwner(address newGovernanceOwner) external onlyGovOwner {
        governanceOwner = newGovernanceOwner;
    }

    ////////////////////////////////////
    /// LensHub Governance functions ///
    ////////////////////////////////////

    function lensHub_setGovernance(address newGovernance) external onlyGovOwner {
        LENS_HUB.setGovernance(newGovernance);
    }

    function lensHub_setEmergencyAdmin(address newEmergencyAdmin) external onlyGovOwner {
        LENS_HUB.setEmergencyAdmin(newEmergencyAdmin);
    }

    function lensHub_whitelistProfileCreator(
        address profileCreator,
        bool whitelist
    ) external onlyGovOwnerOrUpgradeContract {
        LENS_HUB.whitelistProfileCreator(profileCreator, whitelist);
    }

    function lensHub_whitelistFollowModule(
        address followModule,
        bool whitelist
    ) external onlyGovOwnerOrUpgradeContract {
        LENS_HUB.whitelistFollowModule(followModule, whitelist);
    }

    function lensHub_whitelistReferenceModule(
        address referenceModule,
        bool whitelist
    ) external onlyGovOwnerOrUpgradeContract {
        LENS_HUB.whitelistReferenceModule(referenceModule, whitelist);
    }

    function lensHub_whitelistActionModuleId(
        address actionModule,
        uint256 whitelistId
    ) external onlyGovOwnerOrUpgradeContract {
        LENS_HUB.whitelistActionModuleId(actionModule, whitelistId);
    }
}
