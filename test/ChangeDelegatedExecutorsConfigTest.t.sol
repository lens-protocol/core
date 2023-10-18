// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/MetaTxNegatives.t.sol';
import {Typehash} from 'contracts/libraries/constants/Typehash.sol';

contract ChangeDelegatedExecutorsConfigTest_CurrentConfig is BaseTest {
    uint256 constant testDelegatorProfileOwnerPk = 0xDE1E6A708;
    address testDelegatorProfileOwner;
    uint256 testDelegatorProfileId;
    uint64 initConfigNumber;

    function setUp() public virtual override {
        super.setUp();

        testDelegatorProfileOwner = vm.addr(testDelegatorProfileOwnerPk);
        testDelegatorProfileId = _createProfile(testDelegatorProfileOwner);
        initConfigNumber = hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId);
    }

    //////////////////////////////////////////////////////////////////////
    // changeDelegatedExecutorsConfig - Current config - Negatives
    //////////////////////////////////////////////////////////////////////

    function testCannotChangeDelegatedExecutorsConfig_WhenProtocolIsPaused(
        address delegatedExecutor,
        bool approval
    ) public {
        vm.prank(governance);

        hub.setState(Types.ProtocolState.Paused);

        vm.expectRevert(Errors.Paused.selector);

        _changeDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(delegatedExecutor),
            _toBoolArray(approval)
        );
    }

    function testCannotChangeDelegatedExecutorsConfig_PassingDifferentAmountOfExecutorsAndApprovals(
        address firstExecutor,
        address secondExecutor,
        bool approval
    ) public {
        vm.expectRevert(Errors.ArrayMismatch.selector);

        _changeDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(firstExecutor, secondExecutor),
            _toBoolArray(approval)
        );
    }

    function testCannotChangeDelegatedExecutorsConfig_IfCallerIsNotProfileOwner(
        uint256 nonOwnerPk,
        address delegatedExecutor,
        bool approval
    ) public {
        nonOwnerPk = _boundPk(nonOwnerPk);
        vm.assume(nonOwnerPk != testDelegatorProfileOwnerPk);

        vm.expectRevert(Errors.NotProfileOwner.selector);

        _changeDelegatedExecutorsConfig(
            nonOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(delegatedExecutor),
            _toBoolArray(approval)
        );
    }

    function testCannotChangeDelegatedExecutorsConfig_IfDelegatorProfileDoesNotExist(
        uint256 unexistentProfileId,
        address delegatedExecutor,
        bool approval
    ) public {
        vm.assume(!hub.exists(unexistentProfileId));

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _changeDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            unexistentProfileId,
            _toAddressArray(delegatedExecutor),
            _toBoolArray(approval)
        );
    }

    //////////////////////////////////////////////////////////////////////
    // changeDelegatedExecutorsConfig - Current config - Scenarios
    //////////////////////////////////////////////////////////////////////

    function testDelegatedExecutorsConfigIsClearedAfterBeingTransferred(
        address newProfileOwner,
        address delegatedExecutor
    ) public {
        vm.assume(newProfileOwner != address(0));
        vm.assume(newProfileOwner != testDelegatorProfileOwner);

        _changeDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(delegatedExecutor),
            _toBoolArray(true)
        );

        uint64 maxConfigSetBeforeTranster = hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId);

        _effectivelyDisableProfileGuardian(testDelegatorProfileOwner);

        vm.prank(testDelegatorProfileOwner);
        hub.transferFrom(testDelegatorProfileOwner, newProfileOwner, testDelegatorProfileId);

        uint64 expectedMaxConfigSetAfterTransfer = maxConfigSetBeforeTranster + 1;

        assertEq(
            expectedMaxConfigSetAfterTransfer,
            hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId)
        );
        assertEq(expectedMaxConfigSetAfterTransfer, hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId));

        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, delegatedExecutor));
    }

    function testDelegatedExecutorApprovalCanBeChanged(address delegatedExecutor) public {
        vm.assume(!hub.isDelegatedExecutorApproved(testDelegatorProfileId, delegatedExecutor));

        _changeDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(delegatedExecutor),
            _toBoolArray(true)
        );

        assertTrue(hub.isDelegatedExecutorApproved(testDelegatorProfileId, delegatedExecutor));

        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(delegatedExecutor),
            _toBoolArray(false)
        );

        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, delegatedExecutor));
    }

    //////////////////////////////////////////////////////////////////////

    function _refreshCachedNonce(address signer) internal virtual {
        // Nothing to do here, this is meant to be overridden by the meta-tx tests.
    }

    function _changeDelegatedExecutorsConfig(
        uint256 pk,
        uint256 delegatorProfileId,
        address[] memory delegatedExecutors,
        bool[] memory approvals
    ) private {
        _changeDelegatedExecutorsConfig(pk, delegatorProfileId, delegatedExecutors, approvals, initConfigNumber, false);
    }

    function _changeDelegatedExecutorsConfig(
        uint256 pk,
        uint256 delegatorProfileId,
        address[] memory delegatedExecutors,
        bool[] memory approvals,
        uint64 /* configNumber */,
        bool /* switchToGivenConfig */
    ) internal virtual {
        vm.prank(vm.addr(pk));
        hub.changeDelegatedExecutorsConfig(delegatorProfileId, delegatedExecutors, approvals);
    }
}

