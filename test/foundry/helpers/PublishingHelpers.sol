// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import 'contracts/libraries/constants/Types.sol';

contract PublishingHelpers is Test {
    function _verifyPublication(Types.Publication memory pub, Types.Publication memory expectedPub) internal {
        assertEq(pub.pointedProfileId, expectedPub.pointedProfileId, 'Unexpected pointedProfileId');
        assertEq(pub.pointedPubId, expectedPub.pointedPubId, 'Unexpected pointedPubId');
        assertEq(pub.contentURI, expectedPub.contentURI, 'Unexpected contentURI');
        assertEq(pub.referenceModule, expectedPub.referenceModule, 'Unexpected referenceModule');
        // TODO: Proper tests
        // assertEq(pub.actionModules, expectedPub.actionModules, 'Unexpected collectModule');
        // assertEq(pub.collectNFT, expectedPub.collectNFT, 'Unexpected collectNFT');
    }

    function _expectedPubFromInitData(
        Types.PostParams memory postParams
    ) internal pure returns (Types.Publication memory) {
        return
            Types.Publication({
                pointedProfileId: 0,
                pointedPubId: 0,
                contentURI: postParams.contentURI,
                referenceModule: postParams.referenceModule,
                __DEPRECATED__collectModule: address(0),
                __DEPRECATED__collectNFT: address(0),
                pubType: Types.PublicationType.Post,
                rootProfileId: 0,
                rootPubId: 0,
                actionModulesBitmap: 0 // TODO: Proper mock
            });
    }

    function _expectedPubFromInitData(
        Types.CommentParams memory commentParams
    ) internal pure returns (Types.Publication memory) {
        return
            Types.Publication({
                pointedProfileId: commentParams.pointedProfileId,
                pointedPubId: commentParams.pointedPubId,
                contentURI: commentParams.contentURI,
                referenceModule: commentParams.referenceModule,
                __DEPRECATED__collectModule: address(0),
                __DEPRECATED__collectNFT: address(0),
                pubType: Types.PublicationType.Comment,
                rootProfileId: commentParams.pointedProfileId,
                rootPubId: commentParams.pointedPubId,
                actionModulesBitmap: 0 // TODO: Proper mock
            });
    }

    function _expectedPubFromInitData(
        Types.MirrorParams memory mirrorParams
    ) internal pure returns (Types.Publication memory) {
        return
            Types.Publication({
                pointedProfileId: mirrorParams.pointedProfileId,
                pointedPubId: mirrorParams.pointedPubId,
                contentURI: '',
                referenceModule: address(0),
                __DEPRECATED__collectModule: address(0),
                __DEPRECATED__collectNFT: address(0),
                pubType: Types.PublicationType.Mirror,
                rootProfileId: mirrorParams.pointedProfileId,
                rootPubId: mirrorParams.pointedPubId,
                actionModulesBitmap: 0
            });
    }
}
