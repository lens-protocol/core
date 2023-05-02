// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/MetaTxNegatives.t.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';

contract ActTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    // Negatives
    function testCannotAct_ifNonExistingPublication(uint256 nonexistentPubId) public {
        vm.assume(nonexistentPubId != defaultPub.pubId);
        Types.PublicationActionParams memory publicationActionParams = _getDefaultPublicationActionParams();
        publicationActionParams.publicationActedId = nonexistentPubId;

        vm.expectRevert(Errors.ActionNotAllowed.selector);

        _act(defaultAccount.ownerPk, publicationActionParams);
    }

    function testCannotAct_ifActionModuleNotEnabledForPublication(address notEnabledActionModule) public {
        vm.assume(notEnabledActionModule != address(mockActionModule));

        Types.PublicationActionParams memory publicationActionParams = _getDefaultPublicationActionParams();
        publicationActionParams.actionModuleAddress = notEnabledActionModule;

        vm.expectRevert(Errors.ActionNotAllowed.selector);

        _act(defaultAccount.ownerPk, publicationActionParams);
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

        _act(defaultAccount.ownerPk, publicationActionParams);
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

        _act(defaultAccount.ownerPk, publicationActionParams);
    }

    function _act(
        uint256 pk,
        Types.PublicationActionParams memory publicationActionParams
    ) internal virtual returns (bytes memory) {
        vm.prank(vm.addr(pk));
        return hub.act(publicationActionParams);
    }

    function _refreshCachedNonces() internal virtual {
        // Nothing to do there.
    }

    // TODO: Any ideas for more tests?
    // - Cannot act when protocol state is Paused or PublishingPaused
    // - Test this on all types of publications (comment, quote, mirror)
    // - Can't act on mirrors
    // - Create an ACTOR TestAccount
    // -
}

contract ActMetaTxTest is ActTest, MetaTxNegatives {
    mapping(address => uint256) cachedNonceByAddress;

    function testActionMetaTxTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function setUp() public override(ActTest, MetaTxNegatives) {
        ActTest.setUp();
        MetaTxNegatives.setUp();

        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
    }

    function _act(
        uint256 pk,
        Types.PublicationActionParams memory publicationActionParams
    ) internal override returns (bytes memory) {
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

    function _executeMetaTx(uint256 signerPk, uint256 nonce, uint256 deadline) internal virtual override {
        hub.actWithSig({
            publicationActionParams: _getDefaultPublicationActionParams(),
            signature: _getSigStruct({
                signer: vm.addr(_getDefaultMetaTxSignerPk()),
                pKey: signerPk,
                digest: _calculateActWithSigDigest(_getDefaultPublicationActionParams(), nonce, deadline),
                deadline: deadline
            })
        });
    }

    function _getDefaultMetaTxSignerPk() internal virtual override returns (uint256) {
        return defaultAccount.ownerPk;
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
        cachedNonceByAddress[defaultAccount.owner] = hub.nonces(defaultAccount.owner);
    }
}
