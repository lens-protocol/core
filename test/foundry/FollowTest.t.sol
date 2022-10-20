// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract FollowTest is BaseTest {
    // Negatives
    function testFollowNotExecutorFails() public {
        vm.prank(otherSigner);
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.follow(me, _toUint256Array(firstProfileId), _toBytesArray(''));
    }

    // Positives
    function testFollow() public {
        assertEq(hub.getFollowNFT(firstProfileId), address(0));

        uint256[] memory nftIds = hub.follow(
            me,
            _toUint256Array(firstProfileId),
            _toBytesArray('')
        );

        FollowNFT nft = FollowNFT(hub.getFollowNFT(firstProfileId));
        // string memory expectedName = string(abi.encodePacked(mockHandle, FOLLOW_NFT_NAME_SUFFIX));
        // string memory expectedSymbol = string(
            // abi.encodePacked(bytes4(bytes(mockHandle)), FOLLOW_NFT_SYMBOL_SUFFIX)
        // );
        // assertEq(nft.name(), expectedName);
        // assertEq(nft.symbol(), expectedSymbol);
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.ownerOf(1), me);
    }

    function testExecutorFollow() public {
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        uint256[] memory nftIds = hub.follow(
            me,
            _toUint256Array(firstProfileId),
            _toBytesArray('')
        );

        FollowNFT nft = FollowNFT(hub.getFollowNFT(firstProfileId));
        // string memory expectedName = string(abi.encodePacked(mockHandle, FOLLOW_NFT_NAME_SUFFIX));
        // string memory expectedSymbol = string(
            // abi.encodePacked(bytes4(bytes(mockHandle)), FOLLOW_NFT_SYMBOL_SUFFIX)
        // );
        // assertEq(nft.name(), expectedName);
        // assertEq(nft.symbol(), expectedSymbol);
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.ownerOf(1), me);
    }

    // Meta-tx
    // Negatives
    function testFollowWithSigInvalidSignerFails() public {
        uint256[] memory profileIds = new uint256[](1);
        profileIds[0] = firstProfileId;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getFollowTypedDataHash(profileIds, datas, nonce, deadline);

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.followWithSig(
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
        profileIds[0] = firstProfileId;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getFollowTypedDataHash(profileIds, datas, nonce, deadline);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.followWithSig(
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
        assertEq(hub.getFollowNFT(firstProfileId), address(0));

        uint256[] memory profileIds = new uint256[](1);
        profileIds[0] = firstProfileId;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getFollowTypedDataHash(profileIds, datas, nonce, deadline);

        uint256[] memory nftIds = hub.followWithSig(
            _buildFollowWithSigData({
                delegatedSigner: address(0),
                follower: otherSigner,
                profileIds: profileIds,
                datas: datas,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );

        FollowNFT nft = FollowNFT(hub.getFollowNFT(firstProfileId));
        // string memory expectedName = string(abi.encodePacked(mockHandle, FOLLOW_NFT_NAME_SUFFIX));
        // string memory expectedSymbol = string(
        //     // abi.encodePacked(bytes4(bytes(mockHandle)), FOLLOW_NFT_SYMBOL_SUFFIX)
        // // );
        // assertEq(nft.name(), expectedName);
        // assertEq(nft.symbol(), expectedSymbol);
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.ownerOf(1), otherSigner);
    }

    function testExecutorFollowWithSig() public {
        vm.prank(otherSigner);
        hub.setDelegatedExecutorApproval(profileOwner, true);

        uint256[] memory profileIds = new uint256[](1);
        profileIds[0] = firstProfileId;
        bytes[] memory datas = new bytes[](1);
        datas[0] = '';
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getFollowTypedDataHash(profileIds, datas, nonce, deadline);

        uint256[] memory nftIds = hub.followWithSig(
            _buildFollowWithSigData({
                delegatedSigner: profileOwner,
                follower: otherSigner,
                profileIds: profileIds,
                datas: datas,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );

        FollowNFT nft = FollowNFT(hub.getFollowNFT(firstProfileId));
        // string memory expectedName = string(abi.encodePacked(mockHandle, FOLLOW_NFT_NAME_SUFFIX));
        // string memory expectedSymbol = string(
            // abi.encodePacked(bytes4(bytes(mockHandle)), FOLLOW_NFT_SYMBOL_SUFFIX)
        // );
        // assertEq(nft.name(), expectedName);
        // assertEq(nft.symbol(), expectedSymbol);
        assertEq(nftIds.length, 1);
        assertEq(nftIds[0], 1);
        assertEq(nft.ownerOf(1), otherSigner);
    }

    // Private functions
    function _buildFollowWithSigData(
        address delegatedSigner,
        address follower,
        uint256[] memory profileIds,
        bytes[] memory datas,
        DataTypes.EIP712Signature memory sig
    ) private pure returns (DataTypes.FollowWithSigData memory) {
        return DataTypes.FollowWithSigData(delegatedSigner, follower, profileIds, datas, sig);
    }
}
