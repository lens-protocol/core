// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import 'test/base/BaseTest.t.sol';
import {ICollectModule} from 'contracts/modules/interfaces/ICollectModule.sol';
import {CollectPublicationAction} from 'contracts/modules/act/collect/CollectPublicationAction.sol';
import {CollectNFT} from 'contracts/modules/act/collect/CollectNFT.sol';
import {MockCollectModule} from 'test/mocks/MockCollectModule.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

contract CollectPublicationActionTest is BaseTest {
    using stdJson for string;
    using Strings for uint256;

    CollectPublicationAction collectPublicationAction;
    address collectNFTImpl;
    address mockCollectModule;

    event CollectModuleRegistered(address collectModule, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event CollectNFTDeployed(
        uint256 indexed profileId,
        uint256 indexed pubId,
        address indexed collectNFT,
        uint256 timestamp
    );
    event Collected(
        uint256 indexed collectedProfileId,
        uint256 indexed collectedPubId,
        uint256 indexed collectorProfileId,
        address nftRecipient,
        bytes collectActionData,
        bytes collectActionResult,
        address collectNFT,
        uint256 tokenId,
        address transactionExecutor,
        uint256 timestamp
    );

    function setUp() public override {
        super.setUp();

        address collectPublicationActionAddr;
        (collectNFTImpl, collectPublicationActionAddr) = loadOrDeploy_CollectPublicationAction();
        collectPublicationAction = CollectPublicationAction(collectPublicationActionAddr);

        // Deploy & Whitelist MockCollectModule
        mockCollectModule = address(new MockCollectModule());
        collectPublicationAction.registerCollectModule(mockCollectModule);
    }

    // Negatives

    function testCannotInitializePublicationAction_ifNotHub(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        address from
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));
        vm.assume(from != address(hub));

        vm.prank(from);
        vm.expectRevert(Errors.NotHub.selector);
        collectPublicationAction.initializePublicationAction(
            profileId,
            pubId,
            transactionExecutor,
            abi.encode(mockCollectModule, abi.encode(true))
        );
    }

    function testCannotProcessPublicationAction_ifNotHub(
        uint256 publicationActedProfileId,
        uint256 publicationActedId,
        uint256 actorProfileId,
        address actorProfileOwner,
        address transactionExecutor,
        address from
    ) public {
        vm.assume(publicationActedProfileId != 0);
        vm.assume(publicationActedId != 0);
        vm.assume(actorProfileId != 0);
        vm.assume(actorProfileOwner != address(0));
        vm.assume(transactionExecutor != address(0));
        vm.assume(from != address(hub));

        vm.prank(from);
        vm.expectRevert(Errors.NotHub.selector);
        collectPublicationAction.processPublicationAction(
            Types.ProcessActionParams({
                publicationActedProfileId: publicationActedProfileId,
                publicationActedId: publicationActedId,
                actorProfileId: actorProfileId,
                actorProfileOwner: actorProfileOwner,
                transactionExecutor: transactionExecutor,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                actionModuleData: ''
            })
        );
    }

    function testCannotProcessPublicationAction_ifCollectActionNotInitialized(
        uint256 publicationActedProfileId,
        uint256 publicationActedId,
        uint256 actorProfileId,
        address actorProfileOwner,
        address transactionExecutor
    ) public {
        vm.assume(publicationActedProfileId != 0);
        vm.assume(publicationActedId != 0);
        vm.assume(actorProfileId != 0);
        vm.assume(actorProfileOwner != address(0));
        vm.assume(transactionExecutor != address(0));

        vm.assume(
            collectPublicationAction.getCollectData(publicationActedProfileId, publicationActedId).collectModule ==
                address(0)
        );

        vm.prank(address(hub));
        vm.expectRevert(Errors.CollectNotAllowed.selector);
        collectPublicationAction.processPublicationAction(
            Types.ProcessActionParams({
                publicationActedProfileId: publicationActedProfileId,
                publicationActedId: publicationActedId,
                actorProfileId: actorProfileId,
                actorProfileOwner: actorProfileOwner,
                transactionExecutor: transactionExecutor,
                referrerProfileIds: _emptyUint256Array(),
                referrerPubIds: _emptyUint256Array(),
                referrerPubTypes: _emptyPubTypesArray(),
                actionModuleData: ''
            })
        );
    }

    // Scenarios
    function testRegisterCollectModule(address collectModule) public {
        vm.assume(collectModule != address(0));
        vm.assume(!collectPublicationAction.isCollectModuleRegistered(collectModule));

        vm.expectEmit(true, true, true, true, address(collectPublicationAction));
        emit CollectModuleRegistered(collectModule, block.timestamp);
        collectPublicationAction.registerCollectModule(collectModule);

        assertTrue(
            collectPublicationAction.isCollectModuleRegistered(collectModule),
            'Collect module was not registered'
        );
    }

    function testInitializePublicationAction(uint256 profileId, uint256 pubId, address transactionExecutor) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(transactionExecutor != address(0));

        bytes memory initData = abi.encode(mockCollectModule, abi.encode(true));

        vm.expectCall(
            mockCollectModule,
            abi.encodeCall(
                ICollectModule.initializePublicationCollectModule,
                (profileId, pubId, transactionExecutor, abi.encode(true))
            ),
            1
        );

        vm.prank(address(hub));
        bytes memory returnData = collectPublicationAction.initializePublicationAction(
            profileId,
            pubId,
            transactionExecutor,
            initData
        );

        assertEq(returnData, '', 'Return data should be empty');
        assertEq(collectPublicationAction.getCollectData(profileId, pubId).collectModule, mockCollectModule);
    }

    function testProcessPublicationAction_firstCollect(
        uint256 profileId,
        uint256 pubId,
        uint256 actorProfileId,
        address actorProfileOwner,
        address transactionExecutor,
        address collectNftRecipient
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(actorProfileId != 0);
        vm.assume(actorProfileOwner != address(0));
        vm.assume(transactionExecutor != address(0));
        vm.assume(collectNftRecipient != address(0));

        vm.assume(collectPublicationAction.getCollectData(profileId, pubId).collectModule == address(0));

        bytes memory initData = abi.encode(mockCollectModule, abi.encode(true));
        vm.prank(address(hub));
        collectPublicationAction.initializePublicationAction(profileId, pubId, transactionExecutor, initData);
        bytes memory collectModuleData = abi.encode(true);

        Types.ProcessActionParams memory processActionParams = Types.ProcessActionParams({
            publicationActedProfileId: profileId,
            publicationActedId: pubId,
            actorProfileId: actorProfileId,
            actorProfileOwner: actorProfileOwner,
            transactionExecutor: transactionExecutor,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            referrerPubTypes: _emptyPubTypesArray(),
            actionModuleData: abi.encode(collectNftRecipient, collectModuleData)
        });

        uint256 contractNonce = vm.getNonce(address(collectPublicationAction));
        address collectNFT = computeCreateAddress(address(collectPublicationAction), contractNonce);

        vm.expectEmit(true, true, true, true, address(collectPublicationAction));
        emit CollectNFTDeployed(profileId, pubId, collectNFT, block.timestamp);

        vm.expectEmit(true, true, true, true, address(collectNFT));
        emit Transfer({from: address(0), to: collectNftRecipient, tokenId: 1});

        vm.expectEmit(true, true, true, true, address(collectPublicationAction));
        emit Collected({
            collectedProfileId: processActionParams.publicationActedProfileId,
            collectedPubId: processActionParams.publicationActedId,
            collectorProfileId: processActionParams.actorProfileId,
            nftRecipient: collectNftRecipient,
            collectActionData: collectModuleData,
            collectActionResult: collectModuleData,
            collectNFT: collectNFT,
            tokenId: 1,
            transactionExecutor: transactionExecutor,
            timestamp: block.timestamp
        });

        vm.expectCall(collectNFT, abi.encodeCall(CollectNFT.initialize, (profileId, pubId)), 1);

        {
            vm.prank(address(hub));
            bytes memory returnData = collectPublicationAction.processPublicationAction(processActionParams);
            (
                address returnedCollectNFT,
                uint256 tokenId,
                address returnedCollectModule,
                bytes memory collectActionResult
            ) = abi.decode(returnData, (address, uint256, address, bytes));
            assertEq(returnedCollectNFT, collectNFT, 'Invalid collectNFT address');
            assertEq(tokenId, 1, 'Invalid tokenId');
            assertEq(returnedCollectModule, mockCollectModule, 'Invalid collectModule address');
            assertEq(collectActionResult, collectModuleData, 'Invalid collectActionResult data');
        }

        string memory expectedCollectNftName = string.concat(
            'Lens Collect | Profile #',
            profileId.toString(),
            ' - Publication #',
            pubId.toString()
        );

        string memory expectedCollectNftSymbol = 'LENS-COLLECT';

        assertEq(CollectNFT(collectNFT).name(), expectedCollectNftName, 'Invalid collect NFT name');
        assertEq(CollectNFT(collectNFT).symbol(), expectedCollectNftSymbol, 'Invalid collect NFT symbol');

        assertEq(CollectNFT(collectNFT).ownerOf(1), collectNftRecipient, 'Invalid collect NFT owner');
    }

    function testProcessPublicationAction_nonFirstCollect(
        uint256 profileId,
        uint256 pubId,
        uint256 actorProfileId,
        address actorProfileOwner,
        address transactionExecutor,
        address collectNftRecipient
    ) public {
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        vm.assume(actorProfileId != 0);
        vm.assume(actorProfileOwner != address(0));
        vm.assume(transactionExecutor != address(0));

        testProcessPublicationAction_firstCollect(
            profileId,
            pubId,
            actorProfileId,
            actorProfileOwner,
            transactionExecutor,
            collectNftRecipient
        );

        assertTrue(collectPublicationAction.getCollectData(profileId, pubId).collectModule != address(0));
        address collectNFT = collectPublicationAction.getCollectData(profileId, pubId).collectNFT;
        assertTrue(collectNFT != address(0));

        bytes memory collectModuleData = abi.encode(true);

        Types.ProcessActionParams memory processActionParams = Types.ProcessActionParams({
            publicationActedProfileId: profileId,
            publicationActedId: pubId,
            actorProfileId: actorProfileId,
            actorProfileOwner: actorProfileOwner,
            transactionExecutor: transactionExecutor,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            referrerPubTypes: _emptyPubTypesArray(),
            actionModuleData: abi.encode(collectNftRecipient, collectModuleData)
        });

        vm.expectEmit(true, true, true, true, address(collectNFT));
        emit Transfer({from: address(0), to: collectNftRecipient, tokenId: 2});

        vm.expectEmit(true, true, true, true, address(collectPublicationAction));
        emit Collected({
            collectedProfileId: processActionParams.publicationActedProfileId,
            collectedPubId: processActionParams.publicationActedId,
            collectorProfileId: processActionParams.actorProfileId,
            nftRecipient: collectNftRecipient,
            collectActionData: collectModuleData,
            collectActionResult: collectModuleData,
            collectNFT: collectNFT,
            tokenId: 2,
            transactionExecutor: transactionExecutor,
            timestamp: block.timestamp
        });

        vm.prank(address(hub));
        bytes memory returnData = collectPublicationAction.processPublicationAction(processActionParams);
        (
            address returnedCollectNFT,
            uint256 tokenId,
            address returnedCollectModule,
            bytes memory collectActionResult
        ) = abi.decode(returnData, (address, uint256, address, bytes));
        assertEq(returnedCollectNFT, collectNFT, 'Invalid collectNFT address');
        assertEq(tokenId, 2, 'Invalid tokenId');
        assertEq(returnedCollectModule, mockCollectModule, 'Invalid collectModule address');
        assertEq(collectActionResult, collectModuleData, 'Invalid collectActionResult data');

        assertEq(CollectNFT(collectNFT).ownerOf(2), collectNftRecipient, 'Invalid collect NFT owner');
    }

    // TODO: Should we test for mockActionModule reverts processCollect - and NFT is not minted then?
}
