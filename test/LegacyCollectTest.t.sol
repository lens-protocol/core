// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/MetaTxNegatives.t.sol';
import {MockDeprecatedCollectModule} from 'test/mocks/MockDeprecatedCollectModule.sol';
import {ICollectNFT} from 'contracts/interfaces/ICollectNFT.sol';
import {LegacyCollectLib} from 'contracts/libraries/LegacyCollectLib.sol';
import {ILegacyCollectModule} from 'contracts/interfaces/ILegacyCollectModule.sol';
import {ReferralSystemTest} from 'test/ReferralSystem.t.sol';

contract LegacyCollectTest is BaseTest, ReferralSystemTest {
    using Strings for uint256;
    uint256 pubId;
    Types.LegacyCollectParams defaultCollectParams;
    TestAccount blockedProfile;

    bool skipTest;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public virtual override(BaseTest, ReferralSystemTest) {
        ReferralSystemTest.setUp();

        blockedProfile = _loadAccountAs('BLOCKED_PROFILE');

        // Create a V1 pub
        vm.prank(defaultAccount.owner);
        pubId = hub.post(_getDefaultPostParams());

        _toLegacyV1Pub(defaultAccount.profileId, pubId, address(0), address(mockDeprecatedCollectModule));

        defaultCollectParams = Types.LegacyCollectParams({
            publicationCollectedProfileId: defaultAccount.profileId,
            publicationCollectedId: pubId,
            collectorProfileId: defaultAccount.profileId,
            referrerProfileId: 0,
            referrerPubId: 0,
            collectModuleData: abi.encode(true)
        });
    }

    function testV2UnverifiedReferrals() public virtual override {
        // ReferralSystem inherited test that does not apply to this file.
        // This case is tested at `testCannot_PassV2UnverifiedReferrals`.
    }

    function testCannot_PassV2UnverifiedReferral_SameAsTargetAuthor() public virtual override {
        // Note: The following publication is converted to Legacy V1 in this test's setUp.
        TestPublication memory targetPub = TestPublication(defaultAccount.profileId, pubId);

        _referralSystem_PrepareOperation(targetPub, _toUint256Array(targetPub.profileId), _toUint256Array(0));
        vm.expectRevert(Errors.InvalidReferrer.selector);
        _referralSystem_ExecutePreparedOperation();
    }

    function testCannot_PassV2UnverifiedReferrals(address referrerProfileOwner) public {
        vm.assume(referrerProfileOwner != address(0));
        uint256 referrerProfileId = _createProfile(referrerProfileOwner);

        // Set unverified referral
        defaultCollectParams.referrerProfileId = referrerProfileId;
        defaultCollectParams.referrerPubId = 0;

        vm.expectRevert(Errors.InvalidReferrer.selector);
        _collect(defaultAccount.ownerPk, defaultCollectParams);
    }

    function testCannotCollectIfPaused() public {
        vm.prank(governance);
        hub.setState(Types.ProtocolState.Paused);

        vm.expectRevert(Errors.Paused.selector);
        _collect(defaultAccount.ownerPk, defaultCollectParams);
    }

    function testCannot_Collect_IfNotProfileOwnerOrDelegatedExecutor(uint256 otherPk) public {
        otherPk = _boundPk(otherPk);
        address otherAddress = vm.addr(otherPk);
        vm.assume(otherAddress != address(0));
        vm.assume(otherAddress != defaultAccount.owner);
        vm.assume(!hub.isDelegatedExecutorApproved(defaultAccount.profileId, otherAddress));

        vm.expectRevert(Errors.ExecutorInvalid.selector);
        _collect(otherPk, defaultCollectParams);
    }

    function testCannot_Collect_IfCollectorProfileDoesNotExist(uint256 randomProfileId) public {
        vm.assume(randomProfileId != 0);
        vm.assume(hub.exists(randomProfileId) == false);

        defaultCollectParams.collectorProfileId = randomProfileId;

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        _collect(defaultAccount.ownerPk, defaultCollectParams);
    }

    function testCannot_Collect_IfBlocked() public {
        vm.prank(defaultAccount.owner);
        hub.setBlockStatus(defaultAccount.profileId, _toUint256Array(blockedProfile.profileId), _toBoolArray(true));

        defaultCollectParams.collectorProfileId = blockedProfile.profileId;

        vm.expectRevert(Errors.Blocked.selector);
        _collect(blockedProfile.ownerPk, defaultCollectParams);
    }

    function testCannot_Collect_IfNoCollectModuleSet(uint256 randomPubId) public {
        vm.assume(randomPubId != 0);
        vm.assume(hub.getPublication(defaultAccount.profileId, randomPubId).__DEPRECATED__collectModule == address(0));

        defaultCollectParams.publicationCollectedId = randomPubId;

        vm.expectRevert(Errors.CollectNotAllowed.selector);
        _collect(defaultAccount.ownerPk, defaultCollectParams);
    }

    function testCannotExecuteOperationIf_ReferralProfileIdsPassedQty_DiffersFromPubIdsQty() public override {
        // ReferralSystem inherited test that does not apply to this file.
    }

    function testCannotPass_TargetedPublication_AsReferrer() public override {
        // Note: The following publication is converted to Legacy V1 in this test's setUp.
        TestPublication memory targetPub = TestPublication(defaultAccount.profileId, pubId);

        _referralSystem_PrepareOperation(
            targetPub,
            _toUint256Array(targetPub.profileId),
            _toUint256Array(targetPub.pubId)
        );
        vm.expectRevert(Errors.InvalidReferrer.selector);
        _referralSystem_ExecutePreparedOperation();
    }

    function testCannotPass_UnexistentProfile_AsReferrer(uint256 unexistentProfileId, uint8 anyPubId) public override {
        // Note: The following publication is converted to Legacy V1 in this test's setUp.
        TestPublication memory targetPub = TestPublication(defaultAccount.profileId, pubId);

        vm.assume(!hub.exists(unexistentProfileId));
        vm.assume(anyPubId != 0);
        _referralSystem_PrepareOperation(targetPub, _toUint256Array(unexistentProfileId), _toUint256Array(anyPubId));
        vm.expectRevert(Errors.InvalidReferrer.selector);
        _referralSystem_ExecutePreparedOperation();
    }

    function testCannotPass_UnexistentPublication_AsReferrer(uint256 unexistentPubId) public override {
        // Note: The following publication is converted to Legacy V1 in this test's setUp.
        TestPublication memory targetPub = TestPublication(defaultAccount.profileId, pubId);

        TestPublication memory pub = _comment(targetPub);
        uint256 existentProfileId = pub.profileId;
        vm.assume(unexistentPubId > pub.pubId);

        _referralSystem_PrepareOperation(
            targetPub,
            _toUint256Array(existentProfileId),
            _toUint256Array(unexistentPubId)
        );
        vm.expectRevert(Errors.InvalidReferrer.selector);
        _referralSystem_ExecutePreparedOperation();
    }

    function testCannotPass_UnexistentProfile_AsUnverifiedReferrer(uint256 unexistentProfileId) public override {
        // Note: The following publication is converted to Legacy V1 in this test's setUp.
        TestPublication memory targetPub = TestPublication(defaultAccount.profileId, pubId);
        // We need unexistentProfileId to be non-zero, otherwise referral = (0, 0) means no referrals were passed.
        vm.assume(unexistentProfileId != 0);
        vm.assume(!hub.exists(unexistentProfileId));
        _referralSystem_PrepareOperation(targetPub, _toUint256Array(unexistentProfileId), _toUint256Array(0));
        vm.expectRevert(Errors.InvalidReferrer.selector);
        _referralSystem_ExecutePreparedOperation();
    }

    function testCannotPass_BurntProfile_AsReferrer() public {
        // Note: The following publication is converted to Legacy V1 in this test's setUp.
        TestPublication memory targetPub = TestPublication(defaultAccount.profileId, pubId);

        TestPublication memory referrerMirrorPub = _mirror(targetPub);
        address referrerMirrorOwner = hub.ownerOf(referrerMirrorPub.profileId);

        _effectivelyDisableProfileGuardian(referrerMirrorOwner);

        vm.prank(referrerMirrorOwner);
        hub.burn(referrerMirrorPub.profileId);

        _referralSystem_PrepareOperation(
            targetPub,
            _toUint256Array(referrerMirrorPub.profileId),
            _toUint256Array(referrerMirrorPub.pubId)
        );
        vm.expectRevert(Errors.InvalidReferrer.selector);
        _referralSystem_ExecutePreparedOperation();
    }

    function testCannotPass_BurntProfile_AsUnverifiedReferrer() public override {
        // Note: The following publication is converted to Legacy V1 in this test's setUp.
        TestPublication memory targetPub = TestPublication(defaultAccount.profileId, pubId);

        TestPublication memory referralPub = _mirror(targetPub);
        address referralOwner = hub.ownerOf(referralPub.profileId);

        _effectivelyDisableProfileGuardian(referralOwner);

        vm.prank(referralOwner);
        hub.burn(referralPub.profileId);

        _referralSystem_PrepareOperation(targetPub, _toUint256Array(referralPub.profileId), _toUint256Array(0));
        vm.expectRevert(Errors.InvalidReferrer.selector);
        _referralSystem_ExecutePreparedOperation();
    }

    function testCollect() public {
        Types.PublicationMemory memory pub = hub.getPublication(defaultAccount.profileId, pubId);
        assertTrue(pub.__DEPRECATED__collectNFT == address(0));

        address predictedCollectNFT = computeCreateAddress(address(hub), vm.getNonce(address(hub)));

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.LegacyCollectNFTDeployed(defaultAccount.profileId, pubId, predictedCollectNFT, block.timestamp);

        vm.expectCall(
            predictedCollectNFT,
            abi.encodeCall(
                ICollectNFT.initialize,
                (defaultCollectParams.publicationCollectedProfileId, defaultCollectParams.publicationCollectedId)
            ),
            1
        );

        vm.expectCall(
            predictedCollectNFT,
            abi.encodeCall(ICollectNFT.mint, (hub.ownerOf(defaultCollectParams.collectorProfileId))),
            2
        );

        vm.expectCall(
            address(mockDeprecatedCollectModule),
            abi.encodeCall(
                ILegacyCollectModule.processCollect,
                (
                    defaultCollectParams.collectorProfileId,
                    defaultAccount.owner,
                    defaultCollectParams.publicationCollectedProfileId,
                    defaultCollectParams.publicationCollectedId,
                    defaultCollectParams.collectModuleData
                )
            ),
            2
        );

        vm.expectEmit(true, true, true, true, predictedCollectNFT);
        emit Transfer(address(0), hub.ownerOf(defaultCollectParams.collectorProfileId), 1);

        uint256 expectedTokenId = 1; // TODO: fix this if needed

        vm.expectEmit(true, true, true, true, address(hub));
        emit LegacyCollectLib.CollectedLegacy({
            publicationCollectedProfileId: defaultCollectParams.publicationCollectedProfileId,
            publicationCollectedId: defaultCollectParams.publicationCollectedId,
            transactionExecutor: defaultAccount.owner,
            referrerProfileId: defaultCollectParams.referrerProfileId,
            referrerPubId: defaultCollectParams.referrerPubId,
            collectModuleData: defaultCollectParams.collectModuleData,
            tokenId: expectedTokenId,
            nftRecipient: hub.ownerOf(defaultCollectParams.collectorProfileId),
            timestamp: block.timestamp
        });

        uint256 collectTokenId = _collect(defaultAccount.ownerPk, defaultCollectParams);
        assertEq(collectTokenId, expectedTokenId);

        string memory expectedCollectNftName = string.concat(
            'Lens Collect | Profile #',
            defaultCollectParams.publicationCollectedProfileId.toString(),
            ' - Publication #',
            defaultCollectParams.publicationCollectedId.toString()
        );

        string memory expectedCollectNftSymbol = 'LENS-COLLECT';

        assertEq(LegacyCollectNFT(predictedCollectNFT).name(), expectedCollectNftName, 'Invalid collect NFT name');
        assertEq(
            LegacyCollectNFT(predictedCollectNFT).symbol(),
            expectedCollectNftSymbol,
            'Invalid collect NFT symbol'
        );

        _refreshCachedNonces();

        pub = hub.getPublication(defaultAccount.profileId, pubId);
        assertEq(pub.__DEPRECATED__collectNFT, predictedCollectNFT);

        vm.expectEmit(true, true, true, true, predictedCollectNFT);
        emit Transfer(address(0), hub.ownerOf(defaultCollectParams.collectorProfileId), collectTokenId + 1);

        vm.expectEmit(true, true, true, true, address(hub));
        emit LegacyCollectLib.CollectedLegacy({
            publicationCollectedProfileId: defaultCollectParams.publicationCollectedProfileId,
            publicationCollectedId: defaultCollectParams.publicationCollectedId,
            transactionExecutor: defaultAccount.owner,
            referrerProfileId: defaultCollectParams.referrerProfileId,
            referrerPubId: defaultCollectParams.referrerPubId,
            collectModuleData: defaultCollectParams.collectModuleData,
            tokenId: collectTokenId + 1,
            nftRecipient: hub.ownerOf(defaultCollectParams.collectorProfileId),
            timestamp: block.timestamp
        });

        uint256 secondCollectTokenId = _collect(defaultAccount.ownerPk, defaultCollectParams);
        assertEq(secondCollectTokenId, collectTokenId + 1);
    }

    function _collect(uint256 pk, Types.LegacyCollectParams memory collectParams) internal virtual returns (uint256) {
        vm.prank(vm.addr(pk));
        return hub.collectLegacy(collectParams);
    }

    function _referralSystem_PrepareOperation(
        TestPublication memory target,
        uint256[] memory referrerProfileIds,
        uint256[] memory referrerPubIds
    ) internal virtual override {
        if (referrerProfileIds.length == 0 && referrerPubIds.length == 0) {
            defaultCollectParams.referrerProfileId = 0;
            defaultCollectParams.referrerPubId = 0;
        } else if (referrerProfileIds.length == 1 && referrerPubIds.length == 1) {
            defaultCollectParams.referrerProfileId = referrerProfileIds[0];
            defaultCollectParams.referrerPubId = referrerPubIds[0];
        } else {
            skipTest = true;
        }
        defaultCollectParams.publicationCollectedProfileId = target.profileId;
        defaultCollectParams.publicationCollectedId = target.pubId;
        _refreshCachedNonces();
    }

    function _referralSystem_ExpectRevertsIfNeeded(
        TestPublication memory target,
        uint256[] memory /* referrerProfileIds */,
        uint256[] memory /* referrerPubIds */
    ) internal virtual override returns (bool) {
        if (skipTest) {
            return true;
        }

        Types.PublicationMemory memory targetPublication = hub.getPublication(target.profileId, target.pubId);

        if (defaultCollectParams.referrerPubId == 0) {
            // Cannot pass unverified referrer for LegacyCollect
            vm.expectRevert(Errors.InvalidReferrer.selector);
            return true;
        }

        if (defaultCollectParams.referrerProfileId != 0 && defaultCollectParams.referrerPubId != 0) {
            if (!_isV1LegacyPub(targetPublication)) {
                // Cannot collect V2 publications
                vm.expectRevert(Errors.CollectNotAllowed.selector);
                return true;
            } else {
                if (
                    hub.getPublicationType(
                        defaultCollectParams.referrerProfileId,
                        defaultCollectParams.referrerPubId
                    ) != Types.PublicationType.Mirror
                ) {
                    vm.expectRevert(Errors.InvalidReferrer.selector);
                    return true;
                }
                Types.PublicationMemory memory referrerPublication = hub.getPublication(
                    defaultCollectParams.referrerProfileId,
                    defaultCollectParams.referrerPubId
                );

                // A mirror can only be a referrer of a legacy publication if it is pointing to it.
                if (
                    referrerPublication.pointedProfileId != target.profileId ||
                    referrerPublication.pointedPubId != target.pubId
                ) {
                    vm.expectRevert(Errors.InvalidReferrer.selector);
                    return true;
                }
            }
        }
        return false;
    }

    function _referralSystem_ExecutePreparedOperation() internal virtual override {
        // console.log(
        //     'LEGACY COLLECTING: (%s, %s)',
        //     defaultCollectParams.publicationCollectedProfileId,
        //     defaultCollectParams.publicationCollectedId
        // );
        // console.log(
        //     '    with referrer: (%s, %s)',
        //     defaultCollectParams.referrerProfileId,
        //     defaultCollectParams.referrerPubId
        // );
        if (skipTest) {
            console.log('   ^^^ SKIPPED ^^^');
            return;
        }
        _collect(defaultAccount.ownerPk, defaultCollectParams);
    }

    function _refreshCachedNonces() internal virtual {
        // Nothing to do there.
    }
}

