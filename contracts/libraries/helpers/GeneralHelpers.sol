// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {DataTypes} from '../DataTypes.sol';
import {Errors} from '../Errors.sol';

import '../Constants.sol';

/**
 * @title Helpers
 * @author Lens Protocol
 *
 * @notice This is a library that contains helper internal functions used by both the Hub and the GeneralLib.
 */
library GeneralHelpers {
    /**
     * @notice This helper function just returns the pointed publication if the passed publication is a mirror,
     * otherwise it returns the passed publication.
     *
     * @param profileId The token ID of the profile that published the given publication.
     * @param pubId The publication ID of the given publication.
     *
     * @return tuple First, the pointed publication's publishing profile ID, and second, the pointed publication's ID.
     * If the passed publication is not a mirror, this returns the given publication.
     */
    function getPointedIfMirror(uint256 profileId, uint256 pubId)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 slot;
        address collectModule;

        // Load the collect module for the given profile (zero if it is a mirror) and cache the
        // publication storage slot.
        assembly {
            mstore(0, profileId)
            mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            slot := keccak256(0, 64)
            let collectModuleSlot := add(slot, PUBLICATION_COLLECT_MODULE_OFFSET)
            collectModule := sload(collectModuleSlot)
        }

        if (collectModule != address(0)) {
            return (profileId, pubId);
        } else {
            uint256 profileIdPointed;

            // Load the pointed profile ID, first in the cached slot.
            assembly {
                // profile ID pointed is at offset 0, so we don't need to add any offset.
                profileIdPointed := sload(slot)
            }

            // We validate existence here as an optimization, so validating in calling
            // contracts is unnecessary.
            if (profileIdPointed == 0) revert Errors.PublicationDoesNotExist();

            uint256 pubIdPointed;

            // Load the pointed publication ID for the given publication.
            assembly {
                let pointedPubIdSlot := add(slot, PUBLICATION_PUB_ID_POINTED_OFFSET)
                pubIdPointed := sload(pointedPubIdSlot)
            }
            return (profileIdPointed, pubIdPointed);
        }
    }

    /**
     * @notice This helper function just returns the pointed publication if the passed publication is a mirror,
     * otherwise it returns the passed publication.
     *
     * @param profileId The token ID of the profile that published the given publication.
     * @param pubId The publication ID of the given publication.
     *
     * @return tuple First, the pointed publication's publishing profile ID, second, the pointed publication's ID, and third, the
     * pointed publication's collect module. If the passed publication is not a mirror, this returns the given publication.
     */
    function getPointedIfMirrorWithCollectModule(uint256 profileId, uint256 pubId)
        internal
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        uint256 slot;
        address collectModule;

        // Load the collect module for the given profile (zero if it is a mirror) and cache the
        // publication storage slot.
        assembly {
            mstore(0, profileId)
            mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            slot := keccak256(0, 64)
            let collectModuleSlot := add(slot, PUBLICATION_COLLECT_MODULE_OFFSET)
            collectModule := sload(collectModuleSlot)
        }

        if (collectModule != address(0)) {
            return (profileId, pubId, collectModule);
        } else {
            uint256 profileIdPointed;

            // Load the pointed profile ID, first in the cached slot.
            assembly {
                // profile ID pointed is at offset 0, so we don't need to add any offset.
                profileIdPointed := sload(slot)
            }

            // We validate existence here as an optimization, so validating in calling
            // contracts is unnecessary.
            if (profileIdPointed == 0) revert Errors.PublicationDoesNotExist();

            uint256 pubIdPointed;
            address collectModulePointed;

            // Load the pointed publication ID and the pointed collect module for the given
            // publication.
            assembly {
                let pointedPubIdSlot := add(slot, PUBLICATION_PUB_ID_POINTED_OFFSET)
                pubIdPointed := sload(pointedPubIdSlot)

                mstore(0, profileIdPointed)
                mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
                mstore(32, keccak256(0, 64))
                mstore(0, pubIdPointed)
                slot := add(keccak256(0, 64), PUBLICATION_COLLECT_MODULE_OFFSET)
                collectModulePointed := sload(slot)
            }
            return (profileIdPointed, pubIdPointed, collectModulePointed);
        }
    }

    /**
     * @dev This fetches the owner address for a given token ID. Note that this does not check and
     * revert upon loading a zero address.
     *
     * However, this function is only used if the result is compared to the caller or a recovered signer,
     * which is already checked for the zero address.
     */
    function unsafeOwnerOf(uint256 tokenId) internal view returns (address) {
        address owner;
        assembly {
            mstore(0, tokenId)
            mstore(32, TOKEN_DATA_MAPPING_SLOT)
            let slot := keccak256(0, 64)
            // This bit shift is necessary to remove the packing from the variable.
            owner := shr(96, shl(96, sload(slot)))
        }
        return owner;
    }

    function ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = unsafeOwnerOf(tokenId);
        if (owner == address(0)) {
            revert Errors.TokenDoesNotExist();
        }
        return owner;
    }

    function validateAddressIsProfileOwner(address expectedProfileOwner, uint256 profileId)
        internal
        view
    {
        if (expectedProfileOwner != ownerOf(profileId)) {
            revert Errors.NotProfileOwner();
        }
    }

    function validateAddressIsProfileOwnerOrDelegatedExecutor(
        address expectedOwnerOrDelegatedExecutor,
        uint256 profileId
    ) internal view {
        if (expectedOwnerOrDelegatedExecutor != ownerOf(profileId)) {
            validateAddressIsDelegatedExecutor({
                expectedDelegatedExecutor: expectedOwnerOrDelegatedExecutor,
                delegatorProfileId: profileId
            });
        }
    }

    function validateAddressIsDelegatedExecutor(
        address expectedDelegatedExecutor,
        uint256 delegatorProfileId
    ) internal view {
        if (!isExecutorApproved(delegatorProfileId, expectedDelegatedExecutor)) {
            revert Errors.ExecutorInvalid();
        }
    }

    function getDelegatedExecutorsConfig(uint256 delegatorProfileId)
        internal
        pure
        returns (DataTypes.DelegatedExecutorsConfig storage)
    {
        DataTypes.DelegatedExecutorsConfig storage _delegatedExecutorsConfig;
        assembly {
            mstore(0, delegatorProfileId)
            mstore(32, DELEGATED_EXECUTOR_CONFIG_MAPPING_SLOT)
            _delegatedExecutorsConfig.slot := keccak256(0, 64)
        }
        return _delegatedExecutorsConfig;
    }

    function isExecutorApproved(uint256 delegatorProfileId, address executor)
        internal
        view
        returns (bool)
    {
        DataTypes.DelegatedExecutorsConfig
            storage _delegatedExecutorsConfig = getDelegatedExecutorsConfig(delegatorProfileId);
        return
            _delegatedExecutorsConfig.isApproved[_delegatedExecutorsConfig.configNumber][executor];
    }

    /**
     * @dev Returns either the profile owner or the delegated signer if valid.
     */
    function getOriginatorOrDelegatedExecutorSigner(uint256 profileId, address delegatedSigner)
        internal
        view
        returns (address)
    {
        if (delegatedSigner == address(0)) {
            return ownerOf(profileId);
        } else {
            validateAddressIsDelegatedExecutor({
                expectedDelegatedExecutor: delegatedSigner,
                delegatorProfileId: profileId
            });
            return delegatedSigner;
        }
    }

    function validateNotBlocked(uint256 profile, uint256 byProfile) internal view {
        bool isBlocked;
        assembly {
            mstore(0, byProfile)
            mstore(32, BLOCK_STATUS_MAPPING_SLOT)
            let blockStatusByProfileSlot := keccak256(0, 64)
            mstore(0, profile)
            mstore(32, blockStatusByProfileSlot)
            isBlocked := sload(keccak256(0, 64))
        }
        if (isBlocked) {
            revert Errors.Blocked();
        }
    }
}
