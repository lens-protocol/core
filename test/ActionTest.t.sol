// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';

contract ActionTest is BaseTest {
    // TODO: Should we test this on all types of publications?
    // TODO: Can't act on mirrors
    // TODO: Should we test if it works for any profile instead of just default?

    function setUp() public override {
        super.setUp();
    }

    // Negatives

    // TODO: I don't like that we have two different errors for non-existent 0 pubId and general non-existent pubId
    // TODO: And that it doesn't differentiate non-existent pub VS notEnabled actionModule
    function testCannotAct_onZeroPublication() public {
        Types.PublicationActionParams memory publicationActionParams = _getDefaultPublicationActionParams();
        publicationActionParams.publicationActedId = 0;

        vm.expectRevert(Errors.PublicationDoesNotExist.selector);

        vm.prank(defaultAccount.owner);
        hub.act(publicationActionParams);
    }

    function testCannotAct_ifNonExistingPublication(uint256 nonexistentPubId) public {
        vm.assume(nonexistentPubId != 0);
        vm.assume(nonexistentPubId != defaultPub.pubId);
        Types.PublicationActionParams memory publicationActionParams = _getDefaultPublicationActionParams();
        publicationActionParams.publicationActedId = nonexistentPubId;

        vm.expectRevert(Errors.ActionNotAllowed.selector);

        vm.prank(defaultAccount.owner);
        hub.act(publicationActionParams);
    }

    function testCannotAct_ifActionModuleNotEnabledForPublication(address notEnabledActionModule) public {
        vm.assume(notEnabledActionModule != address(mockActionModule));

        Types.PublicationActionParams memory publicationActionParams = _getDefaultPublicationActionParams();
        publicationActionParams.actionModuleAddress = notEnabledActionModule;

        vm.expectRevert(Errors.ActionNotAllowed.selector);

        vm.prank(defaultAccount.owner);
        hub.act(publicationActionParams);
    }

    // Scenarios

    function testAct() public {
        Types.PublicationActionParams memory publicationActionParams = _getDefaultPublicationActionParams();

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.Acted(publicationActionParams, abi.encode(true), block.timestamp);

        Types.ProcessActionParams memory processActionParams = Types.ProcessActionParams({
            publicationActedProfileId: publicationActionParams.publicationActedProfileId,
            publicationActedId: publicationActionParams.publicationActedId,
            actorProfileId: publicationActionParams.actorProfileId,
            actorProfileOwner: defaultAccount.owner,
            transactionExecutor: defaultAccount.owner,
            referrerProfileIds: publicationActionParams.referrerProfileIds,
            referrerPubIds: publicationActionParams.referrerPubIds,
            referrerPubTypes: _emptyPubTypesArray(),
            actionModuleData: publicationActionParams.actionModuleData
        });

        vm.expectCall(
            address(mockActionModule),
            abi.encodeWithSelector(mockActionModule.processPublicationAction.selector, (processActionParams))
        );

        vm.prank(defaultAccount.owner);
        hub.act(publicationActionParams);
    }

    function testCanAct_evenIfActionWasUnwhitelisted() public {
        Types.PublicationActionParams memory publicationActionParams = _getDefaultPublicationActionParams();

        vm.prank(governance);
        hub.whitelistActionModule(publicationActionParams.actionModuleAddress, false);

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.Acted(publicationActionParams, abi.encode(true), block.timestamp);

        Types.ProcessActionParams memory processActionParams = Types.ProcessActionParams({
            publicationActedProfileId: publicationActionParams.publicationActedProfileId,
            publicationActedId: publicationActionParams.publicationActedId,
            actorProfileId: publicationActionParams.actorProfileId,
            actorProfileOwner: defaultAccount.owner,
            transactionExecutor: defaultAccount.owner,
            referrerProfileIds: publicationActionParams.referrerProfileIds,
            referrerPubIds: publicationActionParams.referrerPubIds,
            referrerPubTypes: _emptyPubTypesArray(),
            actionModuleData: publicationActionParams.actionModuleData
        });

        vm.expectCall(
            address(mockActionModule),
            abi.encodeWithSelector(mockActionModule.processPublicationAction.selector, (processActionParams))
        );

        vm.prank(defaultAccount.owner);
        hub.act(publicationActionParams);
    }

    // TODO: Any ideas for more tests?
}