contract LegacyCollectMetaTxTest is LegacyCollectTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function testLegacyCollectMetaTxTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public override(LegacyCollectTest, MetaTxNegatives) {
        LegacyCollectTest.setUp();
        MetaTxNegatives.setUp();

        _refreshCachedNonces();
    }

    function _collect(
        uint256 pk,
        Types.LegacyCollectParams memory collectParams
    ) internal virtual override returns (uint256) {
        address signer = vm.addr(pk);

        return
            hub.collectLegacyWithSig(
                collectParams,
                _getSigStruct({
                    pKey: pk,
                    digest: _calculateCollectWithSigDigest({
                        collectParams: collectParams,
                        nonce: cachedNonceByAddress[signer],
                        deadline: type(uint256).max
                    }),
                    deadline: type(uint256).max
                })
            );
    }

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        hub.collectLegacyWithSig(
            defaultCollectParams,
            _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _calculateCollectWithSigDigest({
                    collectParams: defaultCollectParams,
                    nonce: nonce,
                    deadline: deadline
                }),
                deadline: deadline
            })
        );
    }

    function _incrementNonce(uint8 increment) internal override {
        vm.prank(vm.addr(_getDefaultMetaTxSignerPk()));
        hub.incrementNonce(increment);
        _refreshCachedNonces();
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return defaultAccount.ownerPk;
    }

    function _calculateCollectWithSigDigest(
        Types.LegacyCollectParams memory collectParams,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        return
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.COLLECT_LEGACY,
                        collectParams.publicationCollectedProfileId,
                        collectParams.publicationCollectedId,
                        collectParams.collectorProfileId,
                        collectParams.referrerProfileId,
                        collectParams.referrerPubId,
                        keccak256(collectParams.collectModuleData),
                        nonce,
                        deadline
                    )
                )
            );
    }

    function _refreshCachedNonces() internal override {
        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
        cachedNonceByAddress[blockedProfile.owner] = hub.nonces(blockedProfile.owner);
    }
}
