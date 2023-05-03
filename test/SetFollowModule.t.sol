// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/mocks/MockFollowModule.sol';

// TODO: Refactor out all `hub.` calls (if we decide to go this route)
contract SetFollowModuleTest is BaseTest {
    address mockFollowModule;

    function setUp() public virtual override(BaseTest) {
        BaseTest.setUp();
        mockFollowModule = address(new MockFollowModule());
        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);
    }

    // function _setFollowModulehWithSig(address delegatedSigner, uint256 signerPrivKey) internal virtual {
    //     _setFollowModulehWithSig(delegatedSigner, signerPrivKey, deadline, deadline);
    // }

    // function _setFollowModulehWithSig(
    //     address delegatedSigner,
    //     uint256 signerPrivKey,
    //     uint256 digestDeadline,
    //     uint256 sigDeadline
    // ) internal virtual {
    //     bytes32 digest = _getSetFollowModuleTypedDataHash(
    //         defaultAccount.profileId,
    //         mockFollowModule,
    //         abi.encode(true),
    //         nonce,
    //         digestDeadline
    //     );

    //     hub.setFollowModuleWithSig({
    //         profileId: defaultAccount.profileId,
    //         followModule: mockFollowModule,
    //         followModuleInitData: abi.encode(true),
    //         signature: _getSigStruct(delegatedSigner, signerPrivKey, digest, sigDeadline)
    //     });
    // }

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

    function testDelegatedExecutorSetFollowModule(address delegatedExecutor) public {
        vm.assume(delegatedExecutor != address(0));
        vm.assume(delegatedExecutor != defaultAccount.owner);
        vm.assume(delegatedExecutor != proxyAdmin);

        assertEq(hub.getFollowModule(defaultAccount.profileId), address(0));
        vm.prank(defaultAccount.owner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: defaultAccount.profileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true)
        });

        mockFollowModule = address(new MockFollowModule());
        vm.prank(governance);
        hub.whitelistFollowModule(mockFollowModule, true);

        vm.prank(delegatedExecutor);
        hub.setFollowModule(defaultAccount.profileId, mockFollowModule, abi.encode(true));
        assertEq(hub.getFollowModule(defaultAccount.profileId), mockFollowModule);
    }
}
