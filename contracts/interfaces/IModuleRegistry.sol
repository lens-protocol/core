// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IModuleRegistry {
    enum ModuleType {
        __, // Just to avoid 0 as valid ModuleType
        PUBLICATION_ACTION_MODULE,
        REFERENCE_MODULE,
        FOLLOW_MODULE
    }

    // Modules functions

    function verifyModule(address moduleAddress, uint256 moduleType) external returns (bool);

    function registerModule(address moduleAddress, uint256 moduleType) external returns (bool);

    function getModuleTypes(address moduleAddress) external view returns (uint256);

    function isModuleRegistered(address moduleAddress) external view returns (bool);

    function isModuleRegisteredAs(address moduleAddress, uint256 moduleType) external view returns (bool);

    // Currencies functions

    function verifyErc20Currency(address currencyAddress) external returns (bool);

    function registerErc20Currency(address currencyAddress) external returns (bool);

    function isErc20CurrencyRegistered(address currencyAddress) external view returns (bool);
}
