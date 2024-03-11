// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Errors} from '../libraries/constants/Errors.sol';
import {Types} from '../libraries/constants/Types.sol';
import {MetaTxLib} from '../libraries/MetaTxLib.sol';
import {ILensERC721} from '../interfaces/ILensERC721.sol';
import {IERC721Timestamped} from '../interfaces/IERC721Timestamped.sol';
import {IERC721Burnable} from '../interfaces/IERC721Burnable.sol';
import {IERC721MetaTx} from '../interfaces/IERC721MetaTx.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {ERC165} from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 *
 * Modifications:
 * 1. Refactored _operatorApprovals setter into an internal function to allow meta-transactions.
 * 2. Constructor replaced with an initializer.
 * 3. Mint timestamp is now stored in a TokenData struct alongside the owner address.
 */
abstract contract LensBaseERC721 is ERC165, ILensERC721 {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to token Data (owner address and mint timestamp uint96), this
    // replaces the original mapping(uint256 => address) private _owners;
    mapping(uint256 => Types.TokenData) private _tokenData;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Deprecated in V2 after removing ERC712Enumerable logic.
    mapping(address => mapping(uint256 => uint256)) private __DEPRECATED__ownedTokens;
    mapping(uint256 => uint256) private __DEPRECATED__ownedTokensIndex;

    // Dirty hack on a deprecated slot:
    uint256 private _totalSupply; // uint256[] private __DEPRECATED__allTokens;

    // Deprecated in V2 after removing ERC712Enumerable logic.
    mapping(uint256 => uint256) private __DEPRECATED__allTokensIndex;

    mapping(address => uint256) private _nonces;

    /**
     * @dev Initializes the ERC721 name and symbol.
     *
     * @param name_ The name to set.
     * @param symbol_ The symbol to set.
     */
    function _initialize(string calldata name_, string calldata symbol_) internal {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view virtual returns (string memory);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Timestamped).interfaceId ||
            interfaceId == type(IERC721Burnable).interfaceId ||
            interfaceId == type(IERC721MetaTx).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function nonces(address signer) public view override returns (uint256) {
        return _nonces[signer];
    }

    /// @inheritdoc IERC721MetaTx
    function getDomainSeparator() external view virtual override returns (bytes32) {
        return MetaTxLib.calculateDomainSeparator();
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) {
            revert Errors.InvalidParameter();
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _tokenData[tokenId].owner;
        if (owner == address(0)) {
            revert Errors.TokenDoesNotExist();
        }
        return owner;
    }

    /**
     * @dev See {IERC721Timestamped-mintTimestampOf}
     */
    function mintTimestampOf(uint256 tokenId) public view virtual override returns (uint256) {
        uint96 mintTimestamp = _tokenData[tokenId].mintTimestamp;
        if (mintTimestamp == 0) {
            revert Errors.TokenDoesNotExist();
        }
        return mintTimestamp;
    }

    /**
     * @dev See {IERC721Timestamped-tokenDataOf}
     */
    function tokenDataOf(uint256 tokenId) public view virtual override returns (Types.TokenData memory) {
        if (!_exists(tokenId)) {
            revert Errors.TokenDoesNotExist();
        }
        return _tokenData[tokenId];
    }

    /**
     * @dev See {IERC721Timestamped-exists}
     */
    function exists(uint256 tokenId) public view virtual override returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) {
            revert Errors.InvalidParameter();
        }

        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert Errors.NotOwnerOrApproved();
        }

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) {
            revert Errors.TokenDoesNotExist();
        }

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == msg.sender) {
            revert Errors.InvalidParameter();
        }

        _setOperatorApproval(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Errors.NotOwnerOrApproved();
        }

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Errors.NotOwnerOrApproved();
        }
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Burns `tokenId`.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Errors.NotOwnerOrApproved();
        }
        _burn(tokenId);
    }

    /**
     * @notice Returns the owner of the `tokenId` token.
     *
     * @dev It is prefixed as `unsafe` as it does not revert when the token does not exist.
     *
     * @param tokenId The token whose owner is being queried.
     *
     * @return address The address owning the given token, zero address if the token does not exist.
     */
    function _unsafeOwnerOf(uint256 tokenId) internal view returns (address) {
        return _tokenData[tokenId].owner;
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform a token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert Errors.NonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenData[tokenId].owner != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        // We don't check owner for != address(0) cause it's done inside ownerOf()
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0) || _exists(tokenId)) {
            revert Errors.InvalidParameter();
        }

        _beforeTokenTransfer(address(0), to, tokenId);

        unchecked {
            ++_balances[to];
            ++_totalSupply;
        }
        _tokenData[tokenId].owner = to;
        _tokenData[tokenId].mintTimestamp = uint96(block.timestamp);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        unchecked {
            --_balances[owner];
            --_totalSupply;
        }
        delete _tokenData[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (ownerOf(tokenId) != from) {
            revert Errors.InvalidOwner();
        }
        if (to == address(0)) {
            revert Errors.InvalidParameter();
        }

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        unchecked {
            --_balances[from];
            ++_balances[to];
        }
        _tokenData[tokenId].owner = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Refactored from the original OZ ERC721 implementation: approve or revoke approval from
     * `operator` to operate on all tokens owned by `owner`.
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setOperatorApproval(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert Errors.NonERC721ReceiverImplementer();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
