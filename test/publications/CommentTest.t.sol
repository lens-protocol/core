// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest, ReferencePublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';

contract CommentTest is ReferencePublicationTest {
    function testCommentTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override {
        super.setUp();
        mockCommentParams.profileId = publisher.profileId;
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        mockCommentParams.profileId = publisherProfileId;
        vm.prank(vm.addr(signerPk));
        return hub.comment(mockCommentParams);
    }

    function _setPointedPub(uint256 pointedProfileId, uint256 pointedPubId) internal virtual override {
        mockCommentParams.pointedProfileId = pointedProfileId;
        mockCommentParams.pointedPubId = pointedPubId;
    }

    function _pubType() internal virtual override returns (Types.PublicationType) {
        return Types.PublicationType.Comment;
    }

    function _setReferrers(
        uint256[] memory referrerProfileIds,
        uint256[] memory referrerPubIds
    ) internal virtual override {
        mockCommentParams.referrerProfileIds = referrerProfileIds;
        mockCommentParams.referrerPubIds = referrerPubIds;
    }

    function _setReferenceModuleData(bytes memory referenceModuleData) internal virtual override {
        mockCommentParams.referenceModuleData = referenceModuleData;
    }
}

contract CommentMetaTxTest is CommentTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function testCommentMetaTxTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override(CommentTest, MetaTxNegatives) {
        CommentTest.setUp();
        MetaTxNegatives.setUp();
        cachedNonceByAddress[profileOwner] = _getSigNonce(profileOwner);
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        mockCommentParams.profileId = publisherProfileId;
        address signer = vm.addr(signerPk);
        return
            hub.commentWithSig(
                mockCommentParams,
                _getSigStruct({
                    signer: signer,
                    pKey: signerPk,
                    digest: _getCommentTypedDataHash({
                        commentParams: mockCommentParams,
                        nonce: cachedNonceByAddress[signer],
                        deadline: type(uint256).max
                    }),
                    deadline: type(uint256).max
                })
            );
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        hub.commentWithSig(
            mockCommentParams,
            _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _getCommentTypedDataHash(mockCommentParams, nonce, deadline),
                deadline: deadline
            })
        );
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return publisher.ownerPk;
    }
}
