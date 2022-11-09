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
     * @param vars The PostData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function post(DataTypes.PostData calldata vars) external returns (uint256) {
        uint256 pubId = _preIncrementPubCount(vars.profileId);
        GeneralHelpers.validateCallerIsOwnerOrDispatcherOrExecutor(vars.profileId);
        _createPost(
            vars.profileId,
            msg.sender,
            pubId,
            vars.contentURI,
            vars.collectModule,
            vars.collectModuleInitData,
            vars.referenceModule,
            vars.referenceModuleInitData
        );
        return pubId;
    }

    /**
     * @notice Publishes a post to a given profile via signature.
     *
     * @param vars the PostWithSigData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function postWithSig(DataTypes.PostWithSigData calldata vars) external returns (uint256) {
        uint256 profileId = vars.profileId;
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            GeneralHelpers.unsafeOwnerOf(profileId),
            vars.delegatedSigner
        );
        uint256 pubId = _preIncrementPubCount(profileId);
        MetaTxHelpers.basePostWithSig(signer, vars);
        _createPost(
            profileId,
            signer,
            pubId,
            vars.contentURI,
            vars.collectModule,
            vars.collectModuleInitData,
            vars.referenceModule,
            vars.referenceModuleInitData
        );
        return pubId;
    }

    /**
     * @notice Publishes a comment to a given profile via signature.
     *
     * @param vars the CommentData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function comment(DataTypes.CommentData calldata vars) external returns (uint256) {
        uint256 pubId = _preIncrementPubCount(vars.profileId);
        GeneralHelpers.validateCallerIsOwnerOrDispatcherOrExecutor(vars.profileId);
        _createComment(vars, pubId); // caller is executor
        return pubId;
    }

    /**
     * @notice Publishes a comment to a given profile via signature.
     *
     * @param vars the CommentWithSigData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function commentWithSig(DataTypes.CommentWithSigData calldata vars) external returns (uint256) {
        uint256 profileId = vars.profileId;
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            GeneralHelpers.unsafeOwnerOf(profileId),
            vars.delegatedSigner
        );
        uint256 pubId = _preIncrementPubCount(profileId);
        MetaTxHelpers.baseCommentWithSig(signer, vars);
        _createCommentWithSigStruct(vars, signer, pubId);
        return pubId;
    }

    /**
     * @notice Publishes a mirror to a given profile.
     *
     * @param vars the MirrorData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function mirror(DataTypes.MirrorData calldata vars) external returns (uint256) {
        uint256 pubId = _preIncrementPubCount(vars.profileId);
        GeneralHelpers.validateCallerIsOwnerOrDispatcherOrExecutor(vars.profileId);
        _createMirror(vars, pubId); // caller is executor
        return pubId;
    }

    /**
     * @notice Publishes a mirror to a given profile via signature.
     *
     * @param vars the MirrorWithSigData struct.
     *
     * @return uint256 The created publication's pubId.
     */
    function mirrorWithSig(DataTypes.MirrorWithSigData calldata vars) external returns (uint256) {
        uint256 profileId = vars.profileId;
        address signer = GeneralHelpers.getOriginatorOrDelegatedExecutorSigner(
            GeneralHelpers.unsafeOwnerOf(profileId),
            vars.delegatedSigner
        );
        uint256 pubId = _preIncrementPubCount(profileId);
        MetaTxHelpers.baseMirrorWithSig(signer, vars);
        _createMirrorWithSigStruct(vars, signer, pubId);
        return pubId;
    }

    function _preIncrementPubCount(uint256 profileId) private returns (uint256) {
        uint256 pubCount;
        // Load the previous publication count for the given profile and increment it in storage.
        assembly {
            mstore(0, profileId)
            mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
            // pubCount is at offset 0, so we don't need to add any offset.
            let slot := keccak256(0, 64)
            pubCount := add(sload(slot), 1)
            sstore(slot, pubCount)
        }
        return pubCount;
    }

    function _setPublicationPointer(
        uint256 profileId,
        uint256 pubId,
        uint256 profileIdPointed,
        uint256 pubIdPointed
    ) private {
        // Store the pointed profile ID and pointed pub ID in the appropriate slots for
        // a given publication.
        assembly {
            mstore(0, profileId)
            mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            // profile ID pointed is at offset 0, so we don't need to add any offset.
            let slot := keccak256(0, 64)
            sstore(slot, profileIdPointed)
            slot := add(slot, PUBLICATION_PUB_ID_POINTED_OFFSET)
            sstore(slot, pubIdPointed)
        }
    }

    function _setPublicationContentURI(
        uint256 profileId,
        uint256 pubId,
        string calldata value
    ) private {
        assembly {
            let length := value.length
            let cdOffset := value.offset
            mstore(0, profileId)
            mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            let slot := add(keccak256(0, 64), PUBLICATION_CONTENT_URI_OFFSET)

            // If the length is greater than 31, storage rules are different.
            switch gt(length, 31)
            case 1 {
                // The length is > 31, so we need to store the actual string in a new slot,
                // equivalent to keccak256(startSlot), and store length*2+1 in startSlot.
                sstore(slot, add(shl(1, length), 1))

                // Calculate the amount of storage slots we need to store the full string.
                // This is equivalent to (string.length + 31)/32.
                let totalStorageSlots := shr(5, add(length, 31))

                // Compute the slot where the actual string will begin, which is the keccak256
                // hash of the slot where we stored the modified length.
                mstore(0, slot)
                slot := keccak256(0, 32)

                // Write the actual string to storage starting at the computed slot.
                // prettier-ignore
                for { let i := 0 } lt(i, totalStorageSlots) { i := add(i, 1) } {
                    sstore(add(slot, i), calldataload(add(cdOffset, mul(32, i))))
                }
            }
            default {
                // The length is <= 31 so store the string and the length*2 in the same slot.
                sstore(slot, or(calldataload(cdOffset), shl(1, length)))
            }
        }
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
        _setPublicationContentURI(profileId, pubId, contentURI);

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
     * @param vars The CommentData struct to use to create the comment.
     * @param pubId The publication ID to associate with this publication.
     */
    function _createComment(DataTypes.CommentData calldata vars, uint256 pubId) private {
        (uint256 rootProfileIdPointed, uint256 rootPubIdPointed) = GeneralHelpers
            .getPointedIfMirror(vars.profileIdPointed, vars.pubIdPointed);

        _setPublicationPointer(vars.profileId, pubId, rootProfileIdPointed, rootPubIdPointed);
        _setPublicationContentURI(vars.profileId, pubId, vars.contentURI);

        address referenceModule = vars.referenceModule;

        bytes memory collectModuleReturnData = _initPubCollectModule(
            vars.profileId,
            msg.sender,
            pubId,
            vars.collectModule,
            vars.collectModuleInitData
        );

        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            vars.profileId,
            msg.sender,
            pubId,
            referenceModule,
            vars.referenceModuleInitData
        );

        _processCommentIfNeeded(
            vars.profileId,
            msg.sender,
            rootProfileIdPointed,
            rootPubIdPointed,
            vars.referenceModuleData
        );

        emit Events.CommentCreated(
            vars.profileId,
            pubId,
            vars.contentURI,
            rootProfileIdPointed,
            rootPubIdPointed,
            vars.referenceModuleData,
            vars.collectModule,
            collectModuleReturnData,
            referenceModule,
            referenceModuleReturnData,
            block.timestamp
        );
    }

    /**
     * @notice Creates a comment publication mapped to the given profile with a sig struct.
     *
     * @param vars The CommentWithSigData struct to use to create the comment.
     * @param executor The publisher or an approved delegated executor.
     * @param pubId The publication ID to associate with this publication.
     */
    function _createCommentWithSigStruct(
        DataTypes.CommentWithSigData calldata vars,
        address executor,
        uint256 pubId
    ) private {
        (uint256 rootProfileIdPointed, uint256 rootPubIdPointed) = GeneralHelpers
            .getPointedIfMirror(vars.profileIdPointed, vars.pubIdPointed);

        _setPublicationPointer(vars.profileId, pubId, rootProfileIdPointed, rootPubIdPointed);
        _setPublicationContentURI(vars.profileId, pubId, vars.contentURI);

        address referenceModule = vars.referenceModule;
        address collectModule = vars.collectModule;

        bytes memory collectModuleReturnData = _initPubCollectModule(
            vars.profileId,
            executor,
            pubId,
            collectModule,
            vars.collectModuleInitData
        );

        bytes memory referenceModuleReturnData = _initPubReferenceModule(
            vars.profileId,
            executor,
            pubId,
            referenceModule,
            vars.referenceModuleInitData
        );

        _processCommentIfNeeded(
            vars.profileId,
            executor,
            rootProfileIdPointed,
            rootPubIdPointed,
            vars.referenceModuleData
        );

        emit Events.CommentCreated(
            vars.profileId,
            pubId,
            vars.contentURI,
            rootProfileIdPointed,
            rootPubIdPointed,
            vars.referenceModuleData,
            collectModule,
            collectModuleReturnData,
            referenceModule,
            referenceModuleReturnData,
            block.timestamp
        );
    }

    /**
     * @notice Creates a mirror publication mapped to the given profile.
     *
     * @param vars The MirrorData struct to use to create the mirror.
     * @param pubId The publication ID to associate with this publication.
     */
    function _createMirror(DataTypes.MirrorData calldata vars, uint256 pubId) private {
        (uint256 rootProfileIdPointed, uint256 rootPubIdPointed) = GeneralHelpers
            .getPointedIfMirror(vars.profileIdPointed, vars.pubIdPointed);

        _setPublicationPointer(vars.profileId, pubId, rootProfileIdPointed, rootPubIdPointed);

        _processMirrorIfNeeded(
            vars.profileId,
            msg.sender,
            rootProfileIdPointed,
            rootPubIdPointed,
            vars.referenceModuleData
        );

        emit Events.MirrorCreated(
            vars.profileId,
            pubId,
            rootProfileIdPointed,
            rootPubIdPointed,
            vars.referenceModuleData,
            block.timestamp
        );
    }

    /**
     * @notice Creates a mirror publication mapped to the given profile using a sig struct.
     *
     * @param vars The MirrorWithSigData struct to use to create the mirror.
     * @param executor The publisher or an approved delegated executor.
     * @param pubId The publication ID to associate with this publication.
     */
    function _createMirrorWithSigStruct(
        DataTypes.MirrorWithSigData calldata vars,
        address executor,
        uint256 pubId
    ) private {
        (uint256 rootProfileIdPointed, uint256 rootPubIdPointed) = GeneralHelpers
            .getPointedIfMirror(vars.profileIdPointed, vars.pubIdPointed);

        _setPublicationPointer(vars.profileId, pubId, rootProfileIdPointed, rootPubIdPointed);

        _processMirrorIfNeeded(
            vars.profileId,
            executor,
            rootProfileIdPointed,
            rootPubIdPointed,
            vars.referenceModuleData
        );

        emit Events.MirrorCreated(
            vars.profileId,
            pubId,
            rootProfileIdPointed,
            rootPubIdPointed,
            vars.referenceModuleData,
            block.timestamp
        );
    }

    function _validateCollectModuleWhitelisted(address collectModule) private view {
        bool whitelisted;

        // Load whether the given collect module is whitelisted.
        assembly {
            mstore(0, collectModule)
            mstore(32, COLLECT_MODULE_WHITELIST_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            whitelisted := sload(slot)
        }
        if (!whitelisted) revert Errors.CollectModuleNotWhitelisted();
    }

    function _validateReferenceModuleWhitelisted(address referenceModule) private view {
        bool whitelisted;

        // Load whether the given reference module is whitelisted.
        assembly {
            mstore(0, referenceModule)
            mstore(32, REFERENCE_MODULE_WHITELIST_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            whitelisted := sload(slot)
        }
        if (!whitelisted) revert Errors.ReferenceModuleNotWhitelisted();
    }

    function _processCommentIfNeeded(
        uint256 profileId,
        address executor,
        uint256 profileIdPointed,
        uint256 pubIdPointed,
        bytes calldata referenceModuleData
    ) private {
        address refModule = _getReferenceModule(profileIdPointed, pubIdPointed);
        if (refModule != address(0)) {
            try
                IReferenceModule(refModule).processComment(
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
                if (executor != GeneralHelpers.unsafeOwnerOf(profileId))
                    revert Errors.ExecutorInvalid();
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
        bytes calldata referenceModuleData
    ) private {
        address refModule = _getReferenceModule(profileIdPointed, pubIdPointed);
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
                if (executor != GeneralHelpers.unsafeOwnerOf(profileId))
                    revert Errors.ExecutorInvalid();
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
        _validateCollectModuleWhitelisted(collectModule);

        // Store the collect module in the appropriate slot for the given publication.
        assembly {
            mstore(0, profileId)
            mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            let slot := add(keccak256(0, 64), PUBLICATION_COLLECT_MODULE_OFFSET)
            sstore(slot, collectModule)
        }
        return
            ICollectModule(collectModule).initializePublicationCollectModule(
                profileId,
                executor,
                pubId,
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
        _validateReferenceModuleWhitelisted(referenceModule);

        // Store the reference module in the appropriate slot for the given publication.
        assembly {
            mstore(0, profileId)
            mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            let slot := add(keccak256(0, 64), PUBLICATION_REFERENCE_MODULE_OFFSET)
            sstore(slot, referenceModule)
        }
        return
            IReferenceModule(referenceModule).initializeReferenceModule(
                profileId,
                executor,
                pubId,
                referenceModuleInitData
            );
    }

    function _getPubCount(uint256 profileId) private view returns (uint256) {
        uint256 pubCount;

        // Load the publication count for the given profile.
        assembly {
            mstore(0, profileId)
            mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
            // pubCount is at offset 0, so we don't need to add any offset.
            let slot := keccak256(0, 64)
            pubCount := sload(slot)
        }
        return pubCount;
    }

    function _getReferenceModule(uint256 profileId, uint256 pubId) private view returns (address) {
        address referenceModule;

        // Load the reference module for the given publication.
        assembly {
            mstore(0, profileId)
            mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            let slot := add(keccak256(0, 64), PUBLICATION_REFERENCE_MODULE_OFFSET)
            referenceModule := sload(slot)
        }
        return referenceModule;
    }
}
