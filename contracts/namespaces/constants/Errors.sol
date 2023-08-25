// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library RegistryErrors {
    error NotHandleNorTokenOwner();
    error OnlyLensHub();
    error NotLinked();
    error DoesNotExist();
    error DoesNotHavePermissions();
    error HandleAndTokenNotInSameWallet();
    error SignatureInvalid();
}

library HandlesErrors {
    error HandleLengthInvalid();
    error HandleContainsInvalidCharacters();
    error HandleFirstCharInvalid();
    error NotOwnerNorWhitelisted();
    error NotOwner();
    error NotHub();
    error DoesNotExist();
    error NotEOA();
    error DisablingAlreadyTriggered();
    error GuardianEnabled();
    error AlreadyEnabled();
}
