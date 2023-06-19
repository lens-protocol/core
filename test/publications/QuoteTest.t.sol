// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest, ReferencePublicationTest, ActionablePublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';

contract QuoteTest is ReferencePublicationTest, ActionablePublicationTest {
    Types.QuoteParams quoteParams;

    function testQuoteTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override {
        super.setUp();
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
}
