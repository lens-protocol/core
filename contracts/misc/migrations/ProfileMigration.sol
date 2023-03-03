// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {LensHub} from 'contracts/LensHub.sol';
import {LensHandles} from 'contracts/misc/namespaces/LensHandles.sol';
import {TokenHandleRegistry} from 'contracts/misc/namespaces/TokenHandleRegistry.sol';

struct ProfileMigrationData {
    uint256 profileId;
    address profileDestination;
    string handle;
    bytes32 handleHash;
}

contract ProfileMigration is Ownable {
    LensHub public immutable lensHub;
    LensHandles public immutable lensHandles;
    TokenHandleRegistry public immutable tokenHandleRegistry;

    event ProfileMigrated(uint256 profileId, address profileDestination, string handle, uint256 handleId);

    constructor(
        address ownerAddress,
        address lensHubAddress,
        address lensHandlesAddress,
        address tokenHandleRegistryAddress
    ) {
        Ownable._transferOwnership(ownerAddress);
        lensHub = LensHub(lensHubAddress);
        lensHandles = LensHandles(lensHandlesAddress);
        tokenHandleRegistry = TokenHandleRegistry(tokenHandleRegistryAddress);
    }

    // TODO: Assume we pause everything - creating, transfer, etc.
    function _migrateProfile(ProfileMigrationData calldata profileMigrationData) internal {
        lensHub.migrateProfile(profileMigrationData.profileId, profileMigrationData.handleHash);
        uint256 handleId = lensHandles.mintHandle(profileMigrationData.profileDestination, profileMigrationData.handle);
        tokenHandleRegistry.migrationLinkHandleWithToken(handleId, profileMigrationData.profileId);
        emit ProfileMigrated(
            profileMigrationData.profileId,
            profileMigrationData.profileDestination,
            profileMigrationData.handle,
            handleId
        );
    }

    function batchMigrateProfiles(ProfileMigrationData[] calldata profileMigrationDatas) external onlyOwner {
        for (uint256 i = 0; i < profileMigrationDatas.length; i++) {
            _migrateProfile(profileMigrationDatas[i]);
        }
    }
}
