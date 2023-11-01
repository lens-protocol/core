// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title Types
 * @author Lens Protocol
 *
 * @notice A standard library of data types used throughout the Lens Protocol.
 */
library Types {
    /**
     * @notice ERC721Timestamped storage. Contains the owner address and the mint timestamp for every NFT.
     *
     * Note: Instead of the owner address in the _tokenOwners private mapping, we now store it in the
     * _tokenData mapping, alongside the mint timestamp.
     *
     * @param owner The token owner.
     * @param mintTimestamp The mint timestamp.
     */
    struct TokenData {
        address owner;
        uint96 mintTimestamp;
    }

    /**
     * @notice A struct containing token follow-related data.
     *
     * @param followerProfileId The ID of the profile using the token to follow.
     * @param originalFollowTimestamp The timestamp of the first follow performed with the token.
     * @param followTimestamp The timestamp of the current follow, if a profile is using the token to follow.
     * @param profileIdAllowedToRecover The ID of the profile allowed to recover the follow ID, if any.
     */
    struct FollowData {
        uint160 followerProfileId;
        uint48 originalFollowTimestamp;
        uint48 followTimestamp;
        uint256 profileIdAllowedToRecover;
    }

    /**
     * @notice An enum containing the different states the protocol can be in, limiting certain actions.
     *
     * @param Unpaused The fully unpaused state.
     * @param PublishingPaused The state where only publication creation functions are paused.
     * @param Paused The fully paused state.
     */
    enum ProtocolState {
        Unpaused,
        PublishingPaused,
        Paused
    }

    /**
     * @notice An enum specifically used in a helper function to easily retrieve the publication type for integrations.
     *
     * @param Nonexistent An indicator showing the queried publication does not exist.
     * @param Post A standard post, having an URI, action modules and no pointer to another publication.
     * @param Comment A comment, having an URI, action modules and a pointer to another publication.
     * @param Mirror A mirror, having a pointer to another publication, but no URI or action modules.
     * @param Quote A quote, having an URI, action modules, and a pointer to another publication.
     */
    enum PublicationType {
        Nonexistent,
        Post,
        Comment,
        Mirror,
        Quote
    }

    /**
     * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
     *
     * @param signer The address of the signer. Specially needed as a parameter to support EIP-1271.
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter.
     * @param deadline The signature's deadline.
     */
    struct EIP712Signature {
        address signer;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    /**
     * @notice A struct containing profile data.
     *
     * @param pubCount The number of publications made to this profile.
     * @param followModule The address of the current follow module in use by this profile, can be address(0) in none.
     * @param followNFT The address of the followNFT associated with this profile. It can be address(0) if the
     * profile has not been followed yet, as the collection is lazy-deployed upon the first follow.
     * @param __DEPRECATED__handle DEPRECATED in V2: handle slot, was replaced with LensHandles.
     * @param __DEPRECATED__imageURI DEPRECATED in V2: The URI to be used for the profile image.
     * @param __DEPRECATED__followNFTURI DEPRECATED in V2: The URI used for the follow NFT image.
     * @param metadataURI MetadataURI is used to store the profile's metadata, for example: displayed name, description,
     * interests, etc.
     */
    struct Profile {
        uint256 pubCount; // offset 0
        address followModule; // offset 1
        address followNFT; // offset 2
        string __DEPRECATED__handle; // offset 3
        string __DEPRECATED__imageURI; // offset 4
        string __DEPRECATED__followNFTURI; // Deprecated in V2 as we have a common tokenURI for all Follows, offset 5
        string metadataURI; // offset 6
    }

    /**
     * @notice A struct containing publication data.
     *
     * @param pointedProfileId The profile token ID to point the publication to.
     * @param pointedPubId The publication ID to point the publication to.
     * These are used to implement the "reference" feature of the platform and is used in:
     * - Mirrors
     * - Comments
     * - Quotes
     * There are (0,0) if the publication is not pointing to any other publication (i.e. the publication is a Post).
     * @param contentURI The URI to set for the content of publication (can be ipfs, arweave, http, etc).
     * @param referenceModule Reference module associated with this profile, if any.
     * @param __DEPRECATED__collectModule Collect module associated with this publication, if any. Deprecated in V2.
     * @param __DEPRECATED__collectNFT Collect NFT associated with this publication, if any. Deprecated in V2.
     * @param pubType The type of publication, can be Nonexistent, Post, Comment, Mirror or Quote.
     * @param rootProfileId The profile ID of the root post (to determine if comments/quotes and mirrors come from it).
     * Posts, V1 publications and publications rooted in V1 publications don't have it set.
     * @param rootPubId The publication ID of the root post (to determine if comments/quotes and mirrors come from it).
     * Posts, V1 publications and publications rooted in V1 publications don't have it set.
     * @param actionModuleEnabled The action modules enabled in a given publication.
     */
    struct Publication {
        uint256 pointedProfileId;
        uint256 pointedPubId;
        string contentURI;
        address referenceModule;
        address __DEPRECATED__collectModule; // Deprecated in V2
        address __DEPRECATED__collectNFT; // Deprecated in V2
        // Added in Lens V2, so these will be zero for old publications:
        PublicationType pubType;
        uint256 rootProfileId;
        uint256 rootPubId;
        mapping(address => bool) actionModuleEnabled;
    }

    struct PublicationMemory {
        uint256 pointedProfileId;
        uint256 pointedPubId;
        string contentURI;
        address referenceModule;
        address __DEPRECATED__collectModule; // Deprecated in V2
        address __DEPRECATED__collectNFT; // Deprecated in V2
        // Added in Lens V2, so these will be zero for old publications:
        PublicationType pubType;
        uint256 rootProfileId;
        uint256 rootPubId;
        // bytes32 __ACTION_MODULE_ENABLED_MAPPING; // Mappings are not supported in memory.
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` function.
     *
     * @param to The address receiving the profile.
     * @param followModule The follow module to use, can be the zero address.
     * @param followModuleInitData The follow module initialization data, if any.
     */
    struct CreateProfileParams {
        address to;
        address followModule;
        bytes followModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `post()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param actionModules The action modules to set for this new publication.
     * @param actionModulesInitDatas The data to pass to the action modules' initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct PostParams {
        uint256 profileId;
        string contentURI;
        address[] actionModules;
        bytes[] actionModulesInitDatas;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `comment()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param pointedProfileId The profile token ID to point the comment to.
     * @param pointedPubId The publication ID to point the comment to.
     * @param referrerProfileId The profile token ID of the publication that referred to the publication being commented on/quoted.
     * @param referrerPubId The ID of the publication that referred to the publication being commented on/quoted.
     * @param referenceModuleData The data passed to the reference module.
     * @param actionModules The action modules to set for this new publication.
     * @param actionModulesInitDatas The data to pass to the action modules' initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct CommentParams {
        uint256 profileId;
        string contentURI;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        bytes referenceModuleData;
        address[] actionModules;
        bytes[] actionModulesInitDatas;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `quote()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param pointedProfileId The profile token ID of the publication author that is quoted.
     * @param pointedPubId The publication ID that is quoted.
     * @param referrerProfileId The profile token ID of the publication that referred to the publication being commented on/quoted.
     * @param referrerPubId The ID of the publication that referred to the publication being commented on/quoted.
     * @param referenceModuleData The data passed to the reference module.
     * @param actionModules The action modules to set for this new publication.
     * @param actionModulesInitDatas The data to pass to the action modules' initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct QuoteParams {
        uint256 profileId;
        string contentURI;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        bytes referenceModuleData;
        address[] actionModules;
        bytes[] actionModulesInitDatas;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `comment()` or `quote()` internal functions.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param pointedProfileId The profile token ID of the publication author that is commented on/quoted.
     * @param pointedPubId The publication ID that is commented on/quoted.
     * @param referrerProfileId The profile token ID of the publication that referred to the publication being commented on/quoted.
     * @param referrerPubId The ID of the publication that referred to the publication being commented on/quoted.
     * @param referenceModuleData The data passed to the reference module.
     * @param actionModules The action modules to set for this new publication.
     * @param actionModulesInitDatas The data to pass to the action modules' initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct ReferencePubParams {
        uint256 profileId;
        string contentURI;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        bytes referenceModuleData;
        address[] actionModules;
        bytes[] actionModulesInitDatas;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `mirror()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param metadataURI the URI containing metadata attributes to attach to this mirror publication.
     * @param pointedProfileId The profile token ID to point the mirror to.
     * @param pointedPubId The publication ID to point the mirror to.
     * @param referenceModuleData The data passed to the reference module.
     */
    struct MirrorParams {
        uint256 profileId;
        string metadataURI;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        bytes referenceModuleData;
    }

    /**
     * Deprecated in V2: Will be removed after some time after upgrading to V2.
     * @notice A struct containing the parameters required for the legacy `collect()` function.
     * @dev The referrer can only be a mirror of the publication being collected.
     *
     * @param publicationCollectedProfileId The token ID of the profile that published the publication to collect.
     * @param publicationCollectedId The publication to collect's publication ID.
     * @param collectorProfileId The collector profile.
     * @param referrerProfileId The ID of a profile that authored a mirror that helped discovering the collected pub.
     * @param referrerPubId The ID of the mirror that helped discovering the collected pub.
     * @param collectModuleData The arbitrary data to pass to the collectModule if needed.
     */
    struct LegacyCollectParams {
        uint256 publicationCollectedProfileId;
        uint256 publicationCollectedId;
        uint256 collectorProfileId;
        uint256 referrerProfileId;
        uint256 referrerPubId;
        bytes collectModuleData;
    }

    /**
     * @notice A struct containing the parameters required for the `action()` function.
     *
     * @param publicationActedProfileId The token ID of the profile that published the publication to action.
     * @param publicationActedId The publication to action's publication ID.
     * @param actorProfileId The actor profile.
     * @param referrerProfileId
     * @param referrerPubId
     * @param actionModuleAddress
     * @param actionModuleData The arbitrary data to pass to the actionModule if needed.
     */
    struct PublicationActionParams {
        uint256 publicationActedProfileId;
        uint256 publicationActedId;
        uint256 actorProfileId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        address actionModuleAddress;
        bytes actionModuleData;
    }

    struct ProcessActionParams {
        uint256 publicationActedProfileId;
        uint256 publicationActedId;
        uint256 actorProfileId;
        address actorProfileOwner;
        address transactionExecutor;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        Types.PublicationType[] referrerPubTypes;
        bytes actionModuleData;
    }

    struct ProcessCommentParams {
        uint256 profileId;
        uint256 pubId;
        address transactionExecutor;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        Types.PublicationType[] referrerPubTypes;
        bytes data;
    }

    struct ProcessQuoteParams {
        uint256 profileId;
        uint256 pubId;
        address transactionExecutor;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        Types.PublicationType[] referrerPubTypes;
        bytes data;
    }

    struct ProcessMirrorParams {
        uint256 profileId;
        uint256 pubId;
        address transactionExecutor;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        Types.PublicationType[] referrerPubTypes;
        bytes data;
    }

    /**
     * @notice A struct containing a profile's delegated executors configuration.
     *
     * @param isApproved Tells when an address is approved as delegated executor in the given configuration number.
     * @param configNumber Current configuration number in use.
     * @param prevConfigNumber Previous configuration number set, before switching to the current one.
     * @param maxConfigNumberSet Maximum configuration number ever used.
     */
    struct DelegatedExecutorsConfig {
        mapping(uint256 => mapping(address => bool)) isApproved; // isApproved[configNumber][delegatedExecutor]
        uint64 configNumber;
        uint64 prevConfigNumber;
        uint64 maxConfigNumberSet;
    }

    struct TreasuryData {
        address treasury;
        uint16 treasuryFeeBPS;
    }

    struct MigrationParams {
        address lensHandlesAddress;
        address tokenHandleRegistryAddress;
        address legacyFeeFollowModule;
        address legacyProfileFollowModule;
        address newFeeFollowModule;
    }
}
