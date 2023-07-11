// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ImmutableOwnable} from 'contracts/misc/ImmutableOwnable.sol';
import {ILensHandles} from 'contracts/interfaces/ILensHandles.sol';
import {HandlesEvents} from 'contracts/namespaces/constants/Events.sol';
import {HandlesErrors} from 'contracts/namespaces/constants/Errors.sol';
import {HandleTokenURILib} from 'contracts/libraries/token-uris/HandleTokenURILib.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * A handle is defined as a local name inside a namespace context. A handle is represented as the local name with its
 * namespace applied as a suffix, using the dot symbol as separator.
 *
 *      handle = ${localName}.${namespace}
 *
 * Handle and local name can be used interchangeably once you are in a context of a namespace, as it became redundant.
 *
 *      handle === ${localName} ; inside some namespace.
 */
contract LensHandles is ERC721, ImmutableOwnable, ILensHandles {
    using Address for address;

    uint256 internal constant MAX_HANDLE_LENGTH = 31;
    string internal constant NAMESPACE = 'lens';
    uint256 internal immutable NAMESPACE_LENGTH = bytes(NAMESPACE).length;
    uint256 internal constant SEPARATOR_LENGTH = 1; // bytes('.').length;
    bytes32 internal constant NAMESPACE_HASH = keccak256(bytes(NAMESPACE));

    uint256 internal immutable TOKEN_GUARDIAN_COOLDOWN;

    mapping(address => uint256) internal _tokenGuardianDisablingTimestamp;

    modifier onlyOwnerOrHubOrWhitelistedProfileCreator() {
        if (
            msg.sender != OWNER && msg.sender != LENS_HUB && !ILensHub(LENS_HUB).isProfileCreatorWhitelisted(msg.sender)
        ) {
            revert HandlesErrors.NotOwnerNorWhitelisted();
        }
        _;
    }

    modifier onlyEOA() {
        if (msg.sender.isContract()) {
            revert HandlesErrors.NotEOA();
        }
        _;
    }

    mapping(uint256 tokenId => string localName) internal _localNames;

    constructor(
        address owner,
        address lensHub,
        uint256 tokenGuardianCooldown
    ) ERC721('', '') ImmutableOwnable(owner, lensHub) {
        TOKEN_GUARDIAN_COOLDOWN = tokenGuardianCooldown;
    }

    function name() public pure override returns (string memory) {
        return string.concat(symbol(), ' Handles');
    }

    function symbol() public pure override returns (string memory) {
        return string.concat('.', NAMESPACE);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return HandleTokenURILib.getTokenURI(tokenId, _localNames[tokenId]);
    }

    /// @inheritdoc ILensHandles
    function mintHandle(
        address to,
        string calldata localName
    ) external onlyOwnerOrHubOrWhitelistedProfileCreator returns (uint256) {
        _validateLocalName(localName);
        uint256 tokenId = getTokenId(localName);
        _mint(to, tokenId);
        _localNames[tokenId] = localName;
        emit HandlesEvents.HandleMinted(localName, NAMESPACE, tokenId, to, block.timestamp);
        return tokenId;
    }

    function burn(uint256 tokenId) external {
        if (msg.sender != ownerOf(tokenId)) {
            revert HandlesErrors.NotOwner();
        }
        _burn(tokenId);
        delete _localNames[tokenId];
    }

    /// ************************************
    /// ****  TOKEN GUARDIAN FUNCTIONS  ****
    /// ************************************

    function DANGER__disableTokenGuardian() external onlyEOA {
        if (_tokenGuardianDisablingTimestamp[msg.sender] != 0) {
            revert HandlesErrors.DisablingAlreadyTriggered();
        }
        _tokenGuardianDisablingTimestamp[msg.sender] = block.timestamp + TOKEN_GUARDIAN_COOLDOWN;
        emit HandlesEvents.TokenGuardianStateChanged({
            wallet: msg.sender,
            enabled: false,
            tokenGuardianDisablingTimestamp: block.timestamp + TOKEN_GUARDIAN_COOLDOWN,
            timestamp: block.timestamp
        });
    }

    function enableTokenGuardian() external onlyEOA {
        if (_tokenGuardianDisablingTimestamp[msg.sender] == 0) {
            revert HandlesErrors.AlreadyEnabled();
        }
        _tokenGuardianDisablingTimestamp[msg.sender] = 0;
        emit HandlesEvents.TokenGuardianStateChanged({
            wallet: msg.sender,
            enabled: true,
            tokenGuardianDisablingTimestamp: 0,
            timestamp: block.timestamp
        });
    }

    function approve(address to, uint256 tokenId) public override(IERC721, ERC721) {
        // We allow removing approvals even if the wallet has the token guardian enabled
        if (to != address(0) && _hasTokenGuardianEnabled(msg.sender)) {
            revert HandlesErrors.GuardianEnabled();
        }
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721, ERC721) {
        // We allow removing approvals even if the wallet has the token guardian enabled
        if (approved && _hasTokenGuardianEnabled(msg.sender)) {
            revert HandlesErrors.GuardianEnabled();
        }
        super.setApprovalForAll(operator, approved);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function getNamespace() external pure returns (string memory) {
        return NAMESPACE;
    }

    function getNamespaceHash() external pure returns (bytes32) {
        return NAMESPACE_HASH;
    }

    // TODO: Should we revert if it doesn't exist?
    function getLocalName(uint256 tokenId) public view returns (string memory) {
        string memory localName = _localNames[tokenId];
        if (bytes(localName).length == 0) {
            revert HandlesErrors.DoesNotExist();
        }
        return _localNames[tokenId];
    }

    // TODO: Should we revert if it doesn't exist?
    function getHandle(uint256 tokenId) public view returns (string memory) {
        string memory localName = getLocalName(tokenId);
        return string.concat(localName, '.', NAMESPACE);
    }

    function getTokenId(string memory localName) public pure returns (uint256) {
        return uint256(keccak256(bytes(localName)));
    }

    function getTokenGuardianDisablingTimestamp(address wallet) external view returns (uint256) {
        return _tokenGuardianDisablingTimestamp[wallet];
    }

    //////////////////////////////////////
    ///        INTERNAL FUNCTIONS      ///
    //////////////////////////////////////

    function _validateLocalName(string memory localName) internal view {
        bytes memory localNameAsBytes = bytes(localName);
        uint256 localNameLength = localNameAsBytes.length;

        if (localNameLength == 0 || localNameLength + SEPARATOR_LENGTH + NAMESPACE_LENGTH > MAX_HANDLE_LENGTH) {
            revert HandlesErrors.HandleLengthInvalid();
        }

        bytes1 firstByte = localNameAsBytes[0];
        if (firstByte == '-' || firstByte == '_') {
            revert HandlesErrors.HandleFirstCharInvalid();
        }

        uint256 i;
        while (i < localNameLength) {
            if (!_isAlphaNumeric(localNameAsBytes[i]) && localNameAsBytes[i] != '-' && localNameAsBytes[i] != '_') {
                revert HandlesErrors.HandleContainsInvalidCharacters();
            }
            unchecked {
                ++i;
            }
        }
    }

    function _isAlphaNumeric(bytes1 char) internal pure returns (bool) {
        return (char >= '0' && char <= '9') || (char >= 'a' && char <= 'z');
    }

    function _hasTokenGuardianEnabled(address wallet) internal view returns (bool) {
        return
            !wallet.isContract() &&
            (_tokenGuardianDisablingTimestamp[wallet] == 0 ||
                block.timestamp < _tokenGuardianDisablingTimestamp[wallet]);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /* firstTokenId */,
        uint256 batchSize
    ) internal override {
        if (from != address(0) && _hasTokenGuardianEnabled(from)) {
            // Cannot transfer handle if the guardian is enabled, except at minting time.
            revert HandlesErrors.GuardianEnabled();
        }

        super._beforeTokenTransfer(from, to, 0, batchSize);
    }
}
