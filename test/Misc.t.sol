// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/mocks/MockFollowModule.sol';

// New Misc
contract MiscTest is BaseTest {
    // Negatives
    function testSetProfileImageURINotDelegatedExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileImageURI(newProfileId, MOCK_URI);
    }

    // Positives
    function testDelegatedExecutorSetProfileImageURI() public {
        assertEq(hub.getProfileImageURI(newProfileId), MOCK_URI);
        vm.prank(profileOwner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: newProfileId,
            delegatedExecutors: _toAddressArray(otherSigner),
            approvals: _toBoolArray(true)
        });

        vm.prank(otherSigner);
        hub.setProfileImageURI(newProfileId, 'test');
        assertEq(hub.getProfileImageURI(newProfileId), 'test');
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
        hub.changeDelegatedExecutorsConfig({
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
}
