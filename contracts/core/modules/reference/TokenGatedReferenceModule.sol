// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {IReferenceModule} from '../../../interfaces/IReferenceModule.sol';
import {ModuleBase} from '../ModuleBase.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ILensHub} from '../../../interfaces/ILensHub.sol';

/**
 * @title TokenGatedReferenceModule
 * @author Lens Protocol
 *
 * @notice A simple reference module that validates that comments or mirrors originate from a profile
 * owned by an address that has at least _minimumBalance of ERC-20 token at address _token.
 */
contract TokenGatedReferenceModule is IReferenceModule, ModuleBase {
    address private _token;
    uint256 private _minimumBalance;

    /**
     * @dev The constructor sets token address and the minimum balance.
     *
     * @param token The ERC-20 token address to test the balance against.
     * @param minimumBalance The minimum balance of the ERC-20 token needed to reference the publication.
     */
    constructor(
        address hub,
        address token,
        uint256 minimumBalance
    ) ModuleBase(hub) {
        _token = token;
        _minimumBalance = minimumBalance;
    }

    /**
     * @dev There is nothing needed at initialization.
     */
    function initializeReferenceModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        return new bytes(0);
    }

    /**
     * @notice Validates that the commenting profile's owner passes the token gate.
     *
     * NOTE: We don't need to care what the pointed publication is in this context.
     */
    function processComment(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed
    ) external view override {
        address commentCreatorAddress = IERC721(HUB).ownerOf(profileId);
        _checkBalanceOf(commentCreatorAddress);
    }

    /**
     * @notice Validates that the mirroring profile's owner passes the token gate.
     *
     * NOTE: We don't need to care what the pointed publication is in this context.
     */
    function processMirror(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed
    ) external view override {
        address mirrorCreatorAddress = IERC721(HUB).ownerOf(profileId);
        _checkBalanceOf(mirrorCreatorAddress);
    }

    /**
     * @notice Validates that an address passes the token gate.
     *
     * @param referenceCreator The owner address to test the token gate against.
     */
    function _checkBalanceOf(address referenceCreator) internal view {
        uint256 balance = IERC20(_token).balanceOf(referenceCreator);
        require(
            balance > _minimumBalance,
            'Profile owner does not have the minimum amount of specific token to create a reference.'
        );
    }

    /**
     * @dev Returns the token address.
     */
    function getTokenAddress() external view returns (address) {
        return _token;
    }

    /**
     * @dev Returns the minimum balance.
     */
    function getMinimumBalance() external view returns (uint256) {
        return _minimumBalance;
    }
}
