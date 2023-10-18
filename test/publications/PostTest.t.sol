// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest, ActionablePublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';

contract PostTest is ActionablePublicationTest {
    Types.PostParams postParams;

    function testPostTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override {
        super.setUp();
        postParams = _getDefaultPostParams();
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        postParams.profileId = publisherProfileId;
        vm.prank(vm.addr(signerPk));
        return hub.post(postParams);
    }

    function _pubType() internal virtual override returns (Types.PublicationType) {
        return Types.PublicationType.Post;
    }

    function _contentURI() internal virtual override returns (string memory contentURI) {
        return postParams.contentURI;
    }

    function _setActionModules(
        address[] memory actionModules,
        bytes[] memory actionModulesInitDatas
    ) internal virtual override {
        postParams.actionModules = actionModules;
        postParams.actionModulesInitDatas = actionModulesInitDatas;
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
        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        postParams.profileId = publisherProfileId;
        address signer = vm.addr(signerPk);
        return
            hub.postWithSig(
                postParams,
                _getSigStruct({
                    signer: signer,
                    pKey: signerPk,
                    digest: _getPostTypedDataHash({
                        postParams: postParams,
                        nonce: cachedNonceByAddress[signer],
                        deadline: type(uint256).max
                    }),
                    deadline: type(uint256).max
                })
            );
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        postParams.profileId = publisher.profileId;
        hub.postWithSig(
            postParams,
            _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _getPostTypedDataHash(postParams, nonce, deadline),
                deadline: deadline
            })
        );
    }

    function _incrementNonce(uint8 increment) internal override {
        vm.prank(vm.addr(_getDefaultMetaTxSignerPk()));
        hub.incrementNonce(increment);
        cachedNonceByAddress[vm.addr(_getDefaultMetaTxSignerPk())] = hub.nonces(vm.addr(_getDefaultMetaTxSignerPk()));
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return publisher.ownerPk;
    }
}
