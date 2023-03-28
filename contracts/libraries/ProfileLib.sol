// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {IFollowModule} from 'contracts/interfaces/IFollowModule.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';

library ProfileLib {
    uint16 constant MAX_PROFILE_IMAGE_URI_LENGTH = 6000;

    function ownerOf(uint256 profileId) internal view returns (address) {
        address profileOwner = StorageLib.getTokenData(profileId).owner;
        if (profileOwner == address(0)) {
            revert Errors.TokenDoesNotExist();
        }
        return profileOwner;
    }

    /**
     * @notice Creates a profile with the given parameters to the given address. Minting happens
     * in the hub.
     *
     * @param createProfileParams The CreateProfileParams struct containing the following parameters:
     *      to: The address receiving the profile.
     *      imageURI: The URI to set for the profile image.
     *      followModule: The follow module to use, can be the zero address.
     *      followModuleInitData: The follow module initialization data, if any
     *      followNFTURI: The URI to set for the follow NFT.
     * @param profileId The profile ID to associate with this profile NFT (token ID).
     */
    function createProfile(Types.CreateProfileParams calldata createProfileParams, uint256 profileId) external {
        ValidationLib.validateProfileCreatorWhitelisted(msg.sender);

        if (bytes(createProfileParams.imageURI).length > MAX_PROFILE_IMAGE_URI_LENGTH) {
            revert Errors.ProfileImageURILengthInvalid();
        }

        Types.Profile storage _profile = StorageLib.getProfile(profileId);
        _profile.imageURI = createProfileParams.imageURI;
        _profile.followNFTURI = createProfileParams.followNFTURI;

        bytes memory followModuleReturnData;
        if (createProfileParams.followModule != address(0)) {
            // Load the follow module to be used in the next assembly block.
            address followModule = createProfileParams.followModule;

            StorageLib.getProfile(profileId).followModule = followModule;

            // We don't need to check for deprecated modules here because deprecated ones are no longer whitelisted.
            // Initialize the follow module.
            followModuleReturnData = _initFollowModule(
                profileId,
                createProfileParams.to,
                createProfileParams.followModule,
                createProfileParams.followModuleInitData
            );
        }
        emit Events.ProfileCreated(
            profileId,
            msg.sender,
            createProfileParams.to,
            createProfileParams.imageURI,
            createProfileParams.followModule,
            followModuleReturnData,
            createProfileParams.followNFTURI,
            block.timestamp
        );
    }

    /**
     * @notice Sets the profile image URI for a given profile.
     *
     * @param profileId The profile ID.
     * @param imageURI The image URI to set.

     */
    function setProfileImageURI(uint256 profileId, string calldata imageURI) external {
        _setProfileImageURI(profileId, imageURI);
    }

    /**
     * @notice Sets the follow NFT URI for a given profile.
     *
     * @param profileId The profile ID.
     * @param followNFTURI The follow NFT URI to set.
     */
    function setFollowNFTURI(uint256 profileId, string calldata followNFTURI) external {
        _setFollowNFTURI(profileId, followNFTURI);
    }

    /**
     * @notice Sets the follow module for a given profile.
     *
     * @param profileId The profile ID to set the follow module for.
     * @param followModule The follow module to set for the given profile, if any.
     * @param followModuleInitData The data to pass to the follow module for profile initialization.
     */
    function setFollowModule(uint256 profileId, address followModule, bytes calldata followModuleInitData) external {
        StorageLib.getProfile(profileId).followModule = followModule;
        bytes memory followModuleReturnData;
        if (followModule != address(0)) {
            followModuleReturnData = _initFollowModule(profileId, msg.sender, followModule, followModuleInitData);
        }
        emit Events.FollowModuleSet(profileId, followModule, followModuleReturnData, block.timestamp);
    }

    function setProfileMetadataURI(uint256 profileId, string calldata metadataURI) external {
        StorageLib.getProfile(profileId).metadataURI = metadataURI;
        emit Events.ProfileMetadataSet(profileId, metadataURI, block.timestamp);
    }

    function _initFollowModule(
        uint256 profileId,
        address transactionExecutor,
        address followModule,
        bytes memory followModuleInitData
    ) private returns (bytes memory) {
        ValidationLib.validateFollowModuleWhitelisted(followModule);
        return IFollowModule(followModule).initializeFollowModule(profileId, transactionExecutor, followModuleInitData);
    }

    function _setProfileImageURI(uint256 profileId, string calldata imageURI) private {
        if (bytes(imageURI).length > MAX_PROFILE_IMAGE_URI_LENGTH) {
            revert Errors.ProfileImageURILengthInvalid();
        }
        StorageLib.getProfile(profileId).imageURI = imageURI;
        emit Events.ProfileImageURISet(profileId, imageURI, block.timestamp);
    }

    function _setFollowNFTURI(uint256 profileId, string calldata followNFTURI) private {
        StorageLib.getProfile(profileId).followNFTURI = followNFTURI;
        emit Events.FollowNFTURISet(profileId, followNFTURI, block.timestamp);
    }

    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus
    ) external {
        if (idsOfProfilesToSetBlockStatus.length != blockStatus.length) {
            revert Errors.ArrayMismatch();
        }
        address followNFT = StorageLib.getProfile(byProfileId).followNFT;
        uint256 i;
        uint256 idOfProfileToSetBlockStatus;
        bool blockedStatus;
        mapping(uint256 => bool) storage _blockedStatus = StorageLib.blockedStatus(byProfileId);
        while (i < idsOfProfilesToSetBlockStatus.length) {
            idOfProfileToSetBlockStatus = idsOfProfilesToSetBlockStatus[i];
            ValidationLib.validateProfileExists(idOfProfileToSetBlockStatus);
            if (byProfileId == idOfProfileToSetBlockStatus) {
                revert Errors.SelfBlock();
            }
            blockedStatus = blockStatus[i];
            if (followNFT != address(0) && blockedStatus) {
                bool hasUnfollowed = IFollowNFT(followNFT).processBlock(idOfProfileToSetBlockStatus);
                if (hasUnfollowed) {
                    emit Events.Unfollowed(idOfProfileToSetBlockStatus, byProfileId, block.timestamp);
                }
            }
            _blockedStatus[idOfProfileToSetBlockStatus] = blockedStatus;
            if (blockedStatus) {
                emit Events.Blocked(byProfileId, idOfProfileToSetBlockStatus, block.timestamp);
            } else {
                emit Events.Unblocked(byProfileId, idOfProfileToSetBlockStatus, block.timestamp);
            }
            unchecked {
                ++i;
            }
        }
    }

    function switchToNewFreshDelegatedExecutorsConfig(uint256 profileId) external {
        Types.DelegatedExecutorsConfig storage _delegatedExecutorsConfig = StorageLib.getDelegatedExecutorsConfig({
            delegatorProfileId: profileId
        });
        _changeDelegatedExecutorsConfig({
            _delegatedExecutorsConfig: _delegatedExecutorsConfig,
            delegatorProfileId: profileId,
            delegatedExecutors: new address[](0),
            approvals: new bool[](0),
            configNumber: _delegatedExecutorsConfig.maxConfigNumberSet + 1,
            switchToGivenConfig: true
        });
    }

    function changeCurrentDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals
    ) external {
        Types.DelegatedExecutorsConfig storage _delegatedExecutorsConfig = StorageLib.getDelegatedExecutorsConfig(
            delegatorProfileId
        );
        _changeDelegatedExecutorsConfig(
            _delegatedExecutorsConfig,
            delegatorProfileId,
            delegatedExecutors,
            approvals,
            _delegatedExecutorsConfig.configNumber,
            false
        );
    }

    function changeGivenDelegatedExecutorsConfig(
        uint256 delegatorProfileId,
        address[] calldata delegatedExecutors,
        bool[] calldata approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) external {
        _changeDelegatedExecutorsConfig(
            StorageLib.getDelegatedExecutorsConfig(delegatorProfileId),
            delegatorProfileId,
            delegatedExecutors,
            approvals,
            configNumber,
            switchToGivenConfig
        );
    }

    function isExecutorApproved(uint256 delegatorProfileId, address delegatedExecutor) external view returns (bool) {
        Types.DelegatedExecutorsConfig storage _delegatedExecutorsConfig = StorageLib.getDelegatedExecutorsConfig(
            delegatorProfileId
        );
        return _delegatedExecutorsConfig.isApproved[_delegatedExecutorsConfig.configNumber][delegatedExecutor];
    }

    function _changeDelegatedExecutorsConfig(
        Types.DelegatedExecutorsConfig storage _delegatedExecutorsConfig,
        uint256 delegatorProfileId,
        address[] memory delegatedExecutors,
        bool[] memory approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) private {
        if (delegatedExecutors.length != approvals.length) {
            revert Errors.ArrayMismatch();
        }
        bool configSwitched = _prepareStorageToApplyChangesUnderGivenConfig(
            _delegatedExecutorsConfig,
            configNumber,
            switchToGivenConfig
        );
        uint256 i;
        while (i < delegatedExecutors.length) {
            _delegatedExecutorsConfig.isApproved[configNumber][delegatedExecutors[i]] = approvals[i];
            unchecked {
                ++i;
            }
        }
        emit Events.DelegatedExecutorsConfigChanged(
            delegatorProfileId,
            configNumber,
            delegatedExecutors,
            approvals,
            configSwitched
        );
    }

    function _prepareStorageToApplyChangesUnderGivenConfig(
        Types.DelegatedExecutorsConfig storage _delegatedExecutorsConfig,
        uint64 configNumber,
        bool switchToGivenConfig
    ) private returns (bool) {
        uint64 nextAvailableConfigNumber = _delegatedExecutorsConfig.maxConfigNumberSet + 1;
        if (configNumber > nextAvailableConfigNumber) {
            revert Errors.InvalidParameter();
        }
        bool configSwitched;
        if (configNumber == nextAvailableConfigNumber) {
            // The next configuration available is being changed, it must be marked.
            // Otherwise, on a profile transfer, the next owner can inherit a used/dirty configuration.
            _delegatedExecutorsConfig.maxConfigNumberSet = nextAvailableConfigNumber;
            configSwitched = switchToGivenConfig;
            if (configSwitched) {
                // The configuration is being switched, previous and current configuration numbers must be updated.
                _delegatedExecutorsConfig.prevConfigNumber = _delegatedExecutorsConfig.configNumber;
                _delegatedExecutorsConfig.configNumber = nextAvailableConfigNumber;
            }
        } else {
            // The configuration corresponding to the given number is not a fresh/clean one.
            uint64 currentConfigNumber = _delegatedExecutorsConfig.configNumber;
            // If the given configuration matches the one that is already in use, we keep `configSwitched` as `false`.
            if (configNumber != currentConfigNumber) {
                configSwitched = switchToGivenConfig;
            }
            if (configSwitched) {
                // The configuration is being switched, previous and current configuration numbers must be updated.
                _delegatedExecutorsConfig.prevConfigNumber = currentConfigNumber;
                _delegatedExecutorsConfig.configNumber = configNumber;
            }
        }
        return configSwitched;
    }
}
