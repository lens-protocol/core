// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './helpers/SignatureHelpers.sol';
import './helpers/CollectingHelpers.sol';

// TODO add check for _initialize() called for fork tests - check name and symbol set

contract CollectingTest_Base is BaseTest, SignatureHelpers, CollectingHelpers, SigSetup {
    function _mockCollect() internal virtual returns (uint256) {
        return
            _collect(
                mockCollectData.collector,
                mockCollectData.profileId,
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
            mockCollectData.profileId,
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
    }
}

contract CollectingTest_Generic is CollectingTest_Base {
    function setUp() public override {
        CollectingTest_Base.setUp();
    }

    // NEGATIVES

    function testCannotCollectIfNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _mockCollect();
    }

    function testCannotCollectIfNonexistantPub() public {
        mockCollectData.pubId = 2;
        // Check that the publication doesn't exist.
        assertEq(_getPub(mockCollectData.profileId, mockCollectData.pubId).profileIdPointed, 0);

        vm.startPrank(profileOwner);
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollect();
        vm.stopPrank();
    }

    function testCannotCollectIfZeroPub() public {
        mockCollectData.pubId = 0;
        // Check that the publication doesn't exist.
        assertEq(_getPub(mockCollectData.profileId, mockCollectData.pubId).profileIdPointed, 0);

        vm.startPrank(profileOwner);
        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollect();
        vm.stopPrank();
    }

    // SCENARIOS

    function testCollect() public {
        uint256 startNftId = _checkCollectNFTBefore();

        vm.startPrank(profileOwner);
        uint256 nftId = _mockCollect();
        vm.stopPrank();

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testCollectMirror() public {
        uint256 startNftId = _checkCollectNFTBefore();

        vm.startPrank(profileOwner);
        hub.mirror(mockMirrorData);
        uint256 nftId = _mockCollect();
        vm.stopPrank();

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
        uint256 nftId = _mockCollect();
        vm.stopPrank();

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testExecutorCollect() public {
        uint256 startNftId = _checkCollectNFTBefore();

        // delegate power to executor
        vm.prank(profileOwner);
        _setDelegatedExecutorApproval(otherSigner, true);

        // collect from executor
        vm.startPrank(otherSigner);
        uint256 nftId = _mockCollect();
        vm.stopPrank();

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testExecutorCollectMirror() public {
        uint256 startNftId = _checkCollectNFTBefore();

        // mirror, then delegate power to executor
        vm.startPrank(profileOwner);
        hub.mirror(mockMirrorData);
        _setDelegatedExecutorApproval(otherSigner, true);
        vm.stopPrank();

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

    function testCannotCollectWithSigIfNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _mockCollectWithSig({delegatedSigner: otherSigner, signerPrivKey: otherSignerKey});
    }

    function testCannotCollectWithSigIfNonexistantPub() public {
        mockCollectData.pubId = 2;
        // Check that the publication doesn't exist.
        assertEq(_getPub(mockCollectData.profileId, mockCollectData.pubId).profileIdPointed, 0);

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotCollectWithSigIfZeroPub() public {
        mockCollectData.pubId = 0;
        // Check that the publication doesn't exist.
        assertEq(_getPub(mockCollectData.profileId, mockCollectData.pubId).profileIdPointed, 0);

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotCollectWithSigOnExpiredDeadline() public {
        deadline = block.timestamp - 1;
        vm.expectRevert(Errors.SignatureExpired.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotCollectWithSigOnInvalidNonce() public {
        nonce = 5;
        vm.expectRevert(Errors.SignatureInvalid.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    function testCannotCollectIfNonceWasIncrementedWithAnotherAction() public {
        assertEq(_getSigNonce(profileOwner), nonce, 'Wrong nonce before posting');

        uint256 expectedCollectId = _getCollectCount(newProfileId, mockCollectData.pubId) + 1;

        uint256 nftId = _mockCollectWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey
        });

        assertEq(nftId, expectedCollectId, 'Wrong collectId');

        assertTrue(_getSigNonce(profileOwner) != nonce, 'Wrong nonce after collecting');

        vm.expectRevert(Errors.SignatureInvalid.selector);
        _mockCollectWithSig({delegatedSigner: address(0), signerPrivKey: profileOwnerKey});
    }

    // SCENARIOS

    function testCollectWithSig() public {
        uint256 startNftId = _checkCollectNFTBefore();

        uint256 nftId = _mockCollectWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey
        });

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testCollectWithSigMirror() public {
        uint256 startNftId = _checkCollectNFTBefore();

        vm.prank(profileOwner);
        hub.mirror(mockMirrorData);

        uint256 nftId = _mockCollectWithSig({
            delegatedSigner: address(0),
            signerPrivKey: profileOwnerKey
        });

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }

    function testExecutorCollectWithSig() public {
        uint256 startNftId = _checkCollectNFTBefore();

        // delegate power to executor
        vm.prank(profileOwner);
        _setDelegatedExecutorApproval(otherSigner, true);

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
        vm.startPrank(profileOwner);
        hub.mirror(mockMirrorData);
        _setDelegatedExecutorApproval(otherSigner, true);
        vm.stopPrank();

        // collect from executor
        uint256 nftId = _mockCollectWithSig({
            delegatedSigner: otherSigner,
            signerPrivKey: otherSignerKey
        });

        _checkCollectNFTAfter(nftId, startNftId + 1);
    }
}
