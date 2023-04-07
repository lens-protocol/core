// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title Namespaces Types
 * @author Lens Protocol
 */
library RegistryTypes {
    struct Token {
        uint256 id; // SLOT 0
        address collection; // SLOT 1 - end
        // uint96 _gap; // SLOT 1 - start
    }

    struct Handle {
        uint256 id; // SLOT 0
        address collection; // SLOT 1 - end
        // uint96 _gap; // SLOT 1 - start
    }
}
