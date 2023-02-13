// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './helpers/SignatureHelpers.sol';
import './helpers/CollectingHelpers.sol';

// TODO add check for _initialize() called for fork tests - check name and symbol set

contract CollectingTest_Base is BaseTest, SignatureHelpers, CollectingHelpers, SigSetup {
    uint256 constant collectorProfileOwnerPk = 0xC011EEC7012;
    address collectorProfileOwner;
    uint256 collectorProfileId;

    uint256 constant userWithoutProfilePk = 0x105312;
    address userWithoutProfile;

    function _mockCollect() internal virtual returns (uint256) {
        return
            _collect(
                mockCollectData.collectorProfileId,
                mockCollectData.publisherProfileId,
                mockCollectData.pubId,
                mockCollectData.data
            );
    }

    function _mockCollectWithSig(address delegatedSigner, uint256 signerPrivKey)
        internal
        virtual
        returns (uint256)
    {
        bytes32 digest = _getCollectTypedDataHash(
            mockCollectData.collectorProfileId,
            mockCollectData.publisherProfileId,
            mockCollectData.pubId,
            mockCollectData.data,
            nonce,
            deadline
        );

        return
            _collectWithSig(
                _buildCollectWithSigData(
                    delegatedSigner,
                    mockCollectData,
                    _getSigStruct(signerPrivKey, digest, deadline)
                )
            );
    }

    function setUp() public virtual override(SigSetup, TestSetup) {
        TestSetup.setUp();
        SigSetup.setUp();

        vm.prank(profileOwner);
        hub.post(mockPostData);

        collectorProfileOwner = vm.addr(collectorProfileOwnerPk);
        collectorProfileId = _createProfile(collectorProfileOwner);

        userWithoutProfile = vm.addr(userWithoutProfilePk);

        mockCollectData.collectorProfileId = collectorProfileId;
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
        mockCollectData.pubId = 2;
        // Check that the publication doesn't exist.
        assertEq(
            _getPub(mockCollectData.publisherProfileId, mockCollectData.pubId).profileIdPointed,
            0
        );

        vm.startPrank(collectorProfileOwner);
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollect();
        vm.stopPrank();
    }

    function testCannotCollectIfZeroPub() public {
        mockCollectData.pubId = 0;
        // Check that the publication doesn't exist.
        assertEq(
            _getPub(mockCollectData.publisherProfileId, mockCollectData.pubId).profileIdPointed,
            0
        );

        vm.startPrank(collectorProfileOwner);
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollect();
        vm.stopPrank();
    }

    function testCannotCollect_WithoutProfile() public {
        mockCollectData.collectorProfileId = _getNextProfileId(); // Non-existent profile
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
        hub.mirror(mockMirrorData);

        vm.prank(collectorProfileOwner);
        uint256 nftId = _mockCollect();

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testCollectMirrorOfMirrorPointsToOriginalPost() public {
        uint256 startNftId = _checkCollectNFTBefore();
        uint256 startMirrorId = mockMirrorData.pubIdPointed;

        // mirror once
        vm.startPrank(profileOwner);
        uint256 newPubId = hub.mirror(mockMirrorData);
        assertEq(newPubId, startMirrorId + 1);

        // mirror again
        mockMirrorData.pubIdPointed = newPubId;
        newPubId = hub.mirror(mockMirrorData);
        assertEq(newPubId, startMirrorId + 2);

        // We're expecting a mirror to point at the original post ID
        mockCollectData.pubId = startMirrorId;
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
        hub.mirror(mockMirrorData);
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
        mockCollectData.pubId = 2;
        // Check that the publication doesn't exist.
        assertEq(
            _getPub(mockCollectData.publisherProfileId, mockCollectData.pubId).profileIdPointed,
            0
        );

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: collectorProfileOwnerPk});
    }

    function testCannotCollectWithSigIfZeroPub() public {
        mockCollectData.pubId = 0;
        // Check that the publication doesn't exist.
        assertEq(
            _getPub(mockCollectData.publisherProfileId, mockCollectData.pubId).profileIdPointed,
            0
        );

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: collectorProfileOwnerPk});
    }

    function testCannotCollectWithSig_WithoutProfile() public {
        mockCollectData.collectorProfileId = _getNextProfileId(); // Non-existent profile
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

        uint256 expectedCollectId = _getCollectCount(collectorProfileId, mockCollectData.pubId) + 1;

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
        hub.mirror(mockMirrorData);

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
        hub.mirror(mockMirrorData);
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
