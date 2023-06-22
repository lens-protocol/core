// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest, ReferencePublicationTest, ActionablePublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';
import {ReferralSystemTest} from 'test/ReferralSystem.t.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import 'forge-std/console.sol';

contract QuoteTest is ReferencePublicationTest, ActionablePublicationTest, ReferralSystemTest {
    Types.QuoteParams quoteParams;

    function testQuoteTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override(PublicationTest, ReferralSystemTest) {
        PublicationTest.setUp();
        quoteParams = _getDefaultQuoteParams();
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        quoteParams.profileId = publisherProfileId;
        vm.prank(vm.addr(signerPk));
        return hub.quote(quoteParams);
    }

    function _setPointedPub(uint256 pointedProfileId, uint256 pointedPubId) internal virtual override {
        quoteParams.pointedProfileId = pointedProfileId;
        quoteParams.pointedPubId = pointedPubId;
    }

    function _pubType() internal virtual override returns (Types.PublicationType) {
        return Types.PublicationType.Quote;
    }

    function _contentURI() internal virtual override returns (string memory contentURI) {
        return quoteParams.contentURI;
    }

    function _setReferrers(
        uint256[] memory referrerProfileIds,
        uint256[] memory referrerPubIds
    ) internal virtual override {
        quoteParams.referrerProfileIds = referrerProfileIds;
        quoteParams.referrerPubIds = referrerPubIds;
    }

    function _setReferenceModuleData(bytes memory referenceModuleData) internal virtual override {
        quoteParams.referenceModuleData = referenceModuleData;
    }

    function _setActionModules(
        address[] memory actionModules,
        bytes[] memory actionModulesInitDatas
    ) internal virtual override {
        quoteParams.actionModules = actionModules;
        quoteParams.actionModulesInitDatas = actionModulesInitDatas;
    }

    function _referralSystem_PrepareOperation(
        TestPublication memory target,
        TestPublication memory referralPub
    ) internal virtual override {
        _setPointedPub(target.profileId, target.pubId);
        _setReferrers(_toUint256Array(referralPub.profileId), _toUint256Array(referralPub.pubId));

        Types.Publication memory targetPublication = hub.getPublication(target.profileId, target.pubId);
        if (targetPublication.referenceModule != address(0)) {
            quoteParams.referenceModuleData = abi.encode(true);
        }
        _refreshCachedNonces();
    }

    function _referralSystem_ExpectRevertsIfNeeded(
        TestPublication memory target,
        TestPublication memory referralPub
    ) internal virtual override returns (bool) {
        Types.Publication memory targetPublication = hub.getPublication(target.profileId, target.pubId);

        if (quoteParams.referrerProfileIds.length > 0 || quoteParams.referrerPubIds.length > 0) {
            if (_isV1LegacyPub(targetPublication)) {
                // V1 should not accept referrers for comments
                vm.expectRevert(Errors.InvalidReferrer.selector);
                return true;
            } else {
                // V2 without referenceModule should not accept referrers
                if (targetPublication.referenceModule == address(0)) {
                    vm.expectRevert(Errors.InvalidReferrer.selector);
                    return true;
                }
            }
        }
        return false;
    }

    function _referralSystem_ExecutePreparedOperation(
        TestPublication memory target,
        TestPublication memory referralPub
    ) internal virtual override {
        console.log('QUOTING on %s, %s', vm.toString(target.profileId), vm.toString(target.pubId));
        console.log('    with referral: %s, %s', vm.toString(referralPub.profileId), vm.toString(referralPub.pubId));
        _publish(publisher.ownerPk, publisher.profileId);
    }

    function _refreshCachedNonces() internal virtual {
        // Nothing to do there.
    }
}

contract QuoteMetaTxTest is QuoteTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function testQuoteMetaTxTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override(QuoteTest, MetaTxNegatives) {
        QuoteTest.setUp();
        MetaTxNegatives.setUp();
        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        quoteParams.profileId = publisherProfileId;
        address signer = vm.addr(signerPk);
        return
            hub.quoteWithSig(
                quoteParams,
                _getSigStruct({
                    signer: signer,
                    pKey: signerPk,
                    digest: _getQuoteTypedDataHash({
                        quoteParams: quoteParams,
                        nonce: cachedNonceByAddress[signer],
                        deadline: type(uint256).max
                    }),
                    deadline: type(uint256).max
                })
            );
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        quoteParams.profileId = publisher.profileId;
        hub.quoteWithSig(
            quoteParams,
            _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _getQuoteTypedDataHash(quoteParams, nonce, deadline),
                deadline: deadline
            })
        );
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return publisher.ownerPk;
    }

    function _refreshCachedNonces() internal override {
        cachedNonceByAddress[publisher.owner] = hub.nonces(publisher.owner);
        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
    }
}
