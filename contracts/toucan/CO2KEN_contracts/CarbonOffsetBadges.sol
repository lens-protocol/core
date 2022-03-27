// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

import './IToucanContractRegistry.sol';
import './CarbonOffsetBadgesStorage.sol';
import './CarbonProjects.sol';

/// @notice The `CarbonOffsetBadges` contract lets users mint Badge-NFTs
/// These Badges serve to display how much CO2 a user has offset via the protocols
contract CarbonOffsetBadges is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    CarbonOffsetBadgesStorage
{
    // Libraries
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;

    // Events
    event BadgeMinted(uint256 tokenId);

    // ----------------------------------------
    //      Upgradable related functions
    // ----------------------------------------

    function initialize(address _contractRegistry) public virtual initializer {
        __Context_init_unchained();
        __ERC721_init_unchained(
            'Toucan Protocol: Retirement Badges for Carbon Offset Project Vintage Batches',
            'TOUCAN-COBRB'
        );
        __Ownable_init_unchained();
        contractRegistry = _contractRegistry;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

    function setToucanContractRegistry(address _address)
        public
        virtual
        onlyOwner
    {
        contractRegistry = _address;
    }

    // Mint new Badge NFT that shows how many offsets have been retired
    function mintBadge(
        address to,
        uint256 projectVintageTokenId,
        uint256 amount
    ) external virtual {
        // Logic requires that minting can only originate from a project-vintage ERC20 contract
        require(
            IToucanContractRegistry(contractRegistry).checkERC20(
                _msgSender()
            ) == true,
            'pERC20 not official'
        );
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _safeMint(to, newItemId);
        badges[newItemId].projectVintageTokenId = projectVintageTokenId;
        badges[newItemId].retiredAmount = amount;

        emit BadgeMinted(newItemId);
    }

    function setBaseURI(string memory baseURI_) external virtual onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @dev allows setting a URI or a hash to be used by the `tokenURI` getter
    /// Unique values are enforced. This approach gives us good flexibility
    /// Allows for usage of cloud storage or IPFS pinning (and/or permastorage)
    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            'ERC721URIStorage: URI set of nonexistent token'
        );
        bytes32 h = keccak256(abi.encode(_tokenURI));
        require(hashes[h] == false);
        hashes[h] = true;
        badges[tokenId].tokenURI = _tokenURI;
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    /// based on the ERC721URIStorage implementation
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721URIStorage: URI query for nonexistent token'
        );

        string memory uri = badges[tokenId].tokenURI;
        string memory base = _baseURI();

        // If there is no base URI, return just the uri (or hash)
        if (bytes(base).length == 0) {
            return uri;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked)
        if (bytes(uri).length > 0) {
            return string(abi.encodePacked(base, uri));
        }
        return super.tokenURI(tokenId);
    }
}
