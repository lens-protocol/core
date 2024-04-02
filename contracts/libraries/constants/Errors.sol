// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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
    error CallerNotFollowNFT();
    error CallerNotCollectNFT(); // Legacy
    error ArrayMismatch();
    error NotWhitelisted();
    error NotRegistered();
    error InvalidParameter();
    error ExecutorInvalid();
    error Blocked();
    error SelfBlock();
    error NotFollowing();
    error SelfFollow();
    error InvalidReferrer();
    error InvalidPointedPub();
    error NonERC721ReceiverImplementer();
    error AlreadyEnabled();

    // Module Errors
    error InitParamsInvalid();
    error ActionNotAllowed();

    error CollectNotAllowed(); // Used in LegacyCollectLib (pending deprecation)

    // MultiState Errors
    error Paused();
    error PublishingPaused();

    // Profile Guardian Errors
    error GuardianEnabled();
    error NotEOA();
    error DisablingAlreadyTriggered();

    // Migration Errors
    error NotMigrationAdmin();

    error NotAllowed();
}
