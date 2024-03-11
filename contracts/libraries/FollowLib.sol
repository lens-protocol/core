// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {ValidationLib} from './ValidationLib.sol';
import {Types} from './constants/Types.sol';
import {Errors} from './constants/Errors.sol';
import {Events} from './constants/Events.sol';
import {StorageLib} from './StorageLib.sol';
import {IFollowNFT} from '../interfaces/IFollowNFT.sol';
import {FollowNFTProxy} from '../base/upgradeability/FollowNFTProxy.sol';

library FollowLib {
    function follow(
        uint256 followerProfileId,
        address transactionExecutor,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata followModuleDatas
    ) external returns (uint256[] memory) {
        if (
            idsOfProfilesToFollow.length != followTokenIds.length ||
            idsOfProfilesToFollow.length != followModuleDatas.length
        ) {
            revert Errors.ArrayMismatch();
        }
        uint256[] memory followTokenIdsAssigned = new uint256[](idsOfProfilesToFollow.length);
        uint256 i;
        while (i < idsOfProfilesToFollow.length) {
            ValidationLib.validateProfileExists({profileId: idsOfProfilesToFollow[i]});

            ValidationLib.validateNotBlocked({
                profile: followerProfileId,
                byProfile: idsOfProfilesToFollow[i],
                unidirectionalCheck: true // We allow to follow a blocked profile. Rest of interactions are restricted.
            });

            if (followerProfileId == idsOfProfilesToFollow[i]) {
                revert Errors.SelfFollow();
            }

            followTokenIdsAssigned[i] = _follow({
                followerProfileId: followerProfileId,
                transactionExecutor: transactionExecutor,
                idOfProfileToFollow: idsOfProfilesToFollow[i],
                followTokenId: followTokenIds[i],
                followModuleData: followModuleDatas[i]
            });

            unchecked {
                ++i;
            }
        }
        return followTokenIdsAssigned;
    }

    function unfollow(
        uint256 unfollowerProfileId,
        address transactionExecutor,
        uint256[] calldata idsOfProfilesToUnfollow
    ) external {
        uint256 i;
        while (i < idsOfProfilesToUnfollow.length) {
            uint256 idOfProfileToUnfollow = idsOfProfilesToUnfollow[i];

            address followNFT = StorageLib.getProfile(idOfProfileToUnfollow).followNFT;

            // We don't validate the profile exists because we want to allow unfollowing a burnt profile.
            // Because, if the profile never existed, followNFT will be address(0) and the call will revert.
            if (followNFT == address(0)) {
                revert Errors.NotFollowing();
            }

            IFollowNFT(followNFT).unfollow(unfollowerProfileId);

            emit Events.Unfollowed(unfollowerProfileId, idOfProfileToUnfollow, transactionExecutor, block.timestamp);

            unchecked {
                ++i;
            }
        }
    }

    function isFollowing(uint256 followerProfileId, uint256 followedProfileId) internal view returns (bool) {
        address followNFT = StorageLib.getProfile(followedProfileId).followNFT;
        return followNFT != address(0) && IFollowNFT(followNFT).isFollowing(followerProfileId);
    }

    /**
     * @notice Deploys the given profile's Follow NFT contract.
     *
     * @param profileId The token ID of the profile which Follow NFT should be deployed.
     *
     * @return address The address of the deployed Follow NFT contract.
     */
    function _deployFollowNFT(uint256 profileId) private returns (address) {
        bytes memory functionData = abi.encodeCall(IFollowNFT.initialize, profileId);
        address followNFT = address(new FollowNFTProxy(functionData));
        emit Events.FollowNFTDeployed(profileId, followNFT, block.timestamp);

        return followNFT;
    }

    function _follow(
        uint256 followerProfileId,
        address transactionExecutor,
        uint256 idOfProfileToFollow,
        uint256 followTokenId,
        bytes calldata followModuleData
    ) private returns (uint256) {
        Types.Profile storage _profileToFollow = StorageLib.getProfile(idOfProfileToFollow);

        address followNFT = _profileToFollow.followNFT;
        if (followNFT == address(0)) {
            followNFT = _deployFollowNFT(idOfProfileToFollow);
            _profileToFollow.followNFT = followNFT;
        }

        return
            _processFollow(
                ProcessFollowParams({
                    followNFT: followNFT,
                    followerProfileId: followerProfileId,
                    transactionExecutor: transactionExecutor,
                    idOfProfileToFollow: idOfProfileToFollow,
                    followTokenId: followTokenId,
                    followModule: _profileToFollow.followModule,
                    followModuleData: followModuleData
                })
            );
    }

    // Struct defined for the sole purpose of avoiding 'stack too deep' error.
    struct ProcessFollowParams {
        address followNFT;
        uint256 followerProfileId;
        address transactionExecutor;
        uint256 idOfProfileToFollow;
        uint256 followTokenId;
        address followModule;
        bytes followModuleData;
    }

    function _processFollow(ProcessFollowParams memory processFollowParams) private returns (uint256) {
        uint256 followTokenIdAssigned = IFollowNFT(processFollowParams.followNFT).follow({
            followerProfileId: processFollowParams.followerProfileId,
            transactionExecutor: processFollowParams.transactionExecutor,
            followTokenId: processFollowParams.followTokenId
        });

        bytes memory processFollowModuleReturnData;
        if (processFollowParams.followModule != address(0)) {
            processFollowModuleReturnData = IFollowModule(processFollowParams.followModule).processFollow(
                processFollowParams.followerProfileId,
                processFollowParams.followTokenId,
                processFollowParams.transactionExecutor,
                processFollowParams.idOfProfileToFollow,
                processFollowParams.followModuleData
            );
        }

        emit Events.Followed(
            processFollowParams.followerProfileId,
            processFollowParams.idOfProfileToFollow,
            followTokenIdAssigned,
            processFollowParams.followModuleData,
            processFollowModuleReturnData,
            processFollowParams.transactionExecutor,
            block.timestamp
        );

        return followTokenIdAssigned;
    }
}
