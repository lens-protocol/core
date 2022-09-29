// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import '../../contracts/mocks/MockFollowModule.sol';

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

    function testSetProfileImageURINotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileImageURI(firstProfileId, mockURI);
    }

    function testSetFollowNFTURINotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowNFTURI(firstProfileId, mockURI);
    }

    function testSetProfileMetadataURINotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileMetadataURI(firstProfileId, mockURI);
    }

    // Positives
    function testExecutorSetFollowModule() public {
        assertEq(hub.getFollowModule(firstProfileId), address(0));
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        address mockFollowModule = address(new MockFollowModule());

        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);

        vm.prank(otherSigner);
        hub.setFollowModule(firstProfileId, mockFollowModule, abi.encode(1));
        assertEq(hub.getFollowModule(firstProfileId), mockFollowModule);
    }

    function testExecutorSetDefaultProfile() public {
        assertEq(hub.getDefaultProfile(profileOwner), 0);
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        hub.setDefaultProfile(profileOwner, firstProfileId);
        assertEq(hub.getDefaultProfile(profileOwner), firstProfileId);
    }

    function testExecutorSetProfileImageURI() public {
        assertEq(hub.getProfileImageURI(firstProfileId), mockURI);
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        hub.setProfileImageURI(firstProfileId, 'test');
        assertEq(hub.getProfileImageURI(firstProfileId), 'test');
    }

    function testExecutorSetFollowNFTURI() public {
        assertEq(hub.getFollowNFTURI(firstProfileId), mockURI);
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        hub.setFollowNFTURI(firstProfileId, 'test');
        assertEq(hub.getFollowNFTURI(firstProfileId), 'test');
    }

    function testExecutorSetProfileMetadataURI() public {
        assertEq(hub.getProfileMetadataURI(firstProfileId), '');
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        hub.setProfileMetadataURI(firstProfileId, mockURI);
        assertEq(hub.getProfileMetadataURI(firstProfileId), mockURI);
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

    function testSetProfileImageURIWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(
            firstProfileId,
            mockURI,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setProfileImageURIWithSig(
            DataTypes.SetProfileImageURIWithSigData({
                delegatedSigner: address(0),
                profileId: firstProfileId,
                imageURI: mockURI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetProfileImageURIWithSigNotExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(
            firstProfileId,
            mockURI,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileImageURIWithSig(
            DataTypes.SetProfileImageURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                imageURI: mockURI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetFollowNFTURIWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDatahash(firstProfileId, mockURI, nonce, deadline);

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setFollowNFTURIWithSig(
            DataTypes.SetFollowNFTURIWithSigData({
                delegatedSigner: address(0),
                profileId: firstProfileId,
                followNFTURI: mockURI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetFollowNFTURIWithSigNotExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDatahash(firstProfileId, mockURI, nonce, deadline);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowNFTURIWithSig(
            DataTypes.SetFollowNFTURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                followNFTURI: mockURI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetProfileMetadataURIWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileMetadataURITypedDataHash(
            firstProfileId,
            mockURI,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setProfileMetadataURIWithSig(
            DataTypes.SetProfileMetadataURIWithSigData({
                delegatedSigner: address(0),
                profileId: firstProfileId,
                metadataURI: mockURI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetProfileMetadataURIWithSigNotExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileMetadataURITypedDataHash(
            firstProfileId,
            mockURI,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileMetadataURIWithSig(
            DataTypes.SetProfileMetadataURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                metadataURI: mockURI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    // Postivies
    function testSetFollowModuleWithSig() public {
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
                delegatedSigner: address(0),
                profileId: firstProfileId,
                followModule: address(0),
                followModuleInitData: '',
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

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

    function testSetDefaultProfileWithSig() public {
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
                delegatedSigner: address(0),
                wallet: profileOwner,
                profileId: firstProfileId,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    function testExecutorSetDefaultProfileWithSig() public {
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

    function testSetProfileImageURIWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(
            firstProfileId,
            mockURI,
            nonce,
            deadline
        );

        hub.setProfileImageURIWithSig(
            DataTypes.SetProfileImageURIWithSigData({
                delegatedSigner: address(0),
                profileId: firstProfileId,
                imageURI: mockURI,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    function testExecutorSetProfileImageURIWithSig() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(
            firstProfileId,
            mockURI,
            nonce,
            deadline
        );

        hub.setProfileImageURIWithSig(
            DataTypes.SetProfileImageURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                imageURI: mockURI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetFollowNFTURIWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDatahash(firstProfileId, mockURI, nonce, deadline);

        hub.setFollowNFTURIWithSig(
            DataTypes.SetFollowNFTURIWithSigData({
                delegatedSigner: address(0),
                profileId: firstProfileId,
                followNFTURI: mockURI,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    function testExecutorSetFollowNFTURIWithSig() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDatahash(firstProfileId, mockURI, nonce, deadline);

        hub.setFollowNFTURIWithSig(
            DataTypes.SetFollowNFTURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                followNFTURI: mockURI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetProfileMetadataURIWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileMetadataURITypedDataHash(
            firstProfileId,
            mockURI,
            nonce,
            deadline
        );

        hub.setProfileMetadataURIWithSig(
            DataTypes.SetProfileMetadataURIWithSigData({
                delegatedSigner: address(0),
                profileId: firstProfileId,
                metadataURI: mockURI,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    function testExecutorSetProfileMetadataURIWithSig() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileMetadataURITypedDataHash(
            firstProfileId,
            mockURI,
            nonce,
            deadline
        );

        hub.setProfileMetadataURIWithSig(
            DataTypes.SetProfileMetadataURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: firstProfileId,
                metadataURI: mockURI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }
}
