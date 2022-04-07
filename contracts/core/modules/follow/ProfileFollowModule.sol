// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {IFollowModule} from '../../../interfaces/IFollowModule.sol';
import {Errors} from '../../../libraries/Errors.sol';
import {ModuleBase} from '../ModuleBase.sol';
import {FollowValidatorFollowModuleBase} from './FollowValidatorFollowModuleBase.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @title ProfileFollowModule
 * @author Lens Protocol
 *
 * @notice This follow module only allows profiles that are not already following in the current revision to follow.
 */
contract ProfileFollowModule is FollowValidatorFollowModuleBase {
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))
        internal _isProfileFollowingByRevisionByProfile;

    mapping(uint256 => uint256) internal _revisionByProfile;

    constructor(address hub) ModuleBase(hub) {}

    /**
     * @notice This follow module works on custom profile owner approvals.
     *
     * @param profileId The profile ID of the profile to initialize this module for.
     * @param data The arbitrary data parameter, decoded into:
     *      uint256 revision: The revision number to be used in this module initialization.
     *
     * @return bytes An abi encoded bytes parameter, which is the same as the passed data parameter.
     */
    function initializeFollowModule(uint256 profileId, bytes calldata data)
        external
        override
        onlyHub
        returns (bytes memory)
    {
        _revisionByProfile[profileId] = abi.decode(data, (uint256));
        return data;
    }

    /**
     * @dev Processes a follow by:
     *  1. Validating that the follower owns the profile passed through the data param
     *  2. Validating that the profile that is being used to execute the follow is not already following
     *     the given profile in the current revision
     */
    function processFollow(
        address follower,
        uint256 profileId,
        bytes calldata data
    ) external override onlyHub {
        uint256 followerProfileId = abi.decode(data, (uint256));
        if (IERC721(HUB).ownerOf(followerProfileId) != follower) {
            revert Errors.NotProfileOwner();
        }
        uint256 revision = _revisionByProfile[profileId];
        if (_isProfileFollowingByRevisionByProfile[profileId][revision][followerProfileId]) {
            revert Errors.FollowInvalid();
        } else {
            _isProfileFollowingByRevisionByProfile[profileId][revision][followerProfileId] = true;
        }
    }

    /**
     * @dev We don't need to execute any additional logic on transfers in this follow module.
     */
    function followModuleTransferHook(
        uint256 profileId,
        address from,
        address to,
        uint256 followNFTTokenId
    ) external override {}
}
