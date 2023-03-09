// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ProxyAdmin} from 'contracts/misc/access/ProxyAdmin.sol';
import {Governance} from 'contracts/misc/access/Governance.sol';
import {ImmutableOwnable} from 'contracts/misc/ImmutableOwnable.sol';

contract LensV2UpgradeContract is ImmutableOwnable {
    ProxyAdmin public immutable PROXY_ADMIN;
    Governance public immutable GOVERNANCE;
    address public immutable newImplementation;
    address[] public oldFollowModulesToUnwhitelist;
    address[] public newFollowModulesToWhitelist;
    address[] public oldReferenceModulesToUnwhitelist;
    address[] public newReferenceModulesToWhitelist;
    address[] public oldCollectModulesToUnwhitelist;
    address[] public newActionModulesToWhitelist;

    constructor(
        address proxyAdminAddress,
        address governanceAddress,
        address owner,
        address lensHub,
        address newImplementationAddress,
        address[] memory oldFollowModulesToUnwhitelist_,
        address[] memory newFollowModulesToWhitelist_,
        address[] memory oldReferenceModulesToUnwhitelist_,
        address[] memory newReferenceModulesToWhitelist_,
        address[] memory oldCollectModulesToUnwhitelist_,
        address[] memory newActionModulesToWhitelist_
    ) ImmutableOwnable(owner, lensHub) {
        PROXY_ADMIN = ProxyAdmin(proxyAdminAddress);
        GOVERNANCE = Governance(governanceAddress);
        newImplementation = newImplementationAddress;
        oldFollowModulesToUnwhitelist = oldFollowModulesToUnwhitelist_;
        newFollowModulesToWhitelist = newFollowModulesToWhitelist_;
        oldReferenceModulesToUnwhitelist = oldReferenceModulesToUnwhitelist_;
        newReferenceModulesToWhitelist = newReferenceModulesToWhitelist_;
        oldCollectModulesToUnwhitelist = oldCollectModulesToUnwhitelist_;
        newActionModulesToWhitelist = newActionModulesToWhitelist_;
    }

    function executeLensV2Upgrade() external onlyOwner {
        // _preUpgradeChecks();
        _upgrade();
        // _postUpgradeChecks();
    }

    function _upgrade() internal {
        _unwhitelistOldFollowModules();
        _unwhitelistOldReferenceModules();
        _unwhitelistOldCollectModules();

        PROXY_ADMIN.proxy_upgrade(newImplementation);

        _whitelistNewFollowModules();
        _whitelistNewReferenceModules();
        _whitelistNewActionModules();

        GOVERNANCE.clearControllerContract();
    }

    function _unwhitelistOldFollowModules() internal {
        for (uint256 i = 0; i < oldFollowModulesToUnwhitelist.length; i++) {
            GOVERNANCE.lensHub_whitelistFollowModule(oldFollowModulesToUnwhitelist[i], false);
        }
    }

    function _unwhitelistOldReferenceModules() internal {
        for (uint256 i = 0; i < oldReferenceModulesToUnwhitelist.length; i++) {
            GOVERNANCE.lensHub_whitelistReferenceModule(oldReferenceModulesToUnwhitelist[i], false);
        }
    }

    function _unwhitelistOldCollectModules() internal {
        for (uint256 i = 0; i < oldCollectModulesToUnwhitelist.length; i++) {
            GOVERNANCE.lensHub_whitelistCollectModule(oldCollectModulesToUnwhitelist[i], false);
        }
    }

    function _whitelistNewFollowModules() internal {
        for (uint256 i = 0; i < newFollowModulesToWhitelist.length; i++) {
            GOVERNANCE.lensHub_whitelistFollowModule(newFollowModulesToWhitelist[i], true);
        }
    }

    function _whitelistNewReferenceModules() internal {
        for (uint256 i = 0; i < newReferenceModulesToWhitelist.length; i++) {
            GOVERNANCE.lensHub_whitelistReferenceModule(newReferenceModulesToWhitelist[i], true);
        }
    }

    function _whitelistNewActionModules() internal {
        for (uint256 i = 0; i < newActionModulesToWhitelist.length; i++) {
            uint256 moduleId = i + 1; // Starting from 1
            GOVERNANCE.lensHub_whitelistActionModuleId(newActionModulesToWhitelist[i], moduleId);
        }
    }

    function _whitelistNewCollectModules() internal {
        // TODO: Implement calling each action module needed and whitelisting collectModules inside it
        // GOVERNANCE.executeAsGovernance(target, data);
    }
}
