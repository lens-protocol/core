// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {GeneralHelpers} from './helpers/GeneralHelpers.sol';
import {MetaTxHelpers} from './helpers/MetaTxHelpers.sol';
import {DataTypes} from './DataTypes.sol';
import {Events} from './Events.sol';
import {Errors} from './Errors.sol';
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {IReferenceModule} from '../interfaces/IReferenceModule.sol';
import {IDeprecatedReferenceModule} from '../interfaces/IDeprecatedReferenceModule.sol';
import './Constants.sol';

library PublishingLib {
    /**
     * @notice Publishes a post to a given profile.
     *
     * @param postParams The PostParams struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function post(DataTypes.PostParams calldata postParams, address transactionExecutor)
        external
        returns (uint256)
    {
        uint256 pubIdAssigned = ++GeneralHelpers.getProfileStruct(postParams.profileId).pubCount;

        DataTypes.PublicationStruct storage _post = GeneralHelpers.getPublicationStruct(
            postParams.profileId,
            pubIdAssigned
        );
        _post.contentURI = postParams.contentURI;
        _post.pubType = DataTypes.PublicationType.Post;

        bytes memory collectModuleReturnData = _initPubCollectModule(
            postParams.profileId,
            transactionExecutor,
            pubIdAssigned,
            postParams.collectModule,
            postParams.collectModuleInitData
        );

        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            postParams.profileId,
            transactionExecutor,
            pubIdAssigned,
            postParams.referenceModule,
            postParams.referenceModuleInitData
        );

        emit Events.PostCreated(
            postParams.profileId,
            pubIdAssigned,
            postParams.contentURI,
            postParams.collectModule,
            collectModuleReturnData,
            postParams.referenceModule,
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
    function comment(DataTypes.CommentParams calldata commentParams, address transactionExecutor)
        external
        returns (uint256)
    {
        (
            uint256 pubIdAssigned,
            bytes memory collectModuleReturnData,
            bytes memory referenceModuleReturnData
        ) = _createReferencePublication(
                DataTypes.ReferencePubParams(_copyToReferencePubParams(commentParams)),
                transactionExecutor
            );

        _processCommentIfNeeded(commentParams, transactionExecutor);

        emit Events.CommentCreated({
            profileId: commentParams.profileId,
            pubId: pubIdAssigned,
            contentURI: commentParams.contentURI,
            pointedProfileId: commentParams.pointedProfileId,
            pointedPubId: commentParams.pointedPubId,
            referenceModuleData: commentParams.referenceModuleData,
            collectModule: commentParams.collectModule,
            collectModuleReturnData: collectModuleReturnData,
            referenceModule: commentParams.referenceModule,
            referenceModuleReturnData: referenceModuleReturnData,
            timestamp: block.timestamp
        });

        return pubIdAssigned;
    }

    /**
     * @notice Publishes a mirror to a given profile.
     *
     * @param mirrorParams the MirrorParams struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function mirror(DataTypes.MirrorParams calldata mirrorParams, address transactionExecutor)
        external
        returns (uint256)
    {
        DataTypes.PublicationType referrerPubType = GeneralHelpers
            .validateReferrerAndGetReferrerPubType(
                mirrorParams.referrerProfileId,
                mirrorParams.referrerPubId,
                mirrorParams.publicationCollectedProfileId,
                mirrorParams.publicationCollectedId
            );

        uint256 pubIdAssigned = ++GeneralHelpers.getProfileStruct(mirrorParams.profileId).pubCount;

        DataTypes.PublicationStruct storage _publication = GeneralHelpers.getPublicationStruct(
            mirrorParams.profileId,
            pubIdAssigned
        );
        _publication.pointedProfileId = mirrorParams.pointedProfileId;
        _publication.pointedPubId = mirrorParams.pointedPubId;
        _publication.pubType = DataTypes.PublicationType.Mirror;

        _processMirrorIfNeeded(
            mirrorParams.profileId,
            transactionExecutor,
            mirrorParams.pointedProfileId,
            mirrorParams.pointedPubId,
            mirrorParams.referenceModuleData
        );

        emit Events.MirrorCreated(
            mirrorParams.profileId,
            pubIdAssigned,
            mirrorParams.pointedProfileId,
            mirrorParams.pointedPubId,
            mirrorParams.referenceModuleData,
            block.timestamp
        );

        return pubIdAssigned;
    }

    /**
     * @notice Publishes a quote publication to a given profile via signature.
     *
     * @param quoteParams the QuoteParams struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function quote(DataTypes.QuoteParams calldata quoteParams, address transactionExecutor)
        external
        returns (uint256)
    {
        (
            uint256 pubIdAssigned,
            bytes memory collectModuleReturnData,
            bytes memory referenceModuleReturnData
        ) = _createReferencePublication(
                _copyToReferencePubParams(quoteParams),
                transactionExecutor
            );

        _processQuoteIfNeeded({ // TODO: How about old publications? Maybe we do processComment!
            profileId: quoteParams.profileId,
            transactionExecutor: transactionExecutor,
            pointedProfileId: quoteParams.pointedProfileId, // We already have the correct pointed passed
            pointedPubId: quoteParams.pointedPubId,
            referrerProfileId: quoteParams.referrerProfileId, // TODO: But we don't have a referrer yet in params
            referenceModuleData: quoteParams.referenceModuleData
        });

        emit Events.QuoteCreated(
            quoteParams.profileId,
            pubIdAssigned,
            quoteParams.contentURI,
            quoteParams.pointedProfileId,
            quoteParams.pointedPubId,
            quoteParams.referenceModuleData,
            quoteParams.collectModule,
            collectModuleReturnData,
            quoteParams.referenceModule,
            referenceModuleReturnData,
            block.timestamp
        );

        return pubIdAssigned;
    }

    function _copyToReferencePubParams(DataTypes.QuoteParams calldata quoteParams)
        private
        returns (DataTypes.ReferencePubParams calldata)
    {
        return
            DataTypes.ReferencePubParams({
                profileId: quoteParams.profileId,
                contentURI: quoteParams.contentURI,
                pointedProfileId: quoteParams.pointedProfileId,
                pointedPubId: quoteParams.pointedPubId,
                referenceModuleData: quoteParams.referenceModuleData,
                collectModule: quoteParams.collectModule,
                collectModuleInitData: quoteParams.collectModuleInitData,
                referenceModule: quoteParams.referenceModule,
                referenceModuleInitData: quoteParams.referenceModuleInitData
            });
    }

    function _copyToReferencePubParams(DataTypes.CommentParams calldata commentParams)
        private
        returns (DataTypes.ReferencePubParams calldata)
    {
        return
            DataTypes.ReferencePubParams({
                profileId: commentParams.profileId,
                contentURI: commentParams.contentURI,
                pointedProfileId: commentParams.pointedProfileId,
                pointedPubId: commentParams.pointedPubId,
                referenceModuleData: commentParams.referenceModuleData,
                collectModule: commentParams.collectModule,
                collectModuleInitData: commentParams.collectModuleInitData,
                referenceModule: commentParams.referenceModule,
                referenceModuleInitData: commentParams.referenceModuleInitData
            });
    }

    function _createReferencePublication(
        DataTypes.ReferencePubParams memory referencePubParams,
        address transactionExecutor
    )
        private
        returns (
            uint256,
            bytes memory,
            bytes memory
        )
    {
        DataTypes.PublicationType referrerPubType = GeneralHelpers
            .validateReferrerAndGetReferrerPubType(
                referencePubParams.referrerProfileId,
                referencePubParams.referrerPubId,
                referencePubParams.pointedProfileId,
                referencePubParams.pointedPubId
            );

        uint256 pubIdAssigned = _fillReferencePublicationStorage(referencePubParams);

        bytes memory collectModuleReturnData = _initPubCollectModule(
            referencePubParams.profileId,
            transactionExecutor,
            pubIdAssigned,
            referencePubParams.collectModule,
            referencePubParams.collectModuleInitData
        );

        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            referencePubParams.profileId,
            transactionExecutor,
            pubIdAssigned,
            referencePubParams.referenceModule,
            referencePubParams.referenceModuleInitData
        );

        return (pubIdAssigned, collectModuleReturnData, referenceModuleReturnData);
    }

    function _fillReferencePublicationStorage(
        DataTypes.ReferencePubParams memory referencePubParams
    ) private returns (uint256) {
        uint256 pubIdAssigned = ++GeneralHelpers
            .getProfileStruct(referencePubParams.profileId)
            .pubCount;
        DataTypes.PublicationStruct storage _referencePub;
        _referencePub = GeneralHelpers.getPublicationStruct(
            referencePubParams.profileId,
            pubIdAssigned
        );
        _referencePub.pointedProfileId = referencePubParams.pointedProfileId;
        _referencePub.pointedPubId = referencePubParams.pointedPubId;
        _referencePub.contentURI = referencePubParams.contentURI;
        _referencePub.pubType = referencePubParams.pubType;
        DataTypes.PublicationStruct storage _pubPointed = GeneralHelpers.getPublicationStruct(
            referencePubParams.pointedProfileId,
            referencePubParams.pointedPubId
        );
        if (_pubPointed.pubType == DataTypes.PublicationType.Post) {
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
        DataTypes.CommentParams calldata commentParams,
        address transactionExecutor
    ) private {
        address refModule = GeneralHelpers
            .getPublicationStruct(commentParams.pointedProfileId, commentParams.pointedPubId)
            .referenceModule;
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processComment({
                    profileId: commentParams.profileId,
                    executor: transactionExecutor,
                    pointedProfileId: commentParams.pointedProfileId,
                    pointedPubId: commentParams.pointedPubId,
                    referrerProfileId: commentParams.referrerProfileId,
                    referrerPubId: commentParams.referrerPubId,
                    referrerPubType: commentParams.referrerPubType,
                    data: commentParams.referenceModuleData
                })
            {} catch (bytes memory err) {
                assembly {
                    /// Equivalent to reverting with the returned error selector if
                    /// the length is not zero.
                    let length := mload(err)
                    if iszero(iszero(length)) {
                        revert(add(err, 32), length)
                    }
                }
                if (transactionExecutor != GeneralHelpers.unsafeOwnerOf(commentParams.profileId)) {
                    revert Errors.ExecutorInvalid();
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
        uint256 profileId,
        address transactionExecutor,
        uint256 pointedProfileId,
        uint256 pointedPubId,
        uint256 referrerProfileId,
        bytes memory referenceModuleData
    ) private {
        address refModule = GeneralHelpers
            .getPublicationStruct(pointedProfileId, pointedPubId)
            .referenceModule;
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processQuote({
                    profileId: profileId,
                    executor: transactionExecutor,
                    pointedProfileId: pointedProfileId,
                    pointedPubId: pointedPubId,
                    referrerProfileId: referrerProfileId,
                    data: referenceModuleData
                })
            {} catch (bytes memory err) {
                assembly {
                    /// Equivalent to reverting with the returned error selector if
                    /// the length is not zero.
                    let length := mload(err)
                    if iszero(iszero(length)) {
                        revert(add(err, 32), length)
                    }
                }
                if (transactionExecutor != GeneralHelpers.unsafeOwnerOf(profileId)) {
                    revert Errors.ExecutorInvalid();
                }
                IDeprecatedReferenceModule(refModule).processComment(
                    profileId,
                    pointedProfileId,
                    pointedPubId,
                    referenceModuleData
                );
            }
        }
    }

    function _processMirrorIfNeeded(
        uint256 profileId,
        address transactionExecutor,
        uint256 pointedProfileId,
        uint256 pointedPubId,
        bytes memory referenceModuleData
    ) private {
        address refModule = GeneralHelpers
            .getPublicationStruct(pointedProfileId, pointedPubId)
            .referenceModule;
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processMirror(
                    profileId,
                    transactionExecutor,
                    pointedProfileId,
                    pointedPubId,
                    referenceModuleData
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
                if (transactionExecutor != GeneralHelpers.unsafeOwnerOf(profileId)) {
                    revert Errors.ExecutorInvalid();
                }
                IDeprecatedReferenceModule(refModule).processMirror(
                    profileId,
                    pointedProfileId,
                    pointedPubId,
                    referenceModuleData
                );
            }
        }
    }

    function _initPubCollectModule(
        uint256 profileId,
        address transactionExecutor,
        uint256 pubId,
        address collectModule,
        bytes memory collectModuleInitData
    ) private returns (bytes memory) {
        GeneralHelpers.validateCollectModuleWhitelisted(collectModule);
        GeneralHelpers.getPublicationStruct(profileId, pubId).collectModule = collectModule;
        return
            ICollectModule(collectModule).initializePublicationCollectModule(
                profileId,
                pubId,
                transactionExecutor,
                collectModuleInitData
            );
    }

    function _initPubReferenceModule(
        uint256 profileId,
        address transactionExecutor,
        uint256 pubId,
        address referenceModule,
        bytes memory referenceModuleInitData
    ) private returns (bytes memory) {
        if (referenceModule == address(0)) return new bytes(0);
        GeneralHelpers.validateReferenceModuleWhitelisted(referenceModule);
        GeneralHelpers.getPublicationStruct(profileId, pubId).referenceModule = referenceModule;
        return
            IReferenceModule(referenceModule).initializeReferenceModule(
                profileId,
                transactionExecutor,
                pubId,
                referenceModuleInitData
            );
    }
}
