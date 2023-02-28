// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Events} from 'contracts/libraries/constants/Events.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {ILensMultiState} from 'contracts/interfaces/ILensMultiState.sol';
import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';

/**
 * @title LensMultiState
 *
 * @notice This is an abstract contract that implements internal LensHub state validation.
 *
 * whenNotPaused: Either publishingPaused or Unpaused.
 * whenPublishingEnabled: When Unpaused only.
 */
abstract contract LensMultiState is ILensMultiState {
    Types.ProtocolState private _state; // slot 12

    modifier whenNotPaused() {
        _validateNotPaused();
        _;
    }

    modifier whenPublishingEnabled() {
        _validatePublishingEnabled();
        _;
    }

    modifier onlyProfileOwnerOrDelegatedExecutor(address expectedOwnerOrDelegatedExecutor, uint256 profileId) {
        ValidationLib.validateAddressIsProfileOwnerOrDelegatedExecutor(expectedOwnerOrDelegatedExecutor, profileId);
        _;
    }

    modifier onlyProfileOwner(address expectedOwner, uint256 profileId) {
        ValidationLib.validateAddressIsProfileOwner(expectedOwner, profileId);
        _;
    }

    modifier whenNotBlocked(uint256 profile, uint256 byProfile) {
        ValidationLib.validateNotBlocked(profile, byProfile);
        _;
    }

    modifier onlyValidPointedPub(uint256 profileId, uint256 pubId) {
        ValidationLib.validatePointedPub(profileId, pubId);
        _;
    }

    /**
     * @notice Returns the current protocol state.
     *
     * @return ProtocolState The Protocol state, an enum, where:
     *      0: Unpaused
     *      1: PublishingPaused
     *      2: Paused
     */
    function getState() external view override returns (Types.ProtocolState) {
        return _state;
    }

    function _validatePublishingEnabled() internal view {
        if (_state != Types.ProtocolState.Unpaused) {
            revert Errors.PublishingPaused();
        }
    }

    function _validateNotPaused() internal view {
        if (_state == Types.ProtocolState.Paused) revert Errors.Paused();
    }
}
