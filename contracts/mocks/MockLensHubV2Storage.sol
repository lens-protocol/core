// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {DataTypes} from '../libraries/constants/DataTypes.sol';
import {LensHubStorage} from '../core/storage/LensHubStorage.sol';

/**
 * @dev This is a simple mock LensHub storage contract to be used for testing.
 */
contract MockLensHubV2Storage is LensHubStorage {
    uint256 internal _additionalValue;
}
