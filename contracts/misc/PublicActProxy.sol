// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {CollectPublicationAction} from 'contracts/modules/act/collect/CollectPublicationAction.sol';
import {PublicActProxy_MetaTx} from 'contracts/misc/PublicActProxy_MetaTx.sol';

// This contract should be the owner/DE of the publicationActionParams.actorProfileId
// This contract should be set as publicationActionParams.transactionExecutor
// Correct collectNftRecipient should be passed in the publicationActionParams.actionModuleData

/*
    Here is an example of PublicationActionParams to pass:

    struct PublicationActionParams {
        publicationActedProfileId: ---
        publicationActedId: ---
        actorProfileId: this contract's profile
        referrerProfileIds: ---
        referrerPubIds: ---
        actionModuleAddress: ---
        actionModuleData: {
            collectNftRecipient: who shall receive the NFT
            collectData: {
                expectedCurrency: should match what's stored in CollectModule
                expectedAmount: should match what's stored in CollectModule
            }
        }
    }
*/

/// @title PublicActProxy
/// @author LensProtocol
/// @notice This contract allows anyone to Act on a publication without holding a profile
/// @dev This contract holds a profile (or is a DE of that profile) and acts on behalf of the caller
contract PublicActProxy is PublicActProxy_MetaTx {
    using SafeERC20 for IERC20;

    ILensHub public immutable HUB;
    CollectPublicationAction public immutable COLLECT_PUBLICATION_ACTION;

    constructor(address lensHub, address collectPublicationAction) {
        HUB = ILensHub(lensHub);
        COLLECT_PUBLICATION_ACTION = CollectPublicationAction(collectPublicationAction);
    }

    // The free act is pretty simple, but should follow the rules above:
    /// @notice For actions not involving any ERC20 transfers or approvals from the actor
    /// @dev This is used in the same way as the general .act() function, while following the rules above.
    function publicFreeAct(Types.PublicationActionParams calldata publicationActionParams) external {
        HUB.act(publicationActionParams);
    }

    /// @notice For actions involving ERC20 transfers or approvals from the actor
    /// @dev You need to provide the currency that will be taken from the actor, the amount, and the address to approve
    /// to (usually it's the address of the CollectModule, or any other contract that performs the .transferFrom).
    /// You need to set an approval to publicActProxy, cause the amount will be taken from you by this proxy first.
    function publicPaidAct(
        Types.PublicationActionParams calldata publicationActionParams,
        address currency,
        uint256 amount,
        address approveTo
    ) external {
        _publicAct(publicationActionParams, currency, amount, approveTo, msg.sender);
    }

    /// @notice For actions involving ERC20 transfers or approvals from the actor (with signature)
    /// @dev See publicPaidAct() - same, but with a signature. The signer has to give their approval in this case.
    function publicPaidActWithSig(
        Types.PublicationActionParams calldata publicationActionParams,
        address currency,
        uint256 amount,
        address approveTo,
        Types.EIP712Signature calldata signature
    ) external {
        _validatePaidActSignature(signature, publicationActionParams, PaymentParams(currency, amount, approveTo));
        _publicAct(publicationActionParams, currency, amount, approveTo, signature.signer);
    }

    // Internal functions

    function _publicAct(
        Types.PublicationActionParams calldata publicationActionParams,
        address currency,
        uint256 amount,
        address approveTo,
        address transactionExecutor
    ) internal {
        if (amount > 0) {
            IERC20(currency).safeTransferFrom(transactionExecutor, address(this), amount);
            IERC20(currency).safeIncreaseAllowance(approveTo, amount);
        }
        HUB.act(publicationActionParams);
    }
}
