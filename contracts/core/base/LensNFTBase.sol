// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {ILensNFTBase} from '../../interfaces/ILensNFTBase.sol';
import {Errors} from '../../libraries/Errors.sol';
import {DataTypes} from '../../libraries/DataTypes.sol';
import {Events} from '../../libraries/Events.sol';
import {ERC721Time} from './ERC721Time.sol';
import {ERC721Enumerable} from './ERC721Enumerable.sol';

abstract contract LensNFTBase is ILensNFTBase, ERC721Enumerable {
    bytes32 internal constant EIP712_REVISION_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    // keccak256('1');
    bytes32 internal constant PERMIT_TYPEHASH =
        0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;
    // keccak256('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');
    bytes32 internal constant PERMIT_FOR_ALL_TYPEHASH =
        0x47ab88482c90e4bb94b82a947ae78fa91fb25de1469ab491f4c15b9a0a2677ee;
    // keccak256(
    // 'PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)'
    // );
    bytes32 internal constant BURN_WITH_SIG_TYPEHASH =
        0x108ccda6d7331b00561a3eea66a2ae331622356585681c62731e4a01aae2261a;
    // keccak256('BurnWithSig(uint256 tokenId,uint256 nonce,uint256 deadline)');
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // keccak256(
    // 'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    // )

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
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (spender == address(0)) revert Errors.ZeroSpender();
        address owner = ownerOf(tokenId);

        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    _calculateDomainSeparator(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            spender,
                            tokenId,
                            sigNonces[owner]++,
                            sig.deadline
                        )
                    )
                )
            );
        }

        _validateRecoveredAddress(digest, owner, sig);
        _approve(spender, tokenId);
    }

    /// @inheritdoc ILensNFTBase
    function permitForAll(
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (operator == address(0)) revert Errors.ZeroSpender();

        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    _calculateDomainSeparator(),
                    keccak256(
                        abi.encode(
                            PERMIT_FOR_ALL_TYPEHASH,
                            owner,
                            operator,
                            approved,
                            sigNonces[owner]++,
                            sig.deadline
                        )
                    )
                )
            );
        }

        _validateRecoveredAddress(digest, owner, sig);
        _setOperatorApproval(owner, operator, approved);
    }

    /// @inheritdoc ILensNFTBase
    function getDomainSeparator() external view override returns (bytes32) {
        return _calculateDomainSeparator();
    }

    /// @inheritdoc ILensNFTBase
    function burn(uint256 tokenId) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Errors.NotOwnerOrApproved();
        _burn(tokenId);
    }

    /// @inheritdoc ILensNFTBase
    function burnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig)
        public
        virtual
        override
    {
        address owner = ownerOf(tokenId);

        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    _calculateDomainSeparator(),
                    keccak256(
                        abi.encode(
                            BURN_WITH_SIG_TYPEHASH,
                            tokenId,
                            sigNonces[owner]++,
                            sig.deadline
                        )
                    )
                )
            );
        }

        _validateRecoveredAddress(digest, owner, sig);
        _burn(tokenId);
    }

    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        DataTypes.EIP712Signature memory sig
    ) internal view {
        if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        if (recoveredAddress == address(0) || recoveredAddress != expectedAddress)
            revert Errors.SignatureInvalid();
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(name())),
                    EIP712_REVISION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }
}
