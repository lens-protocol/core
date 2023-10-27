// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from 'contracts/libraries/constants/Types.sol';
import {PublicationTest, ReferencePublicationTest} from 'test/publications/PublicationTest.t.sol';
import {MetaTxNegatives} from 'test/MetaTxNegatives.t.sol';
import {ReferralSystemTest} from 'test/ReferralSystem.t.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import 'forge-std/console.sol';

contract MirrorTest is ReferencePublicationTest, ReferralSystemTest {
    Types.MirrorParams mirrorParams;

    function testMirrorTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public virtual override(PublicationTest, ReferralSystemTest) {
        PublicationTest.setUp();
        ReferralSystemTest.setUp();
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

    function _referralSystem_PrepareOperation(
        TestPublication memory target,
        uint256[] memory referrerProfileIds,
        uint256[] memory referrerPubIds
    ) internal virtual override {
        _setPointedPub(target.profileId, target.pubId);
        _setReferrers(referrerProfileIds, referrerPubIds);

        Types.PublicationMemory memory targetPublication = hub.getPublication(target.profileId, target.pubId);
        if (targetPublication.referenceModule != address(0)) {
            mirrorParams.referenceModuleData = abi.encode(true);
        }
        _refreshCachedNonces();
    }

    function _referralSystem_ExpectRevertsIfNeeded(
        TestPublication memory target,
        uint256[] memory /* referrerProfileIds */,
        uint256[] memory /* referrerPubIds */
    ) internal virtual override returns (bool) {
        Types.PublicationMemory memory targetPublication = hub.getPublication(target.profileId, target.pubId);

        if (mirrorParams.referrerProfileIds.length > 0 || mirrorParams.referrerPubIds.length > 0) {
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

    function _referralSystem_ExecutePreparedOperation() internal virtual override {
        _publish(publisher.ownerPk, publisher.profileId);
    }

    function _refreshCachedNonces() internal virtual {
        // Nothing to do there.
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
        cachedNonceByAddress[publisher.owner] = hub.nonces(publisher.owner);
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

    function _incrementNonce(uint8 increment) internal override {
        vm.prank(vm.addr(_getDefaultMetaTxSignerPk()));
        hub.incrementNonce(increment);
        _refreshCachedNonces();
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return publisher.ownerPk;
    }

    function _refreshCachedNonces() internal override {
        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
        cachedNonceByAddress[publisher.owner] = hub.nonces(publisher.owner);
    }
}
