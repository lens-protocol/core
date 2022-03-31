// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {Helpers} from './Helpers.sol';
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
import {IFollowNFT} from '../interfaces/IFollowNFT.sol';
import {ICollectNFT} from '../interfaces/ICollectNFT.sol';
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

/**
 * @title InteractionLogic
 * @author Lens Protocol
 *
 * @notice This is the library that contains the logic for follows & collects. 
 
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */
library InteractionLogic {
    using Strings for uint256;

    /**
     * @notice Follows the given profiles, executing the necessary logic and module calls before minting the follow
     * NFT(s) to the follower.
     *
     * @param follower The address executing the follow.
     * @param profileIds The array of profile token IDs to follow.
     * @param followModuleDatas The array of follow module data parameters to pass to each profile's follow module.
     * @param followNFTImpl The address of the follow NFT implementation, which has to be passed because it's an immutable in the hub.
     * @param _profileById A pointer to the storage mapping of profile structs by profile ID.
     * @param _profileIdByHandleHash A pointer to the storage mapping of profile IDs by handle hash.
     */
    function follow(
        address follower,
        uint256[] calldata profileIds,
        bytes[] calldata followModuleDatas,
        address followNFTImpl,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
        mapping(bytes32 => uint256) storage _profileIdByHandleHash
    ) external {
        if (profileIds.length != followModuleDatas.length) revert Errors.ArrayMismatch();
        for (uint256 i = 0; i < profileIds.length; ++i) {
            string memory handle = _profileById[profileIds[i]].handle;
            if (_profileIdByHandleHash[keccak256(bytes(handle))] != profileIds[i])
                revert Errors.TokenDoesNotExist();

            address followModule = _profileById[profileIds[i]].followModule;

            address followNFT = _profileById[profileIds[i]].followNFT;

            if (followNFT == address(0)) {
                followNFT = Clones.clone(followNFTImpl);
                _profileById[profileIds[i]].followNFT = followNFT;

                bytes4 firstBytes = bytes4(bytes(handle));

                string memory followNFTName = string(
                    abi.encodePacked(handle, Constants.FOLLOW_NFT_NAME_SUFFIX)
                );
                string memory followNFTSymbol = string(
                    abi.encodePacked(firstBytes, Constants.FOLLOW_NFT_SYMBOL_SUFFIX)
                );

                IFollowNFT(followNFT).initialize(profileIds[i], followNFTName, followNFTSymbol);
                emit Events.FollowNFTDeployed(profileIds[i], followNFT, block.timestamp);
            }

            IFollowNFT(followNFT).mint(follower);

            if (followModule != address(0)) {
                IFollowModule(followModule).processFollow(
                    follower,
                    profileIds[i],
                    followModuleDatas[i]
                );
            }
        }
    }

    /**
     * @notice Collects the given publication, executing the necessary logic and module call before minting the
     * collect NFT to the collector.
     *
     * @param collector The address executing the collect.
     * @param profileId The token ID of the publication being collected's parent profile.
     * @param pubId The publication ID of the publication being collected.
     * @param collectModuleData The data to pass to the publication's collect module.
     * @param collectNFTImpl The address of the collect NFT implementation, which has to be passed because it's an immutable in the hub.
     * @param _pubByIdByProfile A pointer to the storage mapping of publications by pubId by profile ID.
     * @param _profileById A pointer to the storage mapping of profile structs by profile ID.
     */
    function collect(
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata collectModuleData,
        address collectNFTImpl,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById
    ) external {
        (uint256 rootProfileId, uint256 rootPubId, address rootCollectModule) = Helpers
            .getPointedIfMirror(profileId, pubId, _pubByIdByProfile);

        address collectNFT = _pubByIdByProfile[rootProfileId][rootPubId].collectNFT;

        if (collectNFT == address(0)) {
            collectNFT = Clones.clone(collectNFTImpl);
            _pubByIdByProfile[rootProfileId][rootPubId].collectNFT = collectNFT;

            string memory handle = _profileById[rootProfileId].handle;
            bytes4 firstBytes = bytes4(bytes(handle));

            string memory collectNFTName = string(
                abi.encodePacked(handle, Constants.COLLECT_NFT_NAME_INFIX, rootPubId.toString())
            );
            string memory collectNFTSymbol = string(
                abi.encodePacked(
                    firstBytes,
                    Constants.COLLECT_NFT_SYMBOL_INFIX,
                    rootPubId.toString()
                )
            );

            ICollectNFT(collectNFT).initialize(
                rootProfileId,
                rootPubId,
                collectNFTName,
                collectNFTSymbol
            );
            emit Events.CollectNFTDeployed(rootProfileId, rootPubId, collectNFT, block.timestamp);
        }

        ICollectNFT(collectNFT).mint(collector);

        ICollectModule(rootCollectModule).processCollect(
            profileId,
            collector,
            rootProfileId,
            rootPubId,
            collectModuleData
        );
        emit Events.Collected(
            collector,
            profileId,
            pubId,
            rootProfileId,
            rootPubId,
            block.timestamp
        );
    }
}
