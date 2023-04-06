// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library Errors {
    error CannotInitImplementation();
    error Initialized();
    error SignatureExpired();
    error SignatureInvalid();
    error InvalidOwner();
    error NotOwnerOrApproved();
    error NotHub();
    error TokenDoesNotExist();
    error NotGovernance();
    error NotGovernanceOrEmergencyAdmin();
    error EmergencyAdminCanOnlyPauseFurther();
    error NotProfileOwner();
    error PublicationDoesNotExist();
    error HandleLengthInvalid();
    error HandleContainsInvalidCharacters();
    error HandleFirstCharInvalid();
    error ProfileImageURILengthInvalid();
    error CallerNotFollowNFT();
    error ArrayMismatch();
    error NotWhitelisted();
    error InvalidParameter();
    error ExecutorInvalid();
    error Blocked();
    error SelfBlock();
    error NotFollowing();
    error SelfFollow();
    error InvalidReferrer();
    error DeprecaredModulesOnlySupportOneReferrer();
    error InvalidPointedPub();
    error NonERC721ReceiverImplementer();

    // Internal Errors
    error MaxActionModuleIdReached(); // This means we need an upgrade

    // Module Errors
    error InitParamsInvalid();
    error FollowInvalid();
    error ModuleDataMismatch();
    error FollowNotApproved();
    error MintLimitExceeded();
    error CollectNotAllowed(); // TODO: Move this to Modules repo
    error ActionNotAllowed();

    // MultiState Errors
    error Paused();
    error PublishingPaused();
}
