// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {Events} from '../../libraries/constants/Events.sol';
import {DataTypes} from '../../libraries/constants/DataTypes.sol';
import {Errors} from '../../libraries/constants/Errors.sol';
import {ILensMultiState} from '../../interfaces/ILensMultiState.sol';
import {GeneralHelpers} from '../../libraries/GeneralHelpers.sol';

/**
 * @title LensMultiState
 *
 * @notice This is an abstract contract that implements internal LensHub state validation. Setting
 * is delegated to the GeneralLib.
 *
 * whenNotPaused: Either publishingPaused or Unpaused.
 * whenPublishingEnabled: When Unpaused only.
 */
abstract contract LensMultiState is ILensMultiState {
    DataTypes.ProtocolState private _state; // slot 12

    modifier whenNotPaused() {
        _validateNotPaused();
        _;
    }

    modifier whenPublishingEnabled() {
        _validatePublishingEnabled();
        _;
    }

    modifier onlyProfileOwnerOrDelegatedExecutor(
        address expectedOwnerOrDelegatedExecutor,
        uint256 profileId
    ) {
        GeneralHelpers.validateAddressIsProfileOwnerOrDelegatedExecutor(
            expectedOwnerOrDelegatedExecutor,
            profileId
        );
        _;
    }

    modifier onlyProfileOwner(address expectedOwner, uint256 profileId) {
        GeneralHelpers.validateAddressIsProfileOwner(expectedOwner, profileId);
        _;
    }

    modifier whenNotBlocked(uint256 profile, uint256 byProfile) {
        GeneralHelpers.validateNotBlocked(profile, byProfile);
        _;
    }

    modifier onlyValidPointedPub(uint256 profileId, uint256 pubId) {
        GeneralHelpers.validatePointedPub(profileId, pubId);
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
    function getState() external view override returns (DataTypes.ProtocolState) {
        return _state;
    }

    function _validatePublishingEnabled() internal view {
        if (_state != DataTypes.ProtocolState.Unpaused) {
            revert Errors.PublishingPaused();
        }
    }

    function _validateNotPaused() internal view {
        if (_state == DataTypes.ProtocolState.Paused) revert Errors.Paused();
    }
}
