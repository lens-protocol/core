// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/mocks/MockFollowModule.sol';
import 'test/helpers/SignatureHelpers.sol';

// TODO: Refactor out all `hub.` calls (if we decide to go this route)
contract SetFollowModuleTest is BaseTest, SigSetup {
    address mockFollowModule;

    function setUp() public virtual override(SigSetup, TestSetup) {
        TestSetup.setUp();
        SigSetup.setUp();
        mockFollowModule = address(new MockFollowModule());
        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);
    }

    function _setFollowModulehWithSig(address delegatedSigner, uint256 signerPrivKey) internal virtual {
        _setFollowModulehWithSig(delegatedSigner, signerPrivKey, deadline, deadline);
    }

    function _setFollowModulehWithSig(
        address delegatedSigner,
        uint256 signerPrivKey,
        uint256 digestDeadline,
        uint256 sigDeadline
    ) internal virtual {
        bytes32 digest = _getSetFollowModuleTypedDataHash(
            defaultAccount.profileId,
            mockFollowModule,
            abi.encode(true),
            nonce,
            digestDeadline
        );

        hub.setFollowModuleWithSig({
            profileId: defaultAccount.profileId,
            followModule: mockFollowModule,
            followModuleInitData: abi.encode(true),
            signature: _getSigStruct(delegatedSigner, signerPrivKey, digest, sigDeadline)
        });
    }

    // Negatives
    function testCannotSetFollowModuleNotDelegatedExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowModule(defaultAccount.profileId, address(0), '');
    }

    function testCannotSetFollowModuleNotWhitelisted() public {
        vm.expectRevert(Errors.NotWhitelisted.selector);
        vm.prank(defaultAccount.owner);
        hub.setFollowModule(defaultAccount.profileId, address(1), '');
    }

    function testCannotSetFollowModuleWithWrongInitData() public {
        vm.expectRevert(bytes(''));
        vm.prank(defaultAccount.owner);
        hub.setFollowModule(defaultAccount.profileId, mockFollowModule, '');
    }

    // Positives
    function testSetFollowModule() public {
        vm.prank(defaultAccount.owner);
        hub.setFollowModule(defaultAccount.profileId, mockFollowModule, abi.encode(true));
        assertEq(hub.getFollowModule(defaultAccount.profileId), mockFollowModule);

        vm.prank(defaultAccount.owner);
        hub.setFollowModule(defaultAccount.profileId, address(0), '');
        assertEq(hub.getFollowModule(defaultAccount.profileId), address(0));
    }

    function testDelegatedExecutorSetFollowModule() public {
        assertEq(hub.getFollowModule(defaultAccount.profileId), address(0));
        vm.prank(defaultAccount.owner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: defaultAccount.profileId,
            delegatedExecutors: _toAddressArray(otherSigner.owner),
            approvals: _toBoolArray(true)
        });

        mockFollowModule = address(new MockFollowModule());
        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);

        vm.prank(otherSigner.owner);
        hub.setFollowModule(defaultAccount.profileId, mockFollowModule, abi.encode(true));
        assertEq(hub.getFollowModule(defaultAccount.profileId), mockFollowModule);
    }

    // Meta-tx
    // Negatives
    function testCannotSetFollowModuleNotWhitelistedWithSig() public {
        vm.expectRevert(Errors.NotWhitelisted.selector);
        bytes32 digest = _getSetFollowModuleTypedDataHash(defaultAccount.profileId, address(1), '', nonce, deadline);

        hub.setFollowModuleWithSig({
            profileId: defaultAccount.profileId,
            followModule: address(1),
            followModuleInitData: '',
            signature: _getSigStruct(defaultAccount.owner, defaultAccount.ownerPk, digest, deadline)
        });
    }

    function testCannotPublishWithSigInvalidSigner() public {
        address delegatedSigner = defaultAccount.owner;
        uint256 signerPrivKey = otherSigner.ownerPk;
        assertTrue(vm.addr(signerPrivKey) != delegatedSigner);
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig(delegatedSigner, signerPrivKey);
    }

    function testCannotPublishWithSigInvalidNonce() public {
        nonce = _getSigNonce(defaultAccount.owner) + 1;
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig({delegatedSigner: defaultAccount.owner, signerPrivKey: defaultAccount.ownerPk});
    }

    function testCannotPublishWithSigInvalidDeadline() public {
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig({
            delegatedSigner: defaultAccount.owner,
            signerPrivKey: defaultAccount.ownerPk,
            digestDeadline: type(uint256).max,
            sigDeadline: block.timestamp + 10
        });
    }

    function testCannotPublishIfNonceWasIncrementedWithAnotherAction() public {
        assertEq(_getSigNonce(defaultAccount.owner), nonce, 'Wrong nonce before posting');

        _setFollowModulehWithSig({delegatedSigner: defaultAccount.owner, signerPrivKey: defaultAccount.ownerPk});

        assertTrue(_getSigNonce(defaultAccount.owner) != nonce, 'Wrong nonce after posting');

        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig({delegatedSigner: defaultAccount.owner, signerPrivKey: defaultAccount.ownerPk});
    }

    function testCannotPublishWithSigExpiredDeadline() public {
        deadline = 10;
        vm.warp(20);

        vm.expectRevert(Errors.SignatureExpired.selector);
        _setFollowModulehWithSig({delegatedSigner: defaultAccount.owner, signerPrivKey: defaultAccount.ownerPk});
    }

    function testCannotPublishWithSigNotDelegatedExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _setFollowModulehWithSig({delegatedSigner: otherSigner.owner, signerPrivKey: otherSigner.ownerPk});
    }

    function testSetFollowModuleWithSigNotDelegatedExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _setFollowModulehWithSig({delegatedSigner: otherSigner.owner, signerPrivKey: otherSigner.ownerPk});
    }

    // Postivies
    function testPublishWithSig() public {
        assertEq(hub.getFollowModule(defaultAccount.profileId), address(0));
        _setFollowModulehWithSig({delegatedSigner: defaultAccount.owner, signerPrivKey: defaultAccount.ownerPk});
        assertEq(hub.getFollowModule(defaultAccount.profileId), mockFollowModule);
    }

    function testDelegatedExecutorPublishWithSig() public {
        _changeDelegatedExecutorsConfig(defaultAccount.owner, defaultAccount.profileId, otherSigner.owner, true);

        assertEq(hub.getFollowModule(defaultAccount.profileId), address(0));
        _setFollowModulehWithSig({delegatedSigner: otherSigner.owner, signerPrivKey: otherSigner.ownerPk});
        assertEq(hub.getFollowModule(defaultAccount.profileId), mockFollowModule);
    }
}
