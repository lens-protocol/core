// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

import './CarbonProjectsStorage.sol';
import './ICarbonProjects.sol';
import './libraries/Modifiers.sol';

/// @notice The CarbonProjects contract stores carbon project-specific data
/// The data is stored in structs via ERC721 tokens
/// Most contracts in the protocol query the data stored here
/// The attributes in the Project-NFTs are constant over all vintages of the project
/// @dev Each project can have up to n vintages, with data stored in the
/// `CarbonProjectVintages` contract. `vintageTokenId`s are mapped to `projectTokenId`s
/// via `pvToTokenId` in the vintage contract.
contract CarbonProjects is
    ICarbonProjects,
    CarbonProjectsStorage,
    ERC721Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    Modifiers,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    event ProjectMinted(address receiver, uint256 tokenId);
    event ProjectUpdated(uint256 tokenId);
    event ProjectIdUpdated(uint256 tokenId);

    // ----------------------------------------
    //      Upgradable related functions
    // ----------------------------------------

    function initialize() public virtual initializer {
        __Context_init_unchained();
        __ERC721_init_unchained(
            'Toucan Protocol: Carbon Projects',
            'TOUCAN-CP'
        );
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        /// @dev granting the deployer==owner the rights to grant other roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

    // ------------------------
    //      Admin functions
    // ------------------------
    /// @dev modifier that only lets the contract's owner and elected managers add/update/remove project data
    modifier onlyManagers() {
        require(
            hasRole(MANAGER_ROLE, msg.sender) || owner() == msg.sender,
            'Caller is not authorized'
        );
        _;
    }

    /// @notice Emergency function to disable contract's core functionality
    /// @dev wraps _pause(), only Admin
    function pause() public virtual onlyBy(contractRegistry, owner()) {
        _pause();
    }

    /// @dev unpause the system, wraps _unpause(), only Admin
    function unpause() public virtual onlyBy(contractRegistry, owner()) {
        _unpause();
    }

    function setToucanContractRegistry(address _address)
        public
        virtual
        onlyOwner
    {
        contractRegistry = _address;
    }

    /// @notice Updates the controller, the entity in charge of the ProjectData
    /// Questionable if needed if this stays ERC721, as this could be the NFT owner
    function updateController(uint256 tokenId, address _controller)
        external
        virtual
        whenNotPaused
    {
        require(
            msg.sender == ownerOf(tokenId),
            'Error: Caller is not the owner'
        );
        projectData[tokenId].controller = _controller;
    }

    /// @notice Adds a new carbon project along with attributes/data
    /// @dev Projects can be added by data-managers
    function addNewProject(
        address to,
        string memory projectId,
        string memory standard,
        string memory methodology,
        string memory region,
        string memory storageMethod,
        string memory method,
        string memory emissionType,
        string memory category,
        string memory uri
    ) external virtual override onlyManagers whenNotPaused returns (uint256) {
        require(!strcmp(projectId, ''), 'ProjectId cannot be empty');

        /// @FIXME can we deprecate this check?
        require(projectIds[projectId] == false, 'Project already exists');
        projectIds[projectId] = true;

        projectTokenCounter++;
        totalSupply++;
        uint256 newItemId = projectTokenCounter;
        validProjectTokenIds[newItemId] = true;

        _mint(to, newItemId);

        projectData[newItemId].projectId = projectId;
        projectData[newItemId].standard = standard;
        projectData[newItemId].methodology = methodology;
        projectData[newItemId].region = region;
        projectData[newItemId].storageMethod = storageMethod;
        projectData[newItemId].method = method;
        projectData[newItemId].emissionType = emissionType;
        projectData[newItemId].category = category;
        projectData[newItemId].uri = uri;

        emit ProjectMinted(to, newItemId);
        pidToTokenId[projectId] = newItemId;
        return newItemId;
    }

    /// @notice Updates and existing carbon project
    /// @dev Projects can be updated by data-managers
    function updateProject(
        uint256 tokenId,
        string memory newStandard,
        string memory newMethodology,
        string memory newRegion,
        string memory newStorageMethod,
        string memory newMethod,
        string memory newEmissionType,
        string memory newCategory,
        string memory newUri
    ) external virtual onlyManagers whenNotPaused {
        require(_exists(tokenId), 'Project not yet minted');
        projectData[tokenId].standard = newStandard;
        projectData[tokenId].methodology = newMethodology;
        projectData[tokenId].region = newRegion;
        projectData[tokenId].storageMethod = newStorageMethod;
        projectData[tokenId].method = newMethod;
        projectData[tokenId].emissionType = newEmissionType;
        projectData[tokenId].category = newCategory;
        projectData[tokenId].uri = newUri;

        emit ProjectUpdated(tokenId);
    }

    /// @dev Projects and their projectId's must be unique, changing them must be handled carefully
    function updateProjectId(uint256 tokenId, string memory newProjectId)
        external
        virtual
        onlyManagers
        whenNotPaused
    {
        require(_exists(tokenId), 'Project not yet minted');
        require(
            projectIds[newProjectId] == false,
            'Cant change current projectId to an existing one'
        );

        string memory oldProjectId = projectData[tokenId].projectId;
        projectIds[oldProjectId] = false;

        projectData[tokenId].projectId = newProjectId;
        projectIds[newProjectId] = true;

        emit ProjectIdUpdated(tokenId);
    }

    /// @dev Removes a project and corresponding data, sets projectTokenId invalid
    function removeProject(uint256 projectTokenId)
        external
        virtual
        onlyManagers
        whenNotPaused
    {
        delete projectData[projectTokenId];
        /// @dev set projectTokenId to invalid
        totalSupply--;
        validProjectTokenIds[projectTokenId] = false;
    }

    /// @dev Returns the global project-id, for example'VCS-1418'
    function getProjectId(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return projectData[tokenId].projectId;
    }

    /// @dev Function used by the utility function `checkProjectTokenExists`
    function isValidProjectTokenId(uint256 projectTokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return validProjectTokenIds[projectTokenId];
    }

    /// @dev retrieve all data from ProjectData struct
    function getProjectDataByTokenId(uint256 tokenId)
        external
        view
        virtual
        returns (ProjectData memory)
    {
        return (projectData[tokenId]);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlUpgradeable,
            ERC721Upgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory gateway) external virtual onlyOwner {
        baseURI = gateway;
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

        string memory uri = projectData[tokenId].uri;
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return uri;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(uri).length > 0) {
            return string(abi.encodePacked(base, uri));
        }

        return super.tokenURI(tokenId);
    }

    function memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return memcmp(bytes(a), bytes(b));
    }
}
