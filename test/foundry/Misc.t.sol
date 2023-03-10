// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'test/foundry/base/BaseTest.t.sol';
import 'test/mocks/MockFollowModule.sol';

// New Misc
contract MiscTest is BaseTest {
    // Negatives
    function testSetProfileImageURINotDelegatedExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileImageURI(newProfileId, MOCK_URI);
    }

    function testSetFollowNFTURINotDelegatedExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowNFTURI(newProfileId, MOCK_URI);
    }

    // Positives
    function testDelegatedExecutorSetProfileImageURI() public {
        assertEq(hub.getProfileImageURI(newProfileId), MOCK_URI);
        vm.prank(profileOwner);
        hub.changeCurrentDelegatedExecutorsConfig({
            delegatorProfileId: newProfileId,
            delegatedExecutors: _toAddressArray(otherSigner),
            approvals: _toBoolArray(true)
        });

        vm.prank(otherSigner);
        hub.setProfileImageURI(newProfileId, 'test');
        assertEq(hub.getProfileImageURI(newProfileId), 'test');
    }

    function testDelegatedExecutorSetFollowNFTURI() public {
        assertEq(hub.getFollowNFTURI(newProfileId), MOCK_URI);
        vm.prank(profileOwner);
        hub.changeCurrentDelegatedExecutorsConfig({
            delegatorProfileId: newProfileId,
            delegatedExecutors: _toAddressArray(otherSigner),
            approvals: _toBoolArray(true)
        });

        vm.prank(otherSigner);
        hub.setFollowNFTURI(newProfileId, 'test');
        assertEq(hub.getFollowNFTURI(newProfileId), 'test');
    }

    // Meta-tx
    // Negatives
    function testSetProfileImageURIWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(newProfileId, MOCK_URI, nonce, deadline);

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setProfileImageURIWithSig({
            profileId: newProfileId,
            imageURI: MOCK_URI,
            signature: _getSigStruct(profileOwner, otherSignerKey, digest, deadline)
        });
    }

    function testSetProfileImageURIWithSigNotDelegatedExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(newProfileId, MOCK_URI, nonce, deadline);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileImageURIWithSig({
            profileId: newProfileId,
            imageURI: MOCK_URI,
            signature: _getSigStruct(otherSigner, otherSignerKey, digest, deadline)
        });
    }

    function testSetFollowNFTURIWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDataHash(newProfileId, MOCK_URI, nonce, deadline);

        address delegatedSigner = profileOwner;
        uint256 signerPrivKey = otherSignerKey;
        assertTrue(vm.addr(signerPrivKey) != delegatedSigner);

        vm.expectRevert(Errors.SignatureInvalid.selector);
        hub.setFollowNFTURIWithSig({
            profileId: newProfileId,
            followNFTURI: MOCK_URI,
            signature: _getSigStruct(delegatedSigner, signerPrivKey, digest, deadline)
        });
    }

    function testSetFollowNFTURIWithSigNotDelegatedExecutorFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDataHash(newProfileId, MOCK_URI, nonce, deadline);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowNFTURIWithSig({
            profileId: newProfileId,
            followNFTURI: MOCK_URI,
            signature: _getSigStruct(otherSignerKey, digest, deadline)
        });
    }

    // Postivies
    function testSetProfileImageURIWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(newProfileId, 'test', nonce, deadline);

        assertEq(hub.getProfileImageURI(newProfileId), MOCK_URI);
        hub.setProfileImageURIWithSig({
            profileId: newProfileId,
            imageURI: 'test',
            signature: _getSigStruct(profileOwner, profileOwnerKey, digest, deadline)
        });
        assertEq(hub.getProfileImageURI(newProfileId), 'test');
    }

    function testDelegatedExecutorSetProfileImageURIWithSig() public {
        vm.prank(profileOwner);
        hub.changeCurrentDelegatedExecutorsConfig({
            delegatorProfileId: newProfileId,
            delegatedExecutors: _toAddressArray(otherSigner),
            approvals: _toBoolArray(true)
        });

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(newProfileId, 'test', nonce, deadline);

        assertEq(hub.getProfileImageURI(newProfileId), MOCK_URI);
        hub.setProfileImageURIWithSig({
            profileId: newProfileId,
            imageURI: 'test',
            signature: _getSigStruct(otherSigner, otherSignerKey, digest, deadline)
        });
        assertEq(hub.getProfileImageURI(newProfileId), 'test');
    }

    function testSetFollowNFTURIWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDataHash(newProfileId, 'test', nonce, deadline);

        assertEq(hub.getFollowNFTURI(newProfileId), MOCK_URI);
        hub.setFollowNFTURIWithSig({
            profileId: newProfileId,
            followNFTURI: 'test',
            signature: _getSigStruct(profileOwner, profileOwnerKey, digest, deadline)
        });
        assertEq(hub.getFollowNFTURI(newProfileId), 'test');
    }

    function testDelegatedExecutorSetFollowNFTURIWithSig() public {
        vm.prank(profileOwner);
        hub.changeCurrentDelegatedExecutorsConfig({
            delegatorProfileId: newProfileId,
            delegatedExecutors: _toAddressArray(otherSigner),
            approvals: _toBoolArray(true)
        });

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowNFTURITypedDataHash(newProfileId, 'test', nonce, deadline);

        assertEq(hub.getFollowNFTURI(newProfileId), MOCK_URI);
        hub.setFollowNFTURIWithSig({
            profileId: newProfileId,
            followNFTURI: 'test',
            signature: _getSigStruct(otherSigner, otherSignerKey, digest, deadline)
        });
        assertEq(hub.getFollowNFTURI(newProfileId), 'test');
    }
}
