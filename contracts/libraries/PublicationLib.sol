// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';
import {MetaTxLib} from 'contracts/libraries/MetaTxLib.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {ICollectModule} from 'contracts/interfaces/ICollectModule.sol';
import {IReferenceModule} from 'contracts/interfaces/IReferenceModule.sol';
import {IDeprecatedReferenceModule} from 'contracts/interfaces/IDeprecatedReferenceModule.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {IPublicationActionModule} from 'contracts/interfaces/IPublicationActionModule.sol';

library PublicationLib {
    /**
     * @notice Publishes a post to a given profile.
     *
     * @param postParams The PostParams struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function post(Types.PostParams calldata postParams, address transactionExecutor) external returns (uint256) {
        uint256 pubIdAssigned = ++StorageLib.getProfile(postParams.profileId).pubCount;

        Types.Publication storage _post = StorageLib.getPublication(postParams.profileId, pubIdAssigned);
        _post.contentURI = postParams.contentURI;
        _post.pubType = Types.PublicationType.Post;

        bytes[] memory actionModulesReturnDatas = _initPubActionModules(
            postParams.profileId,
            transactionExecutor,
            pubIdAssigned,
            postParams.actionModules,
            postParams.actionModulesInitDatas
        );

        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            postParams.profileId,
            transactionExecutor,
            pubIdAssigned,
            postParams.referenceModule,
            postParams.referenceModuleInitData
        );

        emit Events.PostCreated(
            postParams,
            pubIdAssigned,
            actionModulesReturnDatas,
            referenceModuleReturnData,
            block.timestamp
        );

        return pubIdAssigned;
    }

    /**
     * @notice Publishes a comment to a given profile via signature.
     *
     * @param commentParams the CommentParams struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function comment(
        Types.CommentParams calldata commentParams,
        address transactionExecutor
    ) external returns (uint256) {
        (
            uint256 pubIdAssigned,
            bytes[] memory actionModulesReturnDatas,
            bytes memory referenceModuleReturnData,
            Types.PublicationType[] memory referrerPubTypes
        ) = _createReferencePublication(
                _asReferencePubParams(commentParams),
                transactionExecutor,
                Types.PublicationType.Comment
            );

        _processCommentIfNeeded(commentParams, transactionExecutor, referrerPubTypes);

        emit Events.CommentCreated(
            commentParams,
            pubIdAssigned,
            actionModulesReturnDatas,
            referenceModuleReturnData,
            block.timestamp
        );

        return pubIdAssigned;
    }

    /**
     * @notice Publishes a mirror to a given profile.
     *
     * @param mirrorParams the MirrorParams struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function mirror(Types.MirrorParams calldata mirrorParams, address transactionExecutor) external returns (uint256) {
        Types.PublicationType[] memory referrerPubTypes = ValidationLib.validateReferrersAndGetReferrersPubTypes(
            mirrorParams.referrerProfileIds,
            mirrorParams.referrerPubIds,
            mirrorParams.pointedProfileId,
            mirrorParams.pointedPubId
        );

        uint256 pubIdAssigned = ++StorageLib.getProfile(mirrorParams.profileId).pubCount;

        Types.Publication storage _publication = StorageLib.getPublication(mirrorParams.profileId, pubIdAssigned);
        _publication.pointedProfileId = mirrorParams.pointedProfileId;
        _publication.pointedPubId = mirrorParams.pointedPubId;
        _publication.pubType = Types.PublicationType.Mirror;

        _processMirrorIfNeeded(mirrorParams, transactionExecutor, referrerPubTypes);

        emit Events.MirrorCreated(mirrorParams, pubIdAssigned, block.timestamp);

        return pubIdAssigned;
    }

    /**
     * @notice Publishes a quote publication to a given profile via signature.
     *
     * @param quoteParams the QuoteParams struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function quote(Types.QuoteParams calldata quoteParams, address transactionExecutor) external returns (uint256) {
        (
            uint256 pubIdAssigned,
            bytes[] memory actionModulesReturnDatas,
            bytes memory referenceModuleReturnData,
            Types.PublicationType[] memory referrerPubTypes
        ) = _createReferencePublication(
                _asReferencePubParams(quoteParams),
                transactionExecutor,
                Types.PublicationType.Quote
            );

        _processQuoteIfNeeded(quoteParams, transactionExecutor, referrerPubTypes);

        emit Events.QuoteCreated(
            quoteParams,
            pubIdAssigned,
            actionModulesReturnDatas,
            referenceModuleReturnData,
            block.timestamp
        );

        return pubIdAssigned;
    }

    function getPublicationType(uint256 profileId, uint256 pubId) internal view returns (Types.PublicationType) {
        Types.Publication storage _publication = StorageLib.getPublication(profileId, pubId);
        Types.PublicationType pubType = _publication.pubType;
        if (uint8(pubType) == 0) {
            // Legacy V1: If publication type is 0, we check using the legacy rules.
            if (_publication.pointedProfileId != 0) {
                // It is pointing to a publication, so it can be either a comment or a mirror, depending on if it has a
                // collect module or not.
                if (_publication.__DEPRECATED__collectModule == address(0)) {
                    return Types.PublicationType.Mirror;
                } else {
                    return Types.PublicationType.Comment;
                }
            } else if (_publication.__DEPRECATED__collectModule != address(0)) {
                return Types.PublicationType.Post;
            }
        }
        return pubType;
    }

    function getContentURI(uint256 profileId, uint256 pubId) external view returns (string memory) {
        Types.Publication storage _publication = StorageLib.getPublication(profileId, pubId);
        Types.PublicationType pubType = _publication.pubType;
        if (pubType == Types.PublicationType.Nonexistent) {
            pubType = getPublicationType(profileId, pubId);
        }
        if (pubType == Types.PublicationType.Mirror) {
            uint256 rootProfileId = _publication.pointedProfileId;
            uint256 rootPubId = _publication.pointedPubId;
            return StorageLib.getPublication(rootProfileId, rootPubId).contentURI;
        } else {
            return StorageLib.getPublication(profileId, pubId).contentURI;
        }
    }

    function _asReferencePubParams(
        Types.QuoteParams calldata quoteParams
    ) private pure returns (Types.ReferencePubParams calldata referencePubParams) {
        // We use assembly to cast the types keeping the params in calldata, as they match the fields.
        assembly {
            referencePubParams := quoteParams
        }
    }

    function _asReferencePubParams(
        Types.CommentParams calldata commentParams
    ) private pure returns (Types.ReferencePubParams calldata referencePubParams) {
        // We use assembly to cast the types keeping the params in calldata, as they match the fields.
        assembly {
            referencePubParams := commentParams
        }
    }

    function _createReferencePublication(
        Types.ReferencePubParams calldata referencePubParams,
        address transactionExecutor,
        Types.PublicationType referencePubType
    ) private returns (uint256, bytes[] memory, bytes memory, Types.PublicationType[] memory) {
        Types.PublicationType[] memory referrerPubTypes = ValidationLib.validateReferrersAndGetReferrersPubTypes(
            referencePubParams.referrerProfileIds,
            referencePubParams.referrerPubIds,
            referencePubParams.pointedProfileId,
            referencePubParams.pointedPubId
        );

        uint256 pubIdAssigned = _fillReferencePublicationStorage(referencePubParams, referencePubType);

        bytes[] memory actionModulesReturnDatas = _initPubActionModules(
            referencePubParams.profileId,
            transactionExecutor,
            pubIdAssigned,
            referencePubParams.actionModules,
            referencePubParams.actionModulesInitDatas
        );

        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            referencePubParams.profileId,
            transactionExecutor,
            pubIdAssigned,
            referencePubParams.referenceModule,
            referencePubParams.referenceModuleInitData
        );

        return (pubIdAssigned, actionModulesReturnDatas, referenceModuleReturnData, referrerPubTypes);
    }

    function _fillReferencePublicationStorage(
        Types.ReferencePubParams memory referencePubParams,
        Types.PublicationType referencePubType
    ) private returns (uint256) {
        uint256 pubIdAssigned = ++StorageLib.getProfile(referencePubParams.profileId).pubCount;
        Types.Publication storage _referencePub;
        _referencePub = StorageLib.getPublication(referencePubParams.profileId, pubIdAssigned);
        _referencePub.pointedProfileId = referencePubParams.pointedProfileId;
        _referencePub.pointedPubId = referencePubParams.pointedPubId;
        _referencePub.contentURI = referencePubParams.contentURI;
        _referencePub.pubType = referencePubType;
        Types.Publication storage _pubPointed = StorageLib.getPublication(
            referencePubParams.pointedProfileId,
            referencePubParams.pointedPubId
        );
        if (_pubPointed.pubType == Types.PublicationType.Post) {
            _referencePub.rootProfileId = referencePubParams.pointedProfileId;
            _referencePub.rootPubId = referencePubParams.pointedPubId;
        } else {
            // The publication pointed is either a comment or a quote.
            _referencePub.rootProfileId = _pubPointed.rootProfileId;
            _referencePub.rootPubId = _pubPointed.rootPubId;
        }
        return pubIdAssigned;
    }

    function _processCommentIfNeeded(
        Types.CommentParams calldata commentParams,
        address transactionExecutor,
        Types.PublicationType[] memory referrerPubTypes
    ) private {
        address refModule = StorageLib
            .getPublication(commentParams.pointedProfileId, commentParams.pointedPubId)
            .referenceModule;
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processComment(
                    Types.ProcessCommentParams({
                        profileId: commentParams.profileId,
                        transactionExecutor: transactionExecutor,
                        pointedProfileId: commentParams.pointedProfileId,
                        pointedPubId: commentParams.pointedPubId,
                        referrerProfileIds: commentParams.referrerProfileIds,
                        referrerPubIds: commentParams.referrerPubIds,
                        referrerPubTypes: referrerPubTypes,
                        data: commentParams.referenceModuleData
                    })
                )
            {} catch (bytes memory err) {
                assembly {
                    /// Equivalent to reverting with the returned error selector if
                    /// the length is not zero.
                    let length := mload(err)
                    if iszero(iszero(length)) {
                        revert(add(err, 32), length)
                    }
                }
                if (transactionExecutor != StorageLib.getTokenData(commentParams.profileId).owner) {
                    // TODO: WTF is this?
                    revert Errors.ExecutorInvalid();
                }
                if (commentParams.referrerProfileIds.length > 0) {
                    // Deprecated reference modules don't support referrers.
                    revert Errors.InvalidReferrer();
                }
                IDeprecatedReferenceModule(refModule).processComment(
                    commentParams.profileId,
                    commentParams.pointedProfileId,
                    commentParams.pointedPubId,
                    commentParams.referenceModuleData
                );
            }
        }
    }

    function _processQuoteIfNeeded(
        Types.QuoteParams calldata quoteParams,
        address transactionExecutor,
        Types.PublicationType[] memory referrerPubTypes
    ) private {
        address refModule = StorageLib
            .getPublication(quoteParams.pointedProfileId, quoteParams.pointedPubId)
            .referenceModule;
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processQuote(
                    Types.ProcessQuoteParams({
                        profileId: quoteParams.profileId,
                        transactionExecutor: transactionExecutor,
                        pointedProfileId: quoteParams.pointedProfileId,
                        pointedPubId: quoteParams.pointedPubId,
                        referrerProfileIds: quoteParams.referrerProfileIds,
                        referrerPubIds: quoteParams.referrerPubIds,
                        referrerPubTypes: referrerPubTypes,
                        data: quoteParams.referenceModuleData
                    })
                )
            {} catch (bytes memory err) {
                assembly {
                    /// Equivalent to reverting with the returned error selector if
                    /// the length is not zero.
                    let length := mload(err)
                    if iszero(iszero(length)) {
                        revert(add(err, 32), length)
                    }
                }
                if (transactionExecutor != StorageLib.getTokenData(quoteParams.profileId).owner) {
                    // TODO: WTF is this?
                    revert Errors.ExecutorInvalid();
                }
                if (quoteParams.referrerProfileIds.length > 0) {
                    // Deprecated reference modules don't support referrers.
                    revert Errors.InvalidReferrer();
                }
                IDeprecatedReferenceModule(refModule).processComment(
                    quoteParams.profileId,
                    quoteParams.pointedProfileId,
                    quoteParams.pointedPubId,
                    quoteParams.referenceModuleData
                );
            }
        }
    }

    function _processMirrorIfNeeded(
        Types.MirrorParams calldata mirrorParams,
        address transactionExecutor,
        Types.PublicationType[] memory referrerPubTypes
    ) private {
        address refModule = StorageLib
            .getPublication(mirrorParams.pointedProfileId, mirrorParams.pointedPubId)
            .referenceModule;
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processMirror(
                    Types.ProcessMirrorParams({
                        profileId: mirrorParams.profileId,
                        transactionExecutor: transactionExecutor,
                        pointedProfileId: mirrorParams.pointedProfileId,
                        pointedPubId: mirrorParams.pointedPubId,
                        referrerProfileIds: mirrorParams.referrerProfileIds,
                        referrerPubIds: mirrorParams.referrerPubIds,
                        referrerPubTypes: referrerPubTypes,
                        data: mirrorParams.referenceModuleData
                    })
                )
            {} catch (bytes memory err) {
                assembly {
                    /// Equivalent to reverting with the returned error selector if
                    /// the length is not zero.
                    let length := mload(err)
                    if iszero(iszero(length)) {
                        revert(add(err, 32), length)
                    }
                }
                if (transactionExecutor != StorageLib.getTokenData(mirrorParams.profileId).owner) {
                    // TODO: WTF is this?
                    revert Errors.ExecutorInvalid();
                }
                if (mirrorParams.referrerProfileIds.length > 0) {
                    // Deprecated reference modules don't support referrers.
                    revert Errors.InvalidReferrer();
                }
                IDeprecatedReferenceModule(refModule).processMirror(
                    mirrorParams.profileId,
                    mirrorParams.pointedProfileId,
                    mirrorParams.pointedPubId,
                    mirrorParams.referenceModuleData
                );
            }
        }
    }

    function _initPubActionModules(
        uint256 profileId,
        address transactionExecutor,
        uint256 pubId,
        address[] calldata actionModules,
        bytes[] calldata actionModulesInitDatas
    ) private returns (bytes[] memory) {
        bytes[] memory actionModuleInitResults = new bytes[](actionModules.length);
        uint256 actionModuleBitmap;

        uint256 i;
        while (i < actionModules.length) {
            uint256 actionModuleId = StorageLib.actionModuleWhitelistedId()[actionModules[i]];
            if (actionModuleId == 0) {
                revert Errors.ActionModuleNotWhitelisted();
            }

            actionModuleBitmap |= 1 << (actionModuleId - 1);

            actionModuleInitResults[i] = IPublicationActionModule(actionModules[i]).initializePublicationAction(
                profileId,
                pubId,
                transactionExecutor,
                actionModulesInitDatas[i]
            );

            unchecked {
                ++i;
            }
        }

        StorageLib.getPublication(profileId, pubId).actionModulesBitmap = actionModuleBitmap;

        return actionModuleInitResults;
    }

    function _initPubReferenceModule(
        uint256 profileId,
        address transactionExecutor,
        uint256 pubId,
        address referenceModule,
        bytes memory referenceModuleInitData
    ) private returns (bytes memory) {
        if (referenceModule == address(0)) {
            return new bytes(0);
        }
        ValidationLib.validateReferenceModuleWhitelisted(referenceModule);
        StorageLib.getPublication(profileId, pubId).referenceModule = referenceModule;
        return
            IReferenceModule(referenceModule).initializeReferenceModule(
                profileId,
                transactionExecutor,
                pubId,
                referenceModuleInitData
            );
    }
}
