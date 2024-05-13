// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {PublicActProxy} from 'contracts/misc/PublicActProxy.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {MockCollectModule} from 'test/mocks/MockCollectModule.sol';
import {CollectPublicationAction} from 'contracts/modules/act/collect/CollectPublicationAction.sol';
import {CollectNFT} from 'contracts/modules/act/collect/CollectNFT.sol';
import {SimpleFeeCollectModule} from 'contracts/modules/act/collect/SimpleFeeCollectModule.sol';
import {BaseFeeCollectModuleInitData} from 'contracts/modules/interfaces/IBaseFeeCollectModule.sol';
import {MockCurrency} from 'test/mocks/MockCurrency.sol';
import {ProtocolSharedRevenueDistribution, ProtocolSharedRevenueMinFeeMintModuleInitData, ProtocolSharedRevenueMinFeeMintModule} from 'contracts/modules/act/collect/ProtocolSharedRevenueMinFeeMintModule.sol';

contract PublicActProxyTest is BaseTest {
    using stdJson for string;

    PublicActProxy publicActProxy;

    uint256 defaultPubId;
    Types.PublicationActionParams collectActionParams;

    address payer;
    uint256 payerPk;
    address nftRecipient = makeAddr('NFT_RECIPIENT');

    CollectPublicationAction collectPublicationAction;

    TestAccount publicProfile;

    function setUp() public override {
        super.setUp();

        (payer, payerPk) = makeAddrAndKey('PAYER');

        (, address collectPublicationActionAddr) = loadOrDeploy_CollectPublicationAction();

        collectPublicationAction = CollectPublicationAction(collectPublicationActionAddr);

        if (fork && keyExists(json, string(abi.encodePacked('.', forkEnv, '.PublicActProxy')))) {
            publicActProxy = PublicActProxy(
                json.readAddress(string(abi.encodePacked('.', forkEnv, '.PublicActProxy')))
            );
        } else {
            console.log('PublicActProxy key does not exist');
            publicActProxy = new PublicActProxy(address(hub), address(collectPublicationAction));
        }

        publicProfile = _loadAccountAs('PUBLIC_PROFILE');

        vm.prank(publicProfile.owner);
        hub.changeDelegatedExecutorsConfig(
            publicProfile.profileId,
            _toAddressArray(address(publicActProxy)),
            _toBoolArray(true)
        );
    }

    function testCanPublicFreeAct() public {
        address mockCollectModule = address(new MockCollectModule(address(this)));
        collectPublicationAction.registerCollectModule(mockCollectModule);

        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.actionModules[0] = address(collectPublicationAction);
        postParams.actionModulesInitDatas[0] = abi.encode(mockCollectModule, abi.encode(true));

        vm.prank(defaultAccount.owner);
        defaultPubId = hub.post(postParams);

        collectActionParams = Types.PublicationActionParams({
            publicationActedProfileId: defaultAccount.profileId,
            publicationActedId: defaultPubId,
            actorProfileId: publicProfile.profileId,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            actionModuleAddress: address(collectPublicationAction),
            actionModuleData: abi.encode(nftRecipient, abi.encode(true))
        });

        vm.prank(payer);
        publicActProxy.publicFreeAct(collectActionParams);

        CollectNFT collectNFT = CollectNFT(
            CollectPublicationAction(collectPublicationAction)
                .getCollectData(defaultAccount.profileId, defaultPubId)
                .collectNFT
        );

        assertTrue(collectNFT.balanceOf(nftRecipient) > 0, 'NFT recipient balance is 0');
    }

    function testCanPublicCollect() public {
        vm.prank(deployer);
        address simpleFeeCollectModule = address(
            new SimpleFeeCollectModule(
                address(hub),
                address(collectPublicationAction),
                address(moduleRegistry),
                address(this)
            )
        );

        collectPublicationAction.registerCollectModule(simpleFeeCollectModule);

        MockCurrency currency = new MockCurrency();
        currency.mint(payer, 10 ether);

        BaseFeeCollectModuleInitData memory exampleInitData;
        exampleInitData.amount = 1 ether;
        exampleInitData.collectLimit = 0;
        exampleInitData.currency = address(currency);
        exampleInitData.referralFee = 0;
        exampleInitData.followerOnly = false;
        exampleInitData.endTimestamp = 0;
        exampleInitData.recipient = defaultAccount.owner;

        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.actionModules[0] = address(collectPublicationAction);
        postParams.actionModulesInitDatas[0] = abi.encode(simpleFeeCollectModule, abi.encode(exampleInitData));

        vm.prank(defaultAccount.owner);
        defaultPubId = hub.post(postParams);

        collectActionParams = Types.PublicationActionParams({
            publicationActedProfileId: defaultAccount.profileId,
            publicationActedId: defaultPubId,
            actorProfileId: publicProfile.profileId,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            actionModuleAddress: address(collectPublicationAction),
            actionModuleData: abi.encode(nftRecipient, abi.encode(currency, exampleInitData.amount))
        });

        vm.startPrank(payer);
        currency.approve(address(publicActProxy), exampleInitData.amount);
        publicActProxy.publicCollect(collectActionParams);
        vm.stopPrank();

        CollectNFT collectNFT = CollectNFT(
            CollectPublicationAction(collectPublicationAction)
                .getCollectData(defaultAccount.profileId, defaultPubId)
                .collectNFT
        );

        assertTrue(collectNFT.balanceOf(nftRecipient) > 0, 'NFT recipient balance is 0');
    }

    function testCanPublicCollectWithSig() public {
        vm.prank(deployer);
        address simpleFeeCollectModule = address(
            new SimpleFeeCollectModule(
                address(hub),
                address(collectPublicationAction),
                address(moduleRegistry),
                address(this)
            )
        );

        collectPublicationAction.registerCollectModule(simpleFeeCollectModule);

        MockCurrency currency = new MockCurrency();
        currency.mint(payer, 10 ether);

        BaseFeeCollectModuleInitData memory exampleInitData;
        exampleInitData.amount = 1 ether;
        exampleInitData.collectLimit = 0;
        exampleInitData.currency = address(currency);
        exampleInitData.referralFee = 0;
        exampleInitData.followerOnly = false;
        exampleInitData.endTimestamp = 0;
        exampleInitData.recipient = defaultAccount.owner;

        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.actionModules[0] = address(collectPublicationAction);
        postParams.actionModulesInitDatas[0] = abi.encode(simpleFeeCollectModule, abi.encode(exampleInitData));

        vm.prank(defaultAccount.owner);
        defaultPubId = hub.post(postParams);

        collectActionParams = Types.PublicationActionParams({
            publicationActedProfileId: defaultAccount.profileId,
            publicationActedId: defaultPubId,
            actorProfileId: publicProfile.profileId,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            actionModuleAddress: address(collectPublicationAction),
            actionModuleData: abi.encode(nftRecipient, abi.encode(currency, exampleInitData.amount))
        });

        vm.prank(payer);
        currency.approve(address(publicActProxy), exampleInitData.amount);

        domainSeparator = keccak256(
            abi.encode(
                Typehash.EIP712_DOMAIN,
                keccak256('PublicActProxy'),
                MetaTxLib.EIP712_DOMAIN_VERSION_HASH,
                block.chainid,
                address(publicActProxy)
            )
        );

        publicActProxy.publicCollectWithSig({
            publicationActionParams: collectActionParams,
            signature: _getSigStruct({
                pKey: payerPk,
                digest: _getActTypedDataHash(collectActionParams, publicActProxy.nonces(payer), type(uint256).max),
                deadline: type(uint256).max
            })
        });

        CollectNFT collectNFT = CollectNFT(
            CollectPublicationAction(collectPublicationAction)
                .getCollectData(defaultAccount.profileId, defaultPubId)
                .collectNFT
        );

        assertTrue(collectNFT.balanceOf(nftRecipient) > 0, 'NFT recipient balance is 0');
    }

    function testCanPublicPaidAct_SharedRevenuePaidCollect() public {
        vm.prank(deployer);
        address revenueShareModule = address(
            new ProtocolSharedRevenueMinFeeMintModule(
                address(hub),
                address(collectPublicationAction),
                address(moduleRegistry),
                address(this)
            )
        );

        collectPublicationAction.registerCollectModule(revenueShareModule);

        MockCurrency currency = new MockCurrency();
        currency.mint(payer, 10 ether);

        ProtocolSharedRevenueMinFeeMintModuleInitData memory exampleInitData;
        exampleInitData.amount = 1 ether;
        exampleInitData.collectLimit = 0;
        exampleInitData.currency = address(currency);
        exampleInitData.referralFee = 0;
        exampleInitData.followerOnly = false;
        exampleInitData.endTimestamp = 0;
        exampleInitData.recipient = defaultAccount.owner;
        exampleInitData.creatorClient = address(0);

        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.actionModules[0] = address(collectPublicationAction);
        postParams.actionModulesInitDatas[0] = abi.encode(revenueShareModule, abi.encode(exampleInitData));

        vm.prank(defaultAccount.owner);
        defaultPubId = hub.post(postParams);

        collectActionParams = Types.PublicationActionParams({
            publicationActedProfileId: defaultAccount.profileId,
            publicationActedId: defaultPubId,
            actorProfileId: publicProfile.profileId,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            actionModuleAddress: address(collectPublicationAction),
            actionModuleData: abi.encode(nftRecipient, abi.encode(currency, exampleInitData.amount, address(0)))
        });

        vm.startPrank(payer);
        currency.approve(address(publicActProxy), exampleInitData.amount);
        publicActProxy.publicPaidAct(
            collectActionParams,
            exampleInitData.currency,
            exampleInitData.amount,
            revenueShareModule
        );
        vm.stopPrank();

        CollectNFT collectNFT = CollectNFT(
            CollectPublicationAction(collectPublicationAction)
                .getCollectData(defaultAccount.profileId, defaultPubId)
                .collectNFT
        );

        assertTrue(collectNFT.balanceOf(nftRecipient) > 0, 'NFT recipient balance is 0');
    }

    function _getPublicPaidActTypedDataHash(
        Types.PublicationActionParams memory publicationActionParams,
        address currency,
        uint256 amount,
        address approveTo,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                Typehash.PUBLIC_PAID_ACT,
                publicationActionParams.publicationActedProfileId,
                publicationActionParams.publicationActedId,
                publicationActionParams.actorProfileId,
                _encodeUsingEip712Rules(publicationActionParams.referrerProfileIds),
                _encodeUsingEip712Rules(publicationActionParams.referrerPubIds),
                publicationActionParams.actionModuleAddress,
                _encodeUsingEip712Rules(publicationActionParams.actionModuleData),
                currency,
                amount,
                approveTo,
                nonce,
                deadline
            )
        );
        return _calculateDigest(structHash);
    }

    function testCanPublicPaidActWithSig_SharedRevenuePaidCollect() public {
        vm.prank(deployer);
        address revenueShareModule = address(
            new ProtocolSharedRevenueMinFeeMintModule(
                address(hub),
                address(collectPublicationAction),
                address(moduleRegistry),
                address(this)
            )
        );

        collectPublicationAction.registerCollectModule(revenueShareModule);

        MockCurrency currency = new MockCurrency();
        currency.mint(payer, 10 ether);

        ProtocolSharedRevenueMinFeeMintModuleInitData memory exampleInitData;
        exampleInitData.amount = 1 ether;
        exampleInitData.collectLimit = 0;
        exampleInitData.currency = address(currency);
        exampleInitData.referralFee = 0;
        exampleInitData.followerOnly = false;
        exampleInitData.endTimestamp = 0;
        exampleInitData.recipient = defaultAccount.owner;
        exampleInitData.creatorClient = address(0);

        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.actionModules[0] = address(collectPublicationAction);
        postParams.actionModulesInitDatas[0] = abi.encode(revenueShareModule, abi.encode(exampleInitData));

        vm.prank(defaultAccount.owner);
        defaultPubId = hub.post(postParams);

        collectActionParams = Types.PublicationActionParams({
            publicationActedProfileId: defaultAccount.profileId,
            publicationActedId: defaultPubId,
            actorProfileId: publicProfile.profileId,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            actionModuleAddress: address(collectPublicationAction),
            actionModuleData: abi.encode(nftRecipient, abi.encode(currency, exampleInitData.amount, address(0)))
        });

        vm.prank(payer);
        currency.approve(address(publicActProxy), exampleInitData.amount);

        domainSeparator = keccak256(
            abi.encode(
                Typehash.EIP712_DOMAIN,
                keccak256('PublicActProxy'),
                MetaTxLib.EIP712_DOMAIN_VERSION_HASH,
                block.chainid,
                address(publicActProxy)
            )
        );

        publicActProxy.publicPaidActWithSig({
            publicationActionParams: collectActionParams,
            currency: exampleInitData.currency,
            amount: exampleInitData.amount,
            approveTo: revenueShareModule,
            signature: _getSigStruct({
                pKey: payerPk,
                digest: _getPublicPaidActTypedDataHash(
                    collectActionParams,
                    exampleInitData.currency,
                    exampleInitData.amount,
                    revenueShareModule,
                    publicActProxy.nonces(payer),
                    type(uint256).max
                ),
                deadline: type(uint256).max
            })
        });

        CollectNFT collectNFT = CollectNFT(
            CollectPublicationAction(collectPublicationAction)
                .getCollectData(defaultAccount.profileId, defaultPubId)
                .collectNFT
        );

        assertTrue(collectNFT.balanceOf(nftRecipient) > 0, 'NFT recipient balance is 0');
    }

    function testCanPublicPaidAct_SharedRevenueFreeCollect() public {
        address creatorClient = makeAddr('CREATOR_CLIENT');
        address executorClient = makeAddr('EXECUTOR_CLIENT');

        uint256 mintFee = 10 ether;

        vm.prank(deployer);
        address revenueShareModule = address(
            new ProtocolSharedRevenueMinFeeMintModule(
                address(hub),
                address(collectPublicationAction),
                address(moduleRegistry),
                address(this)
            )
        );

        collectPublicationAction.registerCollectModule(revenueShareModule);

        MockCurrency currency = new MockCurrency();
        currency.mint(payer, mintFee);

        ProtocolSharedRevenueMinFeeMintModule(revenueShareModule).setMintFeeParams(address(currency), mintFee);
        ProtocolSharedRevenueMinFeeMintModule(revenueShareModule).setProtocolSharedRevenueDistribution(
            ProtocolSharedRevenueDistribution({
                creatorSplit: 5000,
                protocolSplit: 2000,
                creatorClientSplit: 1500,
                executorClientSplit: 1500
            })
        );

        ProtocolSharedRevenueMinFeeMintModuleInitData memory exampleInitData;
        exampleInitData.amount = 0 ether;
        exampleInitData.collectLimit = 0;
        exampleInitData.currency = address(0);
        exampleInitData.referralFee = 0;
        exampleInitData.followerOnly = false;
        exampleInitData.endTimestamp = 0;
        exampleInitData.recipient = defaultAccount.owner;
        exampleInitData.creatorClient = creatorClient;

        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.actionModules[0] = address(collectPublicationAction);
        postParams.actionModulesInitDatas[0] = abi.encode(revenueShareModule, abi.encode(exampleInitData));

        vm.prank(defaultAccount.owner);
        defaultPubId = hub.post(postParams);

        collectActionParams = Types.PublicationActionParams({
            publicationActedProfileId: defaultAccount.profileId,
            publicationActedId: defaultPubId,
            actorProfileId: publicProfile.profileId,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            actionModuleAddress: address(collectPublicationAction),
            actionModuleData: abi.encode(
                nftRecipient,
                abi.encode(exampleInitData.currency, exampleInitData.amount, executorClient)
            )
        });

        vm.startPrank(payer);
        currency.approve(address(publicActProxy), mintFee);
        publicActProxy.publicPaidAct(collectActionParams, address(currency), mintFee, revenueShareModule);
        vm.stopPrank();

        CollectNFT collectNFT = CollectNFT(
            CollectPublicationAction(collectPublicationAction)
                .getCollectData(defaultAccount.profileId, defaultPubId)
                .collectNFT
        );

        assertTrue(collectNFT.balanceOf(nftRecipient) > 0, 'NFT recipient balance is 0');

        assertEq(currency.balanceOf(defaultAccount.owner), (mintFee * 5000) / 10000, 'Creator balance is incorrect');
        assertEq(
            currency.balanceOf(hub.getTreasury()),
            (mintFee * 2000) / 10000,
            'Protocol treasury client balance is incorrect'
        );
        assertEq(currency.balanceOf(creatorClient), (mintFee * 1500) / 10000, 'Creator client balance is incorrect');
        assertEq(currency.balanceOf(executorClient), (mintFee * 1500) / 10000, 'Executor client balance is incorrect');
    }

    function testCanPublicPaidActWithSig_SharedRevenueFreeCollect() public {
        address creatorClient = makeAddr('CREATOR_CLIENT');
        address executorClient = makeAddr('EXECUTOR_CLIENT');

        uint256 mintFee = 10 ether;

        vm.prank(deployer);
        address revenueShareModule = address(
            new ProtocolSharedRevenueMinFeeMintModule(
                address(hub),
                address(collectPublicationAction),
                address(moduleRegistry),
                address(this)
            )
        );

        collectPublicationAction.registerCollectModule(revenueShareModule);

        MockCurrency currency = new MockCurrency();
        currency.mint(payer, mintFee);

        ProtocolSharedRevenueMinFeeMintModule(revenueShareModule).setMintFeeParams(address(currency), mintFee);
        ProtocolSharedRevenueMinFeeMintModule(revenueShareModule).setProtocolSharedRevenueDistribution(
            ProtocolSharedRevenueDistribution({
                creatorSplit: 5000,
                protocolSplit: 2000,
                creatorClientSplit: 1500,
                executorClientSplit: 1500
            })
        );

        ProtocolSharedRevenueMinFeeMintModuleInitData memory exampleInitData;
        exampleInitData.amount = 0 ether;
        exampleInitData.collectLimit = 0;
        exampleInitData.currency = address(0);
        exampleInitData.referralFee = 0;
        exampleInitData.followerOnly = false;
        exampleInitData.endTimestamp = 0;
        exampleInitData.recipient = defaultAccount.owner;
        exampleInitData.creatorClient = creatorClient;

        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.actionModules[0] = address(collectPublicationAction);
        postParams.actionModulesInitDatas[0] = abi.encode(revenueShareModule, abi.encode(exampleInitData));

        vm.prank(defaultAccount.owner);
        defaultPubId = hub.post(postParams);

        collectActionParams = Types.PublicationActionParams({
            publicationActedProfileId: defaultAccount.profileId,
            publicationActedId: defaultPubId,
            actorProfileId: publicProfile.profileId,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            actionModuleAddress: address(collectPublicationAction),
            actionModuleData: abi.encode(
                nftRecipient,
                abi.encode(exampleInitData.currency, exampleInitData.amount, executorClient)
            )
        });

        vm.startPrank(payer);
        currency.approve(address(publicActProxy), mintFee);
        vm.stopPrank();

        domainSeparator = keccak256(
            abi.encode(
                Typehash.EIP712_DOMAIN,
                keccak256('PublicActProxy'),
                MetaTxLib.EIP712_DOMAIN_VERSION_HASH,
                block.chainid,
                address(publicActProxy)
            )
        );

        publicActProxy.publicPaidActWithSig({
            publicationActionParams: collectActionParams,
            currency: address(currency),
            amount: mintFee,
            approveTo: revenueShareModule,
            signature: _getSigStruct({
                pKey: payerPk,
                digest: _getPublicPaidActTypedDataHash(
                    collectActionParams,
                    address(currency),
                    mintFee,
                    revenueShareModule,
                    publicActProxy.nonces(payer),
                    type(uint256).max
                ),
                deadline: type(uint256).max
            })
        });

        CollectNFT collectNFT = CollectNFT(
            CollectPublicationAction(collectPublicationAction)
                .getCollectData(defaultAccount.profileId, defaultPubId)
                .collectNFT
        );

        assertTrue(collectNFT.balanceOf(nftRecipient) > 0, 'NFT recipient balance is 0');

        assertEq(currency.balanceOf(defaultAccount.owner), (mintFee * 5000) / 10000, 'Creator balance is incorrect');
        assertEq(
            currency.balanceOf(hub.getTreasury()),
            (mintFee * 2000) / 10000,
            'Protocol treasury client balance is incorrect'
        );
        assertEq(currency.balanceOf(creatorClient), (mintFee * 1500) / 10000, 'Creator client balance is incorrect');
        assertEq(currency.balanceOf(executorClient), (mintFee * 1500) / 10000, 'Executor client balance is incorrect');
    }
}
