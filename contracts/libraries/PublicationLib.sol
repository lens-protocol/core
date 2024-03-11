// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ValidationLib} from './ValidationLib.sol';
import {Types} from './constants/Types.sol';
import {Events} from './constants/Events.sol';
import {Errors} from './constants/Errors.sol';
import {IReferenceModule} from '../interfaces/IReferenceModule.sol';
import {ILegacyReferenceModule} from '../interfaces/ILegacyReferenceModule.sol';
import {StorageLib} from './StorageLib.sol';
import {IPublicationActionModule} from '../interfaces/IPublicationActionModule.sol';
import {IModuleRegistry} from '../interfaces/IModuleRegistry.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';

library PublicationLib {
    function MODULE_REGISTRY() internal view returns (IModuleRegistry) {
        return IModuleRegistry(ILensHub(address(this)).getModuleRegistry());
    }

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

        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            InitReferenceModuleParams(
                postParams.profileId,
                transactionExecutor,
                pubIdAssigned,
                postParams.referenceModule,
                postParams.referenceModuleInitData
            )
        );

        bytes[] memory actionModulesReturnDatas = _initPubActionModules(
            InitActionModuleParams(
                postParams.profileId,
                transactionExecutor,
                pubIdAssigned,
                postParams.actionModules,
                postParams.actionModulesInitDatas
            )
        );

        emit Events.PostCreated(
            postParams,
            pubIdAssigned,
            actionModulesReturnDatas,
            referenceModuleReturnData,
            transactionExecutor,
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
            bytes[] memory actionModulesInitReturnDatas,
            bytes memory referenceModuleInitReturnData,
            Types.PublicationType[] memory referrerPubTypes
        ) = _createReferencePublication(
                _asReferencePubParams(commentParams),
                transactionExecutor,
                Types.PublicationType.Comment
            );

        bytes memory referenceModuleReturnData = _processCommentIfNeeded(
            commentParams,
            pubIdAssigned,
            transactionExecutor,
            referrerPubTypes
        );

        emit Events.CommentCreated(
            commentParams,
            pubIdAssigned,
            referenceModuleReturnData,
            actionModulesInitReturnDatas,
            referenceModuleInitReturnData,
            transactionExecutor,
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
        ValidationLib.validatePointedPub(mirrorParams.pointedProfileId, mirrorParams.pointedPubId);
        ValidationLib.validateNotBlocked({profile: mirrorParams.profileId, byProfile: mirrorParams.pointedProfileId});

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
        _publication.contentURI = mirrorParams.metadataURI;
        _publication.pubType = Types.PublicationType.Mirror;
        _fillRootOfPublicationInStorage(_publication, mirrorParams.pointedProfileId, mirrorParams.pointedPubId);

        bytes memory referenceModuleReturnData = _processMirrorIfNeeded(
            mirrorParams,
            pubIdAssigned,
            transactionExecutor,
            referrerPubTypes
        );

        emit Events.MirrorCreated(
            mirrorParams,
            pubIdAssigned,
            referenceModuleReturnData,
            transactionExecutor,
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
    function quote(Types.QuoteParams calldata quoteParams, address transactionExecutor) external returns (uint256) {
        (
            uint256 pubIdAssigned,
            bytes[] memory actionModulesReturnDatas,
            bytes memory referenceModuleInitReturnData,
            Types.PublicationType[] memory referrerPubTypes
        ) = _createReferencePublication(
                _asReferencePubParams(quoteParams),
                transactionExecutor,
                Types.PublicationType.Quote
            );

        bytes memory referenceModuleReturnData = _processQuoteIfNeeded(
            quoteParams,
            pubIdAssigned,
            transactionExecutor,
            referrerPubTypes
        );

        emit Events.QuoteCreated(
            quoteParams,
            pubIdAssigned,
            referenceModuleReturnData,
            actionModulesReturnDatas,
            referenceModuleInitReturnData,
            transactionExecutor,
            block.timestamp
        );

        return pubIdAssigned;
    }

    function getPublicationType(uint256 profileId, uint256 pubId) internal view returns (Types.PublicationType) {
        Types.Publication storage _publication = StorageLib.getPublication(profileId, pubId);
        Types.PublicationType pubType = _publication.pubType;
        if (uint8(pubType) == 0) {
            // Legacy V1: If the publication type is 0, we check using the legacy rules.
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
            return StorageLib.getPublication(_publication.pointedProfileId, _publication.pointedPubId).contentURI;
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
        ValidationLib.validatePointedPub(referencePubParams.pointedProfileId, referencePubParams.pointedPubId);
        ValidationLib.validateNotBlocked({
            profile: referencePubParams.profileId,
            byProfile: referencePubParams.pointedProfileId
        });

        Types.PublicationType[] memory referrerPubTypes = ValidationLib.validateReferrersAndGetReferrersPubTypes(
            referencePubParams.referrerProfileIds,
            referencePubParams.referrerPubIds,
            referencePubParams.pointedProfileId,
            referencePubParams.pointedPubId
        );

        (uint256 pubIdAssigned, uint256 rootProfileId) = _fillReferencePublicationStorage(
            referencePubParams,
            referencePubType
        );

        if (rootProfileId != referencePubParams.pointedProfileId) {
            // We check the block state between the profile commenting/quoting and the root publication's author.
            ValidationLib.validateNotBlocked({profile: referencePubParams.profileId, byProfile: rootProfileId});
        }

        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            InitReferenceModuleParams(
                referencePubParams.profileId,
                transactionExecutor,
                pubIdAssigned,
                referencePubParams.referenceModule,
                referencePubParams.referenceModuleInitData
            )
        );

        bytes[] memory actionModulesReturnDatas = _initPubActionModules(
            InitActionModuleParams(
                referencePubParams.profileId,
                transactionExecutor,
                pubIdAssigned,
                referencePubParams.actionModules,
                referencePubParams.actionModulesInitDatas
            )
        );

        return (pubIdAssigned, actionModulesReturnDatas, referenceModuleReturnData, referrerPubTypes);
    }

    function _fillReferencePublicationStorage(
        Types.ReferencePubParams calldata referencePubParams,
        Types.PublicationType referencePubType
    ) private returns (uint256, uint256) {
        uint256 pubIdAssigned = ++StorageLib.getProfile(referencePubParams.profileId).pubCount;
        Types.Publication storage _referencePub;
        _referencePub = StorageLib.getPublication(referencePubParams.profileId, pubIdAssigned);
        _referencePub.pointedProfileId = referencePubParams.pointedProfileId;
        _referencePub.pointedPubId = referencePubParams.pointedPubId;
        _referencePub.contentURI = referencePubParams.contentURI;
        _referencePub.pubType = referencePubType;
        uint256 rootProfileId = _fillRootOfPublicationInStorage(
            _referencePub,
            referencePubParams.pointedProfileId,
            referencePubParams.pointedPubId
        );
        return (pubIdAssigned, rootProfileId);
    }

    function _fillRootOfPublicationInStorage(
        Types.Publication storage _publication,
        uint256 pointedProfileId,
        uint256 pointedPubId
    ) internal returns (uint256) {
        Types.Publication storage _pubPointed = StorageLib.getPublication(pointedProfileId, pointedPubId);
        Types.PublicationType pubPointedType = _pubPointed.pubType;
        if (pubPointedType == Types.PublicationType.Post) {
            // The publication pointed is a Lens V2 post.
            _publication.rootPubId = pointedPubId;
            return _publication.rootProfileId = pointedProfileId;
        } else if (pubPointedType == Types.PublicationType.Comment || pubPointedType == Types.PublicationType.Quote) {
            // The publication pointed is either a Lens V2 comment or a Lens V2 quote.
            // Note that even when the publication pointed is a V2 one, it will lack `rootProfileId` and `rootPubId` if
            // there is a Lens V1 Legacy publication in the thread of interactions (including the root post itself).
            _publication.rootPubId = _pubPointed.rootPubId;
            return _publication.rootProfileId = _pubPointed.rootProfileId;
        }
        // Otherwise the root is not filled, as the pointed publication is a Lens V1 Legacy publication, which does not
        // support Lens V2 referral system.
        return 0;
    }

    function _processCommentIfNeeded(
        Types.CommentParams calldata commentParams,
        uint256 pubIdAssigned,
        address transactionExecutor,
        Types.PublicationType[] memory referrerPubTypes
    ) private returns (bytes memory) {
        address refModule = StorageLib
            .getPublication(commentParams.pointedProfileId, commentParams.pointedPubId)
            .referenceModule;
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processComment(
                    Types.ProcessCommentParams({
                        profileId: commentParams.profileId,
                        pubId: pubIdAssigned,
                        transactionExecutor: transactionExecutor,
                        pointedProfileId: commentParams.pointedProfileId,
                        pointedPubId: commentParams.pointedPubId,
                        referrerProfileIds: commentParams.referrerProfileIds,
                        referrerPubIds: commentParams.referrerPubIds,
                        referrerPubTypes: referrerPubTypes,
                        data: commentParams.referenceModuleData
                    })
                )
            returns (bytes memory returnData) {
                return (returnData);
            } catch (bytes memory err) {
                assembly {
                    /// Equivalent to reverting with the returned error selector if
                    /// the length is not zero.
                    let length := mload(err)
                    if iszero(iszero(length)) {
                        revert(add(err, 32), length)
                    }
                }
                if (commentParams.referrerProfileIds.length > 0) {
                    // Deprecated reference modules don't support referrers.
                    revert Errors.InvalidReferrer();
                }
                ILegacyReferenceModule(refModule).processComment(
                    commentParams.profileId,
                    commentParams.pointedProfileId,
                    commentParams.pointedPubId,
                    commentParams.referenceModuleData
                );
            }
        } else {
            if (commentParams.referrerProfileIds.length > 0) {
                // We don't allow referrers if the reference module is not set.
                revert Errors.InvalidReferrer();
            }
        }
        return '';
    }

    function _processQuoteIfNeeded(
        Types.QuoteParams calldata quoteParams,
        uint256 pubIdAssigned,
        address transactionExecutor,
        Types.PublicationType[] memory referrerPubTypes
    ) private returns (bytes memory) {
        address refModule = StorageLib
            .getPublication(quoteParams.pointedProfileId, quoteParams.pointedPubId)
            .referenceModule;
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processQuote(
                    Types.ProcessQuoteParams({
                        profileId: quoteParams.profileId,
                        pubId: pubIdAssigned,
                        transactionExecutor: transactionExecutor,
                        pointedProfileId: quoteParams.pointedProfileId,
                        pointedPubId: quoteParams.pointedPubId,
                        referrerProfileIds: quoteParams.referrerProfileIds,
                        referrerPubIds: quoteParams.referrerPubIds,
                        referrerPubTypes: referrerPubTypes,
                        data: quoteParams.referenceModuleData
                    })
                )
            returns (bytes memory returnData) {
                return (returnData);
            } catch (bytes memory err) {
                assembly {
                    /// Equivalent to reverting with the returned error selector if
                    /// the length is not zero.
                    let length := mload(err)
                    if iszero(iszero(length)) {
                        revert(add(err, 32), length)
                    }
                }
                if (quoteParams.referrerProfileIds.length > 0) {
                    // Deprecated reference modules don't support referrers.
                    revert Errors.InvalidReferrer();
                }
                ILegacyReferenceModule(refModule).processComment(
                    quoteParams.profileId,
                    quoteParams.pointedProfileId,
                    quoteParams.pointedPubId,
                    quoteParams.referenceModuleData
                );
            }
        } else {
            if (quoteParams.referrerProfileIds.length > 0) {
                // We don't allow referrers if the reference module is not set.
                revert Errors.InvalidReferrer();
            }
        }
        return '';
    }

    function _processMirrorIfNeeded(
        Types.MirrorParams calldata mirrorParams,
        uint256 pubIdAssigned,
        address transactionExecutor,
        Types.PublicationType[] memory referrerPubTypes
    ) private returns (bytes memory) {
        address refModule = StorageLib
            .getPublication(mirrorParams.pointedProfileId, mirrorParams.pointedPubId)
            .referenceModule;
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processMirror(
                    Types.ProcessMirrorParams({
                        profileId: mirrorParams.profileId,
                        pubId: pubIdAssigned,
                        transactionExecutor: transactionExecutor,
                        pointedProfileId: mirrorParams.pointedProfileId,
                        pointedPubId: mirrorParams.pointedPubId,
                        referrerProfileIds: mirrorParams.referrerProfileIds,
                        referrerPubIds: mirrorParams.referrerPubIds,
                        referrerPubTypes: referrerPubTypes,
                        data: mirrorParams.referenceModuleData
                    })
                )
            returns (bytes memory returnData) {
                return (returnData);
            } catch (bytes memory err) {
                assembly {
                    /// Equivalent to reverting with the returned error selector if
                    /// the length is not zero.
                    let length := mload(err)
                    if iszero(iszero(length)) {
                        revert(add(err, 32), length)
                    }
                }
                if (mirrorParams.referrerProfileIds.length > 0) {
                    // Deprecated reference modules don't support referrers.
                    revert Errors.InvalidReferrer();
                }
                ILegacyReferenceModule(refModule).processMirror(
                    mirrorParams.profileId,
                    mirrorParams.pointedProfileId,
                    mirrorParams.pointedPubId,
                    mirrorParams.referenceModuleData
                );
            }
        } else {
            if (mirrorParams.referrerProfileIds.length > 0) {
                // We don't allow referrers if the reference module is not set.
                revert Errors.InvalidReferrer();
            }
        }
        return '';
    }

    // Needed to avoid 'stack too deep' issue.
    struct InitActionModuleParams {
        uint256 profileId;
        address transactionExecutor;
        uint256 pubId;
        address[] actionModules;
        bytes[] actionModulesInitDatas;
    }

    function _initPubActionModules(InitActionModuleParams memory params) private returns (bytes[] memory) {
        if (params.actionModules.length != params.actionModulesInitDatas.length) {
            revert Errors.ArrayMismatch();
        }

        bytes[] memory actionModuleInitResults = new bytes[](params.actionModules.length);

        uint256 i;
        while (i < params.actionModules.length) {
            MODULE_REGISTRY().verifyModule(
                params.actionModules[i],
                uint256(IModuleRegistry.ModuleType.PUBLICATION_ACTION_MODULE)
            );

            StorageLib.getPublication(params.profileId, params.pubId).actionModuleEnabled[
                params.actionModules[i]
            ] = true;

            actionModuleInitResults[i] = IPublicationActionModule(params.actionModules[i]).initializePublicationAction(
                params.profileId,
                params.pubId,
                params.transactionExecutor,
                params.actionModulesInitDatas[i]
            );

            unchecked {
                ++i;
            }
        }

        return actionModuleInitResults;
    }

    // Needed to avoid 'stack too deep' issue.
    struct InitReferenceModuleParams {
        uint256 profileId;
        address transactionExecutor;
        uint256 pubId;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    function _initPubReferenceModule(InitReferenceModuleParams memory params) private returns (bytes memory) {
        if (params.referenceModule == address(0)) {
            return new bytes(0);
        }
        MODULE_REGISTRY().verifyModule(params.referenceModule, uint256(IModuleRegistry.ModuleType.REFERENCE_MODULE));
        StorageLib.getPublication(params.profileId, params.pubId).referenceModule = params.referenceModule;
        return
            IReferenceModule(params.referenceModule).initializeReferenceModule(
                params.profileId,
                params.pubId,
                params.transactionExecutor,
                params.referenceModuleInitData
            );
    }
}
