// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ProxyAdmin} from './access/ProxyAdmin.sol';
import {Governance} from './access/Governance.sol';
import {ImmutableOwnable} from './ImmutableOwnable.sol';
import {ILensVersion} from '../interfaces/ILensVersion.sol';

contract LensV2UpgradeContract is ImmutableOwnable {
    ProxyAdmin public immutable PROXY_ADMIN;
    Governance public immutable GOVERNANCE;
    address public immutable newImplementation;
    address public immutable TREASURY;
    uint16 public immutable TREASURY_FEE;

    constructor(
        address proxyAdminAddress,
        address governanceAddress,
        address owner,
        address lensHub,
        address newImplementationAddress,
        address treasury,
        uint16 treasuryFee
    ) ImmutableOwnable(owner, lensHub) {
        PROXY_ADMIN = ProxyAdmin(proxyAdminAddress);
        GOVERNANCE = Governance(governanceAddress);
        newImplementation = newImplementationAddress;
        TREASURY = treasury;
        TREASURY_FEE = treasuryFee;
    }

    function executeLensV2Upgrade() external onlyOwner {
        // _preUpgradeChecks();
        _upgrade();
        // _postUpgradeChecks();
    }

    function _upgrade() internal {
        PROXY_ADMIN.proxy_upgradeAndCall(newImplementation, abi.encodeCall(ILensVersion.emitVersion, ()));
        GOVERNANCE.lensHub_setTreasuryParams(TREASURY, TREASURY_FEE);
        GOVERNANCE.clearControllerContract();
    }
}
