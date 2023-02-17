// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './helpers/SignatureHelpers.sol';
import './helpers/CollectingHelpers.sol';

// TODO add check for _initialize() called for fork tests - check name and symbol set

contract CollectingTest_Base is BaseTest, CollectingHelpers, SigSetup {
    uint256 constant collectorProfileOwnerPk = 0xC011EEC7012;
    address collectorProfileOwner;
    uint256 collectorProfileId;

    uint256 constant userWithoutProfilePk = 0x105312;
    address userWithoutProfile;

    function _mockCollect() internal virtual returns (uint256) {
        return
            _collect(
                mockCollectParams.collectorProfileId,
                mockCollectParams.publicationCollectedProfileId,
                mockCollectParams.publicationCollectedId,
                mockCollectParams.collectModuleData
            );
    }

    function _mockCollectWithSig(address delegatedSigner, uint256 signerPrivKey)
        internal
        virtual
        returns (uint256)
    {
        bytes32 digest = _getCollectTypedDataHash(mockCollectParams, nonce, deadline);

        return
            _collectWithSig(
                mockCollectParams,
                _getSigStruct(delegatedSigner, signerPrivKey, digest, deadline)
            );
    }

    function setUp() public virtual override(SigSetup, TestSetup) {
        TestSetup.setUp();
        SigSetup.setUp();

        vm.prank(profileOwner);
        hub.post(mockPostParams);

        collectorProfileOwner = vm.addr(collectorProfileOwnerPk);
        collectorProfileId = _createProfile(collectorProfileOwner);

        userWithoutProfile = vm.addr(userWithoutProfilePk);

        mockCollectParams.collectorProfileId = collectorProfileId;
    }
}

