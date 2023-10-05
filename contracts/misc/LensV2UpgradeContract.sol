// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ProxyAdmin} from 'contracts/misc/access/ProxyAdmin.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {ImmutableOwnable} from 'contracts/misc/ImmutableOwnable.sol';
import {ILensVersion} from 'contracts/interfaces/ILensVersion.sol';

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
        PROXY_ADMIN.proxy_upgradeAndCall(newImplementation, abi.encodeCall(ILensVersion.emitVersion, ()));
        GOVERNANCE.clearControllerContract();
    }
}
