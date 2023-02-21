// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'test/foundry/base/BaseTest.t.sol';
import 'contracts/mocks/MockFollowModule.sol';

// Original Misc
contract NFTTransferEmittersTest is BaseTest {
    // Negatives
    function testCannotEmitFollowNFTTransferEvent() public {
        vm.expectRevert(Errors.CallerNotFollowNFT.selector);
        hub.emitFollowNFTTransferEvent(newProfileId, 1, profileOwner, otherSigner);
    }

    function testCannotEmitCollectNFTTransferEvent() public {
        vm.expectRevert(Errors.CallerNotCollectNFT.selector);
        hub.emitCollectNFTTransferEvent(newProfileId, 1, 1, profileOwner, otherSigner);
    }
}

// New Misc
contract MiscTest is BaseTest {
    // Negatives
    function testSetProfileImageURINotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileImageURI(newProfileId, MOCK_URI);
    }

    function testSetFollowNFTURINotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowNFTURI(newProfileId, MOCK_URI);
    }

    // Positives
    function testExecutorSetProfileImageURI() public {
        assertEq(hub.getProfileImageURI(newProfileId), MOCK_URI);
        vm.prank(profileOwner);
        hub.changeCurrentDelegatedExecutorsConfig({
            delegatorProfileId: newProfileId,
            executors: _toAddressArray(otherSigner),
            approvals: _toBoolArray(true)
        });

        vm.prank(otherSigner);
        hub.setProfileImageURI(newProfileId, 'test');
        assertEq(hub.getProfileImageURI(newProfileId), 'test');
    }

    function testExecutorSetFollowNFTURI() public {
        assertEq(hub.getFollowNFTURI(newProfileId), MOCK_URI);
        vm.prank(profileOwner);
        hub.changeCurrentDelegatedExecutorsConfig({
            delegatorProfileId: newProfileId,
            executors: _toAddressArray(otherSigner),
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

    function testSetProfileImageURIWithSigNotExecutorFails() public {
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

    function testSetFollowNFTURIWithSigNotExecutorFails() public {
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

    function testExecutorSetProfileImageURIWithSig() public {
        vm.prank(profileOwner);
        hub.changeCurrentDelegatedExecutorsConfig({
            delegatorProfileId: newProfileId,
            executors: _toAddressArray(otherSigner),
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

    function testExecutorSetFollowNFTURIWithSig() public {
        vm.prank(profileOwner);
        hub.changeCurrentDelegatedExecutorsConfig({
            delegatorProfileId: newProfileId,
            executors: _toAddressArray(otherSigner),
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
