// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/MetaTxNegatives.t.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';

contract ProfileMetadataURITest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function _setProfileMetadataURI(
        uint256 pk,
        uint256 profileId,
        string memory metadataURI
    ) internal virtual {
        vm.prank(vm.addr(pk));
        hub.setProfileMetadataURI(profileId, metadataURI);
    }

    // Negatives
    function testCannotSetProfileMetadataURINotDelegatedExecutor(uint256 nonOwnerNorDelegatedExecutorPk) public {
        nonOwnerNorDelegatedExecutorPk = _boundPk(nonOwnerNorDelegatedExecutorPk);
        vm.assume(nonOwnerNorDelegatedExecutorPk != defaultAccount.ownerPk);
        address nonOwnerNorDelegatedExecutor = vm.addr(nonOwnerNorDelegatedExecutorPk);
        vm.assume(!hub.isDelegatedExecutorApproved(defaultAccount.profileId, nonOwnerNorDelegatedExecutor));

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _setProfileMetadataURI({
            pk: nonOwnerNorDelegatedExecutorPk,
            profileId: defaultAccount.profileId,
            metadataURI: MOCK_URI
        });
    }

    // Positives
    function testDelegatedExecutorSetProfileMetadataURI(uint256 delegatedExecutorPk) public {
        delegatedExecutorPk = _boundPk(delegatedExecutorPk);
        address delegatedExecutor = vm.addr(delegatedExecutorPk);
        vm.assume(delegatedExecutorPk != defaultAccount.ownerPk);

        assertEq(hub.getProfile(defaultAccount.profileId).metadataURI, '');
        vm.prank(defaultAccount.owner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: defaultAccount.profileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true)
        });

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ProfileMetadataSet({
            profileId: defaultAccount.profileId,
            metadata: MOCK_URI,
            transactionExecutor: delegatedExecutor,
            timestamp: block.timestamp
        });
        _setProfileMetadataURI({pk: delegatedExecutorPk, profileId: defaultAccount.profileId, metadataURI: MOCK_URI});
        assertEq(hub.getProfile(defaultAccount.profileId).metadataURI, MOCK_URI);
    }

    function testSetProfileMetadataURI() public {
        assertEq(hub.getProfile(defaultAccount.profileId).metadataURI, '');

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.ProfileMetadataSet({
            profileId: defaultAccount.profileId,
            metadata: MOCK_URI,
            transactionExecutor: defaultAccount.owner,
            timestamp: block.timestamp
        });
        _setProfileMetadataURI({
            pk: defaultAccount.ownerPk,
            profileId: defaultAccount.profileId,
            metadataURI: MOCK_URI
        });
        assertEq(hub.getProfile(defaultAccount.profileId).metadataURI, MOCK_URI);
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
        profileId;
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

    function _executeMetaTx(
        uint256 signerPk,
        uint256 nonce,
        uint256 deadline
    ) internal virtual override {
        bytes32 digest = _getSetProfileMetadataURITypedDataHash(defaultAccount.profileId, MOCK_URI, nonce, deadline);

        hub.setProfileMetadataURIWithSig({
            profileId: defaultAccount.profileId,
            metadataURI: MOCK_URI,
            signature: _getSigStruct(vm.addr(_getDefaultMetaTxSignerPk()), signerPk, digest, deadline)
        });
    }

    function _incrementNonce(uint8 increment) internal override {
        vm.prank(vm.addr(_getDefaultMetaTxSignerPk()));
        hub.incrementNonce(increment);
        cachedNonceByAddress[vm.addr(_getDefaultMetaTxSignerPk())] = hub.nonces(vm.addr(_getDefaultMetaTxSignerPk()));
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return defaultAccount.ownerPk;
    }
}
