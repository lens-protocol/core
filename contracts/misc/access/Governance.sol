// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {ControllableByContract} from 'contracts/misc/access/ControllableByContract.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

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

    function lensHub_setTreasuryParams(
        address newTreasury,
        uint16 newTreasuryFee
    ) external onlyOwnerOrControllerContract {
        LENS_HUB.setTreasury(newTreasury);
        LENS_HUB.setTreasuryFee(newTreasuryFee);
    }

    function lensHub_setState(Types.ProtocolState newState) external onlyOwnerOrControllerContract {
        LENS_HUB.setState(newState);
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

        if (!success) {
            uint256 len = returnData.length;
            assembly {
                revert(add(returnData, 32), len)
            }
        }

        return returnData;
    }
}
