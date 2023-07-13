// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/LensBaseERC721Test.t.sol';
import {LegacyCollectNFT} from 'contracts/misc/LegacyCollectNFT.sol';
import {MockDeprecatedCollectModule} from 'test/mocks/MockDeprecatedCollectModule.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';

contract LegacyCollectNFTTest is BaseTest, LensBaseERC721Test {
    using stdJson for string;

    function testLegacyCollectNFTTest() public {
        // Prevents being counted in Foundry Coverage
    }

    Types.CollectParams defaultCollectParams;
    address mockDeprecatedCollectModule;
    LegacyCollectNFT collectNFT;
    address collectNFTImpl;
    uint256 defaultPubId;
    uint256 firstCollectTokenId;

    function setUp() public override {
        super.setUp();

        mockDeprecatedCollectModule = address(new MockDeprecatedCollectModule());

        // Create a V1 pub
        vm.prank(defaultAccount.owner);
        defaultPubId = hub.post(_getDefaultPostParams());

        _toLegacyV1Pub(defaultAccount.profileId, defaultPubId, address(0), mockDeprecatedCollectModule);

        defaultCollectParams = Types.CollectParams({
            publicationCollectedProfileId: defaultAccount.profileId,
            publicationCollectedId: defaultPubId,
            collectorProfileId: defaultAccount.profileId,
            referrerProfileId: 0,
            referrerPubId: 0,
            collectModuleData: abi.encode(true)
        });

        vm.prank(defaultAccount.owner);
        firstCollectTokenId = hub.collect(defaultCollectParams);

        collectNFT = LegacyCollectNFT(
            hub.getPublication(defaultAccount.profileId, defaultPubId).__DEPRECATED__collectNFT
        );
    }

    function _mintERC721(address to) internal virtual override returns (uint256) {
        vm.assume(!_isLensHubProxyAdmin(to));
        defaultCollectParams.collectorProfileId = _createProfile(to);
        vm.prank(to);
        uint256 tokenId = hub.collect(defaultCollectParams);
        return tokenId;
    }

    function _burnERC721(uint256 tokenId) internal virtual override {
        collectNFT.burn(tokenId);
    }

    function _getERC721TokenAddress() internal view virtual override returns (address) {
        return address(collectNFT);
    }

    function testDoesNotSupportOtherThanTheExpectedInterfaces(uint32 interfaceId) public override {
        vm.assume(bytes4(interfaceId) != bytes4(keccak256('royaltyInfo(uint256,uint256)')));
        super.testDoesNotSupportOtherThanTheExpectedInterfaces(interfaceId);
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
            vm.assume(salePrice == 0 || salePriceTimesRoyalties / salePrice == royaltiesInBasisPoints);
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

    //

    function testCannotInitializeTwoTimes(uint256 profileId, uint256 pubId) public {
        vm.expectRevert(Errors.Initialized.selector);
        collectNFT.initialize(profileId, pubId);
    }

    function testTokenURI() public {
        vm.expectCall(address(hub), abi.encodeCall(hub.getContentURI, (defaultAccount.profileId, defaultPubId)), 1);
        collectNFT.tokenURI(firstCollectTokenId);
    }

    function testCannot_GetTokenURIIfTokenDoesNotExist(uint256 nonexistentToken) public {
        vm.assume(collectNFT.exists(nonexistentToken) == false);
        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        collectNFT.tokenURI(nonexistentToken);
    }

    function testCannot_MintNotFromHub(address notHub, address to) public {
        vm.assume(notHub != address(hub));
        vm.assume(notHub != address(0));
        vm.expectRevert(Errors.NotHub.selector);
        collectNFT.mint(to);
    }

    function testGetSourcePublicationPointer(address hub, uint256 profileId, uint256 pubId) public {
        vm.assume(hub != address(0));
        vm.assume(profileId != 0);
        vm.assume(pubId != 0);

        // Deploys Collect NFT implementation
        collectNFTImpl = address(new LegacyCollectNFT(hub));

        // Clones
        collectNFT = LegacyCollectNFT(Clones.clone(collectNFTImpl));

        // Initializes the clone
        collectNFT.initialize(profileId, pubId);

        (uint256 sourceProfileId, uint256 sourcePubId) = collectNFT.getSourcePublicationPointer();

        assertEq(sourceProfileId, profileId);
        assertEq(sourcePubId, pubId);
    }
}
