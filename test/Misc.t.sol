// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/mocks/MockFollowModule.sol';

// New Misc
contract MiscTest is BaseTest {
    // Negatives
    function testSetProfileImageURINotDelegatedExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setProfileImageURI(defaultAccount.profileId, MOCK_URI);
    }

    // Positives
    function testDelegatedExecutorSetProfileImageURI(address delegatedExecutor) public {
        vm.assume(delegatedExecutor != address(0));
        vm.assume(delegatedExecutor != defaultAccount.owner);
        vm.assume(delegatedExecutor != proxyAdmin);

        console.log(hub.getProfileImageURI(defaultAccount.profileId));
        assertEq(hub.getProfileImageURI(defaultAccount.profileId), MOCK_URI);

        vm.prank(defaultAccount.owner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: defaultAccount.profileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true)
        });

        vm.prank(delegatedExecutor);
        hub.setProfileImageURI(defaultAccount.profileId, 'test');
        assertEq(hub.getProfileImageURI(defaultAccount.profileId), 'test');
    }

    // Meta-tx
    // Negatives
    function testSetProfileImageURIWithSigInvalidSignerFails(uint256 otherSignerPk) public {
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

    function testSetProfileImageURIWithSigNotDelegatedExecutorFails(uint256 otherSignerPk) public {
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

    // Postivies
    function testSetProfileImageURIWithSig() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetProfileImageURITypedDataHash(defaultAccount.profileId, 'test', nonce, deadline);

        assertEq(hub.getProfileImageURI(defaultAccount.profileId), MOCK_URI);
        hub.setProfileImageURIWithSig({
            profileId: defaultAccount.profileId,
            imageURI: 'test',
            signature: _getSigStruct(defaultAccount.ownerPk, digest, deadline)
        });
        assertEq(hub.getProfileImageURI(defaultAccount.profileId), 'test');
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

        assertEq(hub.getProfileImageURI(defaultAccount.profileId), MOCK_URI);
        hub.setProfileImageURIWithSig({
            profileId: defaultAccount.profileId,
            imageURI: 'test',
            signature: _getSigStruct(delegatedExecutorPk, digest, deadline)
        });
        assertEq(hub.getProfileImageURI(defaultAccount.profileId), 'test');
    }
}
