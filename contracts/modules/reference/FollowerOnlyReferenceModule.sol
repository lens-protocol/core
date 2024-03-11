// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IReferenceModule} from '../../interfaces/IReferenceModule.sol';
import {HubRestricted} from '../../base/HubRestricted.sol';
import {Types} from '../../libraries/constants/Types.sol';
import {FollowValidationLib} from '../libraries/FollowValidationLib.sol';

import {LensModuleMetadata} from '../LensModuleMetadata.sol';

/**
 * @title FollowerOnlyReferenceModule
 * @author Lens Protocol
 *
 * @notice A simple reference module that validates that comments, quotes or mirrors originate from a profile that
 * follows the profile of the original publication.
 */
contract FollowerOnlyReferenceModule is LensModuleMetadata, HubRestricted, IReferenceModule {
    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == type(IReferenceModule).interfaceId || super.supportsInterface(interfaceID);
    }

    constructor(address hub, address moduleOwner) HubRestricted(hub) LensModuleMetadata(moduleOwner) {}

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev There is nothing needed at initialization.
     */
    function initializeReferenceModule(
        uint256 /* profileId */,
        uint256 /* pubId */,
        address /* transactionExecutor */,
        bytes calldata /* data */
    ) external pure returns (bytes memory) {
        return '';
    }

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev Validates that the commenting profile is the original author or a follower of it.
     */
    function processComment(
        Types.ProcessCommentParams calldata processCommentParams
    ) external view override returns (bytes memory) {
        return
            _performFollowerOnlyCheck({
                followerProfileId: processCommentParams.profileId,
                followedProfileId: processCommentParams.pointedProfileId
            });
    }

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev Validates that the quoting profile is the original author or a follower of it.
     */
    function processQuote(
        Types.ProcessQuoteParams calldata processQuoteParams
    ) external view override returns (bytes memory) {
        return
            _performFollowerOnlyCheck({
                followerProfileId: processQuoteParams.profileId,
                followedProfileId: processQuoteParams.pointedProfileId
            });
    }

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev Validates that the mirroring profile is the original author or a follower of it.
     */
    function processMirror(
        Types.ProcessMirrorParams calldata processMirrorParams
    ) external view override returns (bytes memory) {
        return
            _performFollowerOnlyCheck({
                followerProfileId: processMirrorParams.profileId,
                followedProfileId: processMirrorParams.pointedProfileId
            });
    }

    function _performFollowerOnlyCheck(
        uint256 followerProfileId,
        uint256 followedProfileId
    ) internal view returns (bytes memory) {
        FollowValidationLib.validateIsFollowingOrSelf(HUB, followerProfileId, followedProfileId);
        return '';
    }
}
