// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './base/BaseTest.t.sol';

contract MiscTest is BaseTest {
    // Negatives
    function testSetFollowModuleInvalidCallerFails() public {
        vm.expectRevert(Errors.CallerInvalid.selector);
        hub.setFollowModule(firstProfileId, address(0), '');
    }

    function testSetDefaultProfileInvalidCallerFails() public {
        vm.expectRevert(Errors.CallerInvalid.selector);
        
    }

    // Positives
    function testExecutorSetFollowModule() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        vm.prank(otherSigner);
        hub.setFollowModule(firstProfileId, address(0), '');
    }

    // Meta-tx
    // Negatives
    function testSetFollowModuleWithSigInvalidSignerFails() public {
        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowModuleTypedDataHash(
            firstProfileId,
            address(0),
            '',
            nonce,
            deadline
        );

        vm.expectRevert(Errors.CallerInvalid.selector);
        hub.setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                profileId: firstProfileId,
                followModule: address(0),
                followModuleInitData: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }

    // Postivies
    function testExecutorSetFollowModuleWithSig() public {
        vm.prank(profileOwner);
        hub.setDelegatedExecutorApproval(otherSigner, true);

        uint256 nonce = 0;
        uint256 deadline = type(uint256).max;
        bytes32 digest = _getSetFollowModuleTypedDataHash(
            firstProfileId,
            address(0),
            '',
            nonce,
            deadline
        );

        hub.setFollowModuleWithSig(
            DataTypes.SetFollowModuleWithSigData({
                profileId: firstProfileId,
                followModule: address(0),
                followModuleInitData: '',
                sig: _getSigStruct(otherSignerKey, digest, deadline)
            })
        );
    }
}
