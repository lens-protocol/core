// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILegacyCollectModule} from 'contracts/interfaces/ILegacyCollectModule.sol';
import {MockModule} from 'test/mocks/MockModule.sol';

interface ILensHub {
    function getFollowModule(uint256 profileId) external view returns (address);

    function getFollowNFT(uint256 profileId) external view returns (address);
}

interface IFollowModule {
    function isFollowing(uint256 profileId, address follower, uint256 followNFTTokenId) external view returns (bool);
}

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract MockDeprecatedCollectModuleFollowerOnly is MockModule, ILegacyCollectModule {
    function testMockDeprecatedCollectModuleFollowerOnly() public {
        // Prevents being counted in Foundry Coverage
    }

    address immutable HUB;

    error FollowInvalid();

    constructor(address lensHub, address moduleOwner) MockModule(moduleOwner) {
        HUB = lensHub;
    }

    function initializePublicationCollectModule(
        uint256,
        uint256,
        bytes calldata data
    ) external pure override returns (bytes memory) {
        _decodeFlagAndRevertIfFalse(data);
        return '';
    }

    function processCollect(
        uint256 /* referrerProfileId */,
        address collector,
        uint256 profileId,
        uint256 /* pubId */,
        bytes calldata data
    ) external view override {
        _decodeFlagAndRevertIfFalse(data);
        _checkFollowValidity(profileId, collector);
    }

    function _checkFollowValidity(uint256 profileId, address user) internal view {
        address followModule = ILensHub(HUB).getFollowModule(profileId);
        bool isFollowing;
        if (followModule != address(0)) {
            isFollowing = IFollowModule(followModule).isFollowing(profileId, user, 0);
        } else {
            address followNFT = ILensHub(HUB).getFollowNFT(profileId);
            isFollowing = followNFT != address(0) && IERC721(followNFT).balanceOf(user) != 0;
        }
        if (!isFollowing && IERC721(HUB).ownerOf(profileId) != user) {
            revert FollowInvalid();
        }
    }
}