contract CollectingTest_Generic is CollectingTest_Base {
    function setUp() public override {
        CollectingTest_Base.setUp();
    }

    // NEGATIVES

    // Also acts like a test for cannot collect specifying another (non-owned) profile as a parameter
    function testCannotCollectIfNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        vm.startPrank(otherSigner);
        _mockCollect();
    }

    function testCannotCollectIfNonexistantPub() public {
        mockCollectParams.publicationCollectedId = 2;
        // Check that the publication doesn't exist.
        assertEq(
            _getPub(
                mockCollectParams.publicationCollectedProfileId,
                mockCollectParams.publicationCollectedId
            ).pointedProfileId,
            0
        );

        vm.startPrank(collectorProfileOwner);
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollect();
        vm.stopPrank();
    }

    function testCannotCollectIfZeroPub() public {
        mockCollectParams.publicationCollectedId = 0;
        // Check that the publication doesn't exist.
        assertEq(
            _getPub(
                mockCollectParams.publicationCollectedProfileId,
                mockCollectParams.publicationCollectedId
            ).pointedProfileId,
            0
        );

        vm.startPrank(collectorProfileOwner);
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollect();
        vm.stopPrank();
    }

    function testCannotCollect_WithoutProfile() public {
        mockCollectParams.collectorProfileId = _getNextProfileId(); // Non-existent profile
        vm.startPrank(userWithoutProfile);
        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        _mockCollect();
        vm.stopPrank();
    }

    function testCannotCollectIfBlocked() public {
        vm.prank(profileOwner);
        hub.setBlockStatus(newProfileId, _toUint256Array(collectorProfileId), _toBoolArray(true));
        vm.expectRevert(Errors.Blocked.selector);
        vm.startPrank(collectorProfileOwner);
        _mockCollect();
    }

    // SCENARIOS

    function testCollect() public {
        uint256 startNftId = _checkCollectNFTBefore();

        vm.startPrank(collectorProfileOwner);
        uint256 nftId = _mockCollect();
        vm.stopPrank();

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testCollectMirror() public {
        uint256 startNftId = _checkCollectNFTBefore();

        vm.prank(profileOwner);
        hub.mirror(mockMirrorParams);

        vm.prank(collectorProfileOwner);
        uint256 nftId = _mockCollect();

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testCollectMirrorOfMirrorPointsToOriginalPost() public {
        uint256 startNftId = _checkCollectNFTBefore();
        uint256 startMirrorId = mockMirrorParams.pointedPubId;

        // mirror once
        vm.startPrank(profileOwner);
        uint256 newPubId = hub.mirror(mockMirrorParams);
        assertEq(newPubId, startMirrorId + 1);

        // mirror again
        mockMirrorParams.pointedPubId = newPubId;
        newPubId = hub.mirror(mockMirrorParams);
        assertEq(newPubId, startMirrorId + 2);

        // We're expecting a mirror to point at the original post ID
        mockCollectParams.publicationCollectedId = startMirrorId;
        vm.stopPrank();

        vm.prank(collectorProfileOwner);
        uint256 nftId = _mockCollect();

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testExecutorCollect() public {
        uint256 startNftId = _checkCollectNFTBefore();

        // delegate power to executor
        _changeDelegatedExecutorsConfig(
            collectorProfileOwner,
            collectorProfileId,
            otherSigner,
            true
        );

        // collect from executor
        vm.startPrank(otherSigner);
        uint256 nftId = _mockCollect();
        vm.stopPrank();

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testExecutorCollectMirror() public {
        uint256 startNftId = _checkCollectNFTBefore();

        // mirror, then delegate power to executor
        vm.prank(profileOwner);
        hub.mirror(mockMirrorParams);
        _changeDelegatedExecutorsConfig(
            collectorProfileOwner,
            collectorProfileId,
            otherSigner,
            true
        );

        // collect from executor
        vm.startPrank(otherSigner);
        uint256 nftId = _mockCollect();
        vm.stopPrank();

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }
}

contract CollectingTest_WithSig is CollectingTest_Base {
    function setUp() public override {
        CollectingTest_Base.setUp();
    }

    // NEGATIVES

    // Also acts like a test for cannot collect specifying another (non-owned) profile as a parameter
    function testCannotCollectWithSigIfNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _mockCollectWithSig({delegatedSigner: otherSigner, signerPrivKey: otherSignerKey});
    }

    function testCannotCollectWithSigIfNonexistantPub() public {
        mockCollectParams.publicationCollectedId = 2;
        // Check that the publication doesn't exist.
        assertEq(
            _getPub(
                mockCollectParams.publicationCollectedProfileId,
                mockCollectParams.publicationCollectedId
            ).pointedProfileId,
            0
        );

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: collectorProfileOwnerPk});
    }

    function testCannotCollectWithSigIfZeroPub() public {
        mockCollectParams.publicationCollectedId = 0;
        // Check that the publication doesn't exist.
        assertEq(
            _getPub(
                mockCollectParams.publicationCollectedProfileId,
                mockCollectParams.publicationCollectedId
            ).pointedProfileId,
            0
        );

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: collectorProfileOwnerPk});
    }

    function testCannotCollectWithSig_WithoutProfile() public {
        mockCollectParams.collectorProfileId = _getNextProfileId(); // Non-existent profile
        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: userWithoutProfilePk});
    }

    function testCannotCollectWithSigOnExpiredDeadline() public {
        deadline = block.timestamp - 1;
        vm.expectRevert(Errors.SignatureExpired.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: collectorProfileOwnerPk});
    }

    function testCannotCollectWithSigOnInvalidNonce() public {
        nonce = 5;
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: collectorProfileOwnerPk});
    }

    function testCannotCollectIfNonceWasIncrementedWithAnotherAction() public {
        assertEq(_getSigNonce(collectorProfileOwner), nonce, 'Wrong nonce before posting');

        uint256 expectedCollectId = _getCollectCount(
            collectorProfileId,
            mockCollectParams.publicationCollectedId
        ) + 1;

        uint256 nftId = _mockCollectWithSig({
            delegatedSigner: address(0),
            signerPrivKey: collectorProfileOwnerPk
        });

        assertEq(nftId, expectedCollectId, 'Wrong collectId');

        assertTrue(_getSigNonce(collectorProfileOwner) != nonce, 'Wrong nonce after collecting');

        vm.expectRevert(Errors.SignatureInvalid.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: collectorProfileOwnerPk});
    }

    function testCannotCollectWithSigIfBlocked() public {
        vm.prank(profileOwner);
        hub.setBlockStatus(newProfileId, _toUint256Array(collectorProfileId), _toBoolArray(true));
        vm.expectRevert(Errors.Blocked.selector);
        vm.startPrank(collectorProfileOwner);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: collectorProfileOwnerPk});
    }

    // SCENARIOS

    function testCollectWithSig() public {
        uint256 startNftId = _checkCollectNFTBefore();

        uint256 nftId = _mockCollectWithSig({
            delegatedSigner: address(0),
            signerPrivKey: collectorProfileOwnerPk
        });

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testCollectWithSigMirror() public {
        uint256 startNftId = _checkCollectNFTBefore();

        vm.prank(profileOwner);
        hub.mirror(mockMirrorParams);

        uint256 nftId = _mockCollectWithSig({
            delegatedSigner: address(0),
            signerPrivKey: collectorProfileOwnerPk
        });

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testExecutorCollectWithSig() public {
        uint256 startNftId = _checkCollectNFTBefore();

        // delegate power to executor
        _changeDelegatedExecutorsConfig(
            collectorProfileOwner,
            collectorProfileId,
            otherSigner,
            true
        );

        // collect from executor
        uint256 nftId = _mockCollectWithSig({
            delegatedSigner: otherSigner,
            signerPrivKey: otherSignerKey
        });

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testExecutorCollectWithSigMirror() public {
        uint256 startNftId = _checkCollectNFTBefore();

        // mirror, then delegate power to executor
        vm.prank(profileOwner);
        hub.mirror(mockMirrorParams);
        _changeDelegatedExecutorsConfig(
            collectorProfileOwner,
            collectorProfileId,
            otherSigner,
            true
        );

        // collect from executor
        uint256 nftId = _mockCollectWithSig({
            delegatedSigner: otherSigner,
            signerPrivKey: otherSignerKey
        });

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }
}
