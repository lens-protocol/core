// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/MetaTxNegatives.t.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {ReferralSystemTest} from 'test/ReferralSystem.t.sol';

contract ActTest is ReferralSystemTest {
    TestAccount actor;
    Types.PublicationActionParams actionParams;

    function _referralSystem_PrepareOperation(
        TestPublication memory target,
        uint256[] memory referrerProfileIds,
        uint256[] memory referrerPubIds
    ) internal virtual override {
        actionParams = _getDefaultPublicationActionParams();
        actionParams.publicationActedProfileId = target.profileId;
        actionParams.publicationActedId = target.pubId;
        actionParams.actorProfileId = actor.profileId;
        actionParams.referrerProfileIds = referrerProfileIds;
        actionParams.referrerPubIds = referrerPubIds;
        _refreshCachedNonces();
    }

    function _referralSystem_ExpectRevertsIfNeeded(
        TestPublication memory target,
        uint256[] memory, /* referrerProfileIds */
        uint256[] memory /* referrerPubIds */
    ) internal virtual override returns (bool) {
        if (_isV1LegacyPub(hub.getPublication(target.profileId, target.pubId))) {
            vm.expectRevert(Errors.ActionNotAllowed.selector);
            return true;
        }
        return false;
    }

    function _referralSystem_ExecutePreparedOperation() internal virtual override {
        _act(actor.ownerPk, actionParams);
    }

    function _act(uint256 pk, Types.PublicationActionParams memory publicationActionParams)
        internal
        virtual
        returns (bytes memory)
    {
        vm.prank(vm.addr(pk));
        return hub.act(publicationActionParams);
    }

    function _refreshCachedNonces() internal virtual {
        // Nothing to do there.
    }

    function setUp() public virtual override {
        super.setUp();
        actor = _loadAccountAs('ACTOR');
        actionParams = _getDefaultPublicationActionParams();
        actionParams.actorProfileId = actor.profileId;
    }

    // Negatives
    function testCannotAct_ifNonExistingPublication(uint256 nonexistentPubId) public {
        vm.assume(nonexistentPubId != defaultPub.pubId);
        actionParams.publicationActedId = nonexistentPubId;

        vm.expectRevert(Errors.ActionNotAllowed.selector);

        _act(actor.ownerPk, actionParams);
    }

    function testCannotAct_ifActionModuleNotEnabledForPublication(address notEnabledActionModule) public {
        vm.assume(notEnabledActionModule != address(mockActionModule));

        actionParams.actionModuleAddress = notEnabledActionModule;

        vm.expectRevert(Errors.ActionNotAllowed.selector);

        _act(actor.ownerPk, actionParams);
    }

    function testCannotAct_ifProtocolIsPaused() public {
        vm.prank(governance);
        hub.setState(Types.ProtocolState.Paused);

        vm.expectRevert(Errors.Paused.selector);
        _act(actor.ownerPk, actionParams);
    }

    function testCannotAct_onMirrors() public {
        Types.MirrorParams memory mirrorParams = _getDefaultMirrorParams();
        vm.prank(defaultAccount.owner);
        uint256 mirrorPubId = hub.mirror(mirrorParams);

        actionParams.publicationActedId = mirrorPubId;

        vm.expectRevert(Errors.ActionNotAllowed.selector);
        _act(actor.ownerPk, actionParams);
    }

    // Scenarios

    function testAct() public {
        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.Acted(actionParams, abi.encode(true), block.timestamp);

        Types.ProcessActionParams memory processActionParams = Types.ProcessActionParams({
            publicationActedProfileId: actionParams.publicationActedProfileId,
            publicationActedId: actionParams.publicationActedId,
            actorProfileId: actionParams.actorProfileId,
            actorProfileOwner: actor.owner,
            transactionExecutor: actor.owner,
            referrerProfileIds: actionParams.referrerProfileIds,
            referrerPubIds: actionParams.referrerPubIds,
            referrerPubTypes: _emptyPubTypesArray(),
            actionModuleData: actionParams.actionModuleData
        });

        vm.expectCall(
            address(mockActionModule),
            abi.encodeWithSelector(mockActionModule.processPublicationAction.selector, (processActionParams))
        );

        _act(actor.ownerPk, actionParams);
    }

    function testAct_onComment() public {
        Types.CommentParams memory commentParams = _getDefaultCommentParams();
        vm.prank(defaultAccount.owner);
        uint256 commentPubId = hub.comment(commentParams);

        actionParams.publicationActedId = commentPubId;
        testAct();
    }

    function testAct_onQuote() public {
        Types.QuoteParams memory quoteParams = _getDefaultQuoteParams();
        vm.prank(defaultAccount.owner);
        uint256 quotePubId = hub.quote(quoteParams);

        actionParams.publicationActedId = quotePubId;
        testAct();
    }

    function testCanAct_evenIfActionWasUnwhitelisted() public {
        vm.prank(governance);
        hub.whitelistActionModule(actionParams.actionModuleAddress, false);

        testAct();
    }

    function testCanAct_evenIfPublishingPaused() public {
        vm.prank(governance);
        hub.setState(Types.ProtocolState.PublishingPaused);

        testAct();
    }

    function testGetActionModuleById(address secondActionModule) public {
        address firstActionModule = makeAddr('FIRST_ACTION_MODULE');
        vm.assume(firstActionModule != secondActionModule);

        Types.ActionModuleWhitelistData memory whitelistData = hub.getActionModuleWhitelistData(secondActionModule);
        vm.assume(whitelistData.id == 0);
        vm.assume(whitelistData.isWhitelisted == false);

        vm.prank(governance);
        hub.whitelistActionModule(firstActionModule, true);

        whitelistData = hub.getActionModuleWhitelistData(firstActionModule);
        uint256 firstActionModuleId = whitelistData.id;
        assertTrue(whitelistData.isWhitelisted);

        vm.prank(governance);
        hub.whitelistActionModule(secondActionModule, true);

        whitelistData = hub.getActionModuleWhitelistData(secondActionModule);
        uint256 secondActionModuleId = whitelistData.id;
        assertTrue(whitelistData.isWhitelisted);

        assertEq(hub.getActionModuleById(firstActionModuleId), firstActionModule);
        assertEq(hub.getActionModuleById(secondActionModuleId), secondActionModule);
    }

    // Will not work on fork with more complicated action modules because we don't know how to initialize them
    function testGetEnabledActionModulesBitmap(uint8 enabledActionModulesBitmap) public {
        vm.assume(enabledActionModulesBitmap != 0);

        address[] memory actionModules = new address[](9);
        vm.startPrank(governance);
        for (uint256 i = 1; i < actionModules.length; i++) {
            if (hub.getActionModuleById(i) == address(0)) {
                actionModules[i] = makeAddr(string.concat('ACTION_MODULE_', vm.toString(i)));
                vm.etch(actionModules[i], address(mockActionModule).code);
                hub.whitelistActionModule(actionModules[i], true);
            } else {
                actionModules[i] = hub.getActionModuleById(i);
            }
        }
        vm.stopPrank();

        // Count enabledActionModules from a bitmap
        uint8 enabledActionModulesCount = 0;
        for (uint256 i = 0; i < 8; i++) {
            if (enabledActionModulesBitmap & (1 << i) != 0) {
                enabledActionModulesCount++;
            }
        }

        // Pick enabledActionModulesCount action modules
        address[] memory enabledActionModules = new address[](enabledActionModulesCount);
        uint256 enabledActionModulesIndex = 0;
        for (uint256 i = 0; i < 8; i++) {
            if (enabledActionModulesBitmap & (1 << i) != 0) {
                enabledActionModules[enabledActionModulesIndex] = actionModules[i + 1];
                enabledActionModulesIndex++;
            }
        }

        bytes[] memory enabledActionModulesInitDatas = new bytes[](enabledActionModulesCount);
        for (uint256 i = 0; i < enabledActionModulesCount; i++) {
            enabledActionModulesInitDatas[i] = abi.encode(true);
        }

        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.actionModules = enabledActionModules;
        postParams.actionModulesInitDatas = enabledActionModulesInitDatas;

        vm.prank(defaultAccount.owner);
        uint256 pubId = hub.post(postParams);

        assertEq(
            hub.getPublication(defaultAccount.profileId, pubId).enabledActionModulesBitmap,
            enabledActionModulesBitmap
        );
    }
}

