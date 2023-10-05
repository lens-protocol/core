// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract ControllableByContract is Ownable {
    event ControllerContractUpdated(address previousControllerContract, address newControllerContract);

    error Unauthorized();

    address public controllerContract;

    modifier onlyOwnerOrControllerContract() {
        if (msg.sender != owner() && msg.sender != controllerContract) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address owner_) Ownable() {
        _transferOwnership(owner_);
    }

    function clearControllerContract() external onlyOwnerOrControllerContract {
        emit ControllerContractUpdated(controllerContract, address(0));
        delete controllerContract;
    }

    function setControllerContract(address newControllerContract) external onlyOwner {
        emit ControllerContractUpdated(controllerContract, newControllerContract);
        controllerContract = newControllerContract;
    }
}
