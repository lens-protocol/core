// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';

contract CommentTest is PublicationTest {
    function testCommentTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override {
        super.setUp();
        mockCommentParams.profileId = publisherProfileId;
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        mockCommentParams.profileId = publisherProfileId;
        vm.prank(vm.addr(signerPk));
        return hub.comment(mockCommentParams);
    }

    function _pubType() internal virtual override returns (Types.PublicationType) {
        return Types.PublicationType.Comment;
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
        return publisherOwnerPk;
    }
}
