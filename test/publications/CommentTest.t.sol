// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest, ReferencePublicationTest, ActionablePublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';

contract CommentTest is ReferencePublicationTest, ActionablePublicationTest {
    Types.CommentParams commentParams;

    function testCommentTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override {
        super.setUp();
        commentParams = _getDefaultCommentParams();
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        commentParams.profileId = publisherProfileId;
        vm.prank(vm.addr(signerPk));
        return hub.comment(commentParams);
    }

    function _setPointedPub(uint256 pointedProfileId, uint256 pointedPubId) internal virtual override {
        commentParams.pointedProfileId = pointedProfileId;
        commentParams.pointedPubId = pointedPubId;
    }

    function _pubType() internal virtual override returns (Types.PublicationType) {
        return Types.PublicationType.Comment;
    }

    function _contentURI() internal virtual override returns (string memory contentURI) {
        return commentParams.contentURI;
    }

    function _setReferrers(
        uint256[] memory referrerProfileIds,
        uint256[] memory referrerPubIds
    ) internal virtual override {
        commentParams.referrerProfileIds = referrerProfileIds;
        commentParams.referrerPubIds = referrerPubIds;
    }

    function _setReferenceModuleData(bytes memory referenceModuleData) internal virtual override {
        commentParams.referenceModuleData = referenceModuleData;
    }

    function _setActionModules(
        address[] memory actionModules,
        bytes[] memory actionModulesInitDatas
    ) internal virtual override {
        commentParams.actionModules = actionModules;
        commentParams.actionModulesInitDatas = actionModulesInitDatas;
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
        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        commentParams.profileId = publisherProfileId;
        address signer = vm.addr(signerPk);
        return
            hub.commentWithSig(
                commentParams,
                _getSigStruct({
                    signer: signer,
                    pKey: signerPk,
                    digest: _getCommentTypedDataHash({
                        commentParams: commentParams,
                        nonce: cachedNonceByAddress[signer],
                        deadline: type(uint256).max
                    }),
                    deadline: type(uint256).max
                })
            );
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        commentParams.profileId = publisher.profileId;
        hub.commentWithSig(
            commentParams,
            _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _getCommentTypedDataHash(commentParams, nonce, deadline),
                deadline: deadline
            })
        );
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return publisher.ownerPk;
    }
}
