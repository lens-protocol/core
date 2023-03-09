// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract UpgradeContractPermissions is Ownable {
    error Unauthorized();

    address public upgradeContract;

    modifier onlyOwnerOrUpgradeContract() {
        if (msg.sender != owner() && msg.sender != upgradeContract) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address owner) Ownable() {
        _transferOwnership(owner);
    }

    function clearUpgradeContract() external onlyOwnerOrUpgradeContract {
        delete upgradeContract;
    }

    function setUpgradeContract(address newUpgradeContract) external onlyOwner {
        upgradeContract = newUpgradeContract;
    }
}
