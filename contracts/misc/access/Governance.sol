// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {UpgradeContractPermissions} from 'contracts/misc/access/UpgradeContractPermissions.sol';

contract Governance is UpgradeContractPermissions {
    ILensHub public immutable LENS_HUB;

    constructor(address lensHubAddress_, address governanceOwner_) UpgradeContractPermissions(governanceOwner_) {
        LENS_HUB = ILensHub(payable(lensHubAddress_));
    }

    /////////////////////////////////////////////////////
    ///             ONLY GOVERNANCE OWNER             ///
    /////////////////////////////////////////////////////

    function lensHub_setGovernance(address newGovernance) external onlyOwner {
        LENS_HUB.setGovernance(newGovernance);
    }

    function lensHub_setEmergencyAdmin(address newEmergencyAdmin) external onlyOwner {
        LENS_HUB.setEmergencyAdmin(newEmergencyAdmin);
    }

    /////////////////////////////////////////////////////
    ///   ONLY GOVERNANCE OWNER OR UPGRADE CONTRACT   ///
    /////////////////////////////////////////////////////

    function lensHub_whitelistProfileCreator(
        address profileCreator,
        bool whitelist
    ) external onlyOwnerOrUpgradeContract {
        LENS_HUB.whitelistProfileCreator(profileCreator, whitelist);
    }

    function lensHub_whitelistFollowModule(address followModule, bool whitelist) external onlyOwnerOrUpgradeContract {
        LENS_HUB.whitelistFollowModule(followModule, whitelist);
    }

    function lensHub_whitelistReferenceModule(
        address referenceModule,
        bool whitelist
    ) external onlyOwnerOrUpgradeContract {
        LENS_HUB.whitelistReferenceModule(referenceModule, whitelist);
    }

    function lensHub_whitelistActionModuleId(
        address actionModule,
        uint256 whitelistId
    ) external onlyOwnerOrUpgradeContract {
        LENS_HUB.whitelistActionModuleId(actionModule, whitelistId);
    }
}
