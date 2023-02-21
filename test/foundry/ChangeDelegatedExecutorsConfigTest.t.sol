// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './MetaTxNegatives.t.sol';

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
        address executor,
        bool approval
    ) public {
        vm.prank(governance);

        hub.setState(DataTypes.ProtocolState.Paused);

        vm.expectRevert(Errors.Paused.selector);

        _changeCurrentDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(executor),
            _toBoolArray(approval)
        );
    }

    function testCannotChangeDelegatedExecutorsConfig_PassingDifferentAmountOfExecutorsAndApprovals(
        address firstExecutor,
        address secondExecutor,
        bool approval
    ) public {
        vm.expectRevert(Errors.ArrayMismatch.selector);

        _changeCurrentDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(firstExecutor, secondExecutor),
            _toBoolArray(approval)
        );
    }

    function testCannotChangeDelegatedExecutorsConfig_IfCallerIsNotProfileOwner(
        uint256 nonOwnerPk,
        address executor,
        bool approval
    ) public {
        nonOwnerPk = bound(nonOwnerPk, 1, ISSECP256K1_CURVE_ORDER - 1);
        vm.assume(nonOwnerPk != testDelegatorProfileOwnerPk);

        vm.expectRevert(Errors.NotProfileOwner.selector);

        _changeCurrentDelegatedExecutorsConfig(
            nonOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(executor),
            _toBoolArray(approval)
        );
    }

    function testCannotChangeDelegatedExecutorsConfig_IfDelegatorProfileDoesNotExist(
        uint256 unexistentProfileId,
        address executor,
        bool approval
    ) public {
        vm.assume(!hub.exists(unexistentProfileId));

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        _changeCurrentDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            unexistentProfileId,
            _toAddressArray(executor),
            _toBoolArray(approval)
        );
    }

    //////////////////////////////////////////////////////////////////////
    // changeDelegatedExecutorsConfig - Current config - Scenarios
    //////////////////////////////////////////////////////////////////////

    function testDelegatedExecutorsConfigIsClearedAfterBeingTransferred(
        address newProfileOwner,
        address executor
    ) public {
        vm.assume(newProfileOwner != address(0));
        vm.assume(newProfileOwner != testDelegatorProfileOwner);

        _changeCurrentDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(executor),
            _toBoolArray(true)
        );

        uint64 maxConfigSetBeforeTranster = hub.getDelegatedExecutorsMaxConfigNumberSet(
            testDelegatorProfileId
        );

        vm.prank(testDelegatorProfileOwner);
        hub.transferFrom(testDelegatorProfileOwner, newProfileOwner, testDelegatorProfileId);

        uint64 expectedMaxConfigSetAfterTransfer = maxConfigSetBeforeTranster + 1;

        assertEq(
            expectedMaxConfigSetAfterTransfer,
            hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId)
        );
        assertEq(
            expectedMaxConfigSetAfterTransfer,
            hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId)
        );

        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, executor));
    }

    function testDelegatedExecutorApprovalCanBeChanged(address executor) public {
        vm.assume(!hub.isDelegatedExecutorApproved(testDelegatorProfileId, executor));

        _changeCurrentDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(executor),
            _toBoolArray(true)
        );

        assertTrue(hub.isDelegatedExecutorApproved(testDelegatorProfileId, executor));

        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeCurrentDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(executor),
            _toBoolArray(false)
        );

        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, executor));
    }

    //////////////////////////////////////////////////////////////////////

    function _refreshCachedNonce(address signer) internal virtual {
        // Nothing to do here, this is meant to be overriden by the meta-tx tests.
    }

    function _changeCurrentDelegatedExecutorsConfig(
        uint256 pk,
        uint256 delegatorProfileId,
        address[] memory executors,
        bool[] memory approvals
    ) private {
        _changeDelegatedExecutorsConfig(
            pk,
            delegatorProfileId,
            executors,
            approvals,
            initConfigNumber,
            false
        );
    }

    function _changeDelegatedExecutorsConfig(
        uint256 pk,
        uint256 delegatorProfileId,
        address[] memory executors,
        bool[] memory approvals,
        uint64, /* configNumber */
        bool /* switchToGivenConfig */
    ) internal virtual {
        vm.prank(vm.addr(pk));
        hub.changeDelegatedExecutorsConfig(delegatorProfileId, executors, approvals);
    }
}

