// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract DelegatedExecutorTest is BaseTest {
    // Negatives

    // Positives
    function testSetDelegatedExecutor() public {
        hub.setDelegatedExecutorApproval(otherSigner, true);
        assertEq(hub.isDelegatedExecutorApproved(me, otherSigner), true);
    }

    // Meta-tx
    // Negatives

    // Positives
    function testSetDelegatedExecutorWithSig() public {
        address onBehalfOf = profileOwner;
        address executor = otherSigner;
        bool approved = true;
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;

        bytes32 digest = _getSetDelegatedExecutorApprovalTypedDataHash(
            onBehalfOf,
            executor,
            approved,
            nonce,
            deadline
        );
        hub.setDelegatedExecutorApprovalWithSig(
            _buildSetDelegatedExecutorApprovalWithSigData(
                onBehalfOf,
                executor,
                approved,
                _getSigStruct(profileOwnerKey, digest, deadline)
            )
        );

        assertEq(hub.isDelegatedExecutorApproved(profileOwner, executor), true);
    }

    // Private functions
    function _buildSetDelegatedExecutorApprovalWithSigData(
        address onBehalfOf,
        address executor,
        bool approved,
        DataTypes.EIP712Signature memory sig
    ) private pure returns (DataTypes.SetDelegatedExecutorApprovalWithSigData memory) {
        return
            DataTypes.SetDelegatedExecutorApprovalWithSigData(onBehalfOf, executor, approved, sig);
    }
}
