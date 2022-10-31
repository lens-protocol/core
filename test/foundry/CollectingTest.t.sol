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

contract CollectingTest_Collect is BaseTest, SignatureHelpers, CollectingHelpers, SigSetup {
    function replicateInitData() internal virtual {}

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
    }

    // negatives
    function testCannotCollectIfNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _mockCollect();
    }

    function testCannotCollectWithSigIfNotExecutor() public {
        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _mockCollectWithSig({delegatedSigner: otherSigner, signerPrivKey: otherSignerKey});
    }

    // positives
    // function testCollect() public {
    //     uint256 expectedPubId = _getPubCount(firstProfileId) + 1;

    //     vm.prank(profileOwner);
    //     uint256 pubId = _collect();

    //     assertEq(pubId, expectedPubId);

    //     DataTypes.PublicationStruct memory pub = _getPub(firstProfileId, pubId);
    //     _verifyPublication(pub, _expectedPubFromInitData());
    // }

    // function testCollectWithSig() public {
    //     uint256 expectedPubId = _getPubCount(firstProfileId) + 1;

    //     uint256 pubId = _publishWithSig({
    //         delegatedSigner: address(0),
    //         signerPrivKey: profileOwnerKey
    //     });
    //     assertEq(pubId, expectedPubId);

    //     DataTypes.PublicationStruct memory pub = _getPub(firstProfileId, pubId);
    //     _verifyPublication(pub, _expectedPubFromInitData());
    // }

    // function testExecutorCollect() public {
    //     vm.prank(profileOwner);
    //     _setDelegatedExecutorApproval(otherSigner, true);

    //     uint256 expectedPubId = _getPubCount(firstProfileId) + 1;

    //     vm.prank(otherSigner);
    //     uint256 pubId = _collect();
    //     assertEq(pubId, expectedPubId);

    //     DataTypes.PublicationStruct memory pub = _getPub(firstProfileId, pubId);
    //     _verifyPublication(pub, _expectedPubFromInitData());
    // }

    // function testExecutorCollectWithSig() public {
    //     vm.prank(profileOwner);
    //     _setDelegatedExecutorApproval(otherSigner, true);

    //     uint256 expectedPubId = _getPubCount(firstProfileId) + 1;
    //     uint256 pubId = _publishWithSig({
    //         delegatedSigner: otherSigner,
    //         signerPrivKey: otherSignerKey
    //     });
    //     assertEq(pubId, expectedPubId);

    //     DataTypes.PublicationStruct memory pub = _getPub(firstProfileId, pubId);
    //     _verifyPublication(pub, _expectedPubFromInitData());
    // }
}
