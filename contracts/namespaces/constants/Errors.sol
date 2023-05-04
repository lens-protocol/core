// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library RegistryErrors {
    error NotHandleOwner();
    error NotTokenOwner();
    error NotHandleOrTokenOwner();
    error OnlyLensHub();
}

library HandlesErrors {
    error HandleLengthInvalid();
    error HandleContainsInvalidCharacters();
    error HandleFirstCharInvalid();
    error NotOwnerNorWhitelisted();
    error NotOwner();
}
