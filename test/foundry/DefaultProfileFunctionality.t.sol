// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './helpers/SignatureHelpers.sol';

contract DefaultProfileFunctionalityTest_Generic is BaseTest {
    function setUp() public override {
        TestSetup.setUp();
    }

    // NEGATIVES

    function testCannotSetProfileOwnedByAnotherAccount() public {
        vm.prank(otherSigner);
        vm.expectRevert(Errors.NotProfileOwner.selector);
        hub.setDefaultProfile(otherSigner, FIRST_PROFILE_ID);
    }

    // SCENARIOS

    function testCanSetDefaultProfile() public {
        vm.prank(profileOwner);
        hub.setDefaultProfile(profileOwner, FIRST_PROFILE_ID);
        assertEq(hub.getDefaultProfile(profileOwner), FIRST_PROFILE_ID);
    }

    function testCanSetThenUnsetDefaultProfile() public {
        vm.startPrank(profileOwner);
        hub.setDefaultProfile(profileOwner, FIRST_PROFILE_ID);
        assertEq(hub.getDefaultProfile(profileOwner), FIRST_PROFILE_ID);
        hub.setDefaultProfile(profileOwner, 0);
        assertEq(hub.getDefaultProfile(profileOwner), 0);

        vm.stopPrank();
    }

    function testCanSetThenChangeDefaultProfile() public {
        vm.prank(profileOwner);
        hub.setDefaultProfile(profileOwner, FIRST_PROFILE_ID);
        assertEq(hub.getDefaultProfile(profileOwner), FIRST_PROFILE_ID);

        vm.prank(me);
        uint256 newProfileId = hub.createProfile(mockCreateProfileData);

        vm.prank(profileOwner);
        hub.setDefaultProfile(profileOwner, newProfileId);
        assertEq(hub.getDefaultProfile(profileOwner), newProfileId);
    }

    function testTransferUnsetsDefaultProfile() public {
        vm.startPrank(profileOwner);
        hub.setDefaultProfile(profileOwner, FIRST_PROFILE_ID);
        assertEq(hub.getDefaultProfile(profileOwner), FIRST_PROFILE_ID);

        hub.transferFrom(profileOwner, otherSigner, FIRST_PROFILE_ID);

        assertEq(hub.getDefaultProfile(profileOwner), 0);
    }
}

contract DefaultProfileFunctionalityTest_WithSig is BaseTest, SigSetup, SignatureHelpers {
    function _setDefaultProfileWithSig(address delegatedSigner, uint256 signerPrivKey) public {
        bytes32 digest = _getSetDefaulProfileTypedDataHash(
            mockSetDefaultProfileData.wallet,
            mockSetDefaultProfileData.profileId,
            nonce,
            deadline
        );

        vm.prank(delegatedSigner);
        hub.setDefaultProfileWithSig(
            _buildSetDefaultProfileWithSigData(
                delegatedSigner,
                mockSetDefaultProfileData.wallet,
                mockSetDefaultProfileData.profileId,
                _getSigStruct(signerPrivKey, digest, deadline)
            )
        );
    }

    function setUp() public override(SigSetup, TestSetup) {
        TestSetup.setUp();
        SigSetup.setUp();
    }

    // NEGATIVES

    function testCannotSetDefaultProfileWithSigIfDeadlineMismatch() public {}

    function testCannotSetDefaultProfileWithSigIfInvalidDeadline() public {}

    function testCannotSetDefaultProfileWithSigIfInvalidNonce() public {}

    function testCannotSetDefaultProfileWithSigIfCancelledWithPermitForAll() public {}

    // SCENARIOS

    function testCanSetDefaultProfileWithSig() public {
        _setDefaultProfileWithSig(otherSigner, profileOwnerKey);
        assertEq(hub.getDefaultProfile(profileOwner), FIRST_PROFILE_ID);
    }

    function testCanSetDefaultProfileWithSigThenUnset() public {}

    function testCanSetDefaultProfileWithSigThenChange() public {}
}
