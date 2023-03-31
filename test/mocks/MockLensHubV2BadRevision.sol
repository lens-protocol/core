// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {LensBaseERC721} from 'contracts/base/LensBaseERC721.sol';
import {LensMultiState} from 'contracts/base/LensMultiState.sol';
import {VersionedInitializable} from 'contracts/base/upgradeability/VersionedInitializable.sol';
import {MockLensHubV2Storage} from 'test/mocks/MockLensHubV2Storage.sol';

/**
 * @dev A mock upgraded LensHub contract that is used to validate that the initializer cannot be called with the same revision.
 */
contract MockLensHubV2BadRevision is LensBaseERC721, VersionedInitializable, LensMultiState, MockLensHubV2Storage {
    uint256 internal constant REVISION = 1; // Should fail the initializer check

    function initialize(uint256 newValue) external initializer {
        _additionalValue = newValue;
    }

    function setAdditionalValue(uint256 newValue) external {
        _additionalValue = newValue;
    }

    function getAdditionalValue() external view returns (uint256) {
        return _additionalValue;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
