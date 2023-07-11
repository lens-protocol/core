// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {ProfileLib} from 'contracts/libraries/ProfileLib.sol';

contract SetProfileImageURI is BaseTest {
    // Negatives
    function testCannot_SetProfileImageURI_IfNotDelegatedExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileImageURI(defaultAccount.profileId, MOCK_URI);
    }

    function testCannot_SetProfileImageURI_IfLengthGreaterThanMax() public {
        vm.expectRevert(Errors.ProfileImageURILengthInvalid.selector);
        bytes memory imageURI = new bytes(ProfileLib.MAX_PROFILE_IMAGE_URI_LENGTH + 1);

        vm.prank(defaultAccount.owner);
        hub.setProfileImageURI(defaultAccount.profileId, string(imageURI));
    }

    function testCannot_SetProfileImageURI_WithDelegatedExecutor_IfLengthGreaterThanMax(
        address delegatedExecutor
    ) public {
        vm.assume(delegatedExecutor != address(0));
        vm.assume(delegatedExecutor != defaultAccount.owner);
        vm.assume(delegatedExecutor != proxyAdmin);

        vm.prank(defaultAccount.owner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: defaultAccount.profileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true)
        });

        bytes memory imageURI = new bytes(ProfileLib.MAX_PROFILE_IMAGE_URI_LENGTH + 1);

        vm.expectRevert(Errors.ProfileImageURILengthInvalid.selector);
        vm.prank(delegatedExecutor);
        hub.setProfileImageURI(defaultAccount.profileId, string(imageURI));
    }

    // Positives
    function testDelegatedExecutorSetProfileImageURI(address delegatedExecutor) public {
        vm.assume(delegatedExecutor != address(0));
        vm.assume(delegatedExecutor != defaultAccount.owner);
        vm.assume(delegatedExecutor != proxyAdmin);

        console.log(hub.getProfile(defaultAccount.profileId).imageURI);
        assertEq(hub.getProfile(defaultAccount.profileId).imageURI, MOCK_URI);

        vm.prank(defaultAccount.owner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: defaultAccount.profileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true)
        });

        vm.prank(delegatedExecutor);
        hub.setProfileImageURI(defaultAccount.profileId, 'test');
        assertEq(hub.getProfile(defaultAccount.profileId).imageURI, 'test');
    }

    // Meta-tx
    // Negatives
    function testCannot_SetProfileImageURIWithSig_IfInvalidSigner(uint256 otherSignerPk) public {
        otherSignerPk = _boundPk(otherSignerPk);
        vm.assume(otherSignerPk != defaultAccount.ownerPk);
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(defaultAccount.profileId, MOCK_URI, nonce, deadline);

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setProfileImageURIWithSig({
            profileId: defaultAccount.profileId,
            imageURI: MOCK_URI,
            signature: _getSigStruct(defaultAccount.owner, otherSignerPk, digest, deadline)
        });
    }

    function testCannot_SetProfileImageURIWithSig_IfNotDelegatedExecutor(uint256 otherSignerPk) public {
        otherSignerPk = _boundPk(otherSignerPk);
        vm.assume(otherSignerPk != defaultAccount.ownerPk);
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(defaultAccount.profileId, MOCK_URI, nonce, deadline);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileImageURIWithSig({
            profileId: defaultAccount.profileId,
            imageURI: MOCK_URI,
            signature: _getSigStruct(otherSignerPk, digest, deadline)
        });
    }

    function testCannot_SetProfileImageURIWithSig_IfLengthGreaterThanMax() public {
        bytes memory imageURI = new bytes(ProfileLib.MAX_PROFILE_IMAGE_URI_LENGTH + 1);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(
            defaultAccount.profileId,
            string(imageURI),
            nonce,
            deadline
        );

        vm.expectRevert(Errors.ProfileImageURILengthInvalid.selector);
        hub.setProfileImageURIWithSig({
            profileId: defaultAccount.profileId,
            imageURI: string(imageURI),
            signature: _getSigStruct(defaultAccount.ownerPk, digest, deadline)
        });
    }

    // Postivies
    function testSetProfileImageURIWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(defaultAccount.profileId, 'test', nonce, deadline);

        assertEq(hub.getProfile(defaultAccount.profileId).imageURI, MOCK_URI);
        hub.setProfileImageURIWithSig({
            profileId: defaultAccount.profileId,
            imageURI: 'test',
            signature: _getSigStruct(defaultAccount.ownerPk, digest, deadline)
        });
        assertEq(hub.getProfile(defaultAccount.profileId).imageURI, 'test');
    }

    function testDelegatedExecutorSetProfileImageURIWithSig(uint256 delegatedExecutorPk) public {
        delegatedExecutorPk = _boundPk(delegatedExecutorPk);
        vm.assume(delegatedExecutorPk != defaultAccount.ownerPk);
        address delegatedExecutor = vm.addr(delegatedExecutorPk);

        vm.prank(defaultAccount.owner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: defaultAccount.profileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true)
        });

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(defaultAccount.profileId, 'test', nonce, deadline);

        assertEq(hub.getProfile(defaultAccount.profileId).imageURI, MOCK_URI);
        hub.setProfileImageURIWithSig({
            profileId: defaultAccount.profileId,
            imageURI: 'test',
            signature: _getSigStruct(delegatedExecutorPk, digest, deadline)
        });
        assertEq(hub.getProfile(defaultAccount.profileId).imageURI, 'test');
    }
}
