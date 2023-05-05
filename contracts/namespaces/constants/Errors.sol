// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library RegistryErrors {
    error NotHandleOwner();
    error NotTokenOwner();
    error NotHandleNorTokenOwner();
    error OnlyLensHub();
    error NotBurnt();
    error NotLinked();
}

library HandlesErrors {
    error HandleLengthInvalid();
    error HandleContainsInvalidCharacters();
    error HandleFirstCharInvalid();
    error NotOwnerNorWhitelisted();
    error NotOwner();
}
