// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IReferenceModule} from 'contracts/interfaces/IReferenceModule.sol';
import {HubRestricted} from 'contracts/base/HubRestricted.sol';
import {Errors} from 'contracts/modules/constants/Errors.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

import {LensModuleMetadata} from 'contracts/modules/LensModuleMetadata.sol';

interface IToken {
    /**
     * @dev Returns the amount of ERC20/ERC721 tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @notice A struct containing the necessary data to execute TokenGated references.
 *
 * @param tokenAddress The address of ERC20/ERC721 token used for gating the reference
 * @param minThreshold The minimum balance threshold of the gated token required to execute a reference
 */
struct GateParams {
    address tokenAddress;
    uint256 minThreshold;
}

/**
 * @title TokenGatedReferenceModule
 * @author Lens Protocol
 *
 * @notice A reference module that validates that the user who tries to reference has a required minimum balance of ERC20/ERC721 token.
 */
contract TokenGatedReferenceModule is LensModuleMetadata, HubRestricted, IReferenceModule {
    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == type(IReferenceModule).interfaceId || super.supportsInterface(interfaceID);
    }

    uint256 internal constant UINT256_BYTES = 32;

    event TokenGatedReferencePublicationCreated(
        uint256 indexed profileId,
        uint256 indexed pubId,
        address tokenAddress,
        uint256 minThreshold
    );

    error NotEnoughBalance();

    mapping(uint256 pointedProfileId => mapping(uint256 pointedPubId => GateParams gateParams)) internal _gateParams;

    constructor(address hub) HubRestricted(hub) {}

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev The gating token address and minimum balance threshold is passed during initialization in data field.
     */
    function initializeReferenceModule(
        uint256 profileId,
        uint256 pubId,
        address /* transactionExecutor */,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        GateParams memory gateParams = abi.decode(data, (GateParams));

        // Checking if the tokenAddress resembles ERC20/ERC721 token (by calling balanceOf() function).
        (bool success, bytes memory result) = gateParams.tokenAddress.staticcall(
            abi.encodeWithSelector(IToken.balanceOf.selector, address(this))
        );
        // We don't check if the contract exists because we expect the return data anyway.
        if (gateParams.minThreshold == 0 || !success || result.length != UINT256_BYTES) {
            revert Errors.InitParamsInvalid();
        }

        _gateParams[profileId][pubId] = gateParams;
        emit TokenGatedReferencePublicationCreated(profileId, pubId, gateParams.tokenAddress, gateParams.minThreshold);
        return '';
    }

    /**
     * @inheritdoc IReferenceModule
     * @dev Validates that the commenting profile's owner has enough balance of the gating token.
     *
     * @return balance The ABI-encoded gate token balance of the profile trying to comment/quote/mirror.
     */
    function processComment(
        Types.ProcessCommentParams calldata processCommentParams
    ) external view override onlyHub returns (bytes memory) {
        return
            abi.encode(
                _validateTokenBalance(
                    processCommentParams.profileId,
                    processCommentParams.pointedProfileId,
                    processCommentParams.pointedPubId
                )
            );
    }

    /**
     * @inheritdoc IReferenceModule
     * @dev Validates that the commenting profile's owner has enough balance of the gating token.
     *
     * @return balance The ABI-encoded gate token balance of the profile trying to comment/quote/mirror.
     */
    function processQuote(
        Types.ProcessQuoteParams calldata processQuoteParams
    ) external view override onlyHub returns (bytes memory) {
        return
            abi.encode(
                _validateTokenBalance(
                    processQuoteParams.profileId,
                    processQuoteParams.pointedProfileId,
                    processQuoteParams.pointedPubId
                )
            );
    }

    /**
     * @inheritdoc IReferenceModule
     * @dev Validates that the mirroring profile's owner has enough balance of the gating token.
     *
     * @return balance The ABI-encoded gate token balance of the profile trying to comment/quote/mirror.
     */
    function processMirror(
        Types.ProcessMirrorParams calldata processMirrorParams
    ) external view override onlyHub returns (bytes memory) {
        return
            abi.encode(
                _validateTokenBalance(
                    processMirrorParams.profileId,
                    processMirrorParams.pointedProfileId,
                    processMirrorParams.pointedPubId
                )
            );
    }

    /**
     * @dev Validates the profile's owner balance of gating token. It can work with both ERC20 and ERC721 as both
     * interfaces shares `balanceOf` function prototype.
     *
     * @param profileId The ID of the profile trying to comment/quote/mirror.
     * @param pointedProfileId The ID of the pointed publication's author.
     * @param pointedPubId The ID of the pointed publication.
     *
     * @return uint256 The gate token balance of the profile trying to comment/quote/mirror.
     */
    function _validateTokenBalance(
        uint256 profileId,
        uint256 pointedProfileId,
        uint256 pointedPubId
    ) internal view returns (uint256) {
        GateParams memory gateParams = _gateParams[pointedProfileId][pointedPubId];
        uint256 balance = IToken(gateParams.tokenAddress).balanceOf(IERC721(HUB).ownerOf(profileId));
        if (profileId != pointedProfileId && balance < gateParams.minThreshold) {
            revert NotEnoughBalance();
        }
        return balance;
    }
}
