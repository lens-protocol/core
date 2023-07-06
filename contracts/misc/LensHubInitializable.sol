// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {LensHub} from 'contracts/LensHub.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {GovernanceLib} from 'contracts/libraries/GovernanceLib.sol';
import {ILensHubInitializable} from 'contracts/interfaces/ILensHubInitializable.sol';
import {VersionedInitializable} from 'contracts/base/upgradeability/VersionedInitializable.sol';

/**
 * @title LensHubInitializable
 * @author Lens Protocol
 *
 * @notice Extension of LensHub contract that includes initialization for fresh deployments.
 */
contract LensHubInitializable is LensHub, VersionedInitializable, ILensHubInitializable {
    // Constant for upgradeability purposes, see VersionedInitializable.
    // Do not confuse it with the EIP-712 version number.
    uint256 internal constant REVISION = 1;

    constructor(
        address moduleGlobals,
        address followNFTImpl,
        address collectNFTImpl,
        address lensHandlesAddress,
        address tokenHandleRegistryAddress,
        address legacyFeeFollowModule,
        address legacyProfileFollowModule,
        address newFeeFollowModule,
        uint256 profileGuardianCooldown
    )
        LensHub(
            moduleGlobals,
            followNFTImpl,
            collectNFTImpl,
            lensHandlesAddress,
            tokenHandleRegistryAddress,
            legacyFeeFollowModule,
            legacyProfileFollowModule,
            newFeeFollowModule,
            profileGuardianCooldown
        )
    {}

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
