// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library Errors {
    error FollowInvalid();
    error ModuleDataMismatch();
    error NotHub();
    error InitParamsInvalid();
    error MintLimitExceeded();
    error CollectExpired();
}