contract ChangeDelegatedExecutorsConfigTest_GivenConfig is
    ChangeDelegatedExecutorsConfigTest_CurrentConfig
{
    //////////////////////////////////////////////////////////////////////
    // changeDelegatedExecutorsConfig - Given config - Negatives
    //////////////////////////////////////////////////////////////////////

    function testCannotChangeDelegatedExecutorsConfig_IfPassedConfigNumberIsBiggerThanTheMaxAvailableOne(
        uint64 invalidConfigNumber,
        address executor,
        bool approval
    ) public {
        uint64 maxAvailableConfigNumber = hub.getDelegatedExecutorsMaxConfigNumberSet(
            testDelegatorProfileId
        ) + 1;
        uint64 fistInvalidConfigNumber = maxAvailableConfigNumber + 1;
        invalidConfigNumber = uint64(
            bound(invalidConfigNumber, fistInvalidConfigNumber, type(uint64).max)
        );

        vm.expectRevert(Errors.InvalidParameter.selector);

        _changeDelegatedExecutorsConfig(
            testDelegatorProfileOwnerPk,
            testDelegatorProfileId,
            _toAddressArray(executor),
            _toBoolArray(approval),
            invalidConfigNumber,
            false
        );
    }

    //////////////////////////////////////////////////////////////////////
    // changeDelegatedExecutorsConfig - Given config - Scenarios
    //////////////////////////////////////////////////////////////////////

    function testChangeMaxAvailableDelegatedExecutorsConfigWithoutSwitchingToIt(address executor)
        public
    {
        uint64 configNumberBefore = hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId);
        uint64 maxConfigNumberBefore = hub.getDelegatedExecutorsMaxConfigNumberSet(
            testDelegatorProfileId
        );
        uint64 maxAvailableConfigNumber = maxConfigNumberBefore + 1;

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigChanged({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: maxAvailableConfigNumber,
            executors: _toAddressArray(executor),
            approvals: _toBoolArray(true),
            configSwitched: false
        });

        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            executors: _toAddressArray(executor),
            approvals: _toBoolArray(true),
            configNumber: maxAvailableConfigNumber,
            switchToGivenConfig: false
        });

        assertEq(
            maxAvailableConfigNumber,
            hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId)
        );
        assertEq(configNumberBefore, hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId));

        assertTrue(
            hub.isDelegatedExecutorApproved(
                testDelegatorProfileId,
                executor,
                maxAvailableConfigNumber
            )
        );
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, executor));
    }

    function testChangeMaxAvailableDelegatedExecutorsConfigSwitchingToIt(address executor) public {
        uint64 maxConfigNumberBefore = hub.getDelegatedExecutorsMaxConfigNumberSet(
            testDelegatorProfileId
        );
        uint64 maxAvailableConfigNumber = maxConfigNumberBefore + 1;

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigChanged({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: maxAvailableConfigNumber,
            executors: _toAddressArray(executor),
            approvals: _toBoolArray(true),
            configSwitched: true
        });

        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            executors: _toAddressArray(executor),
            approvals: _toBoolArray(true),
            configNumber: maxAvailableConfigNumber,
            switchToGivenConfig: true
        });

        assertEq(
            maxAvailableConfigNumber,
            hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId)
        );
        assertEq(
            maxAvailableConfigNumber,
            hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId)
        );

        assertTrue(
            hub.isDelegatedExecutorApproved(
                testDelegatorProfileId,
                executor,
                maxAvailableConfigNumber
            )
        );
        assertTrue(hub.isDelegatedExecutorApproved(testDelegatorProfileId, executor));
    }

    function testChangeToPreviousConfiguration() public {
        uint64 firstConfigNumberSet = hub.getDelegatedExecutorsMaxConfigNumberSet(
            testDelegatorProfileId
        ) + 1;
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            executors: _toAddressArray(address(1)),
            approvals: _toBoolArray(true),
            configNumber: firstConfigNumberSet,
            switchToGivenConfig: true
        });

        uint64 secondConfigNumberSet = firstConfigNumberSet + 1;
        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            executors: _toAddressArray(address(2)),
            approvals: _toBoolArray(true),
            configNumber: secondConfigNumberSet,
            switchToGivenConfig: true
        });

        uint64 thirdConfigNumberSet = secondConfigNumberSet + 1;
        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            executors: _toAddressArray(address(3)),
            approvals: _toBoolArray(true),
            configNumber: thirdConfigNumberSet,
            switchToGivenConfig: true
        });

        uint64 fourthConfigNumberSet = thirdConfigNumberSet + 1;
        _refreshCachedNonce(testDelegatorProfileOwner);

        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            executors: _toAddressArray(address(4)),
            approvals: _toBoolArray(true),
            configNumber: fourthConfigNumberSet,
            switchToGivenConfig: true
        });

        // After creating new four configurations, switch to the second one.
        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            executors: new address[](0),
            approvals: new bool[](0),
            configNumber: secondConfigNumberSet,
            switchToGivenConfig: true
        });

        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(1)));
        assertTrue(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(2)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(3)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(4)));

        // Switch to fourth configuration, now the previous configuration is the second one.
        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            executors: new address[](0),
            approvals: new bool[](0),
            configNumber: fourthConfigNumberSet,
            switchToGivenConfig: true
        });

        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(1)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(2)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(3)));
        assertTrue(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(4)));

        // Switch to the previous configuration.
        _refreshCachedNonce(testDelegatorProfileOwner);
        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            executors: new address[](0),
            approvals: new bool[](0),
            configNumber: hub.getDelegatedExecutorsPrevConfigNumber(testDelegatorProfileId),
            switchToGivenConfig: true
        });

        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(1)));
        assertTrue(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(2)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(3)));
        assertFalse(hub.isDelegatedExecutorApproved(testDelegatorProfileId, address(4)));

        assertEq(
            fourthConfigNumberSet,
            hub.getDelegatedExecutorsMaxConfigNumberSet(testDelegatorProfileId)
        );
        assertEq(
            secondConfigNumberSet,
            hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId)
        );
    }

    function testEmitsConfigSwitchedAsFalseWhenPassingCurrentConfigNumber(
        address executor,
        bool approval
    ) public {
        uint64 currentConfigNumber = hub.getDelegatedExecutorsConfigNumber(testDelegatorProfileId);

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.DelegatedExecutorsConfigChanged({
            delegatorProfileId: testDelegatorProfileId,
            configNumber: currentConfigNumber,
            executors: _toAddressArray(executor),
            approvals: _toBoolArray(approval),
            configSwitched: false // Should emit `configSwitched` as `false`...
        });

        _changeDelegatedExecutorsConfig({
            pk: testDelegatorProfileOwnerPk,
            delegatorProfileId: testDelegatorProfileId,
            executors: _toAddressArray(executor),
            approvals: _toBoolArray(approval),
            configNumber: currentConfigNumber,
            switchToGivenConfig: true // ...even if we pass `switchToGivenConfig` as `true`.
        });
    }

    //////////////////////////////////////////////////////////////////////

    function _changeDelegatedExecutorsConfig(
        uint256 pk,
        uint256 delegatorProfileId,
        address[] memory executors,
        bool[] memory approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) internal virtual override {
        vm.prank(vm.addr(pk));
        hub.changeDelegatedExecutorsConfig(
            delegatorProfileId,
            executors,
            approvals,
            configNumber,
            switchToGivenConfig
        );
    }
}

