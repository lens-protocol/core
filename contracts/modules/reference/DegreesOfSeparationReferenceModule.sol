// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IFollowModule} from 'contracts/interfaces/IFollowModule.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {IERC721Timestamped} from 'contracts/interfaces/IERC721Timestamped.sol';
import {IReferenceModule} from 'contracts/interfaces/IReferenceModule.sol';
import {HubRestricted} from 'contracts/base/HubRestricted.sol';
import {FollowValidationLib} from 'contracts/modules/libraries/FollowValidationLib.sol';

/**
 * @notice Struct representing the module configuration for certain publication.
 *
 * @param setUp Indicates if the publication was set up to use this module, to then allow updating params.
 * @param commentsRestricted Indicates if the comment operation is restricted or open to everyone.
 * @param quotesRestricted Indicates if the quote operation is restricted or open to everyone.
 * @param mirrorsRestricted Indicates if the mirror operation is restricted or open to everyone.
 * @param degreesOfSeparation The max degrees of separation allowed for restricted operations.
 * @param sourceProfile The ID of the profile from where the follower path should be started. Expected to be set as the
 * author of the root publication.
 */
struct ModuleConfig {
    bool setUp;
    bool commentsRestricted;
    bool quotesRestricted;
    bool mirrorsRestricted;
    uint8 degreesOfSeparation;
    uint128 sourceProfile;
}

/**
 * @title DegreesOfSeparationReferenceModule
 * @author Lens Protocol
 *
 * @notice This reference module allows to set a degree of separation `n`, and then allows to quote/comment/mirror
 * only to profiles that are at most at `n` degrees of separation from the source profile, which is expected to be set
 * as the author of the root publication.
 */
