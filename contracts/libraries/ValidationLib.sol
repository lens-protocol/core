// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from './constants/Types.sol';
import {Errors} from './constants/Errors.sol';
import {StorageLib} from './StorageLib.sol';
import {ProfileLib} from './ProfileLib.sol';
import {PublicationLib} from './PublicationLib.sol';

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

    function validateProfileCreatorWhitelisted(address profileCreator) internal view {
        if (!StorageLib.profileCreatorWhitelisted()[profileCreator]) {
            revert Errors.NotWhitelisted();
        }
    }

    function validateNotBlocked(uint256 profile, uint256 byProfile) internal view {
        // By default, block validation is bidirectional, meaning interactions are restricted in both ways.
        validateNotBlocked({profile: profile, byProfile: byProfile, unidirectionalCheck: false});
    }

    function validateNotBlocked(uint256 profile, uint256 byProfile, bool unidirectionalCheck) internal view {
        if (
            profile != byProfile &&
            (StorageLib.blockedStatus(byProfile)[profile] ||
                (!unidirectionalCheck && StorageLib.blockedStatus(profile)[byProfile]))
        ) {
            revert Errors.Blocked();
        }
    }

    function validateProfileExists(uint256 profileId) internal view {
        if (!ProfileLib.exists(profileId)) {
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

        // We decided not to check for duplicate referrals here due to gas cost. If transient storage opcodes (EIP-1153)
        // get included into the VM, this could be updated to implement an efficient duplicate check mechanism.
        // For now, if a module strongly needs to avoid duplicate referrals, it can check for them at its own expense.

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
        if (
            !ProfileLib.exists(referrerProfileId) ||
            PublicationLib.getPublicationType(referrerProfileId, referrerPubId) != Types.PublicationType.Mirror
        ) {
            revert Errors.InvalidReferrer();
        }
        Types.Publication storage _referrerMirror = StorageLib.getPublication(referrerProfileId, referrerPubId);
        // A mirror can only be a referrer of a legacy publication if it is pointing to it.
        if (
            _referrerMirror.pointedProfileId != publicationCollectedProfileId ||
            _referrerMirror.pointedPubId != publicationCollectedId
        ) {
            revert Errors.InvalidReferrer();
        }
    }

    function _validateReferrerAndGetReferrerPubType(
        uint256 referrerProfileId,
        uint256 referrerPubId,
        uint256 targetedProfileId,
        uint256 targetedPubId
    ) private view returns (Types.PublicationType) {
        if (referrerPubId == 0) {
            // Unchecked/Unverified referral. Profile referrer, not attached to a publication.
            if (!ProfileLib.exists(referrerProfileId) || referrerProfileId == targetedProfileId) {
                revert Errors.InvalidReferrer();
            }
            return Types.PublicationType.Nonexistent;
        } else {
            // Checked/Verified referral. Publication referrer.
            if (
                // Cannot pass the targeted publication as a referrer.
                referrerProfileId == targetedProfileId && referrerPubId == targetedPubId
            ) {
                revert Errors.InvalidReferrer();
            }
            Types.PublicationType referrerPubType = PublicationLib.getPublicationType(referrerProfileId, referrerPubId);
            if (referrerPubType == Types.PublicationType.Nonexistent) {
                revert Errors.InvalidReferrer();
            }
            if (referrerPubType == Types.PublicationType.Post) {
                _validateReferrerAsPost(referrerProfileId, referrerPubId, targetedProfileId, targetedPubId);
            } else {
                _validateReferrerAsMirrorOrCommentOrQuote(
                    referrerProfileId,
                    referrerPubId,
                    targetedProfileId,
                    targetedPubId
                );
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

    /**
     * @dev Validates that the referrer publication and the interacted publication are linked.
     *
     * @param referrerProfileId The profile id of the referrer.
     * @param referrerPubId The publication id of the referrer.
     * @param targetedProfileId The ID of the profile who authored the publication being acted or referenced.
     * @param targetedPubId The pub ID being acted or referenced.
     */
    function _validateReferrerAsMirrorOrCommentOrQuote(
        uint256 referrerProfileId,
        uint256 referrerPubId,
        uint256 targetedProfileId,
        uint256 targetedPubId
    ) private view {
        Types.Publication storage _referrerPub = StorageLib.getPublication(referrerProfileId, referrerPubId);
        // A mirror/quote/comment is allowed to be a referrer of a publication if it is pointing to it...
        if (_referrerPub.pointedProfileId != targetedProfileId || _referrerPub.pointedPubId != targetedPubId) {
            // ...or if the referrer pub's root is the target pub (i.e. target pub is a Lens V2 post)...
            if (_referrerPub.rootProfileId != targetedProfileId || _referrerPub.rootPubId != targetedPubId) {
                Types.Publication storage _targetedPub = StorageLib.getPublication(targetedProfileId, targetedPubId);
                // ...or if the referrer pub shares the root with the target pub.
                if (
                    // Here the target pub must be a "pure" Lens V2 comment/quote, which means there is no
                    // Lens V1 Legacy comment or post on its tree of interactions, and its root pub is filled.
                    // Otherwise, two Lens V2 "non-pure" publications could be passed as a referrer to each other,
                    // even without having any interaction in common, as they would share the root as zero.
                    _referrerPub.rootPubId == 0 ||
                    // The referrer publication and the target publication must share the same root.
                    _referrerPub.rootProfileId != _targetedPub.rootProfileId ||
                    _referrerPub.rootPubId != _targetedPub.rootPubId
                ) {
                    revert Errors.InvalidReferrer();
                }
            }
        }
    }
}
