// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILensNFTBase} from 'contracts/interfaces/ILensNFTBase.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {MetaTxLib} from 'contracts/libraries/MetaTxLib.sol';
import {ERC721Time} from 'contracts/base/ERC721Time.sol';
import {ERC721Enumerable} from 'contracts/base/ERC721Enumerable.sol';

/**
 * @title LensNFTBase
 * @author Lens Protocol
 *
 * @notice This is an abstract base contract to be inherited by other Lens Protocol NFTs, it includes
 * the slightly modified ERC721Enumerable, which itself inherits from the ERC721Time-- which adds an
 * internal operator approval setter, stores the mint timestamp for each token, and replaces the
 * constructor with an initializer.
 */
abstract contract LensNFTBase is ERC721Enumerable, ILensNFTBase {
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
    function permit(
        address spender,
        uint256 tokenId,
        Types.EIP712Signature calldata signature
    ) external virtual override {
        if (spender == address(0)) {
            revert Errors.ZeroSpender();
        }
        if (signature.signer != ownerOf(tokenId)) {
            revert Errors.NotProfileOwner();
        }
        MetaTxLib.validatePermitSignature(signature, spender, tokenId);
        _approve(spender, tokenId);
    }

    /// @inheritdoc ILensNFTBase
    function getDomainSeparator() external view virtual override returns (bytes32) {
        return MetaTxLib.calculateDomainSeparator();
    }

    /// @inheritdoc ILensNFTBase
    function burn(uint256 tokenId) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Errors.NotOwnerOrApproved();
        _burn(tokenId);
    }

    /// @inheritdoc ILensNFTBase
    function burnWithSig(uint256 tokenId, Types.EIP712Signature calldata signature) public virtual override {
        if (_isApprovedOrOwner(signature.signer, tokenId)) {
            revert Errors.NotOwnerOrApproved();
        }
        MetaTxLib.validateBurnSignature(signature, tokenId);
        _burn(tokenId);
    }
}
