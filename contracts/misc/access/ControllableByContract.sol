// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract ControllableByContract is Ownable {
    error Unauthorized();

    address public controllerContract;

    modifier onlyOwnerOrControllerContract() {
        if (msg.sender != owner() && msg.sender != controllerContract) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address owner) Ownable() {
        _transferOwnership(owner);
    }

    function clearControllerContract() external onlyOwnerOrControllerContract {
        delete controllerContract;
    }

    function setControllerContract(address newControllerContract) external onlyOwner {
        controllerContract = newControllerContract;
    }
}
