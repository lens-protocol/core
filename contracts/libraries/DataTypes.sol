// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title DataTypes
 * @author Lens Protocol
 *
 * @notice A standard library of data types used throughout the Lens Protocol.
 */
library DataTypes {
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
     * @param Post A standard post, having a URI, a collect module but no pointer to another publication.
     * @param Comment A comment, having a URI, a collect module and a pointer to another publication.
     * @param Mirror A mirror, having a pointer to another publication, but no URI or collect module.
     * @param Nonexistent An indicator showing the queried publication does not exist.
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
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter
     * @param deadline The signature's deadline
     */
    struct EIP712Signature {
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
    struct ProfileStruct {
        uint256 pubCount; // offset 0
        address followModule; // offset 1
        address followNFT; // offset 2
        string handleDeprecated; // offset 3
        string imageURI; // offset 4
        string followNFTURI; // offset 5
    }

    struct PublicationStruct {
        uint256 profileIdPointed;
        uint256 pubIdPointed;
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
    struct CreateProfileData {
        address to;
        string imageURI;
        address followModule;
        bytes followModuleInitData;
        string followNFTURI;
    }

    /**
     * @notice A struct containing the parameters required for the `setFollowModuleWithSig()` function. Parameters are
     * the same as the regular `setFollowModule()` function, with an added EIP712Signature.
     *
     * @param delegatedSigner The delegated executor signer, must be either zero, defaulting to the profile owner, or a delegated executor.
     * @param profileId The token ID of the profile to change the followModule for.
     * @param followModule The followModule to set for the given profile, must be whitelisted.
     * @param followModuleInitData The data to be passed to the followModule for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetFollowModuleWithSigData {
        address delegatedSigner;
        uint256 profileId;
        address followModule;
        bytes followModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `changeDelegatedExecutorsConfigWithSig()` function.
     *
     * @param delegatorProfileId The ID of the profile to which the delegated executor is being changed for.
     * @param executors The array of executors to set the approval for.
     * @param approvals The array of booleans indicating the corresponding executor new approval status.
     * @param configNumber The number of the configuration where the executor approval state is being set.
     * @param switchToGivenConfig A boolean indicanting if the configuration will be switched to the one with the given
     * number.

     * @param sig The EIP712Signature struct containing to the signer setting the approval's signature.
     */
    struct ChangeDelegatedExecutorsConfigWithSigData {
        uint256 delegatorProfileId;
        address[] executors;
        bool[] approvals;
        uint64 configNumber;
        bool switchToGivenConfig;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setProfileImageURIWithSig()` function. Parameters are the same
     * as the regular `setProfileImageURI()` function, with an added EIP712Signature.
     *
     * @param delegatedSigner The delegated executor signer, must be either zero, defaulting to the profile owner, or a delegated executor.
     * @param profileId The token ID of the profile to set the URI for.
     * @param imageURI The URI to set for the given profile image.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetProfileImageURIWithSigData {
        address delegatedSigner;
        uint256 profileId;
        string imageURI;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setFollowNFTURIWithSig()` function. Parameters are the same
     * as the regular `setFollowNFTURI()` function, with an added EIP712Signature.
     *
     * @param delegatedSigner The delegated executor signer, must be either zero, defaulting to the profile owner, or a delegated executor.
     * @param profileId The token ID of the profile for which to set the followNFT URI.
     * @param followNFTURI The follow NFT URI to set.
     * @param sig The EIP712Signature struct containing the followNFT's associated profile owner's signature.
     */
    struct SetFollowNFTURIWithSigData {
        address delegatedSigner;
        uint256 profileId;
        string followNFTURI;
        EIP712Signature sig;
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
    struct PostData {
        uint256 profileId;
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `postWithSig()` function. Parameters are the same as
     * the regular `post()` function, with an added EIP712Signature.
     *
     * @param delegatedSigner The delegated executor signer, must be either zero, defaulting to the profile owner, or a delegated executor.
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param collectModule The collectModule to set for this new publication.
     * @param collectModuleInitData The data to pass to the collectModule's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct PostWithSigData {
        address delegatedSigner;
        uint256 profileId;
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `comment()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param profileIdPointed The profile token ID to point the comment to.
     * @param pubIdPointed The publication ID to point the comment to.
     * @param referenceModuleData The data passed to the reference module.
     * @param collectModule The collect module to set for this new publication.
     * @param collectModuleInitData The data to pass to the collect module's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct CommentData {
        uint256 profileId;
        string contentURI;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `commentWithSig()` function. Parameters are the same as
     * the regular `comment()` function, with an added EIP712Signature.
     *
     * @param delegatedSigner The delegated executor signer, must be either zero, defaulting to the profile owner, or a delegated executor.
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param profileIdPointed The profile token ID to point the comment to.
     * @param pubIdPointed The publication ID to point the comment to.
     * @param referenceModuleData The data passed to the reference module.
     * @param collectModule The collectModule to set for this new publication.
     * @param collectModuleInitData The data to pass to the collectModule's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct CommentWithSigData {
        address delegatedSigner;
        uint256 profileId;
        string contentURI;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `mirror()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param profileIdPointed The profile token ID to point the mirror to.
     * @param pubIdPointed The publication ID to point the mirror to.
     * @param referenceModuleData The data passed to the reference module.
     */
    struct MirrorData {
        uint256 profileId;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
    }

    /**
     * @notice A struct containing the parameters required for the `mirrorWithSig()` function. Parameters are the same as
     * the regular `mirror()` function, with an added EIP712Signature.
     *
     * @param delegatedSigner The delegated executor signer, must be either zero, defaulting to the profile owner, or a delegated executor.
     * @param profileId The token ID of the profile to publish to.
     * @param profileIdPointed The profile token ID to point the mirror to.
     * @param pubIdPointed The publication ID to point the mirror to.
     * @param referenceModuleData The data passed to the reference module.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct MirrorWithSigData {
        address delegatedSigner;
        uint256 profileId;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `followWithSig` function. Parameters are the same
     * as the regular `follow` function, with the signer address and an EIP712Signature added.
     *
     * @param delegatedSigner The delegated executor signer, must be either zero, defaulting to the follower,
     * or a delegated executor.
     * @param followerProfileId The ID of the profile the follows are being executed for.
     * @param idsOfProfilesToFollow The array of IDs of profiles to follow.
     * @param followTokenIds The array of follow token IDs to use for each follow.
     * @param datas The arbitrary data array to pass to the follow module for each profile if needed.
     * @param sig The EIP712Signature struct containing the follower's signature.
     */
    struct FollowWithSigData {
        address delegatedSigner;
        uint256 followerProfileId;
        uint256[] idsOfProfilesToFollow;
        uint256[] followTokenIds;
        bytes[] datas;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `unfollowWithSig` function. Parameters are the same
     * as the regular `unfollow` function, with the signer address and an EIP712Signature added.
     *
     * @param delegatedSigner The delegated executor signer, must be either zero, defaulting to the follower,
     * or a delegated executor.
     * @param unfollowerProfileId The ID of the profile the unfollows are being executed for.
     * @param idsOfProfilesToUnfollow The array of IDs of profiles to unfollow.
     * @param sig The EIP712Signature struct containing the follower's signature.
     */
    struct UnfollowWithSigData {
        address delegatedSigner;
        uint256 unfollowerProfileId;
        uint256[] idsOfProfilesToUnfollow;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setBlockStatusWithSig` function. Parameters are the
     * same as the regular `setBlockStatus` function, with the signer address and an EIP712Signature added.
     *
     * @param delegatedSigner The delegated executor signer, must be either zero, defaulting to the blocker,
     * or a delegated executor.
     * @param byProfileId The ID of the profile the block status sets are being executed for.
     * @param idsOfProfilesToSetBlockStatus The array of IDs of profiles to set block status.
     * @param blockStatus The array of block status to use for each setting.
     * @param sig The EIP712Signature struct containing the blocker's signature.
     */
    struct SetBlockStatusWithSigData {
        address delegatedSigner;
        uint256 byProfileId;
        uint256[] idsOfProfilesToSetBlockStatus;
        bool[] blockStatus;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `collect()` function.
     *
     * @param collector The address of the collector.
     * @param profileId The token ID of the profile to that published the content being collected.
     * @param pubId The ID of the publication being collected.
     * @param data The data passed to the collect module.
     */
    struct CollectData {
        // TODO: Move this to tests? And the one below
        uint256 collectorProfileId;
        uint256 publisherProfileId;
        uint256 pubId;
        bytes data;
    }

    /**
     * @notice A struct containing the parameters required for the `collectWithSig()` function. Parameters are the same as
     * the regular `collect()` function, with the collector's (signer) address and an EIP712Signature added.
     *
     * @param delegatedSigner The delegated executor signer, must be either zero, defaulting to the collector profile owner, or a delegated executor.
     * @param publicationCollectedProfileId The token ID of the profile that published the publication to collect.
     * @param publicationCollectedId The publication to collect's publication ID.
     * @param collectorProfileId The collector profile.
     * @param passedReferrerProfileId TODO
     * @param passedReferrerPubId TODO
     * @param collectModuleData The arbitrary data to pass to the collectModule if needed.
     * @param sig The EIP712Signature struct containing the collector's signature.
     */
    struct CollectWithSigData {
        address delegatedSigner;
        uint256 publicationCollectedProfileId;
        uint256 publicationCollectedId;
        uint256 collectorProfileId;
        uint256 passedReferrerProfileId;
        uint256 passedReferrerPubId;
        bytes collectModuleData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setProfileMetadataWithSig()` function.
     *
     * @param delegatedSigner The delegated executor signer, must be either zero, defaulting to the profile owner, or a delegated executor.
     * @param profileId The profile ID for which to set the metadata.
     * @param metadataURI The metadata string to set for the profile and user.
     * @param sig The EIP712Signature struct containing the user's signature.
     */
    struct SetProfileMetadataURIWithSigData {
        address delegatedSigner;
        uint256 profileId;
        string metadataURI;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `toggleFollowWithSig()` function.
     *
     * @note This does not include a delegatedSigner parameter as it is marked for deprecation.
     *
     * @param follower The follower which is the message signer.
     * @param profileIds The token ID array of the profiles.
     * @param enables The array of booleans to enable/disable follows.
     * @param sig The EIP712Signature struct containing the follower's signature.
     */
    struct ToggleFollowWithSigData {
        address follower;
        uint256[] profileIds;
        bool[] enables;
        EIP712Signature sig;
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
