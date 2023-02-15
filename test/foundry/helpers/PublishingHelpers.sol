// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import 'contracts/libraries/DataTypes.sol';

contract PublishingHelpers is Test {
    function _verifyPublication(
        DataTypes.PublicationStruct memory pub,
        DataTypes.PublicationStruct memory expectedPub
    ) internal {
        assertEq(pub.profileIdPointed, expectedPub.profileIdPointed, 'Unexpected profileIdPointed');
        assertEq(pub.pubIdPointed, expectedPub.pubIdPointed, 'Unexpected pubIdPointed');
        assertEq(pub.contentURI, expectedPub.contentURI, 'Unexpected contentURI');
        assertEq(pub.referenceModule, expectedPub.referenceModule, 'Unexpected referenceModule');
        assertEq(pub.collectModule, expectedPub.collectModule, 'Unexpected collectModule');
        assertEq(pub.collectNFT, expectedPub.collectNFT, 'Unexpected collectNFT');
    }

    function _expectedPubFromInitData(DataTypes.PostData memory postData)
        internal
        pure
        returns (DataTypes.PublicationStruct memory)
    {
        return
            DataTypes.PublicationStruct({
                profileIdPointed: 0,
                pubIdPointed: 0,
                contentURI: postData.contentURI,
                referenceModule: postData.referenceModule,
                collectModule: postData.collectModule,
                collectNFT: address(0)
            });
    }

    function _expectedPubFromInitData(DataTypes.CommentData memory commentData)
        internal
        pure
        returns (DataTypes.PublicationStruct memory)
    {
        return
            DataTypes.PublicationStruct({
                profileIdPointed: commentData.profileIdPointed,
                pubIdPointed: commentData.pubIdPointed,
                contentURI: commentData.contentURI,
                referenceModule: commentData.referenceModule,
                collectModule: commentData.collectModule,
                collectNFT: address(0)
            });
    }

    function _expectedPubFromInitData(DataTypes.MirrorData memory mirrorData)
        internal
        pure
        returns (DataTypes.PublicationStruct memory)
    {
        return
            DataTypes.PublicationStruct({
                profileIdPointed: mirrorData.profileIdPointed,
                pubIdPointed: mirrorData.pubIdPointed,
                contentURI: '',
                referenceModule: address(0),
                collectModule: address(0),
                collectNFT: address(0)
            });
    }
}
