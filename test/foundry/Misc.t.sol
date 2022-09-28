// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract MiscTest is BaseTest {
    // Negatives
    function testSetFollowModuleNotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowModule(firstProfileId, address(0), '');
    }

    function testSetDefaultProfileNotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setDefaultProfile(profileOwner, firstProfileId);
    }

    // Positives
    function testExecutorSetFollowModule() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        hub.setFollowModule(firstProfileId, address(0), '');
    }

    function testExecutorSetDefaultProfile() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        hub.setDefaultProfile(profileOwner, firstProfileId);
    }

    // Meta-tx
    // Negatives
    function testSetFollowModuleWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowModuleTypedDataHash(
            firstProfileId,
            address(0),
            '',
            nonce,
            deadline
        );

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                delegatedSigner: address(0),
                profileId: firstProfileId,
                followModule: address(0),
                followModuleInitData: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetFollowModuleWithSigNotExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowModuleTypedDataHash(
            firstProfileId,
            address(0),
            '',
            nonce,
            deadline
        );

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                followModule: address(0),
                followModuleInitData: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetDefaultProfileWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetDefaultProfileTypedDataHash(
            profileOwner,
            firstProfileId,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setDefaultProfileWithSig(
            DataTypes.SetDefaultProfileWithSigData({
                delegatedSigner: address(0),
                wallet: profileOwner,
                profileId: firstProfileId,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetDefaultProfileWithSigNotExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetDefaultProfileTypedDataHash(
            profileOwner,
            firstProfileId,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setDefaultProfileWithSig(
            DataTypes.SetDefaultProfileWithSigData({
                delegatedSigner: otherSigner,
                wallet: profileOwner,
                profileId: firstProfileId,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    // Postivies
    function testExecutorSetFollowModuleWithSig() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowModuleTypedDataHash(
            firstProfileId,
            address(0),
            '',
            nonce,
            deadline
        );

        hub.setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                followModule: address(0),
                followModuleInitData: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testExecutorSetDefaultProfileWithSigInvalidSigner() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetDefaultProfileTypedDataHash(
            profileOwner,
            firstProfileId,
            nonce,
            deadline
        );

        hub.setDefaultProfileWithSig(
            DataTypes.SetDefaultProfileWithSigData({
                delegatedSigner: otherSigner,
                wallet: profileOwner,
                profileId: firstProfileId,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }
}
