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

import './IToucanContractRegistry.sol';
import './ICarbonProjectVintages.sol';
import './CarbonProjectVintagesStorage.sol';
import './CarbonProjects.sol';
import './libraries/ProjectUtils.sol';
import './libraries/Modifiers.sol';

/// @notice The CarbonProjectVintages contract stores vintage-specific data
/// The data is stored in structs via ERC721 tokens
/// Most contracts in the protocol query the data stored here
/// Every `vintageData` struct points to a parent `CarbonProject`
contract CarbonProjectVintages is
    CarbonProjectVintagesStorage,
    ICarbonProjectVintages,
    ERC721Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    Modifiers,
    ProjectUtils
{
    event ProjectVintageMinted(
        address receiver,
        uint256 tokenId,
        uint256 projectTokenId,
        uint64 startTime
    );
    event ProjectVintageUpdated(uint256 tokenId);
    event ProjectVintageIdUpdated(uint256 tokenId);

    // ----------------------------------------
    //      Upgradable related functions
    // ----------------------------------------

    function initialize() public virtual initializer {
        __Context_init_unchained();
        __ERC721_init_unchained(
            'Toucan Protocol: Carbon Project Vintages',
            'TOUCAN-CPV'
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

    /// @notice Adds a new carbon project-vintage along with attributes/data
    /// @dev vintages can be added by data-managers
    function addNewVintage(
        address to,
        uint256 projectTokenId,
        string memory name,
        uint64 startTime,
        uint64 endTime,
        uint64 totalVintageQuantity,
        bool isCorsiaCompliant,
        bool isCCPcompliant,
        string memory coBenefits,
        string memory correspAdjustment,
        string memory additionalCertification,
        string memory uri
    ) external virtual override onlyManagers whenNotPaused returns (uint256) {
        checkProjectTokenExists(contractRegistry, projectTokenId);

        require(
            pvToTokenId[projectTokenId][startTime] == 0,
            'Error: vintage already added'
        );

        require(
            startTime < endTime,
            'Error: vintage startTime must be less than endTime'
        );

        /// @dev Increase `projectVintageTokenCounter` and mark current Id as valid
        projectVintageTokenCounter++;
        totalSupply++;
        uint256 newItemId = projectVintageTokenCounter;
        validProjectVintageIds[newItemId] = true;

        _mint(to, newItemId);

        vintageData[newItemId].name = name;
        vintageData[newItemId].startTime = startTime;
        vintageData[newItemId].endTime = endTime;
        vintageData[newItemId].projectTokenId = projectTokenId;
        vintageData[newItemId].totalVintageQuantity = totalVintageQuantity;
        vintageData[newItemId].isCorsiaCompliant = isCorsiaCompliant;
        vintageData[newItemId].isCCPcompliant = isCCPcompliant;
        vintageData[newItemId].coBenefits = coBenefits;
        vintageData[newItemId].correspAdjustment = correspAdjustment;
        vintageData[newItemId]
            .additionalCertification = additionalCertification;
        vintageData[newItemId].uri = uri;

        emit ProjectVintageMinted(to, newItemId, projectTokenId, startTime);
        pvToTokenId[projectTokenId][startTime] = newItemId;

        return newItemId;
    }

    /// @dev Function to check whether a projectVintageToken exists,
    /// to be called by other (external) contracts
    function exists(uint256 tokenId)
        external
        view
        virtual
        override
        returns (bool)
    {
        return super._exists(tokenId);
    }

    /// @notice Updates and existing carbon project
    /// @dev Only data-managers can update the data for correction
    /// except the sensitive `projectId`
    function updateProjectVintage(
        uint256 tokenId,
        // uint256 projectTokenId, // @dev commented out because very sensitive data, better via separate function
        string memory name,
        uint64 startTime,
        uint64 endTime,
        uint64 totalVintageQuantity,
        bool isCorsiaCompliant,
        bool isCCPcompliant,
        string memory coBenefits,
        string memory correspAdjustment,
        string memory additionalCertification,
        string memory uri
    ) external virtual onlyManagers whenNotPaused {
        require(_exists(tokenId), 'Project not yet minted');
        vintageData[tokenId].name = name;
        vintageData[tokenId].startTime = startTime;
        vintageData[tokenId].endTime = endTime;
        vintageData[tokenId].totalVintageQuantity = totalVintageQuantity;
        vintageData[tokenId].isCorsiaCompliant = isCorsiaCompliant;
        vintageData[tokenId].isCCPcompliant = isCCPcompliant;
        vintageData[tokenId].coBenefits = coBenefits;
        vintageData[tokenId].correspAdjustment = correspAdjustment;
        vintageData[tokenId].additionalCertification = additionalCertification;
        vintageData[tokenId].uri = uri;

        emit ProjectVintageUpdated(tokenId);
    }

    /// @dev Removes a project-vintage and corresponding data
    function removeVintage(uint256 tokenId)
        external
        virtual
        onlyManagers
        whenNotPaused
    {
        totalSupply--;
        delete vintageData[tokenId];
    }

    /// @dev retrieve all data from VintageData struct
    function getProjectVintageDataByTokenId(uint256 tokenId)
        external
        view
        virtual
        returns (VintageData memory)
    {
        return (vintageData[tokenId]);
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

    function setBaseURI(string memory baseURI_) external virtual onlyOwner {
        baseURI = baseURI_;
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

        string memory uri = vintageData[tokenId].uri;
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
}