contract ActMetaTxTest is ActTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function testActionMetaTxTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public override(ActTest, MetaTxNegatives) {
        ActTest.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[actor.owner] = hub.nonces(actor.owner);
    }

    function _act(uint256 pk, Types.PublicationActionParams memory publicationActionParams)
        internal
        override
        returns (bytes memory)
    {
        address signer = vm.addr(pk);
        return
            hub.actWithSig({
                publicationActionParams: publicationActionParams,
                signature: _getSigStruct({
                    pKey: pk,
                    digest: _calculateActWithSigDigest(
                        publicationActionParams,
                        cachedNonceByAddress[signer],
                        type(uint256).max
                    ),
                    deadline: type(uint256).max
                })
            });
    }

    function _executeMetaTx(
        uint256 signerPk,
        uint256 nonce,
        uint256 deadline
    ) internal virtual override {
        hub.actWithSig({
            publicationActionParams: actionParams,
            signature: _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _calculateActWithSigDigest(actionParams, nonce, deadline),
                deadline: deadline
            })
        });
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return actor.ownerPk;
    }

    function _calculateActWithSigDigest(
        Types.PublicationActionParams memory publicationActionParams,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        return
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.ACT,
                        publicationActionParams.publicationActedProfileId,
                        publicationActionParams.publicationActedId,
                        publicationActionParams.actorProfileId,
                        publicationActionParams.referrerProfileIds,
                        publicationActionParams.referrerPubIds,
                        publicationActionParams.actionModuleAddress,
                        keccak256(publicationActionParams.actionModuleData),
                        nonce,
                        deadline
                    )
                )
            );
    }

    function _refreshCachedNonces() internal override {
        cachedNonceByAddress[actor.owner] = hub.nonces(actor.owner);
    }
}