contract ChangeDelegatedExecutorsConfigTest_GivenConfig is ChangeDelegatedExecutorsConfigTest_CurrentConfig {
    //////////////////////////////////////////////////////////////////////
    // changeDelegatedExecutorsConfig - Given config - Negatives
    //////////////////////////////////////////////////////////////////////

    function testCannotChangeDelegatedExecutorsConfig_IfPassedConfigNumberIsBiggerThanTheMaxAvailableOne(
        uint64 invalidConfigNumber,
        address delegatedExecutor,
        bool approval
    ) public {
        uint64 maxAvailableConfigNumber = hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId) + 1;
        uint64 fistInvalidConfigNumber = maxAvailableConfigNumber + 1;
        invalidConfigNumber = uint64(bound(invalidConfigNumber, fistInvalidConfigNumber, type(uint64).max));

        vm.expectRevert(Errors.InvalidParameter.selector);

        _changeDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(delegatedExecutor),
            _toBoolArray(approval),
            invalidConfigNumber,
            false
        );
    }

    //////////////////////////////////////////////////////////////////////
    // changeDelegatedExecutorsConfig - Given config - Scenarios
    //////////////////////////////////////////////////////////////////////

    function testChangeMaxAvailableDelegatedExecutorsConfigWithoutSwitchingToIt(address delegatedExecutor) public {
        uint64 configNumberBefore = hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId);
        uint64 maxConfigNumberBefore = hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId);
        uint64 maxAvailableConfigNumber = maxConfigNumberBefore + 1;

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigChanged({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: maxAvailableConfigNumber,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true),
            timestamp: block.timestamp
        });

        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true),
            configNumber: maxAvailableConfigNumber,
            switchToGivenConfig: false
        });

        assertEq(maxAvailableConfigNumber, hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId));
        assertEq(configNumberBefore, hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId));

        assertTrue(
            hub.isDelegatedExecutorApproved(testDelegatorProfileId, delegatedExecutor, maxAvailableConfigNumber)
        );
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, delegatedExecutor));
    }

    function testChangeMaxAvailableDelegatedExecutorsConfigSwitchingToIt(address delegatedExecutor) public {
        uint64 maxConfigNumberBefore = hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId);
        uint64 maxAvailableConfigNumber = maxConfigNumberBefore + 1;

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigChanged({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: maxAvailableConfigNumber,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true),
            timestamp: block.timestamp
        });

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigApplied({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: maxAvailableConfigNumber,
            timestamp: block.timestamp
        });

        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true),
            configNumber: maxAvailableConfigNumber,
            switchToGivenConfig: true
        });

        assertEq(maxAvailableConfigNumber, hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId));
        assertEq(maxAvailableConfigNumber, hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId));

        assertTrue(
            hub.isDelegatedExecutorApproved(testDelegatorProfileId, delegatedExecutor, maxAvailableConfigNumber)
        );
        assertTrue(hub.isDelegatedExecutorApproved(testDelegatorProfileId, delegatedExecutor));
    }

    function testChangeToPreviousConfiguration() public {
        uint64 firstConfigNumberSet = hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId) + 1;

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigApplied({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: firstConfigNumberSet,
            timestamp: block.timestamp
        });

        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: _toAddressArray(address(1)),
            approvals: _toBoolArray(true),
            configNumber: firstConfigNumberSet,
            switchToGivenConfig: true
        });

        uint64 secondConfigNumberSet = firstConfigNumberSet + 1;

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigApplied({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: secondConfigNumberSet,
            timestamp: block.timestamp
        });

        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: _toAddressArray(address(2)),
            approvals: _toBoolArray(true),
            configNumber: secondConfigNumberSet,
            switchToGivenConfig: true
        });

        uint64 thirdConfigNumberSet = secondConfigNumberSet + 1;

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigApplied({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: thirdConfigNumberSet,
            timestamp: block.timestamp
        });

        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: _toAddressArray(address(3)),
            approvals: _toBoolArray(true),
            configNumber: thirdConfigNumberSet,
            switchToGivenConfig: true
        });

        uint64 fourthConfigNumberSet = thirdConfigNumberSet + 1;

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigApplied({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: fourthConfigNumberSet,
            timestamp: block.timestamp
        });

        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: _toAddressArray(address(4)),
            approvals: _toBoolArray(true),
            configNumber: fourthConfigNumberSet,
            switchToGivenConfig: true
        });

        // After creating new four configurations, switch to the second one.
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigApplied({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: secondConfigNumberSet,
            timestamp: block.timestamp
        });

        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: new address[](0),
            approvals: new bool[](0),
            configNumber: secondConfigNumberSet,
            switchToGivenConfig: true
        });

        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(1)));
        assertTrue(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(2)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(3)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(4)));

        // Switch to the fourth configuration, now the previous configuration is the second one.
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigApplied({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: fourthConfigNumberSet,
            timestamp: block.timestamp
        });

        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: new address[](0),
            approvals: new bool[](0),
            configNumber: fourthConfigNumberSet,
            switchToGivenConfig: true
        });

        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(1)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(2)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(3)));
        assertTrue(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(4)));

        // Switch to the previous configuration.
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigApplied({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: hub.getDelegatedExecutorsPrevConfigNumber(testDelegatorProfileId),
            timestamp: block.timestamp
        });

        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: new address[](0),
            approvals: new bool[](0),
            configNumber: hub.getDelegatedExecutorsPrevConfigNumber(testDelegatorProfileId),
            switchToGivenConfig: true
        });

        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(1)));
        assertTrue(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(2)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(3)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(4)));

        assertEq(fourthConfigNumberSet, hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId));
        assertEq(secondConfigNumberSet, hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId));
    }

    function testDelegatedExecutorsConfigAppliedEventIsNotEmitedWhenPassingCurrentConfigNumber(
        address delegatedExecutor,
        bool approval
    ) public virtual {
        uint64 currentConfigNumber = hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId);

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigChanged({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: currentConfigNumber,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(approval),
            timestamp: block.timestamp
        });

        vm.recordLogs();

        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(approval),
            configNumber: currentConfigNumber,
            switchToGivenConfig: true
        });

        assertEq(vm.getRecordedLogs().length, 1);
    }

    //////////////////////////////////////////////////////////////////////

    function _changeDelegatedExecutorsConfig(
        uint256 pk,
        uint256 delegatorProfileId,
        address[] memory delegatedExecutors,
        bool[] memory approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) internal virtual override {
        vm.prank(vm.addr(pk));
        hub.changeDelegatedExecutorsConfig(
            delegatorProfileId,
            delegatedExecutors,
            approvals,
            configNumber,
            switchToGivenConfig
        );
    }
}

