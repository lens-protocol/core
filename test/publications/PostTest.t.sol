// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';

contract PostTest is PublicationTest {
    function testPostTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override {
        super.setUp();
        mockPostParams.profileId = publisher.profileId;
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        mockPostParams.profileId = publisherProfileId;
        vm.prank(vm.addr(signerPk));
        return hub.post(mockPostParams);
    }

    function _pubType() internal virtual override returns (Types.PublicationType) {
        return Types.PublicationType.Post;
    }
}

contract PostMetaTxTest is PostTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function testPostMetaTxTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override(PostTest, MetaTxNegatives) {
        PostTest.setUp();
        MetaTxNegatives.setUp();
        cachedNonceByAddress[defaultAccount.owner] = _getSigNonce(defaultAccount.owner);
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        mockPostParams.profileId = publisherProfileId;
        address signer = vm.addr(signerPk);
        return
            hub.postWithSig(
                mockPostParams,
                _getSigStruct({
                    signer: signer,
                    pKey: signerPk,
                    digest: _getPostTypedDataHash({
                        postParams: mockPostParams,
                        nonce: cachedNonceByAddress[signer],
                        deadline: type(uint256).max
                    }),
                    deadline: type(uint256).max
                })
            );
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        hub.postWithSig(
            mockPostParams,
            _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _getPostTypedDataHash(mockPostParams, nonce, deadline),
                deadline: deadline
            })
        );
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return publisher.ownerPk;
    }
}