contract ChangeDelegatedExecutorsConfigTest_MetaTx is
    ChangeDelegatedExecutorsConfigTest_GivenConfig,
    MetaTxNegatives
{
    mapping(address => uint256) cachedNonceByAddress;

    function setUp()
        public
        override(ChangeDelegatedExecutorsConfigTest_CurrentConfig, MetaTxNegatives)
    {
        ChangeDelegatedExecutorsConfigTest_CurrentConfig.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[testDelegatorProfileOwner] = _getSigNonce(testDelegatorProfileOwner);
    }

    //////////////////////////////////////////////////////////////////////

    function _refreshCachedNonce(address signer) internal override {
        cachedNonceByAddress[signer] = _getSigNonce(signer);
    }

    function _changeDelegatedExecutorsConfig(
        uint256 pk,
        uint256 delegatorProfileId,
        address[] memory executors,
        bool[] memory approvals,
        uint64 configNumber,
        bool switchToGivenConfig
    ) internal override {
        address signerAddress = vm.addr(pk);
        bytes32 digest = _calculateChangeDelegatedExecutorsConfigWithSigDigest(
            delegatorProfileId,
            executors,
            approvals,
            configNumber,
            switchToGivenConfig,
            cachedNonceByAddress[signerAddress],
            type(uint256).max
        );
        hub.changeDelegatedExecutorsConfigWithSig({
            delegatorProfileId: delegatorProfileId,
            executors: executors,
            approvals: approvals,
            configNumber: configNumber,
            switchToGivenConfig: switchToGivenConfig,
            signature: _getSigStruct({pKey: pk, digest: digest, deadline: type(uint256).max})
        });
    }

    function _calculateChangeDelegatedExecutorsConfigWithSigDigest(
        uint256 delegatorProfileId,
        address[] memory executors,
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
                        CHANGE_DELEGATED_EXECUTORS_CONFIG_TYPEHASH,
                        delegatorProfileId,
                        abi.encodePacked(executors),
                        abi.encodePacked(approvals),
                        configNumber,
                        switchToGivenConfig,
                        nonce,
                        deadline
                    )
                )
            );
    }

    function _executeMetaTx(
        uint256 signerPk,
        uint256 nonce,
        uint256 deadline
    ) internal override {
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
            executors: _toAddressArray(address(0xC0FFEE)),
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

    function _getDefaultMetaTxSignerPk() internal pure override returns (uint256) {
        return testDelegatorProfileOwnerPk;
    }
}
