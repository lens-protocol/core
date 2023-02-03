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
    function _setDefaultProfileWithSig(
        address delegatedSigner,
        uint256 signerPrivKey,
        uint256 possiblyBadDeadline
    ) public {
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
                _getSigStruct(signerPrivKey, digest, possiblyBadDeadline)
            )
        );
    }

    function setUp() public override(SigSetup, TestSetup) {
        TestSetup.setUp();
        SigSetup.setUp();
    }

    // NEGATIVES

    function testCannotSetDefaultProfileWithSigIfDeadlineMismatch() public {
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setDefaultProfileWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey,
            possiblyBadDeadline: block.timestamp + 1
        });
    }

    function testCannotSetDefaultProfileWithSigIfInvalidDeadline() public {
        vm.expectRevert(Errors.SignatureExpired.selector);
        _setDefaultProfileWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey,
            possiblyBadDeadline: 0
        });
    }

    function testCannotSetDefaultProfileWithSigIfInvalidNonce() public {
        _setDefaultProfileWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey,
            possiblyBadDeadline: deadline
        });
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setDefaultProfileWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey,
            possiblyBadDeadline: deadline
        });
    }

    // SCENARIOS

    function testCanSetDefaultProfileWithSig() public {
        _setDefaultProfileWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey,
            possiblyBadDeadline: deadline
        });
        assertEq(hub.getDefaultProfile(profileOwner), FIRST_PROFILE_ID);
    }

    function testCanSetDefaultProfileWithSigThenUnset() public {
        _setDefaultProfileWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey,
            possiblyBadDeadline: deadline
        });
        assertEq(hub.getDefaultProfile(profileOwner), FIRST_PROFILE_ID);

        mockSetDefaultProfileData.profileId = 0;
        nonce++;

        _setDefaultProfileWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey,
            possiblyBadDeadline: deadline
        });
        assertEq(hub.getDefaultProfile(profileOwner), 0);
    }

    function testCanSetDefaultProfileWithSigThenChange() public {
        _setDefaultProfileWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey,
            possiblyBadDeadline: deadline
        });
        assertEq(hub.getDefaultProfile(profileOwner), FIRST_PROFILE_ID);

        uint256 anotherProfileId = hub.createProfile(mockCreateProfileData);
        mockSetDefaultProfileData.profileId = anotherProfileId;
        nonce++;

        _setDefaultProfileWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey,
            possiblyBadDeadline: deadline
        });
        assertEq(hub.getDefaultProfile(profileOwner), mockSetDefaultProfileData.profileId);
        assertFalse(mockSetDefaultProfileData.profileId == FIRST_PROFILE_ID);
    }
}
