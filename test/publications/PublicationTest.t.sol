// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';

/**
 * Tests shared among all type of publications. Posts, Comments, Quotes, and Mirrors.
 */
abstract contract PublicationTest is BaseTest {
    uint256 publisherOwnerPk;
    address publisherOwner;
    uint256 publisherProfileId;

    function _publish(uint256 signerPk, uint256 publisherProfileId) internal virtual returns (uint256);

    function _pubType() internal virtual returns (Types.PublicationType);

    function setUp() public virtual override {
        super.setUp();
        (publisherOwnerPk, publisherOwner, publisherProfileId) = _loadAccountAs('Publisher');
    }

    // Negatives

    function testCannotPublish_IfProtocolStateIs_Paused() public {
        vm.prank(governance);
        hub.setState(Types.ProtocolState.Paused);

        vm.expectRevert(Errors.PublishingPaused.selector);
        _publish({signerPk: publisherOwnerPk, publisherProfileId: publisherProfileId});
    }

    function testCannotPublish_IfProtocolStateIs_PublishingPaused() public {
        vm.prank(governance);
        hub.setState(Types.ProtocolState.PublishingPaused);

        vm.expectRevert(Errors.PublishingPaused.selector);
        _publish({signerPk: publisherOwnerPk, publisherProfileId: publisherProfileId});
    }

    function testCannotPublish_IfExecutorIsNot_PublisherProfileOwnerOrDelegatedExecutor(
        uint256 nonOwnerNorDelegatedExecutorPk
    ) public {
        nonOwnerNorDelegatedExecutorPk = _boundPk(nonOwnerNorDelegatedExecutorPk);
        vm.assume(nonOwnerNorDelegatedExecutorPk != publisherOwnerPk);
        address nonOwnerNorDelegatedExecutor = vm.addr(nonOwnerNorDelegatedExecutorPk);
        vm.assume(!hub.isDelegatedExecutorApproved(publisherProfileId, nonOwnerNorDelegatedExecutor));

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _publish({signerPk: nonOwnerNorDelegatedExecutorPk, publisherProfileId: publisherProfileId});
    }

    // Scenarios

    function testPublisherPubCountIs_IncrementedByOne_AfterPublishing() public {
        uint256 pubCountBeforePublishing = hub.getPubCount(publisherProfileId);
        _publish({signerPk: publisherOwnerPk, publisherProfileId: publisherProfileId});
        uint256 pubCountAfterPublishing = hub.getPubCount(publisherProfileId);
        assertEq(pubCountAfterPublishing, pubCountBeforePublishing + 1);
    }

    function testPubIdAssignedIs_EqualsToPubCount_AfterPublishing() public {
        uint256 pubIdAssigned = _publish({signerPk: publisherOwnerPk, publisherProfileId: publisherProfileId});
        uint256 pubCountAfterPublishing = hub.getPubCount(publisherProfileId);
        assertEq(pubIdAssigned, pubCountAfterPublishing);
    }

    function testCanPublishIf_ExecutorIs_PublisherProfileApprovedDelegatedExecutor(uint256 delegatedExecutorPk) public {
        delegatedExecutorPk = _boundPk(delegatedExecutorPk);
        vm.assume(delegatedExecutorPk != publisherOwnerPk);
        address delegatedExecutor = vm.addr(delegatedExecutorPk);
        vm.prank(publisherOwner);
        hub.changeDelegatedExecutorsConfig({
            delegatorProfileId: publisherProfileId,
            delegatedExecutors: _toAddressArray(delegatedExecutor),
            approvals: _toBoolArray(true)
        });

        _publish({signerPk: delegatedExecutorPk, publisherProfileId: publisherProfileId});
    }

    function testCanPublishIf_ExecutorIs_PublisherProfileOwner() public {
        _publish({signerPk: publisherOwnerPk, publisherProfileId: publisherProfileId});
    }

    function testPublicationTypeIsCorrect() public {
        uint256 publicationIdAssigned = _publish({signerPk: publisherOwnerPk, publisherProfileId: publisherProfileId});
        Types.PublicationType assignedPubType = hub.getPublicationType(publisherProfileId, publicationIdAssigned);
        Types.PublicationType expectedPubType = _pubType();
        assertTrue(assignedPubType == expectedPubType, 'Assigned publication type is different than the expected one');
    }
}

/**
 * Tests for publications that can handle actions. Posts, Comments, and Quotes, but not Mirrors.
 */
abstract contract ActionablePublicationTest is PublicationTest {
    function _setActionModules(address[] memory actionModules, bytes[] memory actionModulesInitDatas) internal virtual;
}

/**
 * Tests for publications that points to another publication. Comments, Quotes, and Mirrors, but not Posts.
 */
abstract contract ReferencePublicationTest is PublicationTest {
    function _setReferrers(uint256[] memory referrerProfileIds, uint256[] memory referrerPubIds) internal virtual;

    function _setReferenceModuleData(bytes memory referenceModuleData) internal virtual;
}
