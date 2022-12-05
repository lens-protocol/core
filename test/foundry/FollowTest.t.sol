// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import './helpers/SignatureHelpers.sol';

contract FollowTest is BaseTest, SignatureHelpers {
    using Strings for uint256;

    // Negatives
    function testFollowNotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _follow({msgSender: otherSigner, onBehalfOf: me, profileId: newProfileId, data: ''});
    }

    // Positives
    function testFollow() public {
        assertEq(hub.getFollowNFT(newProfileId), address(0));

        uint256[] memory nftIds = _follow({
            msgSender: me,
            onBehalfOf: me,
            profileId: newProfileId,
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
        assertEq(nft.ownerOf(1), me);
    }

    function testExecutorFollow() public {
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256[] memory nftIds = _follow({
            msgSender: otherSigner,
            onBehalfOf: me,
            profileId: newProfileId,
            data: ''
        });

        FollowNFT nft = FollowNFT(hub.getFollowNFT(newProfileId));
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.ownerOf(1), me);
    }

    // Meta-tx
    // Negatives
    function testFollowWithSigInvalidSignerFails() public {
        uint256[] memory profileIds = new uint256[](1);
        profileIds[0] = newProfileId;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getFollowTypedDataHash(profileIds, datas, nonce, deadline);

        vm.expectRevert(Errors.SignatureInvalid.selector);
        _followWithSig(
            _buildFollowWithSigData({
                delegatedSigner: address(0),
                follower: profileOwner,
                profileIds: profileIds,
                datas: datas,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testFollowWithSigNotExecutorFails() public {
        uint256[] memory profileIds = new uint256[](1);
        profileIds[0] = newProfileId;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getFollowTypedDataHash(profileIds, datas, nonce, deadline);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _followWithSig(
            _buildFollowWithSigData({
                delegatedSigner: otherSigner,
                follower: profileOwner,
                profileIds: profileIds,
                datas: datas,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    // Positives
    function testFollowWithSig() public {
        assertEq(hub.getFollowNFT(newProfileId), address(0));

        uint256[] memory profileIds = new uint256[](1);
        profileIds[0] = newProfileId;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getFollowTypedDataHash(profileIds, datas, nonce, deadline);

        uint256[] memory nftIds = _followWithSig(
            _buildFollowWithSigData({
                delegatedSigner: address(0),
                follower: otherSigner,
                profileIds: profileIds,
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
        assertEq(nft.ownerOf(1), otherSigner);
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
        bytes32 digest = _getFollowTypedDataHash(profileIds, datas, nonce, deadline);

        uint256[] memory nftIds = _followWithSig(
            _buildFollowWithSigData({
                delegatedSigner: profileOwner,
                follower: otherSigner,
                profileIds: profileIds,
                datas: datas,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );

        FollowNFT nft = FollowNFT(hub.getFollowNFT(newProfileId));
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.ownerOf(1), otherSigner);
    }
}