contract ChangeDelegatedExecutorsConfigTest_MetaTx is ChangeDelegatedExecutorsConfigTest_GivenConfig, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function testChangeDelegatedExecutorsConfigTest_MetaTx() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public override(ChangeDelegatedExecutorsConfigTest_CurrentConfig, MetaTxNegatives) {
        ChangeDelegatedExecutorsConfigTest_CurrentConfig.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[testDelegatorProfileOwner] = hub.nonces(testDelegatorProfileOwner);
    }

    function testDelegatedExecutorsConfigAppliedEventIsNotEmitedWhenPassingCurrentConfigNumber(
        address delegatedExecutor,
        bool approval
    ) public override {
        uint64 currentConfigNumber = hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId);

        // TODO: Expect NonceUpdated event too

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigChanged({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: currentConfigNumber,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(approval),
            timestamp: block.timestamp
        });

        vm.recordLogs();

        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(approval),
            configNumber: currentConfigNumber,
            switchToGivenConfig: true
        });

        assertEq(vm.getRecordedLogs().length, 2);
    }

    //////////////////////////////////////////////////////////////////////

    function _refreshCachedNonce(address signer) internal override {
        cachedNonceByAddress[signer] = hub.nonces(signer);
    }

    function _changeDelegatedExecutorsConfig(
        uint256 pk,
        uint256 delegatorProfileId,
        address[] memory delegatedExecutors,
        bool[] memory approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) internal override {
        address signerAddress = vm.addr(pk);
        bytes32 digest = _calculateChangeDelegatedExecutorsConfigWithSigDigest(
            delegatorProfileId,
            delegatedExecutors,
            approvals,
            configNumber,
            switchToGivenConfig,
            cachedNonceByAddress[signerAddress],
            type(uint256).max
        );
        hub.changeDelegatedExecutorsConfigWithSig({
            delegatorProfileId: delegatorProfileId,
            delegatedExecutors: delegatedExecutors,
            approvals: approvals,
            configNumber: configNumber,
            switchToGivenConfig: switchToGivenConfig,
            signature: _getSigStruct({pKey: pk, digest: digest, deadline: type(uint256).max})
        });
    }

    function _calculateChangeDelegatedExecutorsConfigWithSigDigest(
        uint256 delegatorProfileId,
        address[] memory delegatedExecutors,
        bool[] memory approvals,
        uint64 configNumber,
        bool switchToGivenConfig,
        uint256 nonce,
        uint256 deadline
    ) private view returns (bytes32) {
        return
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.CHANGE_DELEGATED_EXECUTORS_CONFIG,
                        delegatorProfileId,
                        _encodeUsingEip712Rules(delegatedExecutors),
                        _encodeUsingEip712Rules(approvals),
                        configNumber,
                        switchToGivenConfig,
                        nonce,
                        deadline
                    )
                )
            );
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal override {
        bytes32 digest = _calculateChangeDelegatedExecutorsConfigWithSigDigest(
            testDelegatorProfileId,
            _toAddressArray(address(0xC0FFEE)),
            _toBoolArray(true),
            0,
            false,
            nonce,
            deadline
        );
        hub.changeDelegatedExecutorsConfigWithSig({
            delegatorProfileId: testDelegatorProfileId,
            delegatedExecutors: _toAddressArray(address(0xC0FFEE)),
            approvals: _toBoolArray(true),
            configNumber: 0,
            switchToGivenConfig: false,
            signature: _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: digest,
                deadline: deadline
            })
        });
    }

    function _incrementNonce(uint8 increment) internal override {
        vm.prank(vm.addr(_getDefaultMetaTxSignerPk()));
        hub.incrementNonce(increment);
        _refreshCachedNonce(vm.addr(_getDefaultMetaTxSignerPk()));
    }

    function _getDefaultMetaTxSignerPk() internal pure override returns (uint256) {
        return testDelegatorProfileOwnerPk;
    }
}
