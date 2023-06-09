// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/ERC721Test.t.sol';
import {LegacyCollectNFT} from 'contracts/misc/LegacyCollectNFT.sol';
import {MockDeprecatedCollectModule} from 'test/mocks/MockDeprecatedCollectModule.sol';

contract LegacyCollectNFTTest is BaseTest, ERC721Test {
    using stdJson for string;

    function testLegacyCollectNFTTest() public {
        // Prevents being counted in Foundry Coverage
    }

    Types.CollectParams defaultCollectParams;
    address mockDeprecatedCollectModule;
    LegacyCollectNFT collectNFT;
    address collectNFTImpl;

    function setUp() public override {
        super.setUp();

        mockDeprecatedCollectModule = address(new MockDeprecatedCollectModule());

        // Create a V1 pub
        vm.prank(defaultAccount.owner);
        uint256 pubId = hub.post(_getDefaultPostParams());

        _toLegacyV1Pub(defaultAccount.profileId, pubId, address(0), mockDeprecatedCollectModule);

        defaultCollectParams = Types.CollectParams({
            publicationCollectedProfileId: defaultAccount.profileId,
            publicationCollectedId: pubId,
            collectorProfileId: defaultAccount.profileId,
            referrerProfileId: 0,
            referrerPubId: 0,
            collectModuleData: abi.encode(true)
        });

        vm.prank(defaultAccount.owner);
        hub.collect(defaultCollectParams);

        collectNFT = LegacyCollectNFT(hub.getPublication(defaultAccount.profileId, pubId).__DEPRECATED__collectNFT);
    }

    function _mintERC721(address to) internal virtual override returns (uint256) {
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
