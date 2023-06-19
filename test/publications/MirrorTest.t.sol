// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest, ReferencePublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';

contract MirrorTest is ReferencePublicationTest {
    Types.MirrorParams mirrorParams;

    function testMirrorTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override {
        super.setUp();
        mirrorParams = _getDefaultMirrorParams();
    }

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual override returns (uint256) {
        mirrorParams.profileId = publisherProfileId;
        vm.prank(vm.addr(signerPk));
        return hub.mirror(mirrorParams);
    }

    function _setPointedPub(uint256 pointedProfileId, uint256 pointedPubId) internal virtual override {
        mirrorParams.pointedProfileId = pointedProfileId;
        mirrorParams.pointedPubId = pointedPubId;
    }

    function _pubType() internal virtual override returns (Types.PublicationType) {
        return Types.PublicationType.Mirror;
    }

    function _contentURI() internal virtual override returns (string memory contentURI) {
        return hub.getContentURI(mirrorParams.pointedProfileId, mirrorParams.pointedPubId);
    }

    function _setReferrers(
        uint256[] memory referrerProfileIds,
        uint256[] memory referrerPubIds
    ) internal virtual override {
        mirrorParams.referrerProfileIds = referrerProfileIds;
        mirrorParams.referrerPubIds = referrerPubIds;
    }

    function _setReferenceModuleData(bytes memory referenceModuleData) internal virtual override {
        mirrorParams.referenceModuleData = referenceModuleData;
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
        mirrorParams.profileId = publisherProfileId;
        address signer = vm.addr(signerPk);
        return
            hub.mirrorWithSig(
                mirrorParams,
                _getSigStruct({
                    signer: signer,
                    pKey: signerPk,
                    digest: _getMirrorTypedDataHash({
                        mirrorParams: mirrorParams,
                        nonce: cachedNonceByAddress[signer],
                        deadline: type(uint256).max
                    }),
                    deadline: type(uint256).max
                })
            );
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        mirrorParams.profileId = publisher.profileId;
        hub.mirrorWithSig(
            mirrorParams,
            _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _getMirrorTypedDataHash(mirrorParams, nonce, deadline),
                deadline: deadline
            })
        );
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return publisher.ownerPk;
    }
}
