// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/mocks/MockFollowModule.sol';
import 'test/MetaTxNegatives.t.sol';

contract SetFollowModuleTest is BaseTest {
    address mockFollowModule;

    function setUp() public virtual override(BaseTest) {
        BaseTest.setUp();
        mockFollowModule = address(new MockFollowModule(address(this)));
    }

    // Negatives
    function testCannot_SetFollowModule_IfNotProfileOwner(uint256 notOwnerPk) public {
        notOwnerPk = _boundPk(notOwnerPk);

        address notOwner = vm.addr(notOwnerPk);
        vm.assume(notOwner != address(0));
        vm.assume(notOwner != defaultAccount.owner);

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _setFollowModule({
            pk: notOwnerPk,
            profileId: defaultAccount.profileId,
            followModule: address(0),
            followModuleInitData: ''
        });
    }

    function testCannot_SetFollowModule_IfNotDelegatedExecutor(uint256 notDelegatedExecutorPk) public {
        notDelegatedExecutorPk = _boundPk(notDelegatedExecutorPk);

        address notDelegatedExecutor = vm.addr(notDelegatedExecutorPk);
        vm.assume(notDelegatedExecutor != address(0));
        vm.assume(notDelegatedExecutor != defaultAccount.owner);
        vm.assume(!hub.isDelegatedExecutorApproved(defaultAccount.profileId, notDelegatedExecutor));

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _setFollowModule({
            pk: notDelegatedExecutorPk,
            profileId: defaultAccount.profileId,
            followModule: address(0),
            followModuleInitData: ''
        });
    }

    function testCannot_SetFollowModule_WithWrongInitData() public {
        vm.expectRevert(bytes(''));
        _setFollowModule({
            pk: defaultAccount.ownerPk,
            profileId: defaultAccount.profileId,
            followModule: mockFollowModule,
            followModuleInitData: ''
        });
    }

    // Positives
    function testSetFollowModule() public {
        _setFollowModule({
            pk: defaultAccount.ownerPk,
            profileId: defaultAccount.profileId,
            followModule: mockFollowModule,
            followModuleInitData: abi.encode(true)
        });
        assertEq(hub.getProfile(defaultAccount.profileId).followModule, mockFollowModule);

        _refreshCachedNonces();

        _setFollowModule({
            pk: defaultAccount.ownerPk,
            profileId: defaultAccount.profileId,
            followModule: address(0),
            followModuleInitData: ''
        });
        assertEq(hub.getProfile(defaultAccount.profileId).followModule, address(0));
    }

    function testDelegatedExecutorSetFollowModule(uint256 delegatedExecutorPk) public {
        delegatedExecutorPk = _boundPk(delegatedExecutorPk);

        address delegatedExecutor = vm.addr(delegatedExecutorPk);
        vm.assume(delegatedExecutor != address(0));
        vm.assume(delegatedExecutor != defaultAccount.owner);
        vm.assume(delegatedExecutor != proxyAdmin);

        assertEq(hub.getProfile(defaultAccount.profileId).followModule, address(0));
        vm.prank(defaultAccount.owner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: defaultAccount.profileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true)
        });

        mockFollowModule = address(new MockFollowModule(address(this)));

        _setFollowModule({
            pk: delegatedExecutorPk,
            profileId: defaultAccount.profileId,
            followModule: mockFollowModule,
            followModuleInitData: abi.encode(true)
        });
        assertEq(hub.getProfile(defaultAccount.profileId).followModule, mockFollowModule);
    }

    function _setFollowModule(
        uint256 pk,
        uint256 profileId,
        address followModule,
        bytes memory followModuleInitData
    ) internal virtual {
        vm.prank(vm.addr(pk));
        hub.setFollowModule(profileId, followModule, followModuleInitData);
    }

    function _refreshCachedNonces() internal virtual {
        // Nothing to do there.
    }
}

contract SetFollowModuleMetaTxTest is SetFollowModuleTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function testSetFollowModuleMetaTxTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public override(SetFollowModuleTest, MetaTxNegatives) {
        SetFollowModuleTest.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
    }

    function _setFollowModule(
        uint256 pk,
        uint256 profileId,
        address followModule,
        bytes memory followModuleInitData
    ) internal override {
        address signer = vm.addr(pk);
        hub.setFollowModuleWithSig({
            profileId: profileId,
            followModule: followModule,
            followModuleInitData: followModuleInitData,
            signature: _getSigStruct({
                pKey: pk,
                digest: _getSetFollowModuleTypedDataHash(
                    profileId,
                    followModule,
                    followModuleInitData,
                    cachedNonceByAddress[signer],
                    type(uint256).max
                ),
                deadline: type(uint256).max
            })
        });
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        hub.setFollowModuleWithSig({
            profileId: defaultAccount.profileId,
            followModule: mockFollowModule,
            followModuleInitData: abi.encode(true),
            signature: _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _getSetFollowModuleTypedDataHash(
                    defaultAccount.profileId,
                    mockFollowModule,
                    abi.encode(true),
                    nonce,
                    deadline
                ),
                deadline: deadline
            })
        });
    }

    function _incrementNonce(uint8 increment) internal override {
        vm.prank(vm.addr(_getDefaultMetaTxSignerPk()));
        hub.incrementNonce(increment);
        _refreshCachedNonces();
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return defaultAccount.ownerPk;
    }

    function _refreshCachedNonces() internal override {
        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
    }
}
