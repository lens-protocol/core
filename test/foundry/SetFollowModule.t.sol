// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'test/foundry/base/BaseTest.t.sol';
import 'test/mocks/MockFollowModule.sol';
import 'test/foundry/helpers/SignatureHelpers.sol';

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
            newProfileId,
            mockFollowModule,
            abi.encode(1),
            nonce,
            digestDeadline
        );

        hub.setFollowModuleWithSig({
            profileId: newProfileId,
            followModule: mockFollowModule,
            followModuleInitData: abi.encode(1),
            signature: _getSigStruct(delegatedSigner, signerPrivKey, digest, sigDeadline)
        });
    }

    // Negatives
    function testCannotSetFollowModuleNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        hub.setFollowModule(newProfileId, address(0), '');
    }

    function testCannotSetFollowModuleNotWhitelisted() public {
        vm.expectRevert(Errors.FollowModuleNotWhitelisted.selector);
        vm.prank(profileOwner);
        hub.setFollowModule(newProfileId, address(1), '');
    }

    function testCannotSetFollowModuleWithWrongInitData() public {
        vm.expectRevert(bytes(''));
        vm.prank(profileOwner);
        hub.setFollowModule(newProfileId, mockFollowModule, '');
    }

    // Positives
    function testSetFollowModule() public {
        vm.prank(profileOwner);
        hub.setFollowModule(newProfileId, mockFollowModule, abi.encode(1));
        assertEq(hub.getFollowModule(newProfileId), mockFollowModule);

        vm.prank(profileOwner);
        hub.setFollowModule(newProfileId, address(0), '');
        assertEq(hub.getFollowModule(newProfileId), address(0));
    }

    function testExecutorSetFollowModule() public {
        assertEq(hub.getFollowModule(newProfileId), address(0));
        vm.prank(profileOwner);
        hub.changeCurrentDelegatedExecutorsConfig({
            delegatorProfileId: newProfileId,
            executors: _toAddressArray(otherSigner),
            approvals: _toBoolArray(true)
        });

        mockFollowModule = address(new MockFollowModule());
        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);

        vm.prank(otherSigner);
        hub.setFollowModule(newProfileId, mockFollowModule, abi.encode(1));
        assertEq(hub.getFollowModule(newProfileId), mockFollowModule);
    }

    // Meta-tx
    // Negatives
    function testCannotSetFollowModuleNotWhitelistedWithSig() public {
        vm.expectRevert(Errors.FollowModuleNotWhitelisted.selector);
        bytes32 digest = _getSetFollowModuleTypedDataHash(newProfileId, address(1), '', nonce, deadline);

        hub.setFollowModuleWithSig({
            profileId: newProfileId,
            followModule: address(1),
            followModuleInitData: '',
            signature: _getSigStruct(profileOwner, profileOwnerKey, digest, deadline)
        });
    }

    function testCannotPublishWithSigInvalidSigner() public {
        address delegatedSigner = profileOwner;
        uint256 signerPrivKey = otherSignerKey;
        assertTrue(vm.addr(signerPrivKey) != delegatedSigner);
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig(delegatedSigner, signerPrivKey);
    }

    function testCannotPublishWithSigInvalidNonce() public {
        nonce = _getSigNonce(profileOwner) + 1;
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
    }

    function testCannotPublishWithSigInvalidDeadline() public {
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig({
            delegatedSigner: profileOwner,
            signerPrivKey: profileOwnerKey,
            digestDeadline: type(uint256).max,
            sigDeadline: block.timestamp + 10
        });
    }

    function testCannotPublishIfNonceWasIncrementedWithAnotherAction() public {
        assertEq(_getSigNonce(profileOwner), nonce, 'Wrong nonce before posting');

        _setFollowModulehWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});

        assertTrue(_getSigNonce(profileOwner) != nonce, 'Wrong nonce after posting');

        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
    }

    function testCannotPublishWithSigExpiredDeadline() public {
        deadline = 10;
        vm.warp(20);

        vm.expectRevert(Errors.SignatureExpired.selector);
        _setFollowModulehWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
    }

    function testCannotPublishWithSigNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _setFollowModulehWithSig({delegatedSigner: otherSigner, signerPrivKey: otherSignerKey});
    }

    function testSetFollowModuleWithSigNotExecutorFails() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _setFollowModulehWithSig({delegatedSigner: otherSigner, signerPrivKey: otherSignerKey});
    }

    // Postivies
    function testPublishWithSig() public {
        assertEq(hub.getFollowModule(newProfileId), address(0));
        _setFollowModulehWithSig({delegatedSigner: profileOwner, signerPrivKey: profileOwnerKey});
        assertEq(hub.getFollowModule(newProfileId), mockFollowModule);
    }

    function testExecutorPublishWithSig() public {
        _changeDelegatedExecutorsConfig(profileOwner, newProfileId, otherSigner, true);

        assertEq(hub.getFollowModule(newProfileId), address(0));
        _setFollowModulehWithSig({delegatedSigner: otherSigner, signerPrivKey: otherSignerKey});
        assertEq(hub.getFollowModule(newProfileId), mockFollowModule);
    }
}
