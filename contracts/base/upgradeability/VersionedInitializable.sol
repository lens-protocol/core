// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Errors} from '../../libraries/constants/Errors.sol';
import {StorageLib} from '../../libraries/StorageLib.sol';

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * This is slightly modified from [Aave's version.](https://github.com/aave/protocol-v2/blob/6a503eb0a897124d8b9d126c915ffdf3e88343a9/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol)
 *
 * @author Lens Protocol, inspired by Aave's implementation, which is in turn inspired by OpenZeppelin's
 * Initializable contract
 */
abstract contract VersionedInitializable {
    address private immutable originalImpl;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        if (address(this) == originalImpl) {
            revert Errors.CannotInitImplementation();
        }
        if (getRevision() <= StorageLib.getLastInitializedRevision()) {
            revert Errors.Initialized();
        }
        StorageLib.setLastInitializedRevision(getRevision());
        _;
    }

    constructor() {
        originalImpl = address(this);
    }

    /**
     * @dev returns the revision number of the contract
     * Needs to be defined in the inherited class as a constant.
     **/
    function getRevision() internal pure virtual returns (uint256);
}
