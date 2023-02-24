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
        // If it is pointing to itself it will fail because it will return non-existent type.
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

    function validateAddressIsDelegatedExecutor(address expectedDelegatedExecutor, uint256 delegatorProfileId)
        internal
        view
    {
        if (!ProfileLib.isExecutorApproved(delegatorProfileId, expectedDelegatedExecutor)) {
            revert Errors.ExecutorInvalid();
        }
    }

    function validateCollectModuleWhitelisted(address collectModule) internal view {
        if (!StorageLib.collectModuleWhitelisted()[collectModule]) {
            revert Errors.CollectModuleNotWhitelisted();
        }
    }

    function validateReferenceModuleWhitelisted(address referenceModule) internal view {
        if (!StorageLib.referenceModuleWhitelisted()[referenceModule]) {
            revert Errors.ReferenceModuleNotWhitelisted();
        }
    }

    function validateFollowModuleWhitelisted(address followModule) internal view {
        if (!StorageLib.followModuleWhitelisted()[followModule]) {
            revert Errors.FollowModuleNotWhitelisted();
        }
    }

    function validateProfileCreatorWhitelisted(address profileCreator) internal view {
        if (!StorageLib.profileCreatorWhitelisted()[profileCreator]) {
            revert Errors.ProfileCreatorNotWhitelisted();
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

    function validateReferrerAndGetReferrerPubType(
        uint256 referrerProfileId,
        uint256 referrerPubId,
        uint256 profileId,
        uint256 pubId
    ) internal view returns (Types.PublicationType) {
        if (referrerProfileId == 0 && referrerPubId == 0) {
            // No referrer was passed.
            return Types.PublicationType.Nonexistent;
        }

        if (
            // Cannot pass itself as a referrer.
            referrerProfileId == profileId && referrerPubId == pubId
        ) {
            revert Errors.InvalidReferrer();
        }

        Types.PublicationType referrerPubType = PublicationLib.getPublicationType(referrerProfileId, referrerPubId);

        if (referrerPubType == Types.PublicationType.Mirror) {
            _validateReferrerAsMirror(referrerProfileId, referrerPubId, profileId, pubId);
        } else if (referrerPubType == Types.PublicationType.Comment || referrerPubType == Types.PublicationType.Quote) {
            _validateReferrerAsCommentOrQuote(referrerProfileId, referrerPubId, profileId, pubId);
        } else {
            // Referrarls are only supported for mirrors, comments and quotes, not for posts.
            revert Errors.InvalidReferrer();
        }

        return referrerPubType;
    }

    function _validateReferrerAsMirror(
        uint256 referrerProfileId,
        uint256 referrerPubId,
        uint256 profileId,
        uint256 pubId
    ) private view {
        Types.Publication storage _referrerMirror = StorageLib.getPublication(referrerProfileId, referrerPubId);
        if (
            // A mirror can only be a referrer of a publication if it is pointing to it.
            _referrerMirror.pointedProfileId != profileId || _referrerMirror.pointedPubId != pubId
        ) {
            revert Errors.InvalidReferrer();
        }
    }

    /**
     * @dev Validates that the referrer publication and the interacted publilcation are linked.
     *
     * @param referrerProfileId The profile id of the referrer.
     * @param referrerPubId The publication id of the referrer.
     * @param profileId This is the ID of the profile who authored the publication being collected or referenced.
     * @param pubId This is the pub user collects or references.
     */
    function _validateReferrerAsCommentOrQuote(
        uint256 referrerProfileId,
        uint256 referrerPubId,
        uint256 profileId,
        uint256 pubId
    ) private view {
        Types.Publication storage _referrerPub = StorageLib.getPublication(referrerProfileId, referrerPubId);
        Types.PublicationType typeOfPubPointedByReferrer = PublicationLib.getPublicationType(profileId, pubId);
        // We already know that the publication being collected/referenced is not a mirror nor a non-existent one.
        if (typeOfPubPointedByReferrer == Types.PublicationType.Post) {
            // If the publication collected/referenced is a post, the referrer comment/quote must have it as root.
            if (_referrerPub.rootProfileId != profileId || _referrerPub.rootPubId != pubId) {
                revert Errors.InvalidReferrer();
            }
        } else {
            // The publication collected/referenced is a comment or a quote.
            Types.Publication storage _pubPointedByReferrer = StorageLib.getPublication(profileId, pubId);
            // The referrer publication and the collected/referenced publication must share the same root.
            if (
                _referrerPub.rootProfileId != _pubPointedByReferrer.rootProfileId ||
                _referrerPub.rootPubId != _pubPointedByReferrer.rootPubId
            ) {
                revert Errors.InvalidReferrer();
            }
        }
    }
}
