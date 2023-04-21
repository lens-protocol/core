// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';

contract QuoteTest is PublicationTest {
    function testQuoteTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override {
        super.setUp();
        mockQuoteParams.profileId = publisherProfileId;
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        mockQuoteParams.profileId = publisherProfileId;
        vm.prank(vm.addr(signerPk));
        return hub.quote(mockQuoteParams);
    }

    function _pubType() internal virtual override returns (Types.PublicationType) {
        return Types.PublicationType.Quote;
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
        cachedNonceByAddress[profileOwner] = _getSigNonce(profileOwner);
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        mockQuoteParams.profileId = publisherProfileId;
        address signer = vm.addr(signerPk);
        return
            hub.quoteWithSig(
                mockQuoteParams,
                _getSigStruct({
                    signer: signer,
                    pKey: signerPk,
                    digest: _getQuoteTypedDataHash({
                        quoteParams: mockQuoteParams,
                        nonce: cachedNonceByAddress[signer],
                        deadline: type(uint256).max
                    }),
                    deadline: type(uint256).max
                })
            );
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        hub.quoteWithSig(
            mockQuoteParams,
            _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _getQuoteTypedDataHash(mockQuoteParams, nonce, deadline),
                deadline: deadline
            })
        );
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return publisherOwnerPk;
    }
}
