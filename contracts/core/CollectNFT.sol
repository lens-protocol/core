// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {ICollectNFT} from '../interfaces/ICollectNFT.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';
import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';
import {Constants} from '../libraries/Constants.sol';
import {LensNFTBase} from './base/LensNFTBase.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

/**
 * @title CollectNFT
 * @author Lens Protocol
 *
 * @notice This is the NFT contract that is minted upon collecting a given publication. It is cloned upon
 * the first collect for a given publication, and the token URI points to the original publication's contentURI.
 */
contract CollectNFT is LensNFTBase, ICollectNFT {
    using Strings for uint256;

    address public immutable HUB;

    uint256 internal _profileId;
    uint256 internal _pubId;
    uint256 internal _tokenIdCounter;

    bool private _initialized;

    // We create the CollectNFT with the pre-computed HUB address before deploying the hub proxy in order
    // to initialize the hub proxy at construction.
    constructor(address hub) {
        if (hub == address(0)) revert Errors.InitParamsInvalid();
        HUB = hub;
        _initialized = true;
    }

    /// @inheritdoc ICollectNFT
    function initialize(uint256 profileId, uint256 pubId) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        _profileId = profileId;
        _pubId = pubId;
        // super._initialize(name, symbol);
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

    function name() public view override returns (string memory) {
        string memory handle = ILensHub(HUB).getHandle(_profileId);
        return
            string(abi.encodePacked(handle, Constants.COLLECT_NFT_NAME_INFIX, _pubId.toString()));
    }

    function symbol() public view override returns (string memory) {
        string memory handle = ILensHub(HUB).getHandle(_profileId);
        bytes4 firstBytes = bytes4(bytes(handle));
        return
            string(
                abi.encodePacked(firstBytes, Constants.COLLECT_NFT_SYMBOL_INFIX, _pubId.toString())
            );
    }

    /**
     * @dev Upon transfers, we emit the transfer event in the hub.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        ILensHub(HUB).emitCollectNFTTransferEvent(_profileId, _pubId, tokenId, from, to);
    }
}
