// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {ILensHubNFTBase} from '../../interfaces/ILensHubNFTBase.sol';
import {Errors} from '../../libraries/Errors.sol';
import {DataTypes} from '../../libraries/DataTypes.sol';
import {Events} from '../../libraries/Events.sol';
import {ERC721Time} from './ERC721Time.sol';
import {ERC721Enumerable} from './ERC721Enumerable.sol';

/**
 * @title LensNFTBase
 * @author Lens Protocol
 *
 * @dev This is a trimmed down version of the LensNFTBase, mostly for contract size concerns.
 * Meta transaction functions have been moved to the core LensHub to utilize the MetaTxLib library.
 *
 * @notice This is an abstract base contract to be inherited by other Lens Protocol NFTs, it includes
 * the slightly modified ERC721Enumerable, which itself inherits from the ERC721Time-- which adds an
 * internal operator approval setter, stores the mint timestamp for each token, and replaces the
 * constructor with an initializer.
 */
abstract contract LensHubNFTBase is ERC721Enumerable, ILensHubNFTBase {
    mapping(address => uint256) public sigNonces;

    /**
     * @notice Initializer sets the name, symbol and the cached domain separator.
     *
     * NOTE: Inheritor contracts *must* call this function to initialize the name & symbol in the
     * inherited ERC721 contract.
     *
     * @param name The name to set in the ERC721 contract.
     * @param symbol The symbol to set in the ERC721 contract.
     */
    function _initialize(string calldata name, string calldata symbol) internal {
        ERC721Time.__ERC721_Init(name, symbol);

        emit Events.BaseInitialized(name, symbol, block.timestamp);
    }

    /// @inheritdoc ILensNFTBase
    // function permit(
    //     address spender,
    //     uint256 tokenId,
    //     DataTypes.EIP712Signature calldata sig
    // ) external override {
    //     if (spender == address(0)) revert Errors.ZeroSpender();
    //     address owner = ownerOf(tokenId);
    //     unchecked {
    //         _validateRecoveredAddress(
    //             _calculateDigest(
    //                 keccak256(
    //                     abi.encode(
    //                         PERMIT_TYPEHASH,
    //                         spender,
    //                         tokenId,
    //                         sigNonces[owner]++,
    //                         sig.deadline
    //                     )
    //                 )
    //             ),
    //             owner,
    //             sig
    //         );
    //     }
    //     _approve(spender, tokenId);
    // }

    /// @inheritdoc ILensNFTBase
    // function permitForAll(
    //     address owner,
    //     address operator,
    //     bool approved,
    //     DataTypes.EIP712Signature calldata sig
    // ) external override {
    //     if (operator == address(0)) revert Errors.ZeroSpender();
    //     unchecked {
    //         _validateRecoveredAddress(
    //             _calculateDigest(
    //                 keccak256(
    //                     abi.encode(
    //                         PERMIT_FOR_ALL_TYPEHASH,
    //                         owner,
    //                         operator,
    //                         approved,
    //                         sigNonces[owner]++,
    //                         sig.deadline
    //                     )
    //                 )
    //             ),
    //             owner,
    //             sig
    //         );
    //     }
    //     _setOperatorApproval(owner, operator, approved);
    // }

    // / @inheritdoc ILensNFTBase
    // function getDomainSeparator() external view override returns (bytes32) {
    //     return _calculateDomainSeparator();
    // }

    /// @inheritdoc ILensHubNFTBase
    function burn(uint256 tokenId) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Errors.NotOwnerOrApproved();
        _burn(tokenId);
    }

    /// @inheritdoc ILensNFTBase
    // function burnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig)
    //     public
    //     virtual
    //     override
    // {
    //     address owner = ownerOf(tokenId);
    //     unchecked {
    //         _validateRecoveredAddress(
    //             _calculateDigest(
    //                 keccak256(
    //                     abi.encode(
    //                         BURN_WITH_SIG_TYPEHASH,
    //                         tokenId,
    //                         sigNonces[owner]++,
    //                         sig.deadline
    //                     )
    //                 )
    //             ),
    //             owner,
    //             sig
    //         );
    //     }
    //     _burn(tokenId);
    // }
}
