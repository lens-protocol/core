// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ValidationLib} from './ValidationLib.sol';
import {Types} from './constants/Types.sol';
import {Errors} from './constants/Errors.sol';
import {Events} from './constants/Events.sol';
import {StorageLib} from './StorageLib.sol';
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {IFollowNFT} from '../interfaces/IFollowNFT.sol';
import {IModuleRegistry} from '../interfaces/IModuleRegistry.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';

library ProfileLib {
    function MODULE_REGISTRY() internal view returns (IModuleRegistry) {
        return IModuleRegistry(ILensHub(address(this)).getModuleRegistry());
    }

    function ownerOf(uint256 profileId) internal view returns (address) {
        address profileOwner = StorageLib.getTokenData(profileId).owner;
        if (profileOwner == address(0)) {
            revert Errors.TokenDoesNotExist();
        }
        return profileOwner;
    }

    function exists(uint256 profileId) internal view returns (bool) {
        return StorageLib.getTokenData(profileId).owner != address(0);
    }

    /**
     * @notice Creates a profile with the given parameters to the given address. Minting happens
     * in the hub.
     *
     * @param createProfileParams The CreateProfileParams struct containing the following parameters:
     *      to: The address receiving the profile.
     *      followModule: The follow module to use, can be the zero address.
     *      followModuleInitData: The follow module initialization data, if any
     * @param profileId The profile ID to associate with this profile NFT (token ID).
     */
    function createProfile(Types.CreateProfileParams calldata createProfileParams, uint256 profileId) external {
        emit Events.ProfileCreated(profileId, msg.sender, createProfileParams.to, block.timestamp);
        emit Events.DelegatedExecutorsConfigApplied(profileId, 0, block.timestamp);
        _setFollowModule(
            profileId,
            createProfileParams.followModule,
            createProfileParams.followModuleInitData,
            msg.sender // Sender accounts for any initialization requirements (e.g. pay fees, stake asset, etc.).
        );
    }

    /**
     * @notice Sets the follow module for a given profile.
     *
     * @param profileId The profile ID to set the follow module for.
     * @param followModule The follow module to set for the given profile, if any.
     * @param followModuleInitData The data to pass to the follow module for profile initialization.
     */
    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData,
        address transactionExecutor
    ) external {
        _setFollowModule(profileId, followModule, followModuleInitData, transactionExecutor);
    }

    function setProfileMetadataURI(
        uint256 profileId,
        string calldata metadataURI,
        address transactionExecutor
    ) external {
        StorageLib.getProfile(profileId).metadataURI = metadataURI;
        emit Events.ProfileMetadataSet(profileId, metadataURI, transactionExecutor, block.timestamp);
    }

    function _initFollowModule(
        uint256 profileId,
        address transactionExecutor,
        address followModule,
        bytes memory followModuleInitData
    ) private returns (bytes memory) {
        MODULE_REGISTRY().verifyModule(followModule, uint256(IModuleRegistry.ModuleType.FOLLOW_MODULE));
        return IFollowModule(followModule).initializeFollowModule(profileId, transactionExecutor, followModuleInitData);
    }

    function setBlockStatus(
        uint256 byProfileId,
        uint256[] calldata idsOfProfilesToSetBlockStatus,
        bool[] calldata blockStatus,
        address transactionExecutor
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
                    emit Events.Unfollowed(
                        idOfProfileToSetBlockStatus,
                        byProfileId,
                        transactionExecutor,
                        block.timestamp
                    );
                }
            }
            _blockedStatus[idOfProfileToSetBlockStatus] = blockedStatus;
            if (blockedStatus) {
                emit Events.Blocked(byProfileId, idOfProfileToSetBlockStatus, transactionExecutor, block.timestamp);
            } else {
                emit Events.Unblocked(byProfileId, idOfProfileToSetBlockStatus, transactionExecutor, block.timestamp);
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

    function changeDelegatedExecutorsConfig(
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
            block.timestamp
        );
        if (configSwitched) {
            emit Events.DelegatedExecutorsConfigApplied(delegatorProfileId, configNumber, block.timestamp);
        }
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

    function _setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData,
        address transactionExecutor
    ) private {
        StorageLib.getProfile(profileId).followModule = followModule;
        bytes memory followModuleReturnData;
        if (followModule != address(0)) {
            followModuleReturnData = _initFollowModule(
                profileId,
                transactionExecutor,
                followModule,
                followModuleInitData
            );
        }
        emit Events.FollowModuleSet(
            profileId,
            followModule,
            followModuleInitData,
            followModuleReturnData,
            transactionExecutor,
            block.timestamp
        );
    }
}
