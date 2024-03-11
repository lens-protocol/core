// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ImmutableOwnable} from '../misc/ImmutableOwnable.sol';
import {ILensHandles} from '../interfaces/ILensHandles.sol';
import {HandlesEvents} from './constants/Events.sol';
import {HandlesErrors} from './constants/Errors.sol';
import {IHandleTokenURI} from '../interfaces/IHandleTokenURI.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ERC2981CollectionRoyalties} from '../base/ERC2981CollectionRoyalties.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * A handle is defined as a local name inside a namespace context. A handle is represented as the local name with its
 * namespace applied as a prefix, using the slash symbol as separator.
 *
 *      handle = namespace /@ localName
 *
 * Handle and local name can be used interchangeably once you are in a context of a namespace, as it became redundant.
 *
 *      handle === ${localName} ; inside some namespace.
 *
 * @custom:upgradeable Transparent upgradeable proxy without initializer.
 */
contract LensHandles is ERC721, ERC2981CollectionRoyalties, ImmutableOwnable, ILensHandles {
    using Address for address;

    // We used 31 to fit the handle in a single slot, with `.lens` that restricted localName to use 26 characters.
    // Can be extended later if needed.
    uint256 internal constant MAX_LOCAL_NAME_LENGTH = 26;
    string public constant NAMESPACE = 'lens';
    uint256 internal immutable NAMESPACE_LENGTH = bytes(NAMESPACE).length;
    bytes32 public constant NAMESPACE_HASH = keccak256(bytes(NAMESPACE));
    uint256 public immutable TOKEN_GUARDIAN_COOLDOWN;
    uint256 internal constant GUARDIAN_ENABLED = type(uint256).max;
    mapping(address => uint256) internal _tokenGuardianDisablingTimestamp;

    uint256 internal _profileRoyaltiesBps; // Slot 7
    uint256 private _totalSupply;

    mapping(uint256 tokenId => string localName) internal _localNames;

    address internal _handleTokenURIContract;

    modifier onlyOwnerOrWhitelistedProfileCreator() {
        if (msg.sender != OWNER && !ILensHub(LENS_HUB).isProfileCreatorWhitelisted(msg.sender)) {
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

    modifier onlyHub() {
        if (msg.sender != LENS_HUB) {
            revert HandlesErrors.NotHub();
        }
        _;
    }

    constructor(
        address owner,
        address lensHub,
        uint256 tokenGuardianCooldown
    ) ERC721('', '') ImmutableOwnable(owner, lensHub) {
        TOKEN_GUARDIAN_COOLDOWN = tokenGuardianCooldown;
    }

    function name() public pure override returns (string memory) {
        return 'Lens Handles';
    }

    function symbol() public pure override returns (string memory) {
        return 'LH';
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function setHandleTokenURIContract(address handleTokenURIContract) external override onlyOwner {
        _handleTokenURIContract = handleTokenURIContract;
        emit HandlesEvents.BatchMetadataUpdate({fromTokenId: 0, toTokenId: type(uint256).max});
    }

    function getHandleTokenURIContract() external view override returns (address) {
        return _handleTokenURIContract;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return IHandleTokenURI(_handleTokenURIContract).getTokenURI(tokenId, _localNames[tokenId], NAMESPACE);
    }

    /// @inheritdoc ILensHandles
    function mintHandle(
        address to,
        string calldata localName
    ) external onlyOwnerOrWhitelistedProfileCreator returns (uint256) {
        _validateLocalName(localName);
        return _mintHandle(to, localName);
    }

    function migrateHandle(address to, string calldata localName) external onlyHub returns (uint256) {
        _validateLocalNameMigration(localName);
        return _mintHandle(to, localName);
    }

    function burn(uint256 tokenId) external {
        if (msg.sender != ownerOf(tokenId)) {
            revert HandlesErrors.NotOwner();
        }
        --_totalSupply;
        _burn(tokenId);
        delete _localNames[tokenId];
    }

    /// ************************************
    /// ****  TOKEN GUARDIAN FUNCTIONS  ****
    /// ************************************

    function DANGER__disableTokenGuardian() external override onlyEOA {
        if (_tokenGuardianDisablingTimestamp[msg.sender] != GUARDIAN_ENABLED) {
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

    function enableTokenGuardian() external override onlyEOA {
        if (_tokenGuardianDisablingTimestamp[msg.sender] == GUARDIAN_ENABLED) {
            revert HandlesErrors.AlreadyEnabled();
        }
        _tokenGuardianDisablingTimestamp[msg.sender] = GUARDIAN_ENABLED;
        emit HandlesEvents.TokenGuardianStateChanged({
            wallet: msg.sender,
            enabled: true,
            tokenGuardianDisablingTimestamp: GUARDIAN_ENABLED,
            timestamp: block.timestamp
        });
    }

    function approve(address to, uint256 tokenId) public override(IERC721, ERC721) {
        // We allow removing approvals even if the wallet has the token guardian enabled
        if (to != address(0) && _hasTokenGuardianEnabled(ownerOf(tokenId))) {
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

    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    function getNamespace() external pure returns (string memory) {
        return NAMESPACE;
    }

    function getNamespaceHash() external pure returns (bytes32) {
        return NAMESPACE_HASH;
    }

    function getLocalName(uint256 tokenId) public view returns (string memory) {
        string memory localName = _localNames[tokenId];
        if (bytes(localName).length == 0) {
            revert HandlesErrors.DoesNotExist();
        }
        return _localNames[tokenId];
    }

    function getHandle(uint256 tokenId) public view returns (string memory) {
        string memory localName = getLocalName(tokenId);
        return string.concat(NAMESPACE, '/@', localName);
    }

    function getTokenId(string memory localName) public pure returns (uint256) {
        return uint256(keccak256(bytes(localName)));
    }

    function getTokenGuardianDisablingTimestamp(address wallet) external view override returns (uint256) {
        return _tokenGuardianDisablingTimestamp[wallet];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981CollectionRoyalties, IERC165) returns (bool) {
        return (ERC721.supportsInterface(interfaceId) || ERC2981CollectionRoyalties.supportsInterface(interfaceId));
    }

    //////////////////////////////////////
    ///        INTERNAL FUNCTIONS      ///
    //////////////////////////////////////

    function _mintHandle(address to, string calldata localName) internal returns (uint256) {
        uint256 tokenId = getTokenId(localName);
        ++_totalSupply;
        _mint(to, tokenId);
        _localNames[tokenId] = localName;
        emit HandlesEvents.HandleMinted(localName, NAMESPACE, tokenId, to, block.timestamp);
        return tokenId;
    }

    /// @dev This function is used to validate the local name when migrating from V1 to V2.
    ///      As in V1 we also allowed the Hyphen '-' character, we need to allow it here as well and use a separate
    ///      validation function for migration VS newly created handles.
    function _validateLocalNameMigration(string memory localName) internal pure {
        bytes memory localNameAsBytes = bytes(localName);
        uint256 localNameLength = localNameAsBytes.length;

        if (localNameLength == 0 || localNameLength > MAX_LOCAL_NAME_LENGTH) {
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

    /// @dev In V2 we only accept the following characters: [a-z0-9_] to be used in newly created handles.
    ///      We also disallow the first character to be an underscore '_'.
    function _validateLocalName(string memory localName) internal pure {
        bytes memory localNameAsBytes = bytes(localName);
        uint256 localNameLength = localNameAsBytes.length;

        if (localNameLength == 0 || localNameLength > MAX_LOCAL_NAME_LENGTH) {
            revert HandlesErrors.HandleLengthInvalid();
        }

        if (localNameAsBytes[0] == '_') {
            revert HandlesErrors.HandleFirstCharInvalid();
        }

        uint256 i;
        while (i < localNameLength) {
            if (!_isAlphaNumeric(localNameAsBytes[i]) && localNameAsBytes[i] != '_') {
                revert HandlesErrors.HandleContainsInvalidCharacters();
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @dev We only accept lowercase characters to avoid confusion.
    /// @param char The character to check.
    /// @return True if the character is alphanumeric, false otherwise.
    function _isAlphaNumeric(bytes1 char) internal pure returns (bool) {
        return (char >= '0' && char <= '9') || (char >= 'a' && char <= 'z');
    }

    function _hasTokenGuardianEnabled(address wallet) internal view returns (bool) {
        return
            !wallet.isContract() &&
            (_tokenGuardianDisablingTimestamp[wallet] == GUARDIAN_ENABLED ||
                block.timestamp < _tokenGuardianDisablingTimestamp[wallet]);
    }

    function _getRoyaltiesInBasisPointsSlot() internal pure override returns (uint256 slot) {
        assembly {
            slot := _profileRoyaltiesBps.slot
        }
    }

    function _getReceiver(uint256 /* tokenId */) internal view override returns (address) {
        return ILensHub(LENS_HUB).getTreasury();
    }

    function _beforeRoyaltiesSet(uint256 /* royaltiesInBasisPoints */) internal view override {
        if (msg.sender != OWNER) {
            revert OnlyOwner();
        }
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
