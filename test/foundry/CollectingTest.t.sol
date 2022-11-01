// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';
import './helpers/SignatureHelpers.sol';
import './helpers/CollectingHelpers.sol';

contract SigSetup {
    uint256 nonce;
    uint256 deadline;

    function setUp() public virtual {
        nonce = 0;
        deadline = type(uint256).max;
    }
}

contract CollectingTest_Base is BaseTest, SignatureHelpers, CollectingHelpers, SigSetup {
    using Strings for uint256;

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

    function _expectedName() internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    mockCollectData.profileId.toString(),
                    COLLECT_NFT_NAME_INFIX,
                    uint256(mockCollectData.pubId).toString()
                )
            );
    }

    function _expectedSymbol() internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    mockCollectData.profileId.toString(),
                    COLLECT_NFT_SYMBOL_INFIX,
                    uint256(mockCollectData.pubId).toString()
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

    function testFailCollectIfNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _mockCollect();
    }

    function testFailCollectIfNonexistantPub() public {}

    function testFailCollectIfZeroPub() public {}

    // SCENARIOS

    function testCollect() public {
        assertEq(hub.getCollectNFT(firstProfileId, mockCollectData.pubId), address(0));

        vm.startPrank(profileOwner);
        uint256 nftId = _mockCollect();
        vm.stopPrank();

        CollectNFT nft = CollectNFT(hub.getCollectNFT(firstProfileId, mockCollectData.pubId));
        assertEq(nftId, mockCollectData.pubId);
        assertEq(nft.ownerOf(mockCollectData.pubId), mockCollectData.collector);
        assertEq(nft.name(), _expectedName());
        assertEq(nft.symbol(), _expectedSymbol());
    }

    function testCollectMirror() public {}

    function testExecutorCollect() public {}

    function testExecutorCollectMirror() public {}
}

contract CollectingTest_WithSig is CollectingTest_Base {
    function setUp() public override {
        CollectingTest_Base.setUp();
    }

    // NEGATIVES

    function testFailCollectWithSigIfNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _mockCollectWithSig({delegatedSigner: otherSigner, signerPrivKey: otherSignerKey});
    }

    function testFailCollectWithSigIfNonexistantPub() public {}

    function testFailCollectWithSigIfZeroPub() public {}

    function testFailCollectWithSigOnDeadlineMismatch() public {}

    function testFailCollectWithSigOnInvalidDeadline() public {}

    function testFailCollectWithSigOnInvalidNonce() public {}

    function testFailCollectWithSigIfCancelledViaEmptyPermitForAll() public {}

    // SCENARIOS

    function testCollectWithSig() public {
        //TODO
    }

    function testCollectWithSigMirror() public {}

    function testExecutorCollectWithSig() public {}

    function testExecutorCollectWithSigMirror() public {}
}
