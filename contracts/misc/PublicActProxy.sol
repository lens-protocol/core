// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ILensHub} from '../interfaces/ILensHub.sol';
import {Types} from '../libraries/constants/Types.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {CollectPublicationAction} from '../modules/act/collect/CollectPublicationAction.sol';
import {BaseProfilePublicationData, IBaseFeeCollectModule} from '../modules/interfaces/IBaseFeeCollectModule.sol';
import {MetaTxLib} from '../libraries/MetaTxLib.sol';

/// @title PublicActProxy
/// @author LensProtocol
/// @notice This contract allows anyone to Act on a publication without holding a profile
/// @dev This contract holds a profile (or is a DE of that profile) and acts on behalf of the caller
contract PublicActProxy {
    using SafeERC20 for IERC20;

    ILensHub public immutable HUB;
    CollectPublicationAction public immutable COLLECT_PUBLICATION_ACTION;

    uint[9] private __gap;
    mapping(address => uint256) private _nonces; // Slot 10 - to match with MetaTxLib/StorageLib

    constructor(address lensHub, address collectPublicationAction) {
        HUB = ILensHub(lensHub);
        COLLECT_PUBLICATION_ACTION = CollectPublicationAction(collectPublicationAction);
    }

    /*
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

    // This contract should be the owner/DE of the publicationActionParams.actorProfileId
    // This contract should be set as publicationActionParams.transactionExecutor
    // Correct collectNftRecipient should be passed in the publicationActionParams.actionModuleData

    // This is pretty simple, but should follow the rules above:
    function publicFreeAct(Types.PublicationActionParams calldata publicationActionParams) external {
        HUB.act(publicationActionParams);
    }

    // For the paid collect to work, additional steps are required:
    // Collector should set enough allowance to this contract to pay for collect NFT
    // Funds will be taken from msg.sender
    // Funds will be approved from this contract to collectModule found in publication storage
    function publicCollect(Types.PublicationActionParams calldata publicationActionParams) external {
        _publicCollect(publicationActionParams, msg.sender);
    }

    function publicCollectWithSig(
        Types.PublicationActionParams calldata publicationActionParams,
        Types.EIP712Signature calldata signature
    ) external {
        MetaTxLib.validateActSignature(signature, publicationActionParams);
        _publicCollect(publicationActionParams, signature.signer);
    }

    function nonces(address signer) public view returns (uint256) {
        return _nonces[signer];
    }

    function incrementNonce(uint8 increment) external {
        MetaTxLib.incrementNonce(increment);
    }

    function _publicCollect(
        Types.PublicationActionParams calldata publicationActionParams,
        address transactionExecutor
    ) internal {
        address collectModule = COLLECT_PUBLICATION_ACTION
            .getCollectData(
                publicationActionParams.publicationActedProfileId,
                publicationActionParams.publicationActedId
            )
            .collectModule;

        BaseProfilePublicationData memory collectData = IBaseFeeCollectModule(collectModule).getBasePublicationData(
            publicationActionParams.publicationActedProfileId,
            publicationActionParams.publicationActedId
        );

        if (collectData.amount > 0) {
            IERC20(collectData.currency).safeTransferFrom(transactionExecutor, address(this), collectData.amount);
            IERC20(collectData.currency).safeIncreaseAllowance(collectModule, collectData.amount);
        }

        HUB.act(publicationActionParams);
    }

    function name() external pure returns (string memory) {
        return 'PublicActProxy';
    }
}
