// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {TransparentUpgradeableProxy} from 'contracts/base/upgradeability/TransparentUpgradeableProxy.sol';
import {ControllableByContract} from 'contracts/misc/access/ControllableByContract.sol';

contract ProxyAdmin is ControllableByContract {
    TransparentUpgradeableProxy public immutable LENS_HUB_PROXY;
    address public previousImplementation;

    constructor(
        address lensHubAddress_,
        address previousImplementation_,
        address proxyAdminOwner_
    ) ControllableByContract(proxyAdminOwner_) {
        LENS_HUB_PROXY = TransparentUpgradeableProxy(payable(lensHubAddress_));
        previousImplementation = previousImplementation_;
    }

    function currentImplementation() external returns (address) {
        return LENS_HUB_PROXY.implementation();
    }

    /////////////////////////////////////////////////////////
    ///               ONLY PROXY ADMIN OWNER              ///
    /////////////////////////////////////////////////////////

    function rollbackLastUpgrade() external onlyOwner {
        LENS_HUB_PROXY.upgradeTo(previousImplementation);
    }

    function proxy_changeAdmin(address newAdmin) external onlyOwner {
        LENS_HUB_PROXY.changeAdmin(newAdmin);
    }

    /////////////////////////////////////////////////////////
    ///   ONLY PROXY ADMIN OWNER OR CONTROLLER CONTRACT   ///
    /////////////////////////////////////////////////////////

    function proxy_upgrade(address newImplementation) external onlyOwnerOrControllerContract {
        previousImplementation = LENS_HUB_PROXY.implementation();
        LENS_HUB_PROXY.upgradeTo(newImplementation);
        delete controllerContract;
    }

    function proxy_upgradeAndCall(
        address newImplementation,
        bytes calldata data
    ) external onlyOwnerOrControllerContract {
        previousImplementation = LENS_HUB_PROXY.implementation();
        LENS_HUB_PROXY.upgradeToAndCall(newImplementation, data);
        delete controllerContract;
    }
}
