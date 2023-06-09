// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/ERC721Test.t.sol';
import {CollectPublicationAction} from 'contracts/modules/act/collect/CollectPublicationAction.sol';
import {CollectNFT} from 'contracts/CollectNFT.sol';
import {MockCollectModule} from 'test/mocks/MockCollectModule.sol';

contract CollectNFTTest is BaseTest, ERC721Test {
    using stdJson for string;

    function testCollectNFTTest() public {
        // Prevents being counted in Foundry Coverage
    }

    CollectPublicationAction collectPublicationAction;
    address mockCollectModule;
    CollectNFT collectNFT;
    address collectNFTImpl;

    Types.PublicationActionParams collectActionParams;

    // Deploy CollectPublicationAction
    constructor() TestSetup() {
        if (fork && keyExists(string(abi.encodePacked('.', forkEnv, '.CollectNFTImpl')))) {
            collectNFTImpl = json.readAddress(string(abi.encodePacked('.', forkEnv, '.CollectNFTImpl')));
            console.log('Found CollectNFTImpl deployed at:', address(collectNFTImpl));
        }

        if (fork && keyExists(string(abi.encodePacked('.', forkEnv, '.CollectPublicationAction')))) {
            collectPublicationAction = CollectPublicationAction(
                json.readAddress(string(abi.encodePacked('.', forkEnv, '.CollectPublicationAction')))
            );
            console.log('Found collectPublicationAction deployed at:', address(collectPublicationAction));
        }

        // Both deployed - need to verify if they are linked
        if (collectNFTImpl != address(0) && address(collectPublicationAction) != address(0)) {
            if (CollectNFT(collectNFTImpl).ACTION_MODULE() == address(collectPublicationAction)) {
                console.log('CollectNFTImpl and CollectPublicationAction already deployed and linked');
                return;
            }
        }

        uint256 deployerNonce = vm.getNonce(deployer);

        address predictedCollectPublicationAction = computeCreateAddress(deployer, deployerNonce);
        address predictedCollectNFTImpl = computeCreateAddress(deployer, deployerNonce + 1);

        vm.startPrank(deployer);
        collectPublicationAction = new CollectPublicationAction(
            address(hub),
            predictedCollectNFTImpl,
            address(moduleGlobals)
        );
        collectNFTImpl = address(new CollectNFT(address(hub), address(collectPublicationAction)));
        vm.stopPrank();

        vm.prank(governance);
        hub.whitelistActionModule(address(collectPublicationAction), true);

        assertEq(
            address(collectPublicationAction),
            predictedCollectPublicationAction,
            'CollectPublicationAction deployed address mismatch'
        );
        assertEq(collectNFTImpl, predictedCollectNFTImpl, 'CollectNFTImpl deployed address mismatch');

        vm.label(address(collectPublicationAction), 'CollectPublicationAction');
        vm.label(collectNFTImpl, 'CollectNFTImpl');
    }

    function setUp() public override {
        super.setUp();

        // Deploy & Whitelist MockCollectModule
        mockCollectModule = address(new MockCollectModule());
        vm.prank(moduleGlobals.getGovernance());
        collectPublicationAction.whitelistCollectModule(mockCollectModule, true);

        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.actionModules[0] = address(collectPublicationAction);
        postParams.actionModulesInitDatas[0] = abi.encode(mockCollectModule, abi.encode(true));

        vm.prank(defaultAccount.owner);
        uint256 pubId = hub.post(postParams);

        collectActionParams = Types.PublicationActionParams({
            publicationActedProfileId: defaultAccount.profileId,
            publicationActedId: pubId,
            actorProfileId: defaultAccount.profileId,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            actionModuleAddress: address(collectPublicationAction),
            actionModuleData: abi.encode(true)
        });

        vm.prank(defaultAccount.owner);
        hub.act(collectActionParams);

        collectNFT = CollectNFT(collectPublicationAction.getCollectData(defaultAccount.profileId, pubId).collectNFT);
    }

    function _mintERC721(address to) internal virtual override returns (uint256) {
        collectActionParams.actorProfileId = _createProfile(to);
        vm.prank(to);
        bytes memory actResult = hub.act(collectActionParams);
        (uint256 tokenId, ) = abi.decode(actResult, (uint256, bytes));
        return tokenId;
    }

    function _burnERC721(uint256 tokenId) internal virtual override {
        collectNFT.burn(tokenId);
    }

    function _getERC721TokenAddress() internal view virtual override returns (address) {
        return address(collectNFT);
    }

    //////////////////////////////////////////////////////////
    // ERC-2981 Royalties - Scenarios
    //////////////////////////////////////////////////////////

    function testSupportsErc2981Interface() public {
        assertTrue(collectNFT.supportsInterface(bytes4(keccak256('royaltyInfo(uint256,uint256)'))));
    }

    function testDefaultRoyaltiesAreSetTo10Percent(uint256 tokenId) public {
        uint256 salePrice = 100;
        uint256 expectedRoyalties = 10;

        (address receiver, uint256 royalties) = collectNFT.royaltyInfo(tokenId, salePrice);

        assertEq(receiver, defaultAccount.owner);
        assertEq(royalties, expectedRoyalties);
    }

    function testSetRoyalties(uint256 royaltiesInBasisPoints, uint256 tokenId, uint256 salePrice) public {
        uint256 basisPoints = 10000;
        royaltiesInBasisPoints = bound(royaltiesInBasisPoints, 0, basisPoints);
        uint256 salePriceTimesRoyalties;
        unchecked {
            salePriceTimesRoyalties = salePrice * royaltiesInBasisPoints;
            // Fuzz prices that does not generate overflow, otherwise royaltyInfo will revert
            vm.assume(salePrice == 0 || salePriceTimesRoyalties / salePrice == basisPoints);
        }

        vm.prank(defaultAccount.owner);
        collectNFT.setRoyalty(royaltiesInBasisPoints);

        (address receiver, uint256 royalties) = collectNFT.royaltyInfo(tokenId, salePrice);

        assertEq(receiver, defaultAccount.owner);
        assertEq(royalties, salePriceTimesRoyalties / basisPoints);
    }

    //////////////////////////////////////////////////////////
    // ERC-2981 Royalties - Negatives
    //////////////////////////////////////////////////////////

    function testCannotSetRoyaltiesIf_NotOwnerOfProfileAuthoringCollectedPublication(
        address nonCollectionOwner,
        uint256 royaltiesInBasisPoints
    ) public {
        uint256 basisPoints = 10000;
        royaltiesInBasisPoints = bound(royaltiesInBasisPoints, 0, basisPoints);
        vm.assume(nonCollectionOwner != defaultAccount.owner);

        vm.prank(nonCollectionOwner);
        vm.expectRevert(Errors.NotProfileOwner.selector);
        collectNFT.setRoyalty(royaltiesInBasisPoints);
    }

    function testCannotSetRoyaltiesIf_ExceedsBasisPoints(uint256 royaltiesInBasisPoints) public {
        uint256 basisPoints = 10000;
        vm.assume(royaltiesInBasisPoints > basisPoints);

        vm.prank(defaultAccount.owner);
        vm.expectRevert(Errors.InvalidParameter.selector);
        collectNFT.setRoyalty(royaltiesInBasisPoints);
    }
}
