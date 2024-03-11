// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ILensHub} from '../../interfaces/ILensHub.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {CollectPublicationAction} from '../../modules/act/collect/CollectPublicationAction.sol';

/**
 * @title LitAccessControl
 * @author Lens Protocol
 *
 * @notice This contract enables additional access control for encrypted publications on Lens by reporting whether
 *      an address owns or has control over a given profile.
 *
 * @custom:upgradeable Transparent upgradeable proxy without initializer.
 */
contract LitAccessControl {
    address internal immutable LENS_HUB;
    address internal immutable COLLECT_PUB_ACTION;

    constructor(address lensHub, address collectPubAction) {
        LENS_HUB = lensHub;
        COLLECT_PUB_ACTION = collectPubAction;
    }

    /**
     * @dev Function used to check whether an address is the Owner or Delegated Executor of a profile.
     *
     * @param requestorAddress The address to check ownership over a profile.
     * @param profileId The ID of the profile being checked for ownership.
     * param data Optional data parameter, which may be used in future upgrades.
     * @return Boolean indicating whether address owns the profile or not.
     */
    function hasAccess(
        address requestorAddress,
        uint256 profileId,
        bytes memory /* data */
    ) external view returns (bool) {
        return _isOwnerOrDelegatedExecutor(requestorAddress, profileId);
    }

    /**
     * @dev Function used to check whether followerProfileId is following profileId and requestor is Owner/Delegated
     * Executor of followerProfileId.
     *
     * @param requestorAddress The address to check ownership over a profile.
     * @param profileId The ID of the profile being followed.
     * @param followerProfileId The ID of the following profile.
     * param data Optional data parameter, which may be used in future upgrades.
     */
    function isFollowing(
        address requestorAddress,
        uint256 profileId,
        uint256 followerProfileId,
        bytes memory /*data*/
    ) external view returns (bool) {
        if (
            // If profile is following and requestor is Owner/Delegated Executor of the follower profile, allow access
            ILensHub(LENS_HUB).isFollowing(followerProfileId, profileId) &&
            _isOwnerOrDelegatedExecutor(requestorAddress, followerProfileId)
        ) {
            return true;
        } else {
            // If not following, but is the Owner/Delegated Executor of the target profile, then still allow access
            return _isOwnerOrDelegatedExecutor(requestorAddress, profileId);
        }
    }

    /**
     * @dev Function used to check whether an address owns or has collected the publication.
     *
     * @param requestorAddress The address to check if it owns the collect NFT of the publication.
     * @param publisherId ID of the profile who is the publisher of the publication.
     * @param pubId ID of the publication.
     * @param collectorProfileId ID of the collector profile (optional, will check if the profile owner owns the NFT)
     * param data Optional data parameter, which may be used in future upgrades.
     * @return Boolean indicating whether address owns the collect NFT of the publication or not.
     */
    function hasCollected(
        address requestorAddress,
        uint256 publisherId,
        uint256 pubId,
        uint256 collectorProfileId,
        bytes memory /* data */
    ) external view returns (bool) {
        // We get the collect NFT as if the publication is a Lens V2 one
        address collectNFT = CollectPublicationAction(COLLECT_PUB_ACTION).getCollectData(publisherId, pubId).collectNFT;

        if (collectNFT == address(0)) {
            // If there is no collect NFT, we get the collect NFT of the publication as a Lens V1 one
            collectNFT = ILensHub(LENS_HUB).getPublication(publisherId, pubId).__DEPRECATED__collectNFT;
            if (collectNFT == address(0)) {
                // If no collect NFT found in V1 nor V2, that means the publication was not collected
                return false;
            }
        }

        // We check if the requestor address has the collect NFT
        if (IERC721(collectNFT).balanceOf(requestorAddress) > 0) {
            return true;
        }

        // If the requestor address doesn't have the collect NFT,
        // we check if the requestor address is the Owner/Delegated Executor of the collector profile,
        // and then we check if the collector profile's owner holds the NFT
        if (!_isOwnerOrDelegatedExecutor(requestorAddress, collectorProfileId)) {
            return false;
        }
        return IERC721(collectNFT).balanceOf(IERC721(LENS_HUB).ownerOf(collectorProfileId)) > 0;
    }

    /**
     * @dev Internal function used to check whether an address is the Owner or DelegatedExecutor of a profile.
     *
     * @param requestorAddress The address to check ownership over a profile.
     * @param profileId The ID of the profile being checked for ownership.
     * @return Boolean indicating whether address owns the profile or is DelegatedExecutor of it.
     */
    function _isOwnerOrDelegatedExecutor(address requestorAddress, uint256 profileId) internal view returns (bool) {
        return
            requestorAddress == IERC721(LENS_HUB).ownerOf(profileId) ||
            ILensHub(LENS_HUB).isDelegatedExecutorApproved(profileId, requestorAddress);
    }
}
