// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {ILensMultiState} from 'contracts/interfaces/ILensMultiState.sol';
import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';
import {GovernanceLib} from 'contracts/libraries/GovernanceLib.sol';

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
        if (_state == Types.ProtocolState.Paused) {
            revert Errors.Paused();
        }
        _;
    }

    modifier whenPublishingEnabled() {
        if (_state != Types.ProtocolState.Unpaused) {
            revert Errors.PublishingPaused();
        }
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

    function setState(Types.ProtocolState newState) external override {
        GovernanceLib.setState(newState);
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
}
