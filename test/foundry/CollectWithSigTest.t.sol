// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import './base/BaseSigTest.t.sol';

contract CollectWithSigTest is BaseSigTest {
    function setUp() public override {
        super.setUp();
        vm.prank(profileOwner);
        hub.post(mockPostData);
    }

    // negatives
    function testCollectWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getCollectTypeDataHash(firstProfileId, 1, '', nonce, deadline);
        uint256 nftId = hub.collectWithSig(
            DataTypes.CollectWithSigData({
                collector: signer,
                profileId: firstProfileId,
                pubId: 1,
                data: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
        vm.expectRevert();
        CollectNFT nft = CollectNFT(hub.getCollectNFT(firstProfileId, 1));
        assertEq(nftId, 1);
        assertEq(nft.ownerOf(1), signer);
    }

    // positives
    function testCollectWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getCollectTypeDataHash(firstProfileId, 1, '', nonce, deadline);
        uint256 nftId = hub.collectWithSig(
            DataTypes.CollectWithSigData({
                collector: signer,
                profileId: firstProfileId,
                pubId: 1,
                data: '',
                sig: _getSigStruct(signerKey, digest, deadline)
            })
        );

        CollectNFT nft = CollectNFT(hub.getCollectNFT(firstProfileId, 1));
        assertEq(nftId, 1);
        assertEq(nft.ownerOf(1), signer);
    }

    function testExecutorCollectWithSig() public {
        vm.prank(signer);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getCollectTypeDataHash(firstProfileId, 1, '', nonce, deadline);
        uint256 nftId = hub.collectWithSig(
            DataTypes.CollectWithSigData({
                collector: signer,
                profileId: firstProfileId,
                pubId: 1,
                data: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );

        CollectNFT nft = CollectNFT(hub.getCollectNFT(firstProfileId, 1));
        assertEq(nftId, 1);
        assertEq(nft.ownerOf(1), signer);
    }

    // function testCollectWithSigMirror() public {
    //     assertEq(hub.getCollectNFT(1, 1), address(0));

    //     vm.prank(profileOwner);
    //     hub.mirror(
    //         DataTypes.MirrorData({
    //             profileId: firstProfileId,
    //             profileIdPointed: firstProfileId,
    //             pubIdPointed: 1,
    //             referenceModuleData: '',
    //             referenceModule: address(0),
    //             referenceModuleInitData: ''
    //         })
    //     );

    //     uint256 nftId = hub.collect(me, firstProfileId, 2, '');

    //     // Ensure the mirror doesn't have an associated collect NFT.
    //     assertEq(hub.getCollectNFT(firstProfileId, 2), address(0));

    //     // Ensure the original publication does have an associated collect NFT.
    //     CollectNFT nft = CollectNFT(hub.getCollectNFT(1, 1));
    //     assertEq(nftId, 1);
    //     assertEq(nft.ownerOf(1), me);
    // }

    // Meta-tx
    // function testCollectWithSigInvalidSignatureFails() public {}
}
