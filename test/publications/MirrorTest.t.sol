// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest, ReferencePublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';

contract MirrorTest is ReferencePublicationTest {
    function testMirrorTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override {
        super.setUp();
        mockMirrorParams.profileId = publisher.profileId;
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        mockMirrorParams.profileId = publisherProfileId;
        vm.prank(vm.addr(signerPk));
        return hub.mirror(mockMirrorParams);
    }

    function _setPointedPub(uint256 pointedProfileId, uint256 pointedPubId) internal virtual override {
        mockMirrorParams.pointedProfileId = pointedProfileId;
        mockMirrorParams.pointedPubId = pointedPubId;
    }

    function _pubType() internal virtual override returns (Types.PublicationType) {
        return Types.PublicationType.Mirror;
    }

    function _setReferrers(
        uint256[] memory referrerProfileIds,
        uint256[] memory referrerPubIds
    ) internal virtual override {
        mockMirrorParams.referrerProfileIds = referrerProfileIds;
        mockMirrorParams.referrerPubIds = referrerPubIds;
    }

    function _setReferenceModuleData(bytes memory referenceModuleData) internal virtual override {
        mockMirrorParams.referenceModuleData = referenceModuleData;
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
        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
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
        return publisher.ownerPk;
    }
}
