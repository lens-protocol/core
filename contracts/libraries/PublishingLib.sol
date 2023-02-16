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
     * @param postData The PostData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function post(DataTypes.PostData calldata postData) external returns (uint256) {
        uint256 pubId = ++GeneralHelpers.getProfileStruct(postData.profileId).pubCount;
        GeneralHelpers.validateAddressIsProfileOwnerOrDelegatedExecutor(
            msg.sender,
            postData.profileId
        );
        _createPost(
            postData.profileId,
            msg.sender,
            pubId,
            postData.contentURI,
            postData.collectModule,
            postData.collectModuleInitData,
            postData.referenceModule,
            postData.referenceModuleInitData
        );
        return pubId;
    }

    /**
     * @notice Publishes a post to a given profile via signature.
     *
     * @param postWithSigData the PostWithSigData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function postWithSig(DataTypes.PostWithSigData calldata postWithSigData)
        external
        returns (uint256)
    {
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            postWithSigData.profileId,
            postWithSigData.delegatedSigner
        );
        uint256 pubId = ++GeneralHelpers.getProfileStruct(postWithSigData.profileId).pubCount;
        MetaTxHelpers.basePostWithSig(signer, postWithSigData);
        _createPost(
            postWithSigData.profileId,
            signer,
            pubId,
            postWithSigData.contentURI,
            postWithSigData.collectModule,
            postWithSigData.collectModuleInitData,
            postWithSigData.referenceModule,
            postWithSigData.referenceModuleInitData
        );
        return pubId;
    }

    /**
     * @notice Publishes a comment to a given profile via signature.
     *
     * @param commentData the CommentData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function comment(DataTypes.CommentData calldata commentData) external returns (uint256) {
        GeneralHelpers.validateAddressIsProfileOwnerOrDelegatedExecutor(
            msg.sender,
            commentData.profileId
        );
        GeneralHelpers.validateNotBlocked(commentData.profileId, commentData.profileIdPointed);
        return _createComment({commentData: commentData, transactionExecutor: msg.sender});
    }

    /**
     * @notice Publishes a comment to a given profile via signature.
     *
     * @param commentWithSigData the CommentWithSigData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function commentWithSig(DataTypes.CommentWithSigData calldata commentWithSigData)
        external
        returns (uint256)
    {
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            commentWithSigData.profileId,
            commentWithSigData.delegatedSigner
        );
        GeneralHelpers.validateNotBlocked(
            commentWithSigData.profileId,
            commentWithSigData.profileIdPointed
        );
        MetaTxHelpers.baseCommentWithSig(signer, commentWithSigData);
        return
            _createComment({
                commentData: DataTypes.CommentData({
                    profileId: commentWithSigData.profileId,
                    contentURI: commentWithSigData.contentURI,
                    profileIdPointed: commentWithSigData.profileIdPointed,
                    pubIdPointed: commentWithSigData.pubIdPointed,
                    referenceModuleData: commentWithSigData.referenceModuleData,
                    collectModule: commentWithSigData.collectModule,
                    collectModuleInitData: commentWithSigData.collectModuleInitData,
                    referenceModule: commentWithSigData.referenceModule,
                    referenceModuleInitData: commentWithSigData.referenceModuleInitData
                }),
                transactionExecutor: msg.sender
            });
    }

    /**
     * @notice Publishes a mirror to a given profile.
     *
     * @param mirrorData the MirrorData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function mirror(DataTypes.MirrorData calldata mirrorData) external returns (uint256) {
        GeneralHelpers.validateAddressIsProfileOwnerOrDelegatedExecutor(
            msg.sender,
            mirrorData.profileId
        );
        GeneralHelpers.validateNotBlocked(mirrorData.profileId, mirrorData.profileIdPointed);
        return _createMirror({mirrorData: mirrorData, transactionExecutor: msg.sender});
    }

    /**
     * @notice Publishes a mirror to a given profile via signature.
     *
     * @param mirrorWithSigData the MirrorWithSigData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function mirrorWithSig(DataTypes.MirrorWithSigData calldata mirrorWithSigData)
        external
        returns (uint256)
    {
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            mirrorWithSigData.profileId,
            mirrorWithSigData.delegatedSigner
        );
        GeneralHelpers.validateNotBlocked(
            mirrorWithSigData.profileId,
            mirrorWithSigData.profileIdPointed
        );
        MetaTxHelpers.baseMirrorWithSig(signer, mirrorWithSigData);
        return
            _createMirror({
                mirrorData: DataTypes.MirrorData({
                    profileId: mirrorWithSigData.profileId,
                    profileIdPointed: mirrorWithSigData.profileIdPointed,
                    pubIdPointed: mirrorWithSigData.pubIdPointed,
                    referenceModuleData: mirrorWithSigData.referenceModuleData
                }),
                transactionExecutor: mirrorWithSigData.delegatedSigner
            });
    }

    function _setPublicationPointer(
        uint256 profileId,
        uint256 pubId,
        uint256 profileIdPointed,
        uint256 pubIdPointed
    ) private {
        DataTypes.PublicationStruct storage _publication = GeneralHelpers.getPublicationStruct(
            profileId,
            pubId
        );
        _publication.profileIdPointed = profileIdPointed;
        _publication.pubIdPointed = pubIdPointed;
    }

    /**
     * @notice Creates a post publication mapped to the given profile.
     *
     * @param profileId The profile ID to associate this publication to.
     * @param executor The executor, which is either the owner or an approved delegated executor.
     * @param pubId The publication ID to associate with this publication.
     * @param contentURI The URI to set for this publication.
     * @param collectModule The collect module to set for this publication.
     * @param collectModuleInitData The data to pass to the collect module for publication initialization.
     * @param referenceModule The reference module to set for this publication, if any.
     * @param referenceModuleInitData The data to pass to the reference module for publication initialization.
     */
    function _createPost(
        uint256 profileId,
        address executor,
        uint256 pubId,
        string calldata contentURI,
        address collectModule,
        bytes calldata collectModuleInitData,
        address referenceModule,
        bytes calldata referenceModuleInitData
    ) private {
        GeneralHelpers.getPublicationStruct(profileId, pubId).contentURI = contentURI;

        bytes memory collectModuleReturnData = _initPubCollectModule(
            profileId,
            executor,
            pubId,
            collectModule,
            collectModuleInitData
        );

        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            profileId,
            executor,
            pubId,
            referenceModule,
            referenceModuleInitData
        );

        emit Events.PostCreated(
            profileId,
            pubId,
            contentURI,
            collectModule,
            collectModuleReturnData,
            referenceModule,
            referenceModuleReturnData,
            block.timestamp
        );
    }

    /**
     * @notice Creates a comment publication mapped to the given profile.
     *
     * @param commentData The CommentData struct to use to create the comment.
     * @param transactionExecutor The address executing the transaction. It can be the msg.sender if it is a regular
     * transaction, or the signer if it is a meta-tx.
     *
     * @return uint256 The publication ID assigned to the comment being done.
     */
    function _createComment(DataTypes.CommentData memory commentData, address transactionExecutor)
        private
        returns (uint256)
    {
        uint256 pubIdAssigned = ++GeneralHelpers.getProfileStruct(commentData.profileId).pubCount;

        (uint256 profileIdPointed, uint256 pubIdPointed, ) = GeneralHelpers.getPointedIfMirror(
            commentData.profileIdPointed,
            commentData.pubIdPointed
        );

        {
            DataTypes.PublicationStruct storage _publication;
            _publication = GeneralHelpers.getPublicationStruct(
                commentData.profileId,
                pubIdAssigned
            );
            _publication.profileIdPointed = profileIdPointed;
            _publication.pubIdPointed = pubIdPointed;
            _publication.contentURI = commentData.contentURI;
        }

        {
            address referenceModule = commentData.referenceModule; // Stack-too-deep workaround.

            bytes memory collectModuleReturnData = _initPubCollectModule(
                commentData.profileId,
                transactionExecutor,
                pubIdAssigned,
                commentData.collectModule,
                commentData.collectModuleInitData
            );

            bytes memory referenceModuleReturnData = _initPubReferenceModule(
                commentData.profileId,
                transactionExecutor,
                pubIdAssigned,
                referenceModule,
                commentData.referenceModuleInitData
            );

            _processCommentIfNeeded({
                profileId: commentData.profileId,
                executor: transactionExecutor,
                profileIdPointed: profileIdPointed,
                pubIdPointed: pubIdPointed,
                referrerProfileId: commentData.profileIdPointed == profileIdPointed
                    ? 0
                    : commentData.profileIdPointed,
                referenceModuleData: commentData.referenceModuleData
            });

            emit Events.CommentCreated(
                commentData.profileId,
                pubIdAssigned,
                commentData.contentURI,
                profileIdPointed,
                pubIdPointed,
                commentData.referenceModuleData,
                commentData.collectModule,
                collectModuleReturnData,
                referenceModule,
                referenceModuleReturnData,
                block.timestamp
            );
        }

        return pubIdAssigned;
    }

    /**
     * @notice Creates a mirror publication mapped to the given profile.
     *
     * @param mirrorData The MirrorData struct to use to create the mirror.
     * @param transactionExecutor The address executing the transaction. It can be the msg.sender if it is a regular
     * transaction, or the signer if it is a meta-tx.
     *
     * @return uint256 The publication ID to associate with this publication.
     */
    function _createMirror(DataTypes.MirrorData memory mirrorData, address transactionExecutor)
        private
        returns (uint256)
    {
        uint256 pubIdAssigned = ++GeneralHelpers.getProfileStruct(mirrorData.profileId).pubCount;

        (uint256 profileIdPointed, uint256 pubIdPointed, ) = GeneralHelpers.getPointedIfMirror(
            mirrorData.profileIdPointed,
            mirrorData.pubIdPointed
        );

        DataTypes.PublicationStruct storage _publication = GeneralHelpers.getPublicationStruct(
            mirrorData.profileId,
            pubIdAssigned
        );
        _publication.profileIdPointed = profileIdPointed;
        _publication.pubIdPointed = pubIdPointed;

        _processMirrorIfNeeded(
            mirrorData.profileId,
            transactionExecutor,
            profileIdPointed,
            pubIdPointed,
            mirrorData.referenceModuleData
        );

        emit Events.MirrorCreated(
            mirrorData.profileId,
            pubIdAssigned,
            profileIdPointed,
            pubIdPointed,
            mirrorData.referenceModuleData,
            block.timestamp
        );

        return pubIdAssigned;
    }

    function _processCommentIfNeeded(
        uint256 profileId,
        address executor,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        uint256 referrerProfileId,
        bytes memory referenceModuleData
    ) private {
        address refModule = GeneralHelpers
            .getPublicationStruct(profileIdPointed, pubIdPointed)
            .referenceModule;
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processComment({
                    profileId: profileId,
                    executor: executor,
                    profileIdPointed: profileIdPointed,
                    pubIdPointed: pubIdPointed,
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
                if (executor != GeneralHelpers.unsafeOwnerOf(profileId)) {
                    revert Errors.ExecutorInvalid();
                }
                IDeprecatedReferenceModule(refModule).processComment(
                    profileId,
                    profileIdPointed,
                    pubIdPointed,
                    referenceModuleData
                );
            }
        }
    }

    function _processMirrorIfNeeded(
        uint256 profileId,
        address executor,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes memory referenceModuleData
    ) private {
        address refModule = GeneralHelpers
            .getPublicationStruct(profileIdPointed, pubIdPointed)
            .referenceModule;
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processMirror(
                    profileId,
                    executor,
                    profileIdPointed,
                    pubIdPointed,
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
                if (executor != GeneralHelpers.unsafeOwnerOf(profileId)) {
                    revert Errors.ExecutorInvalid();
                }
                IDeprecatedReferenceModule(refModule).processMirror(
                    profileId,
                    profileIdPointed,
                    pubIdPointed,
                    referenceModuleData
                );
            }
        }
    }

    function _initPubCollectModule(
        uint256 profileId,
        address executor,
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
                executor,
                collectModuleInitData
            );
    }

    function _initPubReferenceModule(
        uint256 profileId,
        address executor,
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
                executor,
                pubId,
                referenceModuleInitData
            );
    }
}
