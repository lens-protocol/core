// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/MetaTxNegatives.t.sol';
import {MockDeprecatedCollectModule} from 'test/mocks/MockDeprecatedCollectModule.sol';
import {ICollectNFT} from 'contracts/interfaces/ICollectNFT.sol';
import {LegacyCollectLib} from 'contracts/libraries/LegacyCollectLib.sol';
import {ILegacyCollectModule} from 'contracts/interfaces/ILegacyCollectModule.sol';

contract LegacyCollectTest is BaseTest {
    uint256 pubId;
    Types.CollectParams defaultCollectParams;
    MockDeprecatedCollectModule mockDeprecatedCollectModule;
    TestAccount blockedProfile;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event CollectedLegacy(
        uint256 indexed publicationCollectedProfileId,
        uint256 indexed publicationCollectedId,
        address transactionExecutor,
        uint256 referrerProfileId,
        uint256 referrerPubId,
        bytes collectModuleData,
        uint256 timestamp
    );

    function setUp() public virtual override {
        super.setUp();

        blockedProfile = _loadAccountAs('BLOCKED_PROFILE');

        mockDeprecatedCollectModule = new MockDeprecatedCollectModule();

        // Create a V1 pub
        vm.prank(defaultAccount.owner);
        pubId = hub.post(_getDefaultPostParams());

        _toLegacyV1Pub(defaultAccount.profileId, pubId, address(0), address(mockDeprecatedCollectModule));

        defaultCollectParams = Types.CollectParams({
            publicationCollectedProfileId: defaultAccount.profileId,
            publicationCollectedId: pubId,
            collectorProfileId: defaultAccount.profileId,
            referrerProfileId: 0,
            referrerPubId: 0,
            collectModuleData: abi.encode(true)
        });
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

    function testCollect() public {
        Types.Publication memory pub = hub.getPublication(defaultAccount.profileId, pubId);
        assertTrue(pub.__DEPRECATED__collectNFT == address(0));

        address predictedCollectNFT = computeCreateAddress(address(hub), vm.getNonce(address(hub)));
        string memory predictedCollectNFTName = string.concat(
            vm.toString(defaultAccount.profileId),
            LegacyCollectLib.COLLECT_NFT_NAME_INFIX,
            vm.toString(pubId)
        );
        string memory predictedCollectNFTSymbol = string.concat(
            vm.toString(defaultAccount.profileId),
            LegacyCollectLib.COLLECT_NFT_SYMBOL_INFIX,
            vm.toString(pubId)
        );

        vm.expectEmit(true, true, true, true, address(hub));
        emit Events.CollectNFTDeployed(defaultAccount.profileId, pubId, predictedCollectNFT, block.timestamp);

        vm.expectCall(
            predictedCollectNFT,
            abi.encodeCall(
                ICollectNFT.initialize,
                (
                    defaultCollectParams.publicationCollectedProfileId,
                    defaultCollectParams.publicationCollectedId,
                    predictedCollectNFTName,
                    predictedCollectNFTSymbol
                )
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

        vm.expectEmit(true, true, true, true, address(hub));
        emit CollectedLegacy({
            publicationCollectedProfileId: defaultCollectParams.publicationCollectedProfileId,
            publicationCollectedId: defaultCollectParams.publicationCollectedId,
            transactionExecutor: defaultAccount.owner,
            referrerProfileId: defaultCollectParams.referrerProfileId,
            referrerPubId: defaultCollectParams.referrerPubId,
            collectModuleData: defaultCollectParams.collectModuleData,
            timestamp: block.timestamp
        });

        uint256 collectTokenId = _collect(defaultAccount.ownerPk, defaultCollectParams);
        assertEq(collectTokenId, 1);

        _refreshCachedNonces();

        pub = hub.getPublication(defaultAccount.profileId, pubId);
        assertEq(pub.__DEPRECATED__collectNFT, predictedCollectNFT);

        vm.expectEmit(true, true, true, true, predictedCollectNFT);
        emit Transfer(address(0), hub.ownerOf(defaultCollectParams.collectorProfileId), collectTokenId + 1);

        vm.expectEmit(true, true, true, true, address(hub));
        emit CollectedLegacy({
            publicationCollectedProfileId: defaultCollectParams.publicationCollectedProfileId,
            publicationCollectedId: defaultCollectParams.publicationCollectedId,
            transactionExecutor: defaultAccount.owner,
            referrerProfileId: defaultCollectParams.referrerProfileId,
            referrerPubId: defaultCollectParams.referrerPubId,
            collectModuleData: defaultCollectParams.collectModuleData,
            timestamp: block.timestamp
        });

        uint256 secondCollectTokenId = _collect(defaultAccount.ownerPk, defaultCollectParams);
        assertEq(secondCollectTokenId, collectTokenId + 1);
    }

    function _collect(uint256 pk, Types.CollectParams memory collectParams) internal virtual returns (uint256) {
        vm.prank(vm.addr(pk));
        return hub.collect(collectParams);
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
        Types.CollectParams memory collectParams
    ) internal virtual override returns (uint256) {
        address signer = vm.addr(pk);

        return
            hub.collectWithSig(
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
        hub.collectWithSig(
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

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return defaultAccount.ownerPk;
    }

    function _calculateCollectWithSigDigest(
        Types.CollectParams memory collectParams,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        return
            _calculateDigest(
                keccak256(
                    abi.encode(
                        Typehash.LEGACY_COLLECT,
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
