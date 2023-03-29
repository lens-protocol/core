// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {ControllableByContract} from 'contracts/misc/access/ControllableByContract.sol';

interface ILensHub_V1 {
    function whitelistCollectModule(address collectModule, bool whitelist) external;
}

contract Governance is ControllableByContract {
    ILensHub public immutable LENS_HUB;

    constructor(address lensHubAddress_, address governanceOwner_) ControllableByContract(governanceOwner_) {
        LENS_HUB = ILensHub(payable(lensHubAddress_));
    }

    ////////////////////////////////////////////////////////
    ///               ONLY GOVERNANCE OWNER              ///
    ////////////////////////////////////////////////////////

    function lensHub_setGovernance(address newGovernance) external onlyOwner {
        LENS_HUB.setGovernance(newGovernance);
    }

    function lensHub_setEmergencyAdmin(address newEmergencyAdmin) external onlyOwner {
        LENS_HUB.setEmergencyAdmin(newEmergencyAdmin);
    }

    ////////////////////////////////////////////////////////
    ///   ONLY GOVERNANCE OWNER OR CONTROLLER CONTRACT   ///
    ////////////////////////////////////////////////////////

    function lensHub_whitelistProfileCreator(
        address profileCreator,
        bool whitelist
    ) external onlyOwnerOrControllerContract {
        LENS_HUB.whitelistProfileCreator(profileCreator, whitelist);
    }

    function lensHub_whitelistFollowModule(
        address followModule,
        bool whitelist
    ) external onlyOwnerOrControllerContract {
        LENS_HUB.whitelistFollowModule(followModule, whitelist);
    }

    function lensHub_whitelistReferenceModule(
        address referenceModule,
        bool whitelist
    ) external onlyOwnerOrControllerContract {
        LENS_HUB.whitelistReferenceModule(referenceModule, whitelist);
    }

    function lensHub_whitelistActionModule(
        address actionModule,
        bool whitelist
    ) external onlyOwnerOrControllerContract {
        LENS_HUB.whitelistActionModule(actionModule, whitelist);
    }

    // Interface to the Deprecated LensHub V1 to unwhitelist collect modules
    function lensHub_whitelistCollectModule(
        address collectModule,
        bool whitelist
    ) external onlyOwnerOrControllerContract {
        ILensHub_V1(address(LENS_HUB)).whitelistCollectModule(collectModule, whitelist);
    }

    // This allows the governance to call anything on behalf of itself.
    // And also allows the Upgradable contract to call anything, except the LensHub with Governance permissions.
    function executeAsGovernance(
        address target,
        bytes calldata data
    ) external payable onlyOwnerOrControllerContract returns (bytes memory) {
        if (msg.sender == controllerContract && target == address(LENS_HUB)) {
            revert Unauthorized();
        }
        (bool success, bytes memory returnData) = target.call{gas: gasleft(), value: msg.value}(data);
        require(success, string(returnData));
        return returnData;
    }
}
