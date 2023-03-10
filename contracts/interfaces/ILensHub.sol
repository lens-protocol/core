// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @title ILensHub
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract, the main entry point for the Lens Protocol.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface ILensHub {
    /**
     * @notice Initializes the LensHub NFT, setting the initial governance address as well as the name and symbol in
     * the LensNFTBase contract.
     *
     * @param name The name to set for the hub NFT.
     * @param symbol The symbol to set for the hub NFT.
     * @param newGovernance The governance address to set.
     */
    function initialize(string calldata name, string calldata symbol, address newGovernance) external;

    /**
     * @notice Sets the privileged governance role. This function can only be called by the current governance
     * address.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external;

    /**
     * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state. This function
     * can only be called by the governance address.
     *
     * @param newEmergencyAdmin The new emergency admin address to set.
     */
    function setEmergencyAdmin(address newEmergencyAdmin) external;

    /**
     * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state. This function
     * can only be called by the governance address or the emergency admin address.
     *
     * Note that this reverts if the emergency admin calls it if:
     *      1. The emergency admin is attempting to unpause.
     *      2. The emergency admin is calling while the protocol is already paused.
     *
     * @param newState The state to set, as a member of the ProtocolState enum.
     */
    function setState(Types.ProtocolState newState) external;

    /**
     * @notice Adds or removes a profile creator from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(address profileCreator, bool whitelist) external;

    /**
     * @notice Adds or removes a follow module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param followModule The follow module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the follow module should be whitelisted.
     */
    function whitelistFollowModule(address followModule, bool whitelist) external;

    /**
     * @notice Adds or removes a reference module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param referenceModule The reference module contract to add or remove from the whitelist.
     * @param whitelist Whether or not the reference module should be whitelisted.
     */
    function whitelistReferenceModule(address referenceModule, bool whitelist) external;

    /**
     * @notice Adds or removes a action module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param actionModule The action module contract address to add or remove from the whitelist.
     * @param whitelistId The whitelist ID to set for the action module (0 if not whitelisted).
     */
    function whitelistActionModuleId(address actionModule, uint256 whitelistId) external;

    /**
     * @notice Creates a profile with the specified parameters, minting a profile NFT to the given recipient. This
     * function must be called by a whitelisted profile creator.
     *
     * @param createProfileParams A CreateProfileParams struct containing the following params:
     *      to: The address receiving the profile.
     *      imageURI: The URI to set for the profile image.
     *      followModule: The follow module to use, can be the zero address.
     *      followModuleInitData: The follow module initialization data, if any.
     */
    function createProfile(Types.CreateProfileParams calldata createProfileParams) external returns (uint256);

    /**
     * @notice Sets the metadata URI for the given profile. Must be called either from the profile owner or an approved
     * delegated executor.
     *
     * @param profileId The token ID of the profile to set the metadata URI for.
     * @param metadataURI The metadata URI to set for the given profile.
     */
    function setProfileMetadataURI(uint256 profileId, string calldata metadataURI) external;

    /**
     * @notice Sets the metadata URI via signature for the given profile with the specified parameters. The signer must
     * either be the profile owner or a delegated executor.
     *
     * @param profileId The token ID of the profile to set the metadata URI for.
     * @param metadataURI The metadata URI to set for the given profile.
     * @param signature The signature for the post.
     */
    function setProfileMetadataURIWithSig(
        uint256 profileId,
        string calldata metadataURI,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Sets the follow module for the given profile. Must be called by the profile owner.
     *
     * @param profileId The token ID of the profile to set the follow module for.
     * @param followModule The follow module to set for the given profile, must be whitelisted.
     * @param followModuleInitData The data to be passed to the follow module for initialization.
     */
    function setFollowModule(uint256 profileId, address followModule, bytes calldata followModuleInitData) external;

    /**
     * @notice Sets the follow module via signature for the given profile with the specified parameters. The signer must
     * either be the profile owner or a delegated executor.
     *
     * @param profileId The token ID of the profile to set the follow module for.
     * @param followModule The follow module to set for the given profile, must be whitelisted.
     * @param followModuleInitData The data to be passed to the follow module for initialization.
     * @param signature The signature for the post.
     */
    function setFollowModuleWithSig(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Changes the delegated executors configuration for the given profile. It allows to set the approvals for
     * delegated executors in the specified configuration, as well as switching to it.
     *
     * @dev The message sender must be the owner of the delegator profile.
     *
     * @param delegatorProfileId The ID of the profile to which the delegated executor is being changed for.
     * @param delegatedExecutors The array of delegated executors to set the approval for.
     * @param approvals The array of booleans indicating the corresponding executor new approval status.
     * @param configNumber The number of the configuration where the executor approval state is being set.
     * @param switchToGivenConfig A boolean indicanting if the configuration must be switched to the one with the given
     * number.
     */
    function changeDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) external;

    /**
     * @notice Changes the delegated executors configuration for the given profile under the current configuration.
     *
     * @dev The message sender must be the owner of the delegator profile.
     *
     * @param delegatorProfileId The ID of the profile to which the delegated executor is being changed for.
     * @param delegatedExecutors The array of delegated executors to set the approval for.
     * @param approvals The array of booleans indicating the corresponding executor new approval status.
     */
    function changeCurrentDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals
    ) external;

    /**
     * @notice Changes the delegated executors configuration for the given profile. It allows to set the approvals for
     * delegated executors in the specified configuration, as well as switching to it.
     *
     * @dev The signer must be the owner of the delegator profile. The meta-tx function only exists in the flavour where
     * the `configNumber` and `switchToGivenConfig` params are required to be passed explicitly.
     *
     * @param delegatorProfileId The ID of the profile to which the delegated executor is being changed for.
     * @param delegatedExecutors The array of delegated executors to set the approval for.
     * @param approvals The array of booleans indicating the corresponding executor new approval status.
     * @param configNumber The number of the configuration where the executor approval state is being set.
     * @param switchToGivenConfig A boolean indicanting if the configuration must be switched to the one with the given
     * number.
     * @param signature The signature for the post.
     */
    function changeDelegatedExecutorsConfigWithSig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Sets a profile's image URI, which is reflected in the `tokenURI()` function.
     *
     * @param profileId The token ID of the profile of the profile to set the URI for.
     * @param imageURI The URI to set for the given profile.
     */
    function setProfileImageURI(uint256 profileId, string calldata imageURI) external;

    /**
     * @notice Sets the image URI via signature for the given profile with the specified parameters. The signer must
     * either be the profile owner or a delegated executor.
     *
     * @param profileId The token ID of the profile of the profile to set the URI for.
     * @param imageURI The URI to set for the given profile.
     * @param signature The signature for the post.
     */
    function setProfileImageURIWithSig(
        uint256 profileId,
        string calldata imageURI,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Sets a followNFT URI for a given profile's follow NFT.
     *
     * @param profileId The token ID of the profile for which to set the followNFT URI.
     * @param followNFTURI The follow NFT URI to set.
     */
    function setFollowNFTURI(uint256 profileId, string calldata followNFTURI) external;

    /**
     * @notice Sets a followNFT URI via signature for the given profile with the specified parameters. The signer must
     * either be the profile owner or a delegated executor.
     *
     * @param profileId The token ID of the profile for which to set the followNFT URI.
     * @param followNFTURI The follow NFT URI to set.
     * @param signature The signature for the post.
     */
    function setFollowNFTURIWithSig(
        uint256 profileId,
        string calldata followNFTURI,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Publishes a post to a given profile, must be called by the profile owner.
     *
     * @param postParams A PostParams struct containing the needed parameters.
     *
     * @return uint256 An integer representing the post's publication ID.
     */
    function post(Types.PostParams calldata postParams) external returns (uint256);

    /**
     * @notice Publishes a post to a given profile via signature with the specified parameters. The signer must
     * either be the profile owner or a delegated executor.
     *
     * @param postParams A PostParams struct containing the needed parameters.
     * @param signature The signature for the post.
     *
     * @return uint256 An integer representing the post's publication ID.
     */
    function postWithSig(
        Types.PostParams calldata postParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Publishes a comment to a given profile, must be called by the profile owner.
     *
     * @param commentParams A CommentParams struct containing the needed parameters.
     *
     * @return uint256 An integer representing the comment's publication ID.
     */
    function comment(Types.CommentParams calldata commentParams) external returns (uint256);

    /**
     * @notice Publishes a comment to a given profile via signature with the specified parameters. The signer must
     * either be the profile owner or a delegated executor.
     *
     * @param commentParams A CommentWithSigData struct containing the regular parameters and an EIP712Signature struct.
     * @param signature The signature for the comment.
     *
     * @return uint256 An integer representing the comment's publication ID.
     */
    function commentWithSig(
        Types.CommentParams calldata commentParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Publishes a mirror to a given profile, must be called by the profile owner.
     *
     * @param mirrorParams A MirrorParams struct containing the necessary parameters.
     *
     * @return uint256 An integer representing the mirror's publication ID.
     */
    function mirror(Types.MirrorParams calldata mirrorParams) external returns (uint256);

    /**
     * @notice Publishes a mirror to a given profile via signature with the specified parameters. The signer must
     * either be the profile owner or a delegated executor.
     *
     * @param mirrorParams A MirrorWithSigData struct containing the regular parameters and an EIP712Signature struct.
     * @param signature The signature for the mirror.
     *
     * @return uint256 An integer representing the mirror's publication ID.
     */
    function mirrorWithSig(
        Types.MirrorParams calldata mirrorParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Publishes a quote to a given profile, must be called by the profile owner.
     *
     * @param quoteParams A QuoteParams struct containing the needed parameters.
     *
     * @return uint256 An integer representing the quote's publication ID.
     */
    function quote(Types.QuoteParams calldata quoteParams) external returns (uint256);

    /**
     * @notice Publishes a quote to a given profile via signature with the specified parameters. The signer must
     * either be the profile owner or a delegated executor.
     *
     * @param quoteParams A QuoteParams struct containing the needed parameters.
     * @param signature The signature for the quote.
     *
     * @return uint256 An integer representing the quote's publication ID.
     */
    function quoteWithSig(
        Types.QuoteParams calldata quoteParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Follows the given profiles, executing each profile's follow module logic (if any).
     *
     * @dev Both the `idsOfProfilesToFollow`, `followTokenIds`, and `datas` arrays must be of the same length,
     * regardless if the profiles do not have a follow module set.
     *
     * @param followerProfileId The ID of the profile the follows are being executed for.
     * @param idsOfProfilesToFollow The array of IDs of profiles to follow.
     * @param followTokenIds The array of follow token IDs to use for each follow.
     * @param datas The arbitrary data array to pass to the follow module for each profile if needed.
     *
     * @return uint256[] An array follow token IDs used for each follow operation.
     */
    function follow(
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata datas
    ) external returns (uint256[] memory);

    /**
     * @notice Follows the given profiles via signature with the specified parameters. The signer must either be the
     * follower or a delegated executor.
     *
     * @param followerProfileId The ID of the profile the follows are being executed for.
     * @param idsOfProfilesToFollow The array of IDs of profiles to follow.
     * @param followTokenIds The array of follow token IDs to use for each follow.
     * @param datas The arbitrary data array to pass to the follow module for each profile if needed.
     * @param signature The signature for the post.
     *
     * @return uint256[] An array follow token IDs used for each follow operation.
     */
    function followWithSig(
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata datas,
        Types.EIP712Signature calldata signature
    ) external returns (uint256[] memory);

    /**
     * @notice Unfollows the given profiles.
     *
     * @param unfollowerProfileId The ID of the profile the unfollows are being executed for.
     * @param idsOfProfilesToUnfollow The array of IDs of profiles to unfollow.
     */
    function unfollow(uint256 unfollowerProfileId, uint256[] calldata idsOfProfilesToUnfollow) external;

    /**
     * @notice Unfollows the given profiles via signature with the specified parameters. The signer must either be the
     * unfollower or a delegated executor.
     *
     * @param unfollowerProfileId The ID of the profile the unfollows are being executed for.
     * @param idsOfProfilesToUnfollow The array of IDs of profiles to unfollow.
     * @param signature The signature for the post.
     */
    function unfollowWithSig(
        uint256 unfollowerProfileId,
        uint256[] calldata idsOfProfilesToUnfollow,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Sets the block status for the given profiles. Changing a profile's block status to `true` (i.e. blocked),
     * when it was following, will make it unfollow.
     *
     * @dev Both the `idsOfProfilesToSetBlockStatus` and `blockStatus` arrays must be of the same length.
     *
     * @param byProfileId The ID of the profile the block status sets are being executed for.
     * @param idsOfProfilesToSetBlockStatus The array of IDs of profiles to set block status.
     * @param blockStatus The array of block status to use for each setting.
     */
    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) external;

    /**
     * @notice Blocks the given profiles via signature with the specified parameters. The signer must either be the
     * blocker or a delegated executor.
     *
     * @dev Both the `idsOfProfilesToSetBlockStatus` and `blockStatus` arrays must be of the same length.
     *
     * @param byProfileId The ID of the profile the block status sets are being executed for.
     * @param idsOfProfilesToSetBlockStatus The array of IDs of profiles to set block status.
     * @param blockStatus The array of block status to use for each setting.
     * @param signature The signature for the post.
     */
    function setBlockStatusWithSig(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Collects a given publication via signature with the specified parameters. The caller must either be the collector
     * or a delegated executor.
     *
     * @param collectParams A CollectParams struct containing the parameters.
     *
     * @return uint256 An integer representing the minted token ID.
     */
    function collect(Types.CollectParams calldata collectParams) external returns (uint256);

    /**
     * @notice Collects a given publication via signature with the specified parameters. The signer must either be the collector
     * or a delegated executor.
     *
     * @param collectParams A CollectParams struct containing the parameters.
     * @param signature The signature for the collect.
     *
     * @return uint256 An integer representing the minted token ID.
     */
    function collectWithSig(
        Types.CollectParams calldata collectParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Acts on a given publication with the specified parameters. The caller must either be the profile owner
     * or a delegated executor.
     *
     * @param publicationActionParams A PublicationActionParams struct containing the parameters.
     *
     * @return bytes Arbitrary data the action module returns.
     */
    function act(Types.PublicationActionParams calldata publicationActionParams) external returns (bytes memory);

    /**
     * @notice Acts on a given publication via signature with the specified parameters. The signer must either be the profile owner
     * or a delegated executor.
     *
     * @param publicationActionParams A PublicationActionParams struct containing the parameters.
     * @param signature The signature for the collect.
     *
     * @return bytes Arbitrary data the action module returns.
     */
    function actWithSig(
        Types.PublicationActionParams calldata publicationActionParams,
        Types.EIP712Signature calldata signature
    ) external returns (bytes memory);

    /**
     * @dev Helper function to emit an `Unfollowed` event from the hub, to be consumed by indexers to track unfollows.
     *
     * @param unfollowerProfileId The ID of the profile that executed the unfollow.
     * @param idOfProfileUnfollowed The ID of the profile that was unfollowed.
     */
    function emitUnfollowedEvent(uint256 unfollowerProfileId, uint256 idOfProfileUnfollowed) external;

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns whether  or not `followerProfileId` is following `followedProfileId`.
     *
     * @param followerProfileId The ID of the profile whose following state should be queried.
     * @param followedProfileId The ID of the profile whose followed state should be queried.
     *
     * @return bool True if `followerProfileId` is following `followedProfileId`, false otherwise.
     */
    function isFollowing(uint256 followerProfileId, uint256 followedProfileId) external view returns (bool);

    /**
     * @notice Returns whether or not a profile creator is whitelisted.
     *
     * @param profileCreator The address of the profile creator to check.
     *
     * @return bool True if the profile creator is whitelisted, false otherwise.
     */
    function isProfileCreatorWhitelisted(address profileCreator) external view returns (bool);

    /**
     * @notice Returns whether or not a follow module is whitelisted.
     *
     * @param followModule The address of the follow module to check.
     *
     * @return bool True if the the follow module is whitelisted, false otherwise.
     */
    function isFollowModuleWhitelisted(address followModule) external view returns (bool);

    /**
     * @notice Returns whether or not a reference module is whitelisted.
     *
     * @param referenceModule The address of the reference module to check.
     *
     * @return bool True if the the reference module is whitelisted, false otherwise.
     */
    function isReferenceModuleWhitelisted(address referenceModule) external view returns (bool);

    /**
     * @notice Returns whether or not a action module is whitelisted.
     *
     * @param actionModule The address of the action module to check.
     *
     * @return bool True if the the action module is whitelisted, false otherwise.
     */
    function isActionModuleWhitelisted(address actionModule) external view returns (bool);

    /**
     * @notice Returns the currently configured governance address.
     *
     * @return address The address of the currently configured governance.
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Returns whether the given address is approved as delegated executor, in the configuration with the given
     * number, to act on behalf of the given profile.
     *
     * @param delegatorProfileId The ID of the profile to check the delegated executor approval for.
     * @param delegatedExecutor The address to query the delegated executor approval for.
     * @param configNumber The number of the configuration where the executor approval state is being queried.
     *
     * @return bool True if the address is approved as a delegated executor to act on behalf of the profile in the
     * given configuration, false otherwise.
     */
    function isDelegatedExecutorApproved(
        uint256 delegatorProfileId,
        address delegatedExecutor,
        uint64 configNumber
    ) external view returns (bool);

    /**
     * @notice Returns whether the given address is approved as delegated executor, in the current configuration, to act
     * on behalf of the given profile.
     *
     * @param delegatorProfileId The ID of the profile to check the delegated executor approval for.
     * @param delegatedExecutor The address to query the delegated executor approval for.
     *
     * @return bool True if the address is approved as a delegated executor to act on behalf of the profile in the
     * current configuration, false otherwise.
     */
    function isDelegatedExecutorApproved(
        uint256 delegatorProfileId,
        address delegatedExecutor
    ) external view returns (bool);

    /**
     * @param delegatorProfileId The ID of the profile from which the delegated executors configuration number is being
     * queried.
     *
     * @return uint256 The current delegated executor configuration number.
     */
    function getDelegatedExecutorsConfigNumber(uint256 delegatorProfileId) external view returns (uint64);

    /**
     * @param delegatorProfileId The ID of the profile from which the delegated executors previous configuration number
     * set is being queried.
     *
     * @return uint256 The delegated executor configuration number previously set. It will coincide with the current
     * configuration set if it was never switched from the default one.
     */
    function getDelegatedExecutorsPrevConfigNumber(uint256 delegatorProfileId) external view returns (uint64);

    /**
     * @param delegatorProfileId The ID of the profile from which the delegated executors maximum configuration number
     * set is being queried.
     *
     * @return uint256 The delegated executor maximum configuration number set.
     */
    function getDelegatedExecutorsMaxConfigNumberSet(uint256 delegatorProfileId) external view returns (uint64);

    /**
     * @notice Returns whether `profile` is blocked by `byProfile`.
     *
     * @param profileId The ID of the profile whose blocked status should be queried.
     * @param byProfileId The ID of the profile whose blocker status should be queried.
     *
     * @return bool True if `profileId` is blocked by `byProfileId`, false otherwise.
     */
    function isBlocked(uint256 profileId, uint256 byProfileId) external view returns (bool);

    /**
     * @notice Returns the metadata URI for a given profile
     *
     * @param profileId The token ID of the profile to query the metadata URI for.
     *
     * @return string The metadata URI associated with the given profile.
     */
    function getProfileMetadataURI(uint256 profileId) external view returns (string memory);

    /**
     * @notice Returns the publication count for a given profile.
     *
     * @param profileId The token ID of the profile to query the publication count for.
     *
     * @return uint256 The number of publications associated with the given profile.
     */
    function getPubCount(uint256 profileId) external view returns (uint256);

    /**
     * @notice Returns the image URI for a given profile
     *
     * @param profileId The token ID of the profile to query the image URI for.
     *
     * @return string The image URI associated with the given profile.
     */
    function getProfileImageURI(uint256 profileId) external view returns (string memory);

    /**
     * @notice Returns the followNFT associated with a given profile, if any.
     *
     * @param profileId The token ID of the profile to query the followNFT for.
     *
     * @return address The followNFT associated with the given profile.
     */
    function getFollowNFT(uint256 profileId) external view returns (address);

    /**
     * @notice Returns the followNFT URI associated with a given profile.
     *
     * @param profileId The token ID of the profile to query the followNFT URI for.
     *
     * @return string The followNFT URI associated with the given profile.
     */
    function getFollowNFTURI(uint256 profileId) external view returns (string memory);

    /**
     * @notice Returns the collectNFT associated with a given publication, if any.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return address The address of the collectNFT associated with the given publication.
     */
    function getCollectNFT(uint256 profileId, uint256 pubId) external view returns (address);

    /**
     * @notice Returns the follow module associated witha  given profile, if any.
     *
     * @param profileId The token ID of the profile to query the follow module for.
     *
     * @return address The address of the follow module associated with the given profile.
     */
    function getFollowModule(uint256 profileId) external view returns (address);

    /**
     * @notice Returns the collect module associated with a given publication.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return address The address of the collect module associated with the queried publication.
     */
    function getCollectModule(uint256 profileId, uint256 pubId) external view returns (address);

    /**
     * @notice Returns the reference module associated witha  given profile, if any.
     *
     * @param profileId The token ID of the profile that published the publication to querythe reference module for.
     * @param pubId The publication ID of the publication to query the reference module for.
     *
     * @return address The address of the reference module associated with the given profile.
     */
    function getReferenceModule(uint256 profileId, uint256 pubId) external view returns (address);

    /**
     * @notice Returns the publication pointer (profileId & pubId) associated with a given publication.
     *
     * @param profileId The token ID of the profile that published the publication to query the pointer for.
     * @param pubId The publication ID of the publication to query the pointer for.
     *
     * @return tuple First, the profile ID of the profile the current publication is pointing to, second, the
     * publication ID of the publication the current publication is pointing to.
     */
    function getPubPointer(uint256 profileId, uint256 pubId) external view returns (uint256, uint256);

    /**
     * @notice Returns the URI associated with a given publication.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return string The URI associated with a given publication.
     */
    function getContentURI(uint256 profileId, uint256 pubId) external view returns (string memory);

    /**
     * @notice Returns the full profile struct associated with a given profile token ID.
     *
     * @param profileId The token ID of the profile to query.
     *
     * @return Profile The profile struct of the given profile.
     */
    function getProfile(uint256 profileId) external view returns (Types.Profile memory);

    /**
     * @notice Returns the full publication struct for a given publication.
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return Publication The publication struct associated with the queried publication.
     */
    function getPub(uint256 profileId, uint256 pubId) external view returns (Types.Publication memory);

    function getPublicationType(uint256 profileId, uint256 pubId) external view returns (Types.PublicationType);

    /**
     * @notice Returns the follow NFT implementation address.
     *
     * @return address The follow NFT implementation address.
     */
    function getFollowNFTImpl() external view returns (address);

    /**
     * @notice Returns the collect NFT implementation address.
     *
     * @return address The collect NFT implementation address.
     */
    function getCollectNFTImpl() external view returns (address);
}
