// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import 'test/LensBaseERC721Test.t.sol';
import {Base64} from 'solady/utils/Base64.sol';
import {LibString} from 'solady/utils/LibString.sol';
import {ProfileTokenURI} from 'contracts/misc/token-uris/ProfileTokenURI.sol';
import {IProfileTokenURI} from 'contracts/interfaces/IProfileTokenURI.sol';
import {TokenGuardianTest_Default_On, IGuardedToken} from 'test/TokenGuardian.t.sol';

contract ProfileNFTTest is LensBaseERC721Test, TokenGuardianTest_Default_On {
    using stdJson for string;
    using Strings for uint256;

    function _TOKEN_GUARDIAN_COOLDOWN() internal view override returns (uint256) {
        return fork ? hub.TOKEN_GUARDIAN_COOLDOWN() : PROFILE_GUARDIAN_COOLDOWN;
    }

    function setUp() public override(BaseTest, TokenGuardianTest_Default_On) {
        BaseTest.setUp();
        TokenGuardianTest_Default_On.setUp();
    }

    function _disableGuardian(address wallet) internal override {
        _effectivelyDisableProfileGuardian(wallet);
    }

    function testProfileNFTTest() public {
        // Prevents being counted in Foundry Coverage
    }

    function testGetTokenURI_Fuzz() public {
        IProfileTokenURI profileTokenURIContract = new ProfileTokenURI();

        for (uint256 profileId = type(uint256).max; profileId > 0; profileId >>= 2) {
            string memory profileIdAsString = vm.toString(profileId);
            console.log(profileIdAsString);
            uint256 randomTimestamp = uint256(keccak256(abi.encode(profileId))) % 2000000000;
            string memory tokenURI = profileTokenURIContract.getTokenURI(profileId, randomTimestamp);
            string memory base64prefix = 'data:application/json;base64,';
            string memory decodedTokenURI = string(
                Base64.decode(LibString.slice(tokenURI, bytes(base64prefix).length))
            );
            assertEq(decodedTokenURI.readString('.name'), string.concat('Profile #', profileIdAsString));
            assertEq(
                decodedTokenURI.readString('.description'),
                string.concat('Lens Protocol - Profile #', profileIdAsString)
            );
            assertEq(decodedTokenURI.readUint('.attributes[0].value'), profileId, "Profile ID doesn't match");
            assertEq(
                decodedTokenURI.readString('.attributes[0].display_type'),
                'number',
                "Profile ID display type doesn't match"
            );
            assertEq(
                decodedTokenURI.readString('.attributes[0].trait_type'),
                'ID',
                "Profile ID trait type doesn't match"
            );
            assertEq(
                decodedTokenURI.readString('.attributes[1].value'),
                profileId.toHexString(),
                "Profile HEX ID doesn't match"
            );
            assertEq(
                decodedTokenURI.readString('.attributes[1].trait_type'),
                'HEX ID',
                "Profile HEX ID trait type doesn't match"
            );
            assertEq(
                decodedTokenURI.readUint('.attributes[2].value'),
                bytes(profileIdAsString).length,
                "Profile DIGITS doesn't match"
            );
            assertEq(
                decodedTokenURI.readString('.attributes[2].trait_type'),
                'DIGITS',
                "Profile DIGITS trait type doesn't match"
            );
            assertEq(
                decodedTokenURI.readUint('.attributes[3].value'),
                randomTimestamp,
                "Profile Minted At doesn't match"
            );
            assertEq(
                decodedTokenURI.readString('.attributes[3].display_type'),
                'date',
                "Profile MINTED AT display type doesn't match"
            );
            assertEq(
                decodedTokenURI.readString('.attributes[3].trait_type'),
                'MINTED AT',
                "Profile MINTED AT doesn't match"
            );
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

    function testCannot_GetTokenURI_IfDoesNotExist(uint256 tokenId) public {
        vm.assume(!hub.exists(tokenId));

        vm.expectRevert(Errors.TokenDoesNotExist.selector);
        hub.tokenURI(tokenId);
    }

    function _mintERC721(address to) internal virtual override returns (uint256) {
        vm.assume(!_isLensHubProxyAdmin(to));
        return _createProfile(to);
    }

    function _burnERC721(uint256 tokenId) internal virtual override {
        return hub.burn(tokenId);
    }

    function _getERC721TokenAddress() internal view virtual override returns (address) {
        return address(hub);
    }

    function _getNotOwnerError() internal virtual override returns (bytes4) {
        return Errors.NotProfileOwner.selector;
    }

    function _assumeNotProxyAdmin(address account) internal view virtual override {
        vm.assume(!_isLensHubProxyAdmin(account));
    }

    function testDoesNotSupportOtherThanTheExpectedInterfaces(uint32 interfaceId) public override {
        vm.assume(bytes4(interfaceId) != bytes4(keccak256('royaltyInfo(uint256,uint256)')));
        super.testDoesNotSupportOtherThanTheExpectedInterfaces(interfaceId);
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
