// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';

/**
 * @title Helpers
 * @author Lens Protocol
 *
 * @notice This is a library that only contains a single function that is used in the hub contract as well as in
 * both the publishing logic and interaction logic libraries.
 */
library Helpers {
    uint256 internal constant TOKEN_DATA_MAPPING_SLOT = 2;

    /**
     * @notice This helper function just returns the pointed publication if the passed publication is a mirror,
     * otherwise it returns the passed publication.
     *
     * @param profileId The token ID of the profile that published the given publication.
     * @param pubId The publication ID of the given publication.
     * @param _pubByIdByProfile A pointer to the storage mapping of publications by pubId by profile ID.
     *
     * @return tuple First, the pointed publication's publishing profile ID, second, the pointed publication's ID, and third, the
     * pointed publication's collect module. If the passed publication is not a mirror, this returns the given publication.
     */
    function getPointedIfMirror(
        uint256 profileId,
        uint256 pubId,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile
    )
        internal
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        address collectModule = _pubByIdByProfile[profileId][pubId].collectModule;
        if (collectModule != address(0)) {
            return (profileId, pubId, collectModule);
        } else {
            uint256 pointedTokenId = _pubByIdByProfile[profileId][pubId].profileIdPointed;
            // We validate existence here as an optimization, so validating in calling contracts is unnecessary
            if (pointedTokenId == 0) revert Errors.PublicationDoesNotExist();

            uint256 pointedPubId = _pubByIdByProfile[profileId][pubId].pubIdPointed;

            address pointedCollectModule = _pubByIdByProfile[pointedTokenId][pointedPubId]
                .collectModule;

            return (pointedTokenId, pointedPubId, pointedCollectModule);
        }
    }

    /**
     * @dev This fetches the owner address for a given token ID. Note that this does not check
     * and revert upon receiving a zero address.
     *
     * However, this function is always followed by a call to `_validateRecoveredAddress()` with
     * the returned address from this function as the signer, and since `_validateRecoveredAddress()`
     * reverts upon recovering the zero address, the execution will always revert if the owner returned
     * is the zero address.
     */
    function unsafeOwnerOf(uint256 tokenId) internal view returns (address) {
        // Note that this does *not* include a zero address check, but this is acceptable because
        // _validateRecoveredAddress reverts on recovering a zero address.
        address owner;
        assembly {
            mstore(0, tokenId)
            mstore(32, TOKEN_DATA_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            // this weird bit shift is necessary to remove the packing from the variable
            owner := shr(96, shl(96, sload(slot)))
        }
        return owner;
    }
}