contract DegreesOfSeparationReferenceModule is HubRestricted, IReferenceModule {
    using FollowValidationLib for ILensHub;

    error InvalidDegreesOfSeparation();
    error OperationDisabled();
    error ProfilePathExceedsDegreesOfSeparation();
    error NotInheritingPointedPubConfig();

    /**
     * @dev Because of the "Six degrees of separation" theory, in the long term, setting up 5, 6 or more degrees of
     * separation will be almost equivalent to turning off the restriction.
     * If we also take into account the gas cost of performing the validations on-chain, and the cost of off-chain
     * computation of the path, makes sense to only support up to 3 degrees of separation.
     */
    uint8 constant MAX_DEGREES_OF_SEPARATION = 3;

    mapping(address signer => uint256 nonce) public nonces;

    mapping(uint256 profileId => mapping(uint256 pubId => ModuleConfig config)) internal _moduleConfig;

    constructor(address hub) HubRestricted(hub) {}

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev The `data` param should have ABI-encoded the following information:
     *  - bool commentsRestricted: Indicates if the comment operation is restricted or open to everyone.
     *  - bool quotesRestricted: Indicates if the quote operation is restricted or open to everyone.
     *  - bool mirrorsRestricted: Indicates if the mirror operation is restricted or open to everyone.
     *  - uint8 degreesOfSeparation: The max degrees of separation allowed for restricted operations.
     *  - uint128 sourceProfile The ID of the profile from where the follower path should be started. Expected to be set
     *    as the author of the root publication.
     */
    function initializeReferenceModule(
        uint256 profileId,
        uint256 pubId,
        address /* transactionExecutor */,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (
            bool commentsRestricted,
            bool quotesRestricted,
            bool mirrorsRestricted,
            uint8 degreesOfSeparation,
            uint128 sourceProfile
        ) = abi.decode(data, (bool, bool, bool, uint8, uint128));
        if (degreesOfSeparation > MAX_DEGREES_OF_SEPARATION) {
            revert InvalidDegreesOfSeparation();
        }
        if (!IERC721Timestamped(HUB).exists(sourceProfile)) {
            revert Errors.TokenDoesNotExist();
        }
        _moduleConfig[profileId][pubId] = ModuleConfig(
            true,
            commentsRestricted,
            quotesRestricted,
            mirrorsRestricted,
            degreesOfSeparation,
            sourceProfile
        );
        return '';
    }

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev It will apply the degrees of separation restriction if the publication has `commentsRestricted` enabled.
     * The param `processCommentParams.data` has ABI-encoded the array of profile IDs representing the follower path
     * between the source profile and the profile authoring the comment.
     * In addition, if comments were restricted, inheritance of commenting restrictions will be enforced.
     */
    function processComment(
        Types.ProcessCommentParams calldata processCommentParams
    ) external view override onlyHub returns (bytes memory) {
        ModuleConfig memory config = _moduleConfig[processCommentParams.pointedProfileId][
            processCommentParams.pointedPubId
        ];
        if (config.commentsRestricted) {
            _validateDegreesOfSeparationRestriction({
                sourceProfile: config.sourceProfile,
                profileId: processCommentParams.profileId,
                degreesOfSeparation: config.degreesOfSeparation,
                profilePath: abi.decode(processCommentParams.data, (uint256[]))
            });
            _validateCommentInheritedConfigFromPointedPub({
                pointedPubConfig: config,
                profileId: processCommentParams.profileId
            });
        }
        return '';
    }

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev It will apply the degrees of separation restriction if the publication has `quotesRestricted` enabled.
     * The param `processQuoteParams.data` has ABI-encoded the array of profile IDs representing the follower path
     * between the source profile and the profile authoring the quote.
     */
    function processQuote(
        Types.ProcessQuoteParams calldata processQuoteParams
    ) external view override onlyHub returns (bytes memory) {
        if (_moduleConfig[processQuoteParams.pointedProfileId][processQuoteParams.pointedPubId].quotesRestricted) {
            _validateDegreesOfSeparationRestriction({
                sourceProfile: _moduleConfig[processQuoteParams.pointedProfileId][processQuoteParams.pointedPubId]
                    .sourceProfile,
                profileId: processQuoteParams.profileId,
                degreesOfSeparation: _moduleConfig[processQuoteParams.pointedProfileId][processQuoteParams.pointedPubId]
                    .degreesOfSeparation,
                profilePath: abi.decode(processQuoteParams.data, (uint256[]))
            });
        }
        return '';
    }

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev It will apply the degrees of separation restriction if the publication has `mirrorsRestricted` enabled.
     * The param `processMirrorParams.data` has ABI-encoded the array of profile IDs representing the follower path
     * between the source profile and the profile authoring the mirror.
     */
    function processMirror(
        Types.ProcessMirrorParams calldata processMirrorParams
    ) external view override onlyHub returns (bytes memory) {
        if (_moduleConfig[processMirrorParams.pointedProfileId][processMirrorParams.pointedPubId].mirrorsRestricted) {
            _validateDegreesOfSeparationRestriction({
                sourceProfile: _moduleConfig[processMirrorParams.pointedProfileId][processMirrorParams.pointedPubId]
                    .sourceProfile,
                profileId: processMirrorParams.profileId,
                degreesOfSeparation: _moduleConfig[processMirrorParams.pointedProfileId][
                    processMirrorParams.pointedPubId
                ].degreesOfSeparation,
                profilePath: abi.decode(processMirrorParams.data, (uint256[]))
            });
        }
        return '';
    }

    /**
     * @notice Gets the module configuration for the given publication.
     *
     * @param profileId The token ID of the profile publishing the publication.
     * @param pubId The associated publication's LensHub publication ID.
     *
     * @return ModuleConfig The module configuration set for the given publication.
     */
    function getModuleConfig(uint256 profileId, uint256 pubId) external view returns (ModuleConfig memory) {
        return _moduleConfig[profileId][pubId];
    }

    /**
     * @dev The data has encoded an array of integers, each integer is a profile ID, the whole array represents a path
     * of `n` profiles.
     *
     * Let's define `X --> Y` as `The owner of X is following Y`. Then, being `path[i]` the i-th profile in the path,
     * the following condition must be met for a given path of `n` profiles:
     *
     *    sourceProfile --> path[0] --> path[1] --> path[2] --> ... --> path[n-2] --> path[n-1] --> profileId
     *
     * @param sourceProfile The ID of the profile from where the follower path should be started. Most likely to be the
     * root publication's author.
     * @param profileId The ID of the publication being published's author.
     * @param degreesOfSeparation The degrees of separations configured for the given publication.
     * @param profilePath The array of profile IDs representing the follower path between the source profile and the
     * profile authoring the new publication (it could be a comment, a quote or a mirror of the pointed one).
     */
    function _validateDegreesOfSeparationRestriction(
        uint256 sourceProfile,
        uint256 profileId,
        uint8 degreesOfSeparation,
        uint256[] memory profilePath
    ) internal view {
        // If `degreesOfSeparation` was set to zero, only `sourceProfile` is allowed to interact.
        if (degreesOfSeparation == 0 && profileId != sourceProfile) {
            revert OperationDisabled();
        }
        if (profilePath.length > degreesOfSeparation - 1) {
            revert ProfilePathExceedsDegreesOfSeparation();
        }
        if (profilePath.length > 0) {
            // Checks that the source profile follows the first profile in the path.
            // In the previous notation: sourceProfile --> path[0]
            ILensHub(HUB).validateIsFollowing({followerProfileId: sourceProfile, followedProfileId: profilePath[0]});
            // Checks each profile owner in the path is following the profile coming next, according the order.
            // In the previous notaiton: path[0] --> path[1] --> path[2] --> ... --> path[n-2] --> path[n-1]
            uint256 i;
            while (i < profilePath.length - 1) {
                ILensHub(HUB).validateIsFollowing({
                    followerProfileId: profilePath[i],
                    followedProfileId: profilePath[i + 1]
                });
                unchecked {
                    ++i;
                }
            }
            // Checks that the last profile in the path follows the profile authoring the new publication.
            // In the previous notation: path[n-1] --> profileId
            ILensHub(HUB).validateIsFollowing({followerProfileId: profilePath[i], followedProfileId: profileId});
        } else {
            // Checks that the source profile follows the profile authoring the new publication.
            // In the previous notation: sourceProfile --> profileId
            ILensHub(HUB).validateIsFollowing({followerProfileId: sourceProfile, followedProfileId: profileId});
        }
    }

    /**
     * @notice Validates that the comment configuration is inherited from pointed publication.
     *
     * @param pointedPubConfig The pointed publication's degrees of separation module configuration.
     * @param profileId The ID of the profile authoring the publication being processed.
     */
    function _validateCommentInheritedConfigFromPointedPub(
        ModuleConfig memory pointedPubConfig,
        uint256 profileId
    ) internal view {
        // We are processing profileId's last publication, so we get the ID from his publication counter.
        uint256 pubId = ILensHub(HUB).getPubCount(profileId);
        // We only care about inheritance of the comment restrictions.
        if (
            !_moduleConfig[profileId][pubId].setUp ||
            !_moduleConfig[profileId][pubId].commentsRestricted ||
            _moduleConfig[profileId][pubId].sourceProfile != pointedPubConfig.sourceProfile ||
            _moduleConfig[profileId][pubId].degreesOfSeparation != pointedPubConfig.degreesOfSeparation
        ) {
            revert NotInheritingPointedPubConfig();
        }
    }
}
