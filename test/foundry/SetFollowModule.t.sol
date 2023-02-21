// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import '../../contracts/mocks/MockFollowModule.sol';
import './helpers/SignatureHelpers.sol';

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

    function _setFollowModulehWithSig(address delegatedSigner, uint256 signerPrivKey)
        internal
        virtual
    {
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

        hub.setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                delegatedSigner: delegatedSigner,
                profileId: newProfileId,
                followModule: mockFollowModule,
                followModuleInitData: abi.encode(1),
                sig: _getSigStruct(signerPrivKey, digest, sigDeadline)
            })
        );
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
        hub.changeDelegatedExecutorsConfig({
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
        bytes32 digest = _getSetFollowModuleTypedDataHash(
            newProfileId,
            address(1),
            '',
            nonce,
            deadline
        );

        hub.setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                delegatedSigner: address(0),
                profileId: newProfileId,
                followModule: address(1),
                followModuleInitData: '',
                sig: _getSigStruct(profileOwnerKey, digest, deadline)
            })
        );
    }

    function testCannotPublishWithSigInvalidSigner() public {
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig({delegatedSigner: address(0), signerPrivKey: otherSignerKey});
    }

    function testCannotPublishWithSigInvalidNonce() public {
        nonce = _getSigNonce(otherSigner) + 1;
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig({delegatedSigner: address(0), signerPrivKey: otherSignerKey});
    }

    function testCannotPublishWithSigInvalidDeadline() public {
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey,
            digestDeadline: type(uint256).max,
            sigDeadline: block.timestamp + 10
        });
    }

    function testCannotPublishIfNonceWasIncrementedWithAnotherAction() public {
        assertEq(_getSigNonce(profileOwner), nonce, 'Wrong nonce before posting');

        _setFollowModulehWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});

        assertTrue(_getSigNonce(profileOwner) != nonce, 'Wrong nonce after posting');

        vm.expectRevert(Errors.SignatureInvalid.selector);
        _setFollowModulehWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotPublishWithSigExpiredDeadline() public {
        deadline = 10;
        vm.warp(20);

        vm.expectRevert(Errors.SignatureExpired.selector);
        _setFollowModulehWithSig({delegatedSigner: address(0), signerPrivKey: otherSignerKey});
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
        _setFollowModulehWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
        assertEq(hub.getFollowModule(newProfileId), mockFollowModule);
    }

    function testExecutorPublishWithSig() public {
        _changeDelegatedExecutorsConfig(profileOwner, newProfileId, otherSigner, true);

        assertEq(hub.getFollowModule(newProfileId), address(0));
        _setFollowModulehWithSig({delegatedSigner: otherSigner, signerPrivKey: otherSignerKey});
        assertEq(hub.getFollowModule(newProfileId), mockFollowModule);
    }
}
