// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {ProfileLib} from 'contracts/libraries/ProfileLib.sol';
import {PublicationLib} from 'contracts/libraries/PublicationLib.sol';

/**
 * @title ValidationLib
 * @author Lens Protocol
 */
library ValidationLib {
    function validatePointedPub(uint256 profileId, uint256 pubId) internal view {
        // If it is pointing to itself it will fail because it will return a non-existent type.
        Types.PublicationType pointedPubType = PublicationLib.getPublicationType(profileId, pubId);
        if (pointedPubType == Types.PublicationType.Nonexistent || pointedPubType == Types.PublicationType.Mirror) {
            revert Errors.InvalidPointedPub();
        }
    }

    function validateAddressIsProfileOwner(address expectedProfileOwner, uint256 profileId) internal view {
        if (expectedProfileOwner != ProfileLib.ownerOf(profileId)) {
            revert Errors.NotProfileOwner();
        }
    }

    function validateAddressIsProfileOwnerOrDelegatedExecutor(
        address expectedOwnerOrDelegatedExecutor,
        uint256 profileId
    ) internal view {
        if (expectedOwnerOrDelegatedExecutor != ProfileLib.ownerOf(profileId)) {
            validateAddressIsDelegatedExecutor({
                expectedDelegatedExecutor: expectedOwnerOrDelegatedExecutor,
                delegatorProfileId: profileId
            });
        }
    }

    function validateAddressIsDelegatedExecutor(
        address expectedDelegatedExecutor,
        uint256 delegatorProfileId
    ) internal view {
        if (!ProfileLib.isExecutorApproved(delegatorProfileId, expectedDelegatedExecutor)) {
            revert Errors.ExecutorInvalid();
        }
    }

    function validateReferenceModuleWhitelisted(address referenceModule) internal view {
        if (!StorageLib.referenceModuleWhitelisted()[referenceModule]) {
            revert Errors.NotWhitelisted();
        }
    }

    function validateFollowModuleWhitelisted(address followModule) internal view {
        if (!StorageLib.followModuleWhitelisted()[followModule]) {
            revert Errors.NotWhitelisted();
        }
    }

    function validateProfileCreatorWhitelisted(address profileCreator) internal view {
        if (!StorageLib.profileCreatorWhitelisted()[profileCreator]) {
            revert Errors.NotWhitelisted();
        }
    }

    function validateNotBlocked(uint256 profile, uint256 byProfile) internal view {
        if (StorageLib.blockedStatus(byProfile)[profile]) {
            revert Errors.Blocked();
        }
    }

    function validateProfileExists(uint256 profileId) internal view {
        if (StorageLib.getTokenData(profileId).owner == address(0)) {
            revert Errors.TokenDoesNotExist();
        }
    }

    function validateCallerIsGovernance() internal view {
        if (msg.sender != StorageLib.getGovernance()) {
            revert Errors.NotGovernance();
        }
    }

    function validateReferrersAndGetReferrersPubTypes(
        uint256[] memory referrerProfileIds,
        uint256[] memory referrerPubIds,
        uint256 targetedProfileId,
        uint256 targetedPubId
    ) internal view returns (Types.PublicationType[] memory) {
        if (referrerProfileIds.length != referrerPubIds.length) {
            revert Errors.ArrayMismatch();
        }
        Types.PublicationType[] memory referrerPubTypes = new Types.PublicationType[](referrerProfileIds.length);
        // We decided not to check for duplicate referrals here to save gas and move this responsibility to modules
        uint256 referrerProfileId;
        uint256 referrerPubId;
        uint256 i;

        while (i < referrerProfileIds.length) {
            referrerProfileId = referrerProfileIds[i];
            referrerPubId = referrerPubIds[i];
            referrerPubTypes[i] = _validateReferrerAndGetReferrerPubType(
                referrerProfileId,
                referrerPubId,
                targetedProfileId,
                targetedPubId
            );
            unchecked {
                i++;
            }
        }
        return referrerPubTypes;
    }

    function validateLegacyCollectReferrer(
        uint256 referrerProfileId,
        uint256 referrerPubId,
        uint256 publicationCollectedProfileId,
        uint256 publicationCollectedId
    ) external view {
        if (PublicationLib.getPublicationType(referrerProfileId, referrerPubId) != Types.PublicationType.Mirror) {
            revert Errors.InvalidReferrer();
        }
        _validateReferrerAsMirror(
            referrerProfileId,
            referrerPubId,
            publicationCollectedProfileId,
            publicationCollectedId
        );
    }

    function _validateReferrerAndGetReferrerPubType(
        uint256 referrerProfileId,
        uint256 referrerPubId,
        uint256 targetedProfileId,
        uint256 targetedPubId
    ) private view returns (Types.PublicationType) {
        if (referrerPubId == 0) {
            // Unchecked/Unverified referral. Profile referrer, not attached to a publication.
            if (
                StorageLib.getTokenData(referrerProfileId).owner == address(0) || referrerProfileId == targetedProfileId
            ) {
                revert Errors.InvalidReferrer();
            }
            return Types.PublicationType.Nonexistent;
        } else {
            // Checked/Verified referral. Publication referrer.
            if (
                // Cannot pass itself as a referrer.
                referrerProfileId == targetedProfileId && referrerPubId == targetedPubId
            ) {
                revert Errors.InvalidReferrer();
            }
            Types.PublicationType referrerPubType = PublicationLib.getPublicationType(referrerProfileId, referrerPubId);
            if (referrerPubType == Types.PublicationType.Mirror) {
                _validateReferrerAsMirror(referrerProfileId, referrerPubId, targetedProfileId, targetedPubId);
            } else if (
                referrerPubType == Types.PublicationType.Comment || referrerPubType == Types.PublicationType.Quote
            ) {
                _validateReferrerAsCommentOrQuote(referrerProfileId, referrerPubId, targetedProfileId, targetedPubId);
            } else if (referrerPubType == Types.PublicationType.Post) {
                _validateReferrerAsPost(referrerProfileId, referrerPubId, targetedProfileId, targetedPubId);
            } else {
                revert Errors.InvalidReferrer();
            }
            return referrerPubType;
        }
    }

    function _validateReferrerAsPost(
        uint256 referrerProfileId,
        uint256 referrerPubId,
        uint256 targetedProfileId,
        uint256 targetedPubId
    ) private view {
        Types.Publication storage _targetedPub = StorageLib.getPublication(targetedProfileId, targetedPubId);
        // Publication targeted must have the referrer post as the root. This enables the use case of rewarding the
        // root publication for an action over any of its descendants.
        if (_targetedPub.rootProfileId != referrerProfileId || _targetedPub.rootPubId != referrerPubId) {
            revert Errors.InvalidReferrer();
        }
    }

    function _validateReferrerAsMirror(
        uint256 referrerProfileId,
        uint256 referrerPubId,
        uint256 targetedProfileId,
        uint256 targetedPubId
    ) private view {
        Types.Publication storage _referrerMirror = StorageLib.getPublication(referrerProfileId, referrerPubId);
        if (
            // A mirror can only be a referrer of a publication if it is pointing to it.
            _referrerMirror.pointedProfileId != targetedProfileId || _referrerMirror.pointedPubId != targetedPubId
        ) {
            revert Errors.InvalidReferrer();
        }
    }

    /**
     * @dev Validates that the referrer publication and the interacted publication are linked.
     *
     * @param referrerProfileId The profile id of the referrer.
     * @param referrerPubId The publication id of the referrer.
     * @param targetedProfileId The ID of the profile who authored the publication being acted or referenced.
     * @param targetedPubId The pub ID being acted or referenced.
     */
    function _validateReferrerAsCommentOrQuote(
        uint256 referrerProfileId,
        uint256 referrerPubId,
        uint256 targetedProfileId,
        uint256 targetedPubId
    ) private view {
        Types.Publication storage _referrerPub = StorageLib.getPublication(referrerProfileId, referrerPubId);
        Types.PublicationType typeOfTargetedPub = PublicationLib.getPublicationType(targetedProfileId, targetedPubId);
        // We already know that the publication being acted/referenced is not a mirror nor a non-existent one.
        if (typeOfTargetedPub == Types.PublicationType.Post) {
            // If the publication acted/referenced is a post, the referrer comment/quote must have it as the root.
            if (_referrerPub.rootProfileId != targetedProfileId || _referrerPub.rootPubId != targetedPubId) {
                revert Errors.InvalidReferrer();
            }
        } else {
            // The publication acted/referenced is a comment or a quote.
            Types.Publication storage _targetedPub = StorageLib.getPublication(targetedProfileId, targetedPubId);
            if (
                // The referrer publication and the acted/referenced publication must share the same root.
                _referrerPub.rootProfileId != _targetedPub.rootProfileId ||
                _referrerPub.rootPubId != _targetedPub.rootPubId
            ) {
                revert Errors.InvalidReferrer();
            }
        }
    }
}
