// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ProxyAdmin} from 'contracts/misc/access/ProxyAdmin.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {ImmutableOwnable} from 'contracts/misc/ImmutableOwnable.sol';

contract LensV2UpgradeContract is ImmutableOwnable {
    ProxyAdmin public immutable PROXY_ADMIN;
    Governance public immutable GOVERNANCE;
    address public immutable newImplementation;

    constructor(
        address proxyAdminAddress,
        address governanceAddress,
        address owner,
        address lensHub,
        address newImplementationAddress
    ) ImmutableOwnable(owner, lensHub) {
        PROXY_ADMIN = ProxyAdmin(proxyAdminAddress);
        GOVERNANCE = Governance(governanceAddress);
        newImplementation = newImplementationAddress;
    }

    function executeLensV2Upgrade() external onlyOwner {
        // _preUpgradeChecks();
        _upgrade();
        // _postUpgradeChecks();
    }

    function _upgrade() internal {
        PROXY_ADMIN.proxy_upgrade(newImplementation);
        GOVERNANCE.clearControllerContract();
    }
}
