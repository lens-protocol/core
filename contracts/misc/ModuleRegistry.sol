// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract ModuleRegistry {
    event ModuleRegistered(
        address indexed moduleAddress,
        ModuleType indexed moduleType,
        address registrar,
        uint256 timestamp
    );

    struct Module {
        address registrar;
        bool isPublicationActionModule;
        bool isReferenceModule;
        bool isFollowModule;
    }

    enum ModuleType {
        NOT_REGISTERED,
        PUBLICATION_ACTION_MODULE,
        REFERENCE_MODULE,
        FOLLOW_MODULE
    }

    mapping(address => Module) public modules;

    /// @dev This is frontrunnable, so...
    function register(address moduleAddress, ModuleType moduleType) public {
        if (moduleType == ModuleType.NOT_REGISTERED) {
            revert('Module type cannot be NOT_REGISTERED');
        }
        if (modules[moduleAddress].moduleType != ModuleType.NOT_REGISTERED) {
            revert('Module already registered');
        }
        if (moduleAddress.code.length == 0) {
            revert('Module address is not a contract');
        }
        modules[moduleAddress] = Module(msg.sender, moduleType);
        emit ModuleRegistered(moduleAddress, moduleType, msg.sender, block.timestamp);
    }

    function getModuleType(address moduleAddress) public view returns (ModuleType) {
        return modules[moduleAddress].moduleType;
    }

    function getModuleRegistrar(address moduleAddress) public view returns (address) {
        return modules[moduleAddress].registrar;
    }

    function isRegistered(address moduleAddress) public view returns (bool) {
        return modules[moduleAddress].moduleType != ModuleType.NOT_REGISTERED;
    }

    function areRegistered(address[] calldata moduleAddresses) public view returns (bool) {
        uint256 i;
        while (i < moduleAddresses.length) {
            if (modules[moduleAddresses[i]].moduleType == ModuleType.NOT_REGISTERED) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }
}
