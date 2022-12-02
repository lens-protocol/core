// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import '../../contracts/mocks/MockFollowModule.sol';

contract MiscTest is BaseTest {
    // Negatives
    function testSetFollowModuleNotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowModule(newProfileId, address(0), '');
    }

    function testSetDefaultProfileNotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setDefaultProfile(profileOwner, newProfileId);
    }

    function testSetProfileImageURINotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileImageURI(newProfileId, MOCK_URI);
    }

    function testSetFollowNFTURINotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowNFTURI(newProfileId, MOCK_URI);
    }

    function testSetProfileMetadataURINotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileMetadataURI(newProfileId, MOCK_URI);
    }

    // Positives
    function testExecutorSetFollowModule() public {
        assertEq(hub.getFollowModule(newProfileId), address(0));
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        address mockFollowModule = address(new MockFollowModule());
        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);

        vm.prank(otherSigner);
        hub.setFollowModule(newProfileId, mockFollowModule, abi.encode(1));
        assertEq(hub.getFollowModule(newProfileId), mockFollowModule);
    }

    function testExecutorSetDefaultProfile() public {
        assertEq(hub.getDefaultProfile(profileOwner), 0);
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        hub.setDefaultProfile(profileOwner, newProfileId);
        assertEq(hub.getDefaultProfile(profileOwner), newProfileId);
    }

    function testExecutorSetProfileImageURI() public {
        assertEq(hub.getProfileImageURI(newProfileId), MOCK_URI);
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        hub.setProfileImageURI(newProfileId, 'test');
        assertEq(hub.getProfileImageURI(newProfileId), 'test');
    }

    function testExecutorSetFollowNFTURI() public {
        assertEq(hub.getFollowNFTURI(newProfileId), MOCK_URI);
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        hub.setFollowNFTURI(newProfileId, 'test');
        assertEq(hub.getFollowNFTURI(newProfileId), 'test');
    }

    function testExecutorSetProfileMetadataURI() public {
        assertEq(hub.getProfileMetadataURI(newProfileId), '');
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        hub.setProfileMetadataURI(newProfileId, MOCK_URI);
        assertEq(hub.getProfileMetadataURI(newProfileId), MOCK_URI);
    }

    // Meta-tx
    // Negatives
    function testSetFollowModuleWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowModuleTypedDataHash(
            newProfileId,
            address(0),
            '',
            nonce,
            deadline
        );

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
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
            newProfileId,
            address(0),
            '',
            nonce,
            deadline
        );

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                delegatedSigner: otherSigner,
                profileId: newProfileId,
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
            newProfileId,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setDefaultProfileWithSig(
            DataTypes.SetDefaultProfileWithSigData({
                delegatedSigner: address(0),
                wallet: profileOwner,
                profileId: newProfileId,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetDefaultProfileWithSigNotExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetDefaultProfileTypedDataHash(
            profileOwner,
            newProfileId,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setDefaultProfileWithSig(
            DataTypes.SetDefaultProfileWithSigData({
                delegatedSigner: otherSigner,
                wallet: profileOwner,
                profileId: newProfileId,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetProfileImageURIWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(
            newProfileId,
            MOCK_URI,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setProfileImageURIWithSig(
            DataTypes.SetProfileImageURIWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
                imageURI: MOCK_URI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetProfileImageURIWithSigNotExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(
            newProfileId,
            MOCK_URI,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileImageURIWithSig(
            DataTypes.SetProfileImageURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: newProfileId,
                imageURI: MOCK_URI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetFollowNFTURIWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDatahash(newProfileId, MOCK_URI, nonce, deadline);

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setFollowNFTURIWithSig(
            DataTypes.SetFollowNFTURIWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
                followNFTURI: MOCK_URI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetFollowNFTURIWithSigNotExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDatahash(newProfileId, MOCK_URI, nonce, deadline);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowNFTURIWithSig(
            DataTypes.SetFollowNFTURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: newProfileId,
                followNFTURI: MOCK_URI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetProfileMetadataURIWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileMetadataURITypedDataHash(
            newProfileId,
            MOCK_URI,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setProfileMetadataURIWithSig(
            DataTypes.SetProfileMetadataURIWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
                metadataURI: MOCK_URI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    function testSetProfileMetadataURIWithSigNotExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileMetadataURITypedDataHash(
            newProfileId,
            MOCK_URI,
            nonce,
            deadline
        );

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileMetadataURIWithSig(
            DataTypes.SetProfileMetadataURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: newProfileId,
                metadataURI: MOCK_URI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    // Postivies
    function testSetFollowModuleWithSig() public {
        address mockFollowModule = address(new MockFollowModule());
        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;

        bytes32 digest = _getSetFollowModuleTypedDataHash(
            newProfileId,
            mockFollowModule,
            abi.encode(1),
            nonce,
            deadline
        );

        assertEq(hub.getFollowModule(newProfileId), address(0));
        hub.setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
                followModule: mockFollowModule,
                followModuleInitData: abi.encode(1),
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
        assertEq(hub.getFollowModule(newProfileId), mockFollowModule);
    }

    function testExecutorSetFollowModuleWithSig() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        address mockFollowModule = address(new MockFollowModule());
        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowModuleTypedDataHash(
            newProfileId,
            mockFollowModule,
            abi.encode(1),
            nonce,
            deadline
        );

        assertEq(hub.getFollowModule(newProfileId), address(0));
        hub.setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                delegatedSigner: otherSigner,
                profileId: newProfileId,
                followModule: mockFollowModule,
                followModuleInitData: abi.encode(1),
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
        assertEq(hub.getFollowModule(newProfileId), mockFollowModule);
    }

    function testSetDefaultProfileWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetDefaultProfileTypedDataHash(
            profileOwner,
            newProfileId,
            nonce,
            deadline
        );

        assertEq(hub.getDefaultProfile(profileOwner), 0);
        hub.setDefaultProfileWithSig(
            DataTypes.SetDefaultProfileWithSigData({
                delegatedSigner: address(0),
                wallet: profileOwner,
                profileId: newProfileId,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
        assertEq(hub.getDefaultProfile(profileOwner), newProfileId);
    }

    function testExecutorSetDefaultProfileWithSig() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetDefaultProfileTypedDataHash(
            profileOwner,
            newProfileId,
            nonce,
            deadline
        );

        assertEq(hub.getDefaultProfile(profileOwner), 0);
        hub.setDefaultProfileWithSig(
            DataTypes.SetDefaultProfileWithSigData({
                delegatedSigner: otherSigner,
                wallet: profileOwner,
                profileId: newProfileId,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
        assertEq(hub.getDefaultProfile(profileOwner), newProfileId);
    }

    function testSetProfileImageURIWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(newProfileId, 'test', nonce, deadline);

        assertEq(hub.getProfileImageURI(newProfileId), MOCK_URI);
        hub.setProfileImageURIWithSig(
            DataTypes.SetProfileImageURIWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
                imageURI: 'test',
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
        assertEq(hub.getProfileImageURI(newProfileId), 'test');
    }

    function testExecutorSetProfileImageURIWithSig() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(newProfileId, 'test', nonce, deadline);

        assertEq(hub.getProfileImageURI(newProfileId), MOCK_URI);
        hub.setProfileImageURIWithSig(
            DataTypes.SetProfileImageURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: newProfileId,
                imageURI: 'test',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
        assertEq(hub.getProfileImageURI(newProfileId), 'test');
    }

    function testSetFollowNFTURIWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDatahash(newProfileId, 'test', nonce, deadline);

        assertEq(hub.getFollowNFTURI(newProfileId), MOCK_URI);
        hub.setFollowNFTURIWithSig(
            DataTypes.SetFollowNFTURIWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
                followNFTURI: 'test',
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
        assertEq(hub.getFollowNFTURI(newProfileId), 'test');
    }

    function testExecutorSetFollowNFTURIWithSig() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDatahash(newProfileId, 'test', nonce, deadline);

        assertEq(hub.getFollowNFTURI(newProfileId), MOCK_URI);
        hub.setFollowNFTURIWithSig(
            DataTypes.SetFollowNFTURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: newProfileId,
                followNFTURI: 'test',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
        assertEq(hub.getFollowNFTURI(newProfileId), 'test');
    }

    function testSetProfileMetadataURIWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileMetadataURITypedDataHash(
            newProfileId,
            MOCK_URI,
            nonce,
            deadline
        );

        assertEq(hub.getProfileMetadataURI(newProfileId), '');
        hub.setProfileMetadataURIWithSig(
            DataTypes.SetProfileMetadataURIWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
                metadataURI: MOCK_URI,
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
        assertEq(hub.getProfileMetadataURI(newProfileId), MOCK_URI);
    }

    function testExecutorSetProfileMetadataURIWithSig() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileMetadataURITypedDataHash(
            newProfileId,
            MOCK_URI,
            nonce,
            deadline
        );

        assertEq(hub.getProfileMetadataURI(newProfileId), '');
        hub.setProfileMetadataURIWithSig(
            DataTypes.SetProfileMetadataURIWithSigData({
                delegatedSigner: otherSigner,
                profileId: newProfileId,
                metadataURI: MOCK_URI,
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
        assertEq(hub.getProfileMetadataURI(newProfileId), MOCK_URI);
    }
}
