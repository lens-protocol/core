// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {CollectPublicationAction} from 'contracts/modules/act/collect/CollectPublicationAction.sol';
import {BaseProfilePublicationData, IBaseFeeCollectModule} from 'contracts/modules/interfaces/IBaseFeeCollectModule.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';
import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';

interface IProtocolSharedRevenueMinFeeMintModule {
    function getMintFeeParams() external view returns (address, uint256);
}

/// @title PublicActProxy
/// @author LensProtocol
/// @notice This contract allows anyone to Act on a publication without holding a profile
/// @dev This contract holds a profile (or is a DE of that profile) and acts on behalf of the caller
contract PublicActProxy {
    string constant EIP712_DOMAIN_VERSION = '2';
    bytes32 constant EIP712_DOMAIN_VERSION_HASH = keccak256(bytes(EIP712_DOMAIN_VERSION));
    bytes4 constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

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

    function publicPaidAct(
        Types.PublicationActionParams calldata publicationActionParams,
        address currency,
        uint256 amount,
        address approveTo
    ) external {
        _publicAct(publicationActionParams, currency, amount, approveTo, msg.sender);
    }

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

    struct PaymentParams {
        address currency;
        uint256 amount;
        address approveTo;
    }

    function _validatePaidActSignature(
        Types.EIP712Signature calldata signature,
        Types.PublicationActionParams calldata publicationActionParams,
        PaymentParams memory paymentParams
    ) internal {
        bytes memory encodedAbi = abi.encode(
            Typehash.PUBLIC_PAID_ACT,
            publicationActionParams.publicationActedProfileId,
            publicationActionParams.publicationActedId,
            publicationActionParams.actorProfileId,
            _encodeUsingEip712Rules(publicationActionParams.referrerProfileIds),
            _encodeUsingEip712Rules(publicationActionParams.referrerPubIds),
            publicationActionParams.actionModuleAddress,
            _encodeUsingEip712Rules(publicationActionParams.actionModuleData),
            paymentParams.currency,
            paymentParams.amount,
            paymentParams.approveTo,
            _getNonceIncrementAndEmitEvent(signature.signer),
            signature.deadline
        );
        _validateRecoveredAddress(_calculateDigest(keccak256(encodedAbi)), signature);
    }

    function _validateActSignature(
        Types.EIP712Signature calldata signature,
        Types.PublicationActionParams calldata publicationActionParams
    ) internal {
        _validateRecoveredAddress(
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.ACT,
                        publicationActionParams.publicationActedProfileId,
                        publicationActionParams.publicationActedId,
                        publicationActionParams.actorProfileId,
                        _encodeUsingEip712Rules(publicationActionParams.referrerProfileIds),
                        _encodeUsingEip712Rules(publicationActionParams.referrerPubIds),
                        publicationActionParams.actionModuleAddress,
                        _encodeUsingEip712Rules(publicationActionParams.actionModuleData),
                        _getNonceIncrementAndEmitEvent(signature.signer),
                        signature.deadline
                    )
                )
            ),
            signature
        );
    }

    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(bytes32 digest, Types.EIP712Signature calldata signature) private view {
        if (block.timestamp > signature.deadline) revert Errors.SignatureExpired();
        // If the expected address is a contract, check the signature there.
        if (signature.signer.code.length != 0) {
            bytes memory concatenatedSig = abi.encodePacked(signature.r, signature.s, signature.v);
            if (IERC1271(signature.signer).isValidSignature(digest, concatenatedSig) != EIP1271_MAGIC_VALUE) {
                revert Errors.SignatureInvalid();
            }
        } else {
            address recoveredAddress = ecrecover(digest, signature.v, signature.r, signature.s);
            if (recoveredAddress == address(0) || recoveredAddress != signature.signer) {
                revert Errors.SignatureInvalid();
            }
        }
    }

    function _encodeUsingEip712Rules(bytes memory bytesValue) private pure returns (bytes32) {
        return keccak256(bytesValue);
    }

    function _encodeUsingEip712Rules(uint256[] memory uint256Array) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(uint256Array));
    }

    /**
     * @dev This fetches a signer's current nonce and increments it so it's ready for the next meta-tx. Also emits
     * the `NonceUpdated` event.
     *
     * @param signer The address to get and increment the nonce for.
     *
     * @return uint256 The current nonce for the given signer prior to being incremented.
     */
    function _getNonceIncrementAndEmitEvent(address signer) private returns (uint256) {
        uint256 currentNonce;
        unchecked {
            currentNonce = _nonces[signer]++;
        }
        emit Events.NonceUpdated(signer, currentNonce + 1, block.timestamp);
        return currentNonce;
    }

    /**
     * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest.
     */
    function _calculateDigest(bytes32 hashedMessage) private view returns (bytes32) {
        return keccak256(abi.encodePacked('\x19\x01', _calculateDomainSeparator(), hashedMessage));
    }

    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    Typehash.EIP712_DOMAIN,
                    keccak256(bytes(name())),
                    EIP712_DOMAIN_VERSION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    // For the paid collect to work, additional steps are required:
    // Collector should set enough allowance to this contract to pay for collect NFT
    // Funds will be taken from msg.sender
    // Funds will be approved from this contract to collectModule found in publication storage
    // DEPRECATED:
    function publicCollect(Types.PublicationActionParams calldata publicationActionParams) external {
        _publicCollect(publicationActionParams, msg.sender);
    }

    // DEPRECATED:
    function publicCollectWithSig(
        Types.PublicationActionParams calldata publicationActionParams,
        Types.EIP712Signature calldata signature
    ) external {
        _validateActSignature(signature, publicationActionParams);
        _publicCollect(publicationActionParams, signature.signer);
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

    // DEPRECATED:
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

    // View functions

    function nonces(address signer) public view returns (uint256) {
        return _nonces[signer];
    }

    /// @dev This function is used to invalidate signatures by incrementing the nonce
    function incrementNonce(uint8 increment) external {
        uint256 currentNonce = _nonces[msg.sender];
        _nonces[msg.sender] = currentNonce + increment;
        emit Events.NonceUpdated(msg.sender, currentNonce + increment, block.timestamp);
    }

    function name() public pure returns (string memory) {
        return 'PublicActProxy';
    }
}
