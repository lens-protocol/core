// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Errors} from '../libraries/constants/Errors.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {IERC2981} from '@openzeppelin/contracts/interfaces/IERC2981.sol';

abstract contract ERC2981CollectionRoyalties is IERC2981 {
    uint16 internal constant BASIS_POINTS = 10000;
    // bytes4(keccak256('royaltyInfo(uint256,uint256)')) == 0x2a55205a
    bytes4 internal constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == INTERFACE_ID_ERC2981 || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice Changes the royalty percentage for secondary sales.
     *
     * @param royaltiesInBasisPoints The royalty percentage (measured in basis points).
     */
    function setRoyalty(uint256 royaltiesInBasisPoints) external {
        _beforeRoyaltiesSet(royaltiesInBasisPoints);
        _setRoyalty(royaltiesInBasisPoints);
    }

    /**
     * @notice Called with the sale price to determine how much royalty is owed and to whom.
     *
     * @param tokenId The ID of the token queried for royalty information.
     * @param salePrice The sale price of the token specified.
     * @return A tuple with the address that should receive the royalties and the royalty
     * payment amount for the given sale price.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        return (_getReceiver(tokenId), _getRoyaltyAmount(tokenId, salePrice));
    }

    function _setRoyalty(uint256 royaltiesInBasisPoints) internal virtual {
        if (royaltiesInBasisPoints > BASIS_POINTS) {
            revert Errors.InvalidParameter();
        }
        _storeRoyaltiesInBasisPoints(royaltiesInBasisPoints);
    }

    function _getRoyaltyAmount(uint256 /* tokenId */, uint256 salePrice) internal view virtual returns (uint256) {
        return (salePrice * _loadRoyaltiesInBasisPoints()) / BASIS_POINTS;
    }

    function _storeRoyaltiesInBasisPoints(uint256 royaltiesInBasisPoints) internal virtual {
        uint256 royaltiesInBasisPointsSlot = _getRoyaltiesInBasisPointsSlot();
        assembly {
            sstore(royaltiesInBasisPointsSlot, royaltiesInBasisPoints)
        }
    }

    function _loadRoyaltiesInBasisPoints() internal view virtual returns (uint256) {
        uint256 royaltiesInBasisPointsSlot = _getRoyaltiesInBasisPointsSlot();
        uint256 royaltyAmount;
        assembly {
            royaltyAmount := sload(royaltiesInBasisPointsSlot)
        }
        return royaltyAmount;
    }

    function _beforeRoyaltiesSet(uint256 royaltiesInBasisPoints) internal view virtual;

    function _getRoyaltiesInBasisPointsSlot() internal view virtual returns (uint256);

    function _getReceiver(uint256 tokenId) internal view virtual returns (address);
}
