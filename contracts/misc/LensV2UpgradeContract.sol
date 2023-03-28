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
        uint256 oldFollowModulesToUnwhitelistLength = oldFollowModulesToUnwhitelist.length;
        uint256 i;
        while (i < oldFollowModulesToUnwhitelistLength) {
            GOVERNANCE.lensHub_whitelistFollowModule(oldFollowModulesToUnwhitelist[i], false);
            unchecked {
                ++i;
            }
        }
    }

    function _unwhitelistOldReferenceModules() internal {
        uint256 oldReferenceModulesToUnwhitelistLength = oldReferenceModulesToUnwhitelist.length;
        uint256 i;
        while (i < oldReferenceModulesToUnwhitelistLength) {
            GOVERNANCE.lensHub_whitelistReferenceModule(oldReferenceModulesToUnwhitelist[i], false);
            unchecked {
                ++i;
            }
        }
    }

    function _unwhitelistOldCollectModules() internal {
        uint256 oldCollectModulesToUnwhitelistLength = oldCollectModulesToUnwhitelist.length;
        uint256 i;
        while (i < oldCollectModulesToUnwhitelistLength) {
            GOVERNANCE.lensHub_whitelistCollectModule(oldCollectModulesToUnwhitelist[i], false);
            unchecked {
                ++i;
            }
        }
    }

    function _whitelistNewFollowModules() internal {
        uint256 newFollowModulesToWhitelistLength = newFollowModulesToWhitelist.length;
        uint256 i;
        while (i < newFollowModulesToWhitelistLength) {
            GOVERNANCE.lensHub_whitelistFollowModule(newFollowModulesToWhitelist[i], true);
            unchecked {
                ++i;
            }
        }
    }

    function _whitelistNewReferenceModules() internal {
        uint256 newReferenceModulesToWhitelistLength = newReferenceModulesToWhitelist.length;
        uint256 i;
        while (i < newReferenceModulesToWhitelistLength) {
            GOVERNANCE.lensHub_whitelistReferenceModule(newReferenceModulesToWhitelist[i], true);
            unchecked {
                ++i;
            }
        }
    }

    function _whitelistNewActionModules() internal {
        uint256 newActionModulesToWhitelistLength = newActionModulesToWhitelist.length;
        uint256 i;
        while (i < newActionModulesToWhitelistLength) {
            uint256 moduleId = i + 1; // Starting from 1
            GOVERNANCE.lensHub_whitelistActionModuleId(newActionModulesToWhitelist[i], moduleId);
            unchecked {
                ++i;
            }
        }
    }
}
