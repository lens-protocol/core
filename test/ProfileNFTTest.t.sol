// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/ERC721Test.t.sol';

contract ProfileNFTTest is BaseTest, ERC721Test {
    function testProfileNFTTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function _mintERC721(address to) internal virtual override returns (uint256) {
        return _createProfile(to);
    }

    function _burnERC721(uint256 tokenId) internal virtual override {
        return hub.burn(tokenId);
    }

    function _getERC721TokenAddress() internal view virtual override returns (address) {
        return address(hub);
    }

    //////////////////////////////////////////////////////////
    // ERC-2981 Royalties - Scenarios
    //////////////////////////////////////////////////////////

    function testSupportsErc2981Interface() public {
        assertTrue(hub.supportsInterface(bytes4(keccak256('royaltyInfo(uint256,uint256)'))));
    }

    function testDefaultRoyaltiesAreSetToZero(uint256 tokenId, uint256 salePrice) public {
        (address receiver, uint256 royalties) = hub.royaltyInfo(tokenId, salePrice);

        assertEq(receiver, treasury);
        assertEq(royalties, 0);
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

        vm.prank(governance);
        hub.setRoyalty(royaltiesInBasisPoints);

        (address receiver, uint256 royalties) = hub.royaltyInfo(tokenId, salePrice);

        assertEq(receiver, treasury);
        assertEq(royalties, salePriceTimesRoyalties / basisPoints);
    }

    //////////////////////////////////////////////////////////
    // ERC-2981 Royalties - Negatives
    //////////////////////////////////////////////////////////

    function testCannotSetRoyaltiesIf_NotGovernance(
        address nonGovernanceAddress,
        uint256 royaltiesInBasisPoints
    ) public {
        uint256 basisPoints = 10000;
        royaltiesInBasisPoints = bound(royaltiesInBasisPoints, 0, basisPoints);
        vm.assume(nonGovernanceAddress != governance);
        vm.assume(!_isLensHubProxyAdmin(nonGovernanceAddress));

        vm.prank(nonGovernanceAddress);
        vm.expectRevert(Errors.NotGovernance.selector);
        hub.setRoyalty(royaltiesInBasisPoints);
    }

    function testCannotSetRoyaltiesIf_ExceedsBasisPoints(uint256 royaltiesInBasisPoints) public {
        uint256 basisPoints = 10000;
        vm.assume(royaltiesInBasisPoints > basisPoints);

        vm.prank(governance);
        vm.expectRevert(Errors.InvalidParameter.selector);
        hub.setRoyalty(royaltiesInBasisPoints);
    }
}
