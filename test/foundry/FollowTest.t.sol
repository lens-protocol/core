// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import './helpers/SignatureHelpers.sol';

contract FollowTest is BaseTest, SignatureHelpers {
    using Strings for uint256;

    uint256 followerProfileId;

    function setUp() public virtual override {
        super.setUp();
        followerProfileId = _createProfile(me);
    }

    // Negatives
    // TODO

    // Positives
    function testFollow() public {
        assertEq(hub.getFollowNFT(newProfileId), address(0));

        uint256[] memory nftIds = _follow({
            msgSender: me,
            followerProfileId: followerProfileId,
            idOfProfileToFollow: newProfileId,
            followTokenId: 0,
            data: ''
        });

        FollowNFT nft = FollowNFT(hub.getFollowNFT(newProfileId));
        string memory expectedName = string(
            abi.encodePacked(newProfileId.toString(), FOLLOW_NFT_NAME_SUFFIX)
        );
        string memory expectedSymbol = string(
            abi.encodePacked(newProfileId.toString(), FOLLOW_NFT_SYMBOL_SUFFIX)
        );
        assertEq(nft.name(), expectedName);
        assertEq(nft.symbol(), expectedSymbol);
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.getFollowerProfileId(1), followerProfileId);
        assertEq(nft.getFollowTokenId(followerProfileId), 1);
    }

    function testExecutorFollow() public {
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256[] memory nftIds = _follow({
            msgSender: otherSigner,
            followerProfileId: followerProfileId,
            idOfProfileToFollow: newProfileId,
            followTokenId: 0,
            data: ''
        });

        FollowNFT nft = FollowNFT(hub.getFollowNFT(newProfileId));
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.getFollowerProfileId(1), followerProfileId);
        assertEq(nft.getFollowTokenId(followerProfileId), 1);
    }

    // Meta-tx
    // Negatives
    // TODO

    // Positives
    function testFollowWithSig() public {
        assertEq(hub.getFollowNFT(newProfileId), address(0));

        uint256[] memory profileIds = new uint256[](1);
        profileIds[0] = newProfileId;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        uint256 followerProfileId = _createProfile(otherSigner);
        bytes32 digest = _getFollowTypedDataHash(
            followerProfileId,
            profileIds,
            _toUint256Array(0),
            datas,
            nonce,
            deadline
        );

        uint256[] memory nftIds = _followWithSig(
            DataTypes.FollowWithSigData({
                delegatedSigner: address(0),
                followerProfileId: followerProfileId,
                idsOfProfilesToFollow: profileIds,
                followTokenIds: _toUint256Array(0),
                datas: datas,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );

        FollowNFT nft = FollowNFT(hub.getFollowNFT(newProfileId));
        string memory expectedName = string(
            abi.encodePacked(newProfileId.toString(), FOLLOW_NFT_NAME_SUFFIX)
        );
        string memory expectedSymbol = string(
            abi.encodePacked(newProfileId.toString(), FOLLOW_NFT_SYMBOL_SUFFIX)
        );
        assertEq(nft.name(), expectedName);
        assertEq(nft.symbol(), expectedSymbol);
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.getFollowerProfileId(1), followerProfileId);
        assertEq(nft.getFollowTokenId(followerProfileId), 1);
    }

    function testExecutorFollowWithSig() public {
        vm.prank(otherSigner);
        hub.setDelegatedExecutorApproval(profileOwner, true);

        uint256[] memory profileIds = new uint256[](1);
        profileIds[0] = newProfileId;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        uint256 followerProfileId = _createProfile(otherSigner);
        bytes32 digest = _getFollowTypedDataHash(
            followerProfileId,
            profileIds,
            _toUint256Array(0),
            datas,
            nonce,
            deadline
        );
        uint256[] memory nftIds = _followWithSig(
            DataTypes.FollowWithSigData({
                delegatedSigner: profileOwner,
                followerProfileId: followerProfileId,
                idsOfProfilesToFollow: profileIds,
                followTokenIds: _toUint256Array(0),
                datas: datas,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );

        FollowNFT nft = FollowNFT(hub.getFollowNFT(newProfileId));
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.getFollowerProfileId(1), followerProfileId);
        assertEq(nft.getFollowTokenId(followerProfileId), 1);
    }
}
