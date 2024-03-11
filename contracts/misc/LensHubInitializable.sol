// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {LensHub} from '../LensHub.sol';
import {Types} from '../libraries/constants/Types.sol';
import {GovernanceLib} from '../libraries/GovernanceLib.sol';
import {ILensHubInitializable} from '../interfaces/ILensHubInitializable.sol';
import {VersionedInitializable} from '../base/upgradeability/VersionedInitializable.sol';

/**
 * @title LensHubInitializable
 * @author Lens Protocol
 *
 * @notice Extension of LensHub contract that includes initialization for fresh deployments.
 *
 * @custom:upgradeable Transparent upgradeable proxy.
 * See `../LensHub.sol` for the version without initalizer.
 */
contract LensHubInitializable is LensHub, VersionedInitializable, ILensHubInitializable {
    // Constant for upgradeability purposes, see VersionedInitializable.
    // Do not confuse it with the EIP-712 version number.
    uint256 internal constant REVISION = 1;

    constructor(
        address followNFTImpl,
        address collectNFTImpl,
        address moduleRegistry,
        uint256 tokenGuardianCooldown,
        Types.MigrationParams memory migrationParams
    ) LensHub(followNFTImpl, collectNFTImpl, moduleRegistry, tokenGuardianCooldown, migrationParams) {}

    /**
     * @inheritdoc ILensHubInitializable
     * @custom:permissions Callable once. This is expected to be atomically called during the deployment by the Proxy.
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        address newGovernance
    ) external override initializer {
        super._initialize(name, symbol);
        GovernanceLib.initState(Types.ProtocolState.Paused);
        GovernanceLib.setGovernance(newGovernance);
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
