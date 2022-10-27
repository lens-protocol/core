// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {VersionedInitializable} from '../upgradeability/VersionedInitializable.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @title MockAccessControlV2BadRevision
 * @author Lens Protocol
 *
 * @notice This contract enables additional access control for encrypted publications on Lens by reporting whether
 *      an address owns or has control over a given profile.
 */
contract MockAccessControlV2BadRevision is VersionedInitializable {
    uint256 internal constant REVISION = 1;

    address internal immutable LENS_HUB;

    uint256 public randomNumber = 7; // contract must be different to original

    constructor(address _lensHub) {
        LENS_HUB = _lensHub;
    }

    function initialize() external initializer {}

    /**
     * @dev Function used to check whether an address is the owner of a profile.
     *
     * @param requestorAddress The address to check ownership over a profile.
     * @param profileId The ID of the profile being checked for ownership.
     * @param data Optional data parameter, which may be used in future upgrades.
     * @return Boolean indicating whether address owns the profile or not.
     */
    function hasAccess(
        address requestorAddress,
        uint256 profileId,
        bytes memory data
    ) external view returns (bool) {
        return IERC721(LENS_HUB).ownerOf(profileId) == requestorAddress;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
