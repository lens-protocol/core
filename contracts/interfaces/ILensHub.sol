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
     * @notice Initializes the LensHub, setting the initial governance address, the name and symbol of the profiles
     * in the LensNFTBase contract, and Protocol State (Paused).
     * @custom:permissions Anyone. This is expected to be called using upgradeAndCall() and is only callable once.
     *
     * @param name The name of the Profile NFT.
     * @param symbol The symbol of the Profile NFT.
     * @param newGovernance The governance address to set.
     */
    function initialize(string calldata name, string calldata symbol, address newGovernance) external;

    /**
     * @notice Sets the privileged governance role.
     * @custom:permissions Governance.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external;

    /**
     * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state.
     * @custom:permissions Governance.
     *
     * @param newEmergencyAdmin The new emergency admin address to set.
     */
    function setEmergencyAdmin(address newEmergencyAdmin) external;

    /**
     * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state.
     * @custom:permissions Governance or Emergency Admin. Emergency Admin can only restrict more.
     *
     * @param newState The state to set (from ProtocolState enum).
     */
    function setState(Types.ProtocolState newState) external;

    /**
     * @notice Adds or removes a profile creator from the whitelist.
     * @custom:permissions Governance.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(address profileCreator, bool whitelist) external;

    /**
     * @notice Adds or removes a follow module from the whitelist.
     * @custom:permissions Governance.
     *
     * @param followModule The follow module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the follow module should be whitelisted.
     */
    function whitelistFollowModule(address followModule, bool whitelist) external;

    /**
     * @notice Adds or removes a reference module from the whitelist.
     * @custom:permissions Governance.
     *
     * @param referenceModule The reference module contract to add or remove from the whitelist.
     * @param whitelist Whether or not the reference module should be whitelisted.
     */
    function whitelistReferenceModule(address referenceModule, bool whitelist) external;

    /**
     * @notice Adds or removes an action module from the whitelist. This function can only be called by the current
     * governance address.
     * @custom:permissions Governance.
     *
     * @param actionModule The action module contract address to add or remove from the whitelist.
     * @param whitelist True if the action module should be whitelisted, false if it should be unwhitelisted.
     */
    function whitelistActionModule(address actionModule, bool whitelist) external;

    /**
     * @notice Creates a profile with the specified parameters, minting a Profile NFT to the given recipient.
     * @custom:permissions Any whitelisted profile creator.
     *
     * @param createProfileParams A CreateProfileParams struct containing the needed params.
     */
    function createProfile(Types.CreateProfileParams calldata createProfileParams) external returns (uint256);

    /**
     * @notice Sets the metadata URI for the given profile.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param profileId The token ID of the profile to set the metadata URI for.
     * @param metadataURI The metadata URI to set for the given profile.
     */
    function setProfileMetadataURI(uint256 profileId, string calldata metadataURI) external;

    /**
     * @custom:meta-tx setProfileMetadataURI.
     */
    function setProfileMetadataURIWithSig(
        uint256 profileId,
        string calldata metadataURI,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Sets the follow module for the given profile.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param profileId The token ID of the profile to set the follow module for.
     * @param followModule The follow module to set for the given profile, must be whitelisted.
     * @param followModuleInitData The data to be passed to the follow module for initialization.
     */
    function setFollowModule(uint256 profileId, address followModule, bytes calldata followModuleInitData) external;

    /**
     * @custom:meta-tx setFollowModule.
     */
    function setFollowModuleWithSig(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Changes the delegated executors configuration for the given profile. It allows setting the approvals for
     * delegated executors in the specified configuration, as well as switching to it.
     * @custom:permissions Profile Owner.
     *
     * @param delegatorProfileId The ID of the profile to which the delegated executor is being changed for.
     * @param delegatedExecutors The array of delegated executors to set the approval for.
     * @param approvals The array of booleans indicating the corresponding executor's new approval status.
     * @param configNumber The number of the configuration where the executor approval state is being set.
     * @param switchToGivenConfig A boolean indicating if the configuration must be switched to the one with the given
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
     * @custom:permissions Profile Owner.
     *
     * @param delegatorProfileId The ID of the profile to which the delegated executor is being changed for.
     * @param delegatedExecutors The array of delegated executors to set the approval for.
     * @param approvals The array of booleans indicating the corresponding executor's new approval status.
     */
    function changeCurrentDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals
    ) external;

    /**
     * @custom:meta-tx changeDelegatedExecutorsConfig.
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
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param profileId The token ID of the profile to set the URI for.
     * @param imageURI The URI to set for the given profile.
     */
    function setProfileImageURI(uint256 profileId, string calldata imageURI) external;

    /**
     * @custom:meta-tx setProfileImageURI.
     */
    function setProfileImageURIWithSig(
        uint256 profileId,
        string calldata imageURI,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Publishes a post.
     * Post is the most basic publication type, and can be used to publish any kind of content.
     * Posts can have these types of modules initialized:
     *  - Action modules: any number of publication actions (e.g. collect, tip, etc.)
     *  - Reference module: a module handling the rules when referencing this post (e.g. token-gated comments)
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param postParams A PostParams struct containing the needed parameters.
     *
     * @return uint256 An integer representing the post's publication ID.
     */
    function post(Types.PostParams calldata postParams) external returns (uint256);

    /**
     * @custom:meta-tx post.
     */
    function postWithSig(
        Types.PostParams calldata postParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Publishes a comment on the given publication.
     * Comment is a type of reference publication that points to another publication.
     * Comments can have these types of modules initialized:
     *  - Action modules: any number of publication actions (e.g. collect, tip, etc.)
     *  - Reference module: a module handling the rules when referencing this comment (e.g. token-gated mirrors)
     * Comments can have referrers (e.g. publications or profiles that allowed to discover the pointed publication).
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param commentParams A CommentParams struct containing the needed parameters.
     *
     * @return uint256 An integer representing the comment's publication ID.
     */
    function comment(Types.CommentParams calldata commentParams) external returns (uint256);

    /**
     * @custom:meta-tx comment.
     */
    function commentWithSig(
        Types.CommentParams calldata commentParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Publishes a mirror of the given publication.
     * Mirror is a type of reference publication that points to another publication but doesn't have content.
     * Mirrors don't have any modules initialized.
     * Mirrors can have referrers (e.g. publications or profiles that allowed to discover the pointed publication).
     * You cannot mirror a mirror, comment on a mirror, or quote a mirror.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param mirrorParams A MirrorParams struct containing the necessary parameters.
     *
     * @return uint256 An integer representing the mirror's publication ID.
     */
    function mirror(Types.MirrorParams calldata mirrorParams) external returns (uint256);

    /**
     * @custom:meta-tx mirror.
     */
    function mirrorWithSig(
        Types.MirrorParams calldata mirrorParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Publishes a quote of the given publication.
     * Quote is a type of reference publication similar to mirror, but it has content and modules.
     * Quotes can have these types of modules initialized:
     *  - Action modules: any number of publication actions (e.g. collect, tip, etc.)
     *  - Reference module: a module handling the rules when referencing this quote (e.g. token-gated comments on quote)
     * Quotes can have referrers (e.g. publications or profiles that allowed to discover the pointed publication).
     * Unlike mirrors, you can mirror a quote, comment on a quote, or quote a quote.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param quoteParams A QuoteParams struct containing the needed parameters.
     *
     * @return uint256 An integer representing the quote's publication ID.
     */
    function quote(Types.QuoteParams calldata quoteParams) external returns (uint256);

    /**
     * @custom:meta-tx quote.
     */
    function quoteWithSig(
        Types.QuoteParams calldata quoteParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Follows given profiles, executing each profile's follow module logic (if any).
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @dev Both the `idsOfProfilesToFollow`, `followTokenIds`, and `datas` arrays must be of the same length,
     * regardless if the profiles do not have a follow module set.
     *
     * @param followerProfileId The ID of the profile the follows are being executed for.
     * @param idsOfProfilesToFollow The array of IDs of profiles to follow.
     * @param followTokenIds The array of follow token IDs to use for each follow (0 if you don't own a follow token).
     * @param datas The arbitrary data array to pass to the follow module for each profile if needed.
     *
     * @return uint256[] An array of follow token IDs representing the follow tokens created for each follow.
     */
    function follow(
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata datas
    ) external returns (uint256[] memory);

    /**
     * @custom:meta-tx follow.
     */
    function followWithSig(
        uint256 followerProfileId,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata datas,
        Types.EIP712Signature calldata signature
    ) external returns (uint256[] memory);

    /**
     * @notice Unfollows given profiles.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @param unfollowerProfileId The ID of the profile the unfollows are being executed for.
     * @param idsOfProfilesToUnfollow The array of IDs of profiles to unfollow.
     */
    function unfollow(uint256 unfollowerProfileId, uint256[] calldata idsOfProfilesToUnfollow) external;

    /**
     * @custom:meta-tx unfollow.
     */
    function unfollowWithSig(
        uint256 unfollowerProfileId,
        uint256[] calldata idsOfProfilesToUnfollow,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Sets the block status for the given profiles. Changing a profile's block status to `true` (i.e. blocked),
     * when will also force them to unfollow.
     * Blocked profiles cannot perform any actions with the profile that blocked them: they cannot comment or mirror
     * their publications, they cannot follow them, they cannot collect, tip them, etc.
     * @custom:permissions Profile Owner or Delegated Executor.
     *
     * @dev Both the `idsOfProfilesToSetBlockStatus` and `blockStatus` arrays must be of the same length.
     *
     * @param byProfileId The ID of the profile that is blocking/unblocking somebody.
     * @param idsOfProfilesToSetBlockStatus The array of IDs of profiles to set block status.
     * @param blockStatus The array of block statuses to use for each (true is blocked).
     */
    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) external;

    /**
     * @custom:meta-tx setBlockStatus.
     */
    function setBlockStatusWithSig(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus,
        Types.EIP712Signature calldata signature
    ) external;

    /**
     * @notice Collects a given publication via signature with the specified parameters.
     * Collect can have referrers (e.g. publications or profiles that allowed to discover the pointed publication).
     * @custom:permissions Collector Profile Owner or its Delegated Executor.
     * @custom:pending-deprecation Collect modules were replaced by PublicationAction Collect modules in V2. This method
     * is left here for backwards compatibility with posts made in V1 that had Collect modules.
     *
     * @param collectParams A CollectParams struct containing the parameters.
     *
     * @return uint256 An integer representing the minted token ID.
     */
    function collect(Types.CollectParams calldata collectParams) external returns (uint256);

    /**
     * @custom:meta-tx collect.
     * @custom:pending-deprecation
     */
    function collectWithSig(
        Types.CollectParams calldata collectParams,
        Types.EIP712Signature calldata signature
    ) external returns (uint256);

    /**
     * @notice Acts on a given publication with the specified parameters.
     * You can act on a publication except a mirror (if it has at least one action module initialized).
     * Actions can have referrers (e.g. publications or profiles that allowed to discover the pointed publication).
     * @custom:permissions Actor Profile Owner or its Delegated Executor.
     *
     * @param publicationActionParams A PublicationActionParams struct containing the parameters.
     *
     * @return bytes Arbitrary data the action module returns.
     */
    function act(Types.PublicationActionParams calldata publicationActionParams) external returns (bytes memory);

    /**
     * @custom:meta-tx act.
     */
    function actWithSig(
        Types.PublicationActionParams calldata publicationActionParams,
        Types.EIP712Signature calldata signature
    ) external returns (bytes memory);

    /**
     * @dev Helper function to emit an `Unfollowed` event from the hub, to be consumed by indexers to track unfollows.
     * @custom:permissions FollowNFT of the Profile unfollowed.
     *
     * @param unfollowerProfileId The ID of the profile that executed the unfollow.
     * @param idOfProfileUnfollowed The ID of the profile that was unfollowed.
     */
    function emitUnfollowedEvent(uint256 unfollowerProfileId, uint256 idOfProfileUnfollowed) external;

    /////////////////////////////////
    ///       VIEW FUNCTIONS      ///
    /////////////////////////////////

    /**
     * @notice Returns whether or not `followerProfileId` is following `followedProfileId`.
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
     * @return bool True if the follow module is whitelisted, false otherwise.
     */
    function isFollowModuleWhitelisted(address followModule) external view returns (bool);

    /**
     * @notice Returns whether or not a reference module is whitelisted.
     *
     * @param referenceModule The address of the reference module to check.
     *
     * @return bool True if the reference module is whitelisted, false otherwise.
     */
    function isReferenceModuleWhitelisted(address referenceModule) external view returns (bool);

    /**
     * @notice Returns whether or not an action module is whitelisted, and its ID assigned.
     * @dev If the ID is zero, it means the module has never been whitelisted, so no ID assigned to it yet.
     *
     * @param actionModule The address of the action module to get whitelist data of.
     *
     * @return ActionModuleWhitelistData The data containing the ID and whitelist status of the given module.
     */
    function getActionModuleWhitelistData(
        address actionModule
    ) external view returns (Types.ActionModuleWhitelistData memory);

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
     * @notice Returns the current delegated executor config number for the given profile.
     *
     * @param delegatorProfileId The ID of the profile from which the delegated executors config number is being queried
     *
     * @return uint256 The current delegated executor configuration number.
     */
    function getDelegatedExecutorsConfigNumber(uint256 delegatorProfileId) external view returns (uint64);

    /**
     * @notice Returns the previous used delegated executor config number for the given profile.
     *
     * @param delegatorProfileId The ID of the profile from which the delegated executors' previous configuration number
     * set is being queried.
     *
     * @return uint256 The delegated executor configuration number previously set. It will coincide with the current
     * configuration set if it was never switched from the default one.
     */
    function getDelegatedExecutorsPrevConfigNumber(uint256 delegatorProfileId) external view returns (uint64);

    /**
     * @notice Returns the maximum delegated executor config number for the given profile.
     * This is the maximum config number that was ever used by this profile.
     * When creating a new clean configuration, you can only use a number that is maxConfigNumber + 1.
     *
     * @param delegatorProfileId The ID of the profile from which the delegated executors' maximum configuration number
     * set is being queried.
     *
     * @return uint256 The delegated executor maximum configuration number set.
     */
    function getDelegatedExecutorsMaxConfigNumberSet(uint256 delegatorProfileId) external view returns (uint64);

    /**
     * @notice Returns whether `profileId` is blocked by `byProfileId`.
     * See setBlockStatus() for more information on how blocking works on the platform.
     *
     * @param profileId The ID of the profile whose blocked status should be queried.
     * @param byProfileId The ID of the profile whose blocker status should be queried.
     *
     * @return bool True if `profileId` is blocked by `byProfileId`, false otherwise.
     */
    function isBlocked(uint256 profileId, uint256 byProfileId) external view returns (bool);

    /**
     * @notice Returns the metadata URI for a given profile
     * MetadataURI is used to store the profile's metadata, for example: displayed name, description, interests, etc.
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
     * @notice Returns the address of the Follow NFT collection associated with a given profile.
     * @dev It can return address(0) if the profile has not been followed yet, as the collection is lazy-deployed upon
     * the first follow.
     *
     * @param profileId The token ID of the profile to query the Follow NFT for.
     *
     * @return address The Follow NFT associated with the given profile.
     */
    function getFollowNFT(uint256 profileId) external view returns (address);

    /**
     * @notice Returns the collectNFT associated with a given publication, if any.
     * @custom:pending-deprecation
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return address The address of the collectNFT associated with the given publication.
     */
    function getCollectNFT(uint256 profileId, uint256 pubId) external view returns (address);

    /**
     * @notice Returns the follow module associated with a given profile.
     * Returns address(0) if none.
     *
     * @param profileId The token ID of the profile to query the follow module for.
     *
     * @return address The address of the follow module associated with the given profile.
     */
    function getFollowModule(uint256 profileId) external view returns (address);

    /**
     * @notice Returns the collect module associated with a given publication.
     * @custom:pending-deprecation
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return address The address of the collect module associated with the queried publication.
     */
    function getCollectModule(uint256 profileId, uint256 pubId) external view returns (address);

    /**
     * @notice Returns the reference module associated with a given profile, if any.
     *
     * @param profileId The token ID of the profile that published the publication to query the reference module for.
     * @param pubId The publication ID of the publication to query the reference module for.
     *
     * @return address The address of the reference module associated with the given profile.
     */
    function getReferenceModule(uint256 profileId, uint256 pubId) external view returns (address);

    /**
     * @notice Returns the action modules associated with a given publication in a bitmap.
     * The bitmap is a uint256 where each bit represents an action module: 1 if the publication uses it, and 0 if not.
     * You can use getActionModuleById() to get the address of the action module associated with a given bit.
     *
     *
     * In the future this can be replaced with a getter that allows to query the bitmap by index, if there are more than
     * 256 action modules.
     *
     * @param profileId The ID of the profile that published the publication to query the action modules for.
     * @param pubId The publication ID of the publication to query the action modules for.
     *
     * @return uint256 The bitmap that represents the action modules associated with the given publication.
     */
    function getActionModulesBitmap(uint256 profileId, uint256 pubId) external view returns (uint256);

    /**
     * @notice Returns the address of the action module associated with the given whitelist ID, address(0) if none.
     *
     * @param id The ID of the module whose address wants to be queried.
     *
     * @return address The address of the action module associated with the given ID.
     */
    function getActionModuleById(uint256 id) external view returns (address);

    /**
     * @notice Returns the publication (profileId & pubId) that a given publication is pointing to.
     * This is used to implement the "reference" feature of the platform and is used in:
     * - Mirrors
     * - Comments
     * - Quotes
     * Returns (0,0) if the publication is not pointing to any other publication (i.e. the publication is a Post).
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
     * This is used to store the publication's metadata, e.g.: content, images, etc.
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

    /**
     * @notice Returns the type of a given publication.
     * The type can be one of the following (see PublicationType enum):
     * - Nonexistent
     * - Post
     * - Comment
     * - Mirror
     * - Quote
     *
     * @param profileId The token ID of the profile that published the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return PublicationType The publication type of the queried publication.
     */
    function getPublicationType(uint256 profileId, uint256 pubId) external view returns (Types.PublicationType);

    /**
     * @notice Returns the Follow NFT implementation address that is used across the hub to deploy Follow NFTs.
     *
     * @return address The Follow NFT implementation address.
     */
    function getFollowNFTImpl() external view returns (address);

    /**
     * @notice Returns the Collect NFT implementation address.
     * @custom:pending-deprecation
     *
     * @return address The Collect NFT implementation address.
     */
    function getCollectNFTImpl() external view returns (address);
}
