// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest, ReferencePublicationTest, ActionablePublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';
import {ReferralSystemTest} from 'test/ReferralSystem.t.sol';
import 'forge-std/console.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';

contract CommentTest is ReferencePublicationTest, ActionablePublicationTest, ReferralSystemTest {
    Types.CommentParams commentParams;

    function testCommentTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override(PublicationTest, ReferralSystemTest) {
        PublicationTest.setUp();
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

    function _referralSystem_PrepareOperation(
        TestPublication memory target,
        TestPublication memory referralPub
    ) internal virtual override {
        _setPointedPub(target.profileId, target.pubId);
        _setReferrers(_toUint256Array(referralPub.profileId), _toUint256Array(referralPub.pubId));

        Types.Publication memory targetPublication = hub.getPublication(target.profileId, target.pubId);
        if (targetPublication.referenceModule != address(0)) {
            commentParams.referenceModuleData = abi.encode(true);
        }
    }

    function _referralSystem_ExpectRevertsIfNeeded(
        TestPublication memory target,
        TestPublication memory referralPub
    ) internal virtual override {
        Types.Publication memory targetPublication = hub.getPublication(target.profileId, target.pubId);

        if (commentParams.referrerProfileIds.length > 0 || commentParams.referrerPubIds.length > 0) {
            if (_isV1LegacyPub(targetPublication)) {
                // V1 should not accept referrers for comments
                vm.expectRevert(Errors.InvalidReferrer.selector);
            } else {
                // V2 without referenceModule should not accept referrers
                if (targetPublication.referenceModule == address(0)) {
                    vm.expectRevert(Errors.InvalidReferrer.selector);
                }
            }
        }
    }

    function _referralSystem_ExecutePreparedOperation(
        TestPublication memory target,
        TestPublication memory referralPub
    ) internal virtual override {
        console.log('COMMENTING on %s, %s', vm.toString(target.profileId), vm.toString(target.pubId));
        console.log('    with referral: %s, %s', vm.toString(referralPub.profileId), vm.toString(referralPub.pubId));

        // TODO:
        // we do some action on target while passing reference as referral and expect it to be called,
        // so expectCall should check that the reference was passed as referral and it didn't revert.

        // TODO TLDR: should do vm.expectCall /* */();

        _publish(publisher.ownerPk, publisher.profileId);
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
