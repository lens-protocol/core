// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {IERC721Time} from 'contracts/interfaces/IERC721Time.sol';

import 'contracts/libraries/Constants.sol';

library StorageLib {
    function getPublication(uint256 profileId, uint256 pubId) internal pure returns (Types.Publication storage) {
        Types.Publication storage _publication;
        assembly {
            mstore(0, profileId)
            mstore(32, PUB_BY_ID_BY_PROFILE_MAPPING_SLOT)
            mstore(32, keccak256(0, 64))
            mstore(0, pubId)
            _publication.slot := keccak256(0, 64)
        }
        return _publication;
    }

    function getProfile(uint256 profileId) internal pure returns (Types.Profile storage) {
        Types.Profile storage _profile;
        assembly {
            mstore(0, profileId)
            mstore(32, PROFILE_BY_ID_MAPPING_SLOT)
            _profile.slot := keccak256(0, 64)
        }
        return _profile;
    }

    function getDelegatedExecutorsConfig(uint256 delegatorProfileId)
        internal
        pure
        returns (Types.DelegatedExecutorsConfig storage)
    {
        Types.DelegatedExecutorsConfig storage _delegatedExecutorsConfig;
        assembly {
            mstore(0, delegatorProfileId)
            mstore(32, DELEGATED_EXECUTOR_CONFIG_MAPPING_SLOT)
            _delegatedExecutorsConfig.slot := keccak256(0, 64)
        }
        return _delegatedExecutorsConfig;
    }

    function getTokenData(uint256 tokenId) internal pure returns (IERC721Time.TokenData storage) {
        IERC721Time.TokenData storage tokenData;
        assembly {
            mstore(0, tokenId)
            mstore(32, TOKEN_DATA_MAPPING_SLOT)
            tokenData.slot := keccak256(0, 64)
        }
        return tokenData;
    }

    function getBlockedStatusMapping(uint256 blockerProfileId)
        internal
        pure
        returns (mapping(uint256 => bool) storage _blockedStatus)
    {
        // NOTE: Currently Solidity does not allow to define mapping storage fields, so we use the named return instead.
        assembly {
            mstore(0, blockerProfileId)
            mstore(32, BLOCK_STATUS_MAPPING_SLOT)
            _blockedStatus.slot := keccak256(0, 64)
        }
    }

    function getNoncesMapping() internal pure returns (mapping(address => uint256) storage _nonces) {
        // NOTE: Currently Solidity does not allow to define mapping storage fields, so we use the named return instead.
        assembly {
            _nonces.slot := SIG_NONCES_MAPPING_SLOT
        }
    }

    // Used for all `ERC721Time` inherited contracts.
    function getName() internal pure returns (string storage) {
        string storage _name;
        assembly {
            _name.slot := NAME_SLOT
        }
        return _name;
    }
}
