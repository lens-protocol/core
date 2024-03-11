// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {Types} from './Types.sol';

library Events {
    /**
     * @dev Emitted when the NFT contract's name and symbol are set at initialization.
     *
     * @param name The NFT name set.
     * @param symbol The NFT symbol set.
     * @param timestamp The current block timestamp.
     */
    event BaseInitialized(string name, string symbol, uint256 timestamp);

    /**
     * @dev Emitted when the hub state is set.
     *
     * @param caller The caller who set the state.
     * @param prevState The previous protocol state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param newState The newly set state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param timestamp The current block timestamp.
     */
    event StateSet(
        address indexed caller,
        Types.ProtocolState indexed prevState,
        Types.ProtocolState indexed newState,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the governance address is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the governance address.
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event GovernanceSet(
        address indexed caller,
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the emergency admin is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the emergency admin address.
     * @param oldEmergencyAdmin The previous emergency admin address.
     * @param newEmergencyAdmin The new emergency admin address set.
     * @param timestamp The current block timestamp.
     */
    event EmergencyAdminSet(
        address indexed caller,
        address indexed oldEmergencyAdmin,
        address indexed newEmergencyAdmin,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a profile creator is added to or removed from the whitelist.
     *
     * @param profileCreator The address of the profile creator.
     * @param whitelisted Whether or not the profile creator is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreatorWhitelisted(address indexed profileCreator, bool indexed whitelisted, uint256 timestamp);

    /**
     * @dev Emitted when a profile is created.
     *
     * @param profileId The newly created profile's token ID.
     * @param creator The profile creator, who created the token with the given profile ID.
     * @param to The address receiving the profile with the given profile ID.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreated(uint256 indexed profileId, address indexed creator, address indexed to, uint256 timestamp);

    /**
     * @dev Emitted when a delegated executors configuration is changed.
     *
     * @param delegatorProfileId The ID of the profile for which the delegated executor was changed.
     * @param configNumber The number of the configuration where the executor approval state was set.
     * @param delegatedExecutors The array of delegated executors whose approval was set for.
     * @param approvals The array of booleans indicating the corresponding executor new approval status.
     * @param timestamp The current block timestamp.
     */
    event DelegatedExecutorsConfigChanged(
        uint256 indexed delegatorProfileId,
        uint256 indexed configNumber,
        address[] delegatedExecutors,
        bool[] approvals,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a delegated executors configuration is applied.
     *
     * @param delegatorProfileId The ID of the profile applying the configuration.
     * @param configNumber The number of the configuration applied.
     * @param timestamp The current block timestamp.
     */
    event DelegatedExecutorsConfigApplied(
        uint256 indexed delegatorProfileId,
        uint256 indexed configNumber,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a profile's follow module is set.
     *
     * @param profileId The profile's token ID.
     * @param followModule The profile's newly set follow module. This CAN be the zero address.
     * @param followModuleInitData The data passed to the follow module, if any.
     * @param followModuleReturnData The data returned from the follow module's initialization. This is ABI-encoded
     * and depends on the follow module chosen.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The current block timestamp.
     */
    event FollowModuleSet(
        uint256 indexed profileId,
        address followModule,
        bytes followModuleInitData,
        bytes followModuleReturnData,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a post is successfully published.
     *
     * @param postParams The parameters passed to create the post publication.
     * @param pubId The publication ID assigned to the created post.
     * @param actionModulesInitReturnDatas The data returned from the action modules' initialization for this given
     * publication. This is ABI-encoded and depends on the action module chosen.
     * @param referenceModuleInitReturnData The data returned from the reference module at initialization. This is
     * ABI-encoded and depends on the reference module chosen.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The current block timestamp.
     */
    event PostCreated(
        Types.PostParams postParams,
        uint256 indexed pubId,
        bytes[] actionModulesInitReturnDatas,
        bytes referenceModuleInitReturnData,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a comment is successfully published.
     *
     * @param commentParams The parameters passed to create the comment publication.
     * @param pubId The publication ID assigned to the created comment.
     * @param referenceModuleReturnData The data returned by the commented publication reference module's
     * processComment function, if the commented publication has a reference module set.
     * @param actionModulesInitReturnDatas The data returned from the action modules' initialization for this given
     * publication. This is ABI-encoded and depends on the action module chosen.
     * @param referenceModuleInitReturnData The data returned from the reference module at initialization. This is
     * ABI-encoded and depends on the reference module chosen.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The current block timestamp.
     */
    event CommentCreated(
        Types.CommentParams commentParams,
        uint256 indexed pubId,
        bytes referenceModuleReturnData,
        bytes[] actionModulesInitReturnDatas,
        bytes referenceModuleInitReturnData,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a mirror is successfully published.
     *
     * @param mirrorParams The parameters passed to create the mirror publication.
     * @param pubId The publication ID assigned to the created mirror.
     * @param referenceModuleReturnData The data returned by the mirrored publication reference module's
     * processMirror function, if the mirrored publication has a reference module set.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The current block timestamp.
     */
    event MirrorCreated(
        Types.MirrorParams mirrorParams,
        uint256 indexed pubId,
        bytes referenceModuleReturnData,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a quote is successfully published.
     *
     * @param quoteParams The parameters passed to create the quote publication.
     * @param pubId The publication ID assigned to the created quote.
     * @param referenceModuleReturnData The data returned by the quoted publication reference module's
     * processQuote function, if the quoted publication has a reference module set.
     * @param actionModulesInitReturnDatas The data returned from the action modules' initialization for this given
     * publication. This is ABI-encoded and depends on the action module chosen.
     * @param referenceModuleInitReturnData The data returned from the reference module at initialization. This is
     * ABI-encoded and depends on the reference module chosen.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The current block timestamp.
     */
    event QuoteCreated(
        Types.QuoteParams quoteParams,
        uint256 indexed pubId,
        bytes referenceModuleReturnData,
        bytes[] actionModulesInitReturnDatas,
        bytes referenceModuleInitReturnData,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a followNFT clone is deployed using a lazy deployment pattern.
     *
     * @param profileId The token ID of the profile to which this followNFT is associated.
     * @param followNFT The address of the newly deployed followNFT clone.
     * @param timestamp The current block timestamp.
     */
    event FollowNFTDeployed(uint256 indexed profileId, address indexed followNFT, uint256 timestamp);
    /**
     * @dev Emitted when a collectNFT clone is deployed using a lazy deployment pattern.
     *
     * @param profileId The publisher's profile token ID.
     * @param pubId The publication associated with the newly deployed collectNFT clone's ID.
     * @param collectNFT The address of the newly deployed collectNFT clone.
     * @param timestamp The current block timestamp.
     */
    event LegacyCollectNFTDeployed(
        uint256 indexed profileId,
        uint256 indexed pubId,
        address indexed collectNFT,
        uint256 timestamp
    );
    /**
     * @dev Emitted upon a successful action.
     *
     * @param publicationActionParams The parameters passed to act on a publication.
     * @param actionModuleReturnData The data returned from the action modules. This is ABI-encoded and the format
     * depends on the action module chosen.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The current block timestamp.
     */
    event Acted(
        Types.PublicationActionParams publicationActionParams,
        bytes actionModuleReturnData,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted upon a successful follow operation.
     *
     * @param followerProfileId The ID of the profile that executed the follow.
     * @param idOfProfileFollowed The ID of the profile that was followed.
     * @param followTokenIdAssigned The ID of the follow token assigned to the follower.
     * @param followModuleData The data to pass to the follow module, if any.
     * @param processFollowModuleReturnData The data returned by the followed profile follow module's processFollow
     * function, if the followed profile has a reference module set.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The timestamp of the follow operation.
     */
    event Followed(
        uint256 indexed followerProfileId,
        uint256 idOfProfileFollowed,
        uint256 followTokenIdAssigned,
        bytes followModuleData,
        bytes processFollowModuleReturnData,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted upon a successful unfollow operation.
     *
     * @param unfollowerProfileId The ID of the profile that executed the unfollow.
     * @param idOfProfileUnfollowed The ID of the profile that was unfollowed.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The timestamp of the unfollow operation.
     */
    event Unfollowed(
        uint256 indexed unfollowerProfileId,
        uint256 idOfProfileUnfollowed,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted upon a successful block, through a block status setting operation.
     *
     * @param byProfileId The ID of the profile that executed the block status change.
     * @param idOfProfileBlocked The ID of the profile whose block status have been set to blocked.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The timestamp of the block operation.
     */
    event Blocked(
        uint256 indexed byProfileId,
        uint256 idOfProfileBlocked,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted upon a successful unblock, through a block status setting operation.
     *
     * @param byProfileId The ID of the profile that executed the block status change.
     * @param idOfProfileUnblocked The ID of the profile whose block status have been set to unblocked.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The timestamp of the unblock operation.
     */
    event Unblocked(
        uint256 indexed byProfileId,
        uint256 idOfProfileUnblocked,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted via callback when a collectNFT is transferred.
     *
     * @param profileId The token ID of the profile associated with the collectNFT being transferred.
     * @param pubId The publication ID associated with the collectNFT being transferred.
     * @param collectNFTId The collectNFT being transferred's token ID.
     * @param from The address the collectNFT is being transferred from.
     * @param to The address the collectNFT is being transferred to.
     * @param timestamp The current block timestamp.
     */
    event CollectNFTTransferred(
        uint256 indexed profileId,
        uint256 indexed pubId,
        uint256 indexed collectNFTId,
        address from,
        address to,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the treasury address is set.
     *
     * @param prevTreasury The previous treasury address.
     * @param newTreasury The new treasury address set.
     * @param timestamp The current block timestamp.
     */
    event TreasurySet(address indexed prevTreasury, address indexed newTreasury, uint256 timestamp);

    /**
     * @notice Emitted when the treasury fee is set.
     *
     * @param prevTreasuryFee The previous treasury fee in BPS.
     * @param newTreasuryFee The new treasury fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event TreasuryFeeSet(uint16 indexed prevTreasuryFee, uint16 indexed newTreasuryFee, uint256 timestamp);

    /**
     * @dev Emitted when the metadata associated with a profile is set in the `LensPeriphery`.
     *
     * @param profileId The profile ID the metadata is set for.
     * @param metadata The metadata set for the profile and user.
     * @param transactionExecutor The address of the account that executed this operation.
     * @param timestamp The current block timestamp.
     */
    event ProfileMetadataSet(
        uint256 indexed profileId,
        string metadata,
        address transactionExecutor,
        uint256 timestamp
    );

    /**
     * @dev Emitted when an address' Profile Guardian state change is triggered.
     *
     * @param wallet The address whose Token Guardian state change is being triggered.
     * @param enabled True if the Token Guardian is being enabled, false if it is being disabled.
     * @param tokenGuardianDisablingTimestamp The UNIX timestamp when disabling the Token Guardian will take effect,
     * if disabling it. Zero if the protection is being enabled.
     * @param timestamp The UNIX timestamp of the change being triggered.
     */
    event TokenGuardianStateChanged(
        address indexed wallet,
        bool indexed enabled,
        uint256 tokenGuardianDisablingTimestamp,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a signer's nonce is used and, as a consequence, the next available nonce is updated.
     *
     * @param signer The signer whose next available nonce was updated.
     * @param nonce The next available nonce that can be used to execute a meta-tx successfully.
     * @param timestamp The UNIX timestamp of the nonce being used.
     */
    event NonceUpdated(address indexed signer, uint256 nonce, uint256 timestamp);

    /**
     * @dev Emitted when a collection's token URI is updated.
     * @param fromTokenId The ID of the smallest token that requires its token URI to be refreshed.
     * @param toTokenId The ID of the biggest token that requires its token URI to be refreshed. Max uint256 to refresh
     * all of them.
     */
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);
}
