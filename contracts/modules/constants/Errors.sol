// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library Errors {
    error FollowInvalid();
    error ModuleDataMismatch();
    error NotHub();
    error InitParamsInvalid();
    error InvalidParams();
    error MintLimitExceeded();
    error CollectExpired();
    error NotActionModule();
    error CollectNotAllowed();
    error AlreadyInitialized();
}
