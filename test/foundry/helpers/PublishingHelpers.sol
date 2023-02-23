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
        assertEq(pub.collectModule, expectedPub.collectModule, 'Unexpected collectModule');
        assertEq(pub.collectNFT, expectedPub.collectNFT, 'Unexpected collectNFT');
    }

    function _expectedPubFromInitData(Types.PostParams memory postParams)
        internal
        pure
        returns (Types.Publication memory)
    {
        return
            Types.Publication({
                pointedProfileId: 0,
                pointedPubId: 0,
                contentURI: postParams.contentURI,
                referenceModule: postParams.referenceModule,
                collectModule: postParams.collectModule,
                collectNFT: address(0),
                pubType: Types.PublicationType.Post,
                rootProfileId: 0,
                rootPubId: 0
            });
    }

    function _expectedPubFromInitData(Types.CommentParams memory commentParams)
        internal
        pure
        returns (Types.Publication memory)
    {
        return
            Types.Publication({
                pointedProfileId: commentParams.pointedProfileId,
                pointedPubId: commentParams.pointedPubId,
                contentURI: commentParams.contentURI,
                referenceModule: commentParams.referenceModule,
                collectModule: commentParams.collectModule,
                collectNFT: address(0),
                pubType: Types.PublicationType.Comment,
                rootProfileId: commentParams.pointedProfileId,
                rootPubId: commentParams.pointedPubId
            });
    }

    function _expectedPubFromInitData(Types.MirrorParams memory mirrorParams)
        internal
        pure
        returns (Types.Publication memory)
    {
        return
            Types.Publication({
                pointedProfileId: mirrorParams.pointedProfileId,
                pointedPubId: mirrorParams.pointedPubId,
                contentURI: '',
                referenceModule: address(0),
                collectModule: address(0),
                collectNFT: address(0),
                pubType: Types.PublicationType.Mirror,
                rootProfileId: mirrorParams.pointedProfileId,
                rootPubId: mirrorParams.pointedPubId
            });
    }
}
