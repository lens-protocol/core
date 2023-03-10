// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'test/foundry/base/BaseTest.t.sol';
import 'test/foundry/MetaTxNegatives.t.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';

contract ProfileMetadataURITest is BaseTest {
    function _setProfileMetadataURI(uint256 pk, uint256 profileId, string memory metadataURI) internal virtual {
        vm.prank(vm.addr(pk));
        hub.setProfileMetadataURI(profileId, metadataURI);
    }

    // Negatives
    function testCannotSetProfileMetadataURINotDelegatedExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _setProfileMetadataURI({pk: alienSignerKey, profileId: newProfileId, metadataURI: MOCK_URI});
    }

    // Positives
    function testDelegatedExecutorSetProfileMetadataURI() public {
        assertEq(hub.getProfileMetadataURI(newProfileId), '');
        vm.prank(profileOwner);
        hub.changeCurrentDelegatedExecutorsConfig({
            delegatorProfileId: newProfileId,
            delegatedExecutors: _toAddressArray(otherSigner),
            approvals: _toBoolArray(true)
        });

        _setProfileMetadataURI({pk: otherSignerKey, profileId: newProfileId, metadataURI: MOCK_URI});
        assertEq(hub.getProfileMetadataURI(newProfileId), MOCK_URI);
    }

    function testSetProfileMetadataURI() public {
        assertEq(hub.getProfileMetadataURI(newProfileId), '');

        _setProfileMetadataURI({pk: profileOwnerKey, profileId: newProfileId, metadataURI: MOCK_URI});
        assertEq(hub.getProfileMetadataURI(newProfileId), MOCK_URI);
    }

    // Events
    function expectProfileMetadataSetEvent() public {
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ProfileMetadataSet({profileId: newProfileId, metadata: MOCK_URI, timestamp: block.timestamp});
    }

    function testSetProfileMetadataURI_EmitsProperEvent() public {
        expectProfileMetadataSetEvent();
        testSetProfileMetadataURI();
    }

    function testDelegatedExecutorSetProfileMetadataURI_EmitsProperEvent() public {
        expectProfileMetadataSetEvent();
        testDelegatedExecutorSetProfileMetadataURI();
    }
}

contract ProfileMetadataURITest_MetaTx is ProfileMetadataURITest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function setUp() public override(MetaTxNegatives, TestSetup) {
        TestSetup.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[alienSigner] = _getSigNonce(alienSigner);
        cachedNonceByAddress[otherSigner] = _getSigNonce(otherSigner);
        cachedNonceByAddress[profileOwner] = _getSigNonce(profileOwner);
    }

    function _setProfileMetadataURI(
        uint256 pk,
        uint256 profileId,
        string memory metadataURI
    ) internal virtual override {
        /* Wen @solc-nowarn unused-param?
            Silence the compiler warning, but allow calling this with Named Params.
            These variables aren't used here, but are used in withSig case */
        profileId = profileId;
        metadataURI = metadataURI;

        address signer = vm.addr(pk);
        uint256 nonce = cachedNonceByAddress[signer];
        uint256 deadline = type(uint256).max;

        bytes32 digest = _getSetProfileMetadataURITypedDataHash(newProfileId, MOCK_URI, nonce, deadline);

        hub.setProfileMetadataURIWithSig({
            profileId: newProfileId,
            metadataURI: MOCK_URI,
            signature: _getSigStruct(signer, pk, digest, deadline)
        });
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        bytes32 digest = _getSetProfileMetadataURITypedDataHash(newProfileId, MOCK_URI, nonce, deadline);

        hub.setProfileMetadataURIWithSig({
            profileId: newProfileId,
            metadataURI: MOCK_URI,
            signature: _getSigStruct(vm.addr(_getDefaultMetaTxSignerPk()), signerPk, digest, deadline)
        });
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return profileOwnerKey;
    }
}
