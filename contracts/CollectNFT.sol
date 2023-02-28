// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ERC2981CollectionRoyalties} from 'contracts/base/ERC2981CollectionRoyalties.sol';
import {ERC721Enumerable} from 'contracts/base/ERC721Enumerable.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {ICollectNFT} from 'contracts/interfaces/ICollectNFT.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {LensNFTBase} from 'contracts/base/LensNFTBase.sol';

/**
 * @title CollectNFT
 * @author Lens Protocol
 *
 * @notice This is the NFT contract that is minted upon collecting a given publication. It is cloned upon
 * the first collect for a given publication, and the token URI points to the original publication's contentURI.
 */
contract CollectNFT is LensNFTBase, ERC2981CollectionRoyalties, ICollectNFT {
    address public immutable HUB;

    uint256 internal _profileId;
    uint256 internal _pubId;
    uint256 internal _tokenIdCounter;

    bool private _initialized;

    uint256 internal _royaltiesInBasisPoints;

    // We create the CollectNFT with the pre-computed HUB address before deploying the hub proxy in order
    // to initialize the hub proxy at construction.
    constructor(address hub) {
        if (hub == address(0)) revert Errors.InitParamsInvalid();
        HUB = hub;
        _initialized = true;
    }

    /// @inheritdoc ICollectNFT
    function initialize(
        uint256 profileId,
        uint256 pubId,
        string calldata name,
        string calldata symbol
    ) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        _setRoyalty(1000); // 10% of royalties
        _profileId = profileId;
        _pubId = pubId;
        super._initialize(name, symbol);
        emit Events.CollectNFTInitialized(profileId, pubId, block.timestamp);
    }

    /// @inheritdoc ICollectNFT
    function mint(address to) external override returns (uint256) {
        if (msg.sender != HUB) revert Errors.NotHub();
        unchecked {
            uint256 tokenId = ++_tokenIdCounter;
            _mint(to, tokenId);
            return tokenId;
        }
    }

    /// @inheritdoc ICollectNFT
    function getSourcePublicationPointer() external view override returns (uint256, uint256) {
        return (_profileId, _pubId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert Errors.TokenDoesNotExist();
        return ILensHub(HUB).getContentURI(_profileId, _pubId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981CollectionRoyalties, ERC721Enumerable) returns (bool) {
        return
            ERC2981CollectionRoyalties.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _getReceiver(uint256 /* tokenId */) internal view override returns (address) {
        return IERC721(HUB).ownerOf(_profileId);
    }

    function _beforeRoyaltiesSet(uint256 /* royaltiesInBasisPoints */) internal view override {
        if (IERC721(HUB).ownerOf(_profileId) != msg.sender) {
            revert Errors.NotProfileOwner();
        }
    }

    function _getRoyaltiesInBasisPointsSlot() internal pure override returns (uint256) {
        uint256 slot;
        assembly {
            slot := _royaltiesInBasisPoints.slot
        }
        return slot;
    }

    /**
     * @dev Upon transfers, we emit the transfer event in the hub.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        ILensHub(HUB).emitCollectNFTTransferEvent(_profileId, _pubId, tokenId, from, to);
    }
}
