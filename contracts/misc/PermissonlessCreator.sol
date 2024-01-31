// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {LensV2Migration} from 'contracts/misc/LensV2Migration.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {ImmutableOwnable} from 'contracts/misc/ImmutableOwnable.sol';

import {ILensHandles} from 'contracts/interfaces/ILensHandles.sol';
import {ITokenHandleRegistry} from 'contracts/interfaces/ITokenHandleRegistry.sol';

/**
 * @title PermissonlessCreator
 * @author Lens Protocol
 * @notice This is an ownable public proxy contract that enforces ".lens" handle suffixes at profile creation but is open for all.
 */
contract PermissonlessCreator is ImmutableOwnable {
    ILensHandles public immutable LENS_HANDLES;
    ITokenHandleRegistry public immutable TOKEN_HANDLE_REGISTRY;

    uint256 public profileWithHandleCreationCost = 5 ether;
    uint256 public handleCreationCost = 5 ether;

    mapping(address => uint256) public credits;
    mapping(address => bool) public creditors;

    // mapping(profileId, creditAddress)
    mapping(uint256 => address) profileCreatedOnlyByCredit;

    modifier onlyCredit() {
        require(credits[msg.sender] > 0, 'PublicProfileCreator: Insufficient Credits');
        _;
    }

    modifier onlyCreditor() {
        require(creditors[msg.sender], 'PublicProfileCreator: Not a Creditor');
        _;
    }

    error ProfileAlreadyExists();
    error InvalidFunds();
    error InsufficientCredits();
    error ProfileAlreadyLinked();
    error NotAllowedToLinkHandleToProfile();

    constructor(
        address owner_,
        address hub,
        address lensHandles,
        address tokenHandleRegistry
    ) ImmutableOwnable(owner_, hub) {
        LENS_HANDLES = ILensHandles(lensHandles);
        TOKEN_HANDLE_REGISTRY = ITokenHandleRegistry(tokenHandleRegistry);
    }

    function createProfileOnly(
        Types.CreateProfileParams calldata createProfileParams
    ) external onlyCredit returns (uint256 profileId) {
        _checkAndApplyCredit(msg.sender);

        uint256 _profileId = ILensHub(LENS_HUB).createProfile(createProfileParams);

        profileCreatedOnlyByCredit[_profileId] = msg.sender;

        return _profileId;
    }

    function createProfileWithHandle(
        Types.CreateProfileParams calldata createProfileParams,
        string calldata handle
    ) external payable returns (uint256 profileId, uint256 handleId) {
        if (msg.value != profileWithHandleCreationCost) {
            revert InvalidFunds();
        }
        return _createProfileWithHandle(createProfileParams, handle);
    }

    function createProfileWithHandleCredits(
        Types.CreateProfileParams calldata createProfileParams,
        string calldata handle
    ) external onlyCredit returns (uint256 profileId, uint256 handleId) {
        _checkAndApplyCredit(msg.sender);
        return _createProfileWithHandle(createProfileParams, handle);
    }

    function createHandle(address to, string calldata handle) external payable returns (uint256 handleId) {
        if (msg.value != handleCreationCost) {
            revert InvalidFunds();
        }
        return LENS_HANDLES.mintHandle(to, handle);
    }

    // some credit addresses will be minting profiles before they have a handle so minting x amount of profiles.
    // This means onboarding they can mint the handle only and apply it to the profile to avoid the slow onboarding process
    function createHandleWithCredits(
        address to,
        string calldata handle,
        uint256 linkToProfileId
    ) external onlyCredit returns (uint256 handleId) {
        _checkAndApplyCredit(msg.sender);

        if (linkToProfileId != 0) {
            // only credit address which pre-minted the profiles can mint a handle
            // and apply it to the profile
            if (profileCreatedOnlyByCredit[linkToProfileId] != msg.sender) {
                revert NotAllowedToLinkHandleToProfile();
            }

            // if profile already has a handle linked to it, revert to avoid mistake from credit
            if (TOKEN_HANDLE_REGISTRY.getDefaultHandle(linkToProfileId) != 0) {
                revert ProfileAlreadyLinked();
            }

            uint256 _handleId = LENS_HANDLES.mintHandle(address(this), handle);

            TOKEN_HANDLE_REGISTRY.link({handleId: _handleId, profileId: linkToProfileId});
            // Transfer the handle & profile to the destination
            LENS_HANDLES.transferFrom(address(this), to, _handleId);

            return _handleId;
        } else {
            return LENS_HANDLES.mintHandle(to, handle);
        }
    }

    function increaseCredits(address to, uint256 amount) external onlyCreditor {
        credits[to] += amount;
    }

    function decreaseCredits(address to, uint256 amount) external onlyCreditor {
        require(credits[to] >= amount, 'PublicProfileCreator: Insufficient Credits to Decrease');
        credits[to] -= amount;
    }

    function addCreditor(address creditor) external onlyOwner {
        creditors[creditor] = true;
    }

    function removeCreditor(address creditor) external onlyOwner {
        creditors[creditor] = false;
    }

    function changeProfileWithHandleCreationPrice(uint256 newPrice) external onlyOwner {
        profileWithHandleCreationCost = newPrice;
    }

    function changeHandleCreationPrice(uint256 newPrice) external onlyOwner {
        handleCreationCost = newPrice;
    }

    function getPriceForProfileWithHandleCreation() external view returns (uint256) {
        return profileWithHandleCreationCost;
    }

    function getPriceForHandleCreation() external view returns (uint256) {
        return handleCreationCost;
    }

    function _createProfileWithHandle(
        Types.CreateProfileParams calldata createProfileParamsCalldata,
        string calldata handle
    ) private returns (uint256 profileId, uint256 handleId) {
        bytes32 handleHash = keccak256(abi.encodePacked(handle, '.lens'));
        if (LensV2Migration(LENS_HUB).getProfileIdByHandleHash(handleHash) != 0) {
            revert ProfileAlreadyExists();
        }

        // Copy the struct from calldata to memory to make it mutable
        Types.CreateProfileParams memory createProfileParams = createProfileParamsCalldata;

        // We mint the handle & profile to this contract first, then link it to the profile
        // This will not allow to initialize follow modules that require funds from the msg.sender,
        // but we assume only simple follow modules should be set during profile creation.
        // Complex ones can be set after the profile is created.
        address destination = createProfileParams.to;

        createProfileParams.to = address(this);

        uint256 _profileId = ILensHub(LENS_HUB).createProfile(createProfileParams);
        uint256 _handleId = LENS_HANDLES.mintHandle(address(this), handle);

        TOKEN_HANDLE_REGISTRY.link({handleId: _handleId, profileId: _profileId});

        // Transfer the handle & profile to the destination
        LENS_HANDLES.transferFrom(address(this), destination, _handleId);
        ILensHub(LENS_HUB).transferFrom(address(this), destination, profileId);

        return (_profileId, _handleId);
    }

    function _checkAndApplyCredit(address from) private {
        if (credits[from] < 1) {
            revert InsufficientCredits();
        }
        credits[from] -= 1;
    }
}
