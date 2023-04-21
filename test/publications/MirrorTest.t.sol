// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';

contract MirrorTest is PublicationTest {
    function testMirrorTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override {
        super.setUp();
        mockMirrorParams.profileId = publisherProfileId;
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        mockMirrorParams.profileId = publisherProfileId;
        vm.prank(vm.addr(signerPk));
        return hub.mirror(mockMirrorParams);
    }

    function _pubType() internal virtual override returns (Types.PublicationType) {
        return Types.PublicationType.Mirror;
    }
}

contract MirrorMetaTxTest is MirrorTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function testMirrorMetaTxTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override(MirrorTest, MetaTxNegatives) {
        MirrorTest.setUp();
        MetaTxNegatives.setUp();
        cachedNonceByAddress[profileOwner] = _getSigNonce(profileOwner);
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        mockMirrorParams.profileId = publisherProfileId;
        address signer = vm.addr(signerPk);
        return
            hub.mirrorWithSig(
                mockMirrorParams,
                _getSigStruct({
                    signer: signer,
                    pKey: signerPk,
                    digest: _getMirrorTypedDataHash({
                        mirrorParams: mockMirrorParams,
                        nonce: cachedNonceByAddress[signer],
                        deadline: type(uint256).max
                    }),
                    deadline: type(uint256).max
                })
            );
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        hub.mirrorWithSig(
            mockMirrorParams,
            _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _getMirrorTypedDataHash(mockMirrorParams, nonce, deadline),
                deadline: deadline
            })
        );
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return publisherOwnerPk;
    }
}
