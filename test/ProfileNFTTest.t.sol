// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/ERC721Test.t.sol';
import {Base64} from 'solady/utils/Base64.sol';
import {LibString} from 'solady/utils/LibString.sol';

contract ProfileNFTTest is BaseTest, ERC721Test {
    using stdJson for string;
    using Strings for uint256;

    function testProfileNFTTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function testGetTokenURI_Fuzz() public {
        for (uint256 profileId = type(uint256).max; profileId > 0; profileId >>= 2) {
            string memory profileIdAsString = vm.toString(profileId);
            console.log(profileIdAsString);
            string memory tokenURI = hub.tokenURI(profileId);
            string memory base64prefix = 'data:application/json;base64,';
            string memory decodedTokenURI = string(
                Base64.decode(LibString.slice(tokenURI, bytes(base64prefix).length))
            );
            assertEq(decodedTokenURI.readString('.name'), string.concat('Profile #', profileIdAsString));
            assertEq(
                decodedTokenURI.readString('.description'),
                string.concat('Lens Protocol - Profile #', profileIdAsString)
            );
            assertEq(decodedTokenURI.readUint('.attributes[0].value'), profileId);
            assertEq(decodedTokenURI.readString('.attributes[1].value'), profileId.toHexString());
            assertEq(decodedTokenURI.readUint('.attributes[2].value'), bytes(profileIdAsString).length);
        }
    }

    function testGetTokenURI() public {
        uint256 profileId = hub.createProfile(_getDefaultCreateProfileParams());

        string memory profileIdAsString = vm.toString(profileId);

        string memory tokenURI = hub.tokenURI(profileId);

        string memory base64prefix = 'data:application/json;base64,';

        string memory decodedTokenURI = string(Base64.decode(LibString.slice(tokenURI, bytes(base64prefix).length)));

        assertEq(decodedTokenURI.readString('.name'), string.concat('Profile #', profileIdAsString));
        assertEq(
            decodedTokenURI.readString('.description'),
            string.concat('Lens Protocol - Profile #', profileIdAsString)
        );
        assertEq(decodedTokenURI.readUint('.attributes[0].value'), profileId, "Profile ID doesn't match");
        assertEq(
            decodedTokenURI.readString('.attributes[1].value'),
            profileId.toHexString(),
            "Profile HEX ID doesn't match"
        );
        assertEq(
            decodedTokenURI.readUint('.attributes[2].value'),
            bytes(profileIdAsString).length,
            "Profile Digits doesn't match"
        );
        assertEq(
            decodedTokenURI.readUint('.attributes[3].value'),
            hub.tokenDataOf(profileId).mintTimestamp,
            "Profile Minted At doesn't match"
        );
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
            vm.assume(salePrice == 0 || salePriceTimesRoyalties / salePrice == royaltiesInBasisPoints);
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
