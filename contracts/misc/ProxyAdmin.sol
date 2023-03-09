// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {TransparentUpgradeableProxy} from 'contracts/base/upgradeability/TransparentUpgradeableProxy.sol';

contract ProxyAdmin {
    error Unauthorized();

    TransparentUpgradeableProxy public immutable LENS_HUB_PROXY;
    address public previousImplementation;

    address public proxyAdminOwner;
    address public upgradeContract;

    modifier onlyProxyAdminOwner() {
        if (msg.sender != proxyAdminOwner) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyProxyAdminOwnerOrUpgradeContract() {
        if (msg.sender != proxyAdminOwner && msg.sender != upgradeContract) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address lensHubAddress_, address previousImplementation_, address proxyAdminOwner_) {
        LENS_HUB_PROXY = TransparentUpgradeableProxy(payable(lensHubAddress_));
        previousImplementation = previousImplementation_;
        proxyAdminOwner = proxyAdminOwner_;
    }

    ///////////////////////////////////
    /// TransparentUpgradeableProxy ///
    ///     Standard Functions      ///
    ///////////////////////////////////

    function proxy_upgrade(address newImplementation) external onlyProxyAdminOwnerOrUpgradeContract {
        previousImplementation = LENS_HUB_PROXY.implementation();
        LENS_HUB_PROXY.upgradeTo(newImplementation);
        delete upgradeContract;
    }

    function proxy_upgradeAndCall(
        address newImplementation,
        bytes calldata data
    ) external onlyProxyAdminOwnerOrUpgradeContract {
        previousImplementation = LENS_HUB_PROXY.implementation();
        LENS_HUB_PROXY.upgradeToAndCall(newImplementation, data);
        delete upgradeContract;
    }

    function proxy_changeAdmin(address newAdmin) external onlyProxyAdminOwner {
        LENS_HUB_PROXY.changeAdmin(newAdmin);
    }

    ///////////////////////////////////
    ///     Extra functionality     ///
    ///////////////////////////////////

    function rollbackLastUpgrade() external onlyProxyAdminOwner {
        LENS_HUB_PROXY.upgradeTo(previousImplementation);
    }

    function clearUpgradeContract() external onlyProxyAdminOwner {
        delete upgradeContract;
    }

    //////////////////////////////
    ///   Permissions setters  ///
    //////////////////////////////

    function setProxyAdminOwner(address newProxyAdminOwner) external onlyProxyAdminOwner {
        proxyAdminOwner = newProxyAdminOwner;
    }

    function setUpgradeContract(address newUpgradeContract) external onlyProxyAdminOwner {
        upgradeContract = newUpgradeContract;
    }

    //////////////////////////////
    ///        Getters         ///
    //////////////////////////////

    function currentImplementation() external returns (address) {
        return LENS_HUB_PROXY.implementation();
    }
}
