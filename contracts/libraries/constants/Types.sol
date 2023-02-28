// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

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
     * _tokenData mapping, alongside the unchanging mintTimestamp.
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
     * @param Post A standard post, having an URI, a collect module but no pointer to another publication.
     * @param Comment A comment, having an URI, a collect module and a pointer to another publication.
     * @param Mirror A mirror, having a pointer to another publication, but no URI or collect module.
     * @param Quote A quote, having an URI, a collect module and a pointer to another publication.
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
     * @param signer The address of the signer.
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter
     * @param deadline The signature's deadline
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
     * @param followModule The address of the current follow module in use by this profile, can be empty.
     * @param followNFT The address of the followNFT associated with this profile, can be empty..
     * @param handleDeprecated The deprecated handle slot, no longer used. .
     * @param imageURI The URI to be used for the profile's image.
     * @param followNFTURI The URI to be used for the follow NFT.
     */
    struct Profile {
        uint256 pubCount; // offset 0
        address followModule; // offset 1
        address followNFT; // offset 2
        string handleDeprecated; // offset 3
        string imageURI; // offset 4
        string followNFTURI; // offset 5
        string metadataURI; // offset 6
    }

    struct Publication {
        uint256 pointedProfileId;
        uint256 pointedPubId;
        string contentURI;
        address referenceModule;
        address collectModule;
        address collectNFT;
        // Added in Lens V2, so these will be zero for old publications:
        PublicationType pubType;
        uint256 rootProfileId;
        uint256 rootPubId;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` function.
     *
     * @param to The address receiving the profile.
     * @param imageURI The URI to set for the profile image.
     * @param followModule The follow module to use, can be the zero address.
     * @param followModuleInitData The follow module initialization data, if any.
     * @param followNFTURI The URI to use for the follow NFT.
     */
    struct CreateProfileParams {
        address to;
        string imageURI;
        address followModule;
        bytes followModuleInitData;
        string followNFTURI;
    }

    /**
     * @notice A struct containing the parameters required for the `post()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param collectModule The collect module to set for this new publication.
     * @param collectModuleInitData The data to pass to the collect module's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct PostParams {
        uint256 profileId;
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
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
     * @param collectModule The collect module to set for this new publication.
     * @param collectModuleInitData The data to pass to the collect module's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct CommentParams {
        uint256 profileId;
        string contentURI;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256 referrerProfileId;
        uint256 referrerPubId;
        bytes referenceModuleData;
        address collectModule;
        bytes collectModuleInitData;
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
     * @param collectModule The collect module to set for this new publication.
     * @param collectModuleInitData The data to pass to the collect module's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct QuoteParams {
        uint256 profileId;
        string contentURI;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256 referrerProfileId;
        uint256 referrerPubId;
        bytes referenceModuleData;
        address collectModule;
        bytes collectModuleInitData;
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
     * @param collectModule The collect module to set for this new publication.
     * @param collectModuleInitData The data to pass to the collect module's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct ReferencePubParams {
        uint256 profileId;
        string contentURI;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256 referrerProfileId;
        uint256 referrerPubId;
        bytes referenceModuleData;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `mirror()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param pointedProfileId The profile token ID to point the mirror to.
     * @param pointedPubId The publication ID to point the mirror to.
     * @param referenceModuleData The data passed to the reference module.
     */
    struct MirrorParams {
        uint256 profileId;
        uint256 pointedProfileId;
        uint256 pointedPubId;
        uint256 referrerProfileId;
        uint256 referrerPubId;
        bytes referenceModuleData;
    }

    /**
     * @notice A struct containing the parameters required for the `collect()` function.
     *
     * @param publicationCollectedProfileId The token ID of the profile that published the publication to collect.
     * @param publicationCollectedId The publication to collect's publication ID.
     * @param collectorProfileId The collector profile.
     * @param referrerProfileId TODO
     * @param referrerPubId TODO
     * @param collectModuleData The arbitrary data to pass to the collectModule if needed.
     */
    struct CollectParams {
        uint256 publicationCollectedProfileId;
        uint256 publicationCollectedId;
        uint256 collectorProfileId;
        uint256 referrerProfileId;
        uint256 referrerPubId;
        bytes collectModuleData;
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
        mapping(uint256 => mapping(address => bool)) isApproved; // isApproved[configNumber][executor]
        uint64 configNumber;
        uint64 prevConfigNumber;
        uint64 maxConfigNumberSet;
    }
}
