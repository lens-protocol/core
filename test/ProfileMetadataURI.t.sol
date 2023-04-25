// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/MetaTxNegatives.t.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';

contract ProfileMetadataURITest is BaseTest {
    // TODO: We can avoid this `alienSigner` and do it better by using fuzzing instead, but it requires a refactor here.
    TestAccount alienSigner;

    function setUp() public virtual override {
        TestSetup.setUp();

        alienSigner = _loadAccountAs('ALIEN_SIGNER_ACCOUNT');
    }

    function _setProfileMetadataURI(uint256 pk, uint256 profileId, string memory metadataURI) internal virtual {
        vm.prank(vm.addr(pk));
        hub.setProfileMetadataURI(profileId, metadataURI);
    }

    // Negatives
    function testCannotSetProfileMetadataURINotDelegatedExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _setProfileMetadataURI({pk: alienSigner.ownerPk, profileId: defaultAccount.profileId, metadataURI: MOCK_URI});
    }

    // Positives
    function testDelegatedExecutorSetProfileMetadataURI() public {
        assertEq(hub.getProfileMetadataURI(defaultAccount.profileId), '');
        vm.prank(defaultAccount.owner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: defaultAccount.profileId,
            delegatedExecutors: _toAddressArray(otherSigner.owner),
            approvals: _toBoolArray(true)
        });

        _setProfileMetadataURI({pk: otherSigner.ownerPk, profileId: defaultAccount.profileId, metadataURI: MOCK_URI});
        assertEq(hub.getProfileMetadataURI(defaultAccount.profileId), MOCK_URI);
    }

    function testSetProfileMetadataURI() public {
        assertEq(hub.getProfileMetadataURI(defaultAccount.profileId), '');

        _setProfileMetadataURI({
            pk: defaultAccount.ownerPk,
            profileId: defaultAccount.profileId,
            metadataURI: MOCK_URI
        });
        assertEq(hub.getProfileMetadataURI(defaultAccount.profileId), MOCK_URI);
    }

    // Events
    function expectProfileMetadataSetEvent() public {
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ProfileMetadataSet({
            profileId: defaultAccount.profileId,
            metadata: MOCK_URI,
            timestamp: block.timestamp
        });
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

    function testProfileMetadataURITest_MetaTx() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public override(MetaTxNegatives, ProfileMetadataURITest) {
        ProfileMetadataURITest.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[alienSigner.owner] = hub.nonces(alienSigner.owner);
        cachedNonceByAddress[otherSigner.owner] = hub.nonces(otherSigner.owner);
        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
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

        bytes32 digest = _getSetProfileMetadataURITypedDataHash(defaultAccount.profileId, MOCK_URI, nonce, deadline);

        hub.setProfileMetadataURIWithSig({
            profileId: defaultAccount.profileId,
            metadataURI: MOCK_URI,
            signature: _getSigStruct(signer, pk, digest, deadline)
        });
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        bytes32 digest = _getSetProfileMetadataURITypedDataHash(defaultAccount.profileId, MOCK_URI, nonce, deadline);

        hub.setProfileMetadataURIWithSig({
            profileId: defaultAccount.profileId,
            metadataURI: MOCK_URI,
            signature: _getSigStruct(vm.addr(_getDefaultMetaTxSignerPk()), signerPk, digest, deadline)
        });
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return defaultAccount.ownerPk;
    }
}
