// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {LibString} from 'solady/utils/LibString.sol';
import {Base64} from 'solady/utils/Base64.sol';
import {HandlesErrors} from 'contracts/namespaces/constants/Errors.sol';
import {HandlesEvents} from 'contracts/namespaces/constants/Events.sol';

contract LensHandlesTest is BaseTest {
    using stdJson for string;

    uint256 constant MAX_HANDLE_LENGTH = 26;

    function setUp() public override {
        super.setUp();
    }

    // NEGATIVES

    function testCannot_GetTokenURI_IfNotMinted(uint256 tokenId) public {
        vm.assume(!lensHandles.exists(tokenId));

        vm.expectRevert('ERC721: invalid token ID');
        lensHandles.tokenURI(tokenId);
    }

    function testCannot_Burn_IfNotOwnerOf(address owner, address otherAddress) public {
        vm.assume(owner != otherAddress);
        vm.assume(owner != address(0));
        vm.assume(otherAddress != address(0));
        vm.assume(!_isLensHubProxyAdmin(otherAddress));

        string memory handle = 'handle';

        vm.prank(address(hub));
        uint256 handleId = lensHandles.mintHandle(owner, handle);

        assertTrue(lensHandles.exists(handleId));
        assertEq(lensHandles.ownerOf(handleId), owner);

        vm.expectRevert(HandlesErrors.NotOwner.selector);

        vm.prank(otherAddress);
        lensHandles.burn(handleId);
    }

    function testCannot_MintHandle_IfNotOwnerOrHubOrWhitelistedProfileCreator(address otherAddress) public {
        vm.assume(otherAddress != address(0));
        vm.assume(otherAddress != address(hub));
        vm.assume(otherAddress != lensHandles.OWNER());
        vm.assume(!hub.isProfileCreatorWhitelisted(otherAddress));
        vm.assume(!_isLensHubProxyAdmin(otherAddress));

        string memory handle = 'handle';

        vm.expectRevert(HandlesErrors.NotOwnerNorWhitelisted.selector);

        vm.prank(otherAddress);
        lensHandles.mintHandle(otherAddress, handle);
    }

    function testCannot_MintHandle_WithZeroLength() public {
        vm.expectRevert(HandlesErrors.HandleLengthInvalid.selector);

        vm.prank(address(hub));
        lensHandles.mintHandle(address(this), '');
    }

    function testCannot_MintHandle_WithNonUniqueLocalName() public {
        vm.prank(address(hub));
        lensHandles.mintHandle(address(this), 'handle');

        vm.expectRevert('ERC721: token already minted');

        vm.prank(address(hub));
        lensHandles.mintHandle(makeAddr('ANOTHER_ADDRESS'), 'handle');
    }

    function testCannot_MintHandle_WithLengthMoreThanMax(uint256 randomFuzz) public {
        string memory randomHandle = _randomAlphanumericString(MAX_HANDLE_LENGTH + 1, randomFuzz);

        vm.expectRevert(HandlesErrors.HandleLengthInvalid.selector);

        vm.prank(address(hub));
        lensHandles.mintHandle(address(this), randomHandle);
    }

    function testCannot_MintHandle_WithInvalidFirstChar(uint256 length, uint256 randomFuzz) public {
        length = bound(length, 0, MAX_HANDLE_LENGTH - 1); // we will add 1 char at the start, so length is shorter by 1

        string memory randomHandle = _randomAlphanumericString(length, randomFuzz);

        string memory invalidUnderscoreHandle = string.concat('_', randomHandle);

        vm.expectRevert(HandlesErrors.HandleFirstCharInvalid.selector);

        vm.prank(address(hub));
        lensHandles.mintHandle(address(this), invalidUnderscoreHandle);

        string memory invalidDashHandle = string.concat('-', randomHandle);

        vm.expectRevert(HandlesErrors.HandleFirstCharInvalid.selector);

        vm.prank(address(hub));
        lensHandles.mintHandle(address(this), invalidDashHandle);
    }

    function testCannot_MintHandle_WithInvalidChar(
        uint256 length,
        uint256 insertionPosition,
        uint256 randomFuzz,
        uint256 invalidCharCode
    ) public {
        length = bound(length, 1, MAX_HANDLE_LENGTH);
        insertionPosition = bound(insertionPosition, 0, length - 1);
        invalidCharCode = bound(invalidCharCode, 0x00, 0xFF);
        vm.assume(
            (invalidCharCode < 48 || // '0'
                invalidCharCode > 122 || // 'z'
                (invalidCharCode > 57 && invalidCharCode < 97)) && // '9' and 'a'
                invalidCharCode != 45 && // '-'
                invalidCharCode != 95 // '_'
        );

        string memory randomHandle = _randomAlphanumericString(length, randomFuzz);

        console.log('randomHandle:', randomHandle);
        console.log('insert position:', insertionPosition);
        console.log('invalid char code:', invalidCharCode);

        bytes memory randomHandleBytes = bytes(randomHandle);
        randomHandleBytes[insertionPosition] = bytes1(uint8(invalidCharCode));

        string memory invalidHandle = string(randomHandleBytes);

        console.log('invalidHandle', invalidHandle);

        vm.expectRevert(HandlesErrors.HandleContainsInvalidCharacters.selector);
        vm.prank(address(hub));
        lensHandles.mintHandle(address(this), invalidHandle);
    }

    // SCENARIOS

    function testName() public {
        string memory name = lensHandles.name();
        assertEq(name, '.lens Handles');
    }

    function testSymbol() public {
        string memory symbol = lensHandles.symbol();
        assertEq(symbol, '.lens');
    }

    function testExists(uint256 number) public {
        number = bound(number, 1, 10 ** (MAX_HANDLE_LENGTH) - 1);
        string memory numbersHandle = vm.toString(number);
        uint256 expectedTokenId = lensHandles.getTokenId(numbersHandle);
        vm.assume(!lensHandles.exists(expectedTokenId));

        vm.prank(address(hub));
        uint256 handleId = lensHandles.mintHandle(address(this), numbersHandle);

        assertEq(handleId, expectedTokenId);
        assertTrue(lensHandles.exists(handleId));

        lensHandles.burn(handleId);
        assertFalse(lensHandles.exists(handleId));
    }

    function testGetNamespace() public {
        string memory namespace = lensHandles.getNamespace();
        assertEq(namespace, 'lens');
    }

    function testGetNamespaceHash() public {
        string memory namespace = lensHandles.getNamespace();
        bytes32 namespaceHash = lensHandles.getNamespaceHash();
        assertEq(namespaceHash, keccak256(bytes(namespace)));
    }

    function testConstructionImmutables(address owner, address hub) public {
        LensHandles newLensHandles = new LensHandles(owner, hub);
        assertEq(newLensHandles.OWNER(), owner);
        assertEq(newLensHandles.LENS_HUB(), hub);
    }

    // TODO: Should we revert if it doesn't exist?
    function testGetLocalName(uint256 number) public {
        number = bound(number, 1, 10 ** (MAX_HANDLE_LENGTH) - 1);
        string memory numbersHandle = vm.toString(number);
        uint256 expectedTokenId = lensHandles.getTokenId(numbersHandle);
        vm.assume(!lensHandles.exists(expectedTokenId));

        vm.expectRevert(HandlesErrors.DoesNotExist.selector);
        lensHandles.getLocalName(expectedTokenId);

        vm.prank(address(hub));
        uint256 handleId = lensHandles.mintHandle(address(this), numbersHandle);

        assertEq(handleId, expectedTokenId);

        string memory localName = lensHandles.getLocalName(handleId);
        assertEq(localName, numbersHandle);

        lensHandles.burn(handleId);

        vm.expectRevert(HandlesErrors.DoesNotExist.selector);
        lensHandles.getLocalName(expectedTokenId);
    }

    // TODO: Should we revert if it doesn't exist?
    function testGetHandle(uint256 number) public {
        number = bound(number, 1, 10 ** (MAX_HANDLE_LENGTH) - 1);
        string memory numbersHandle = vm.toString(number);
        uint256 expectedTokenId = lensHandles.getTokenId(numbersHandle);
        vm.assume(!lensHandles.exists(expectedTokenId));

        vm.expectRevert(HandlesErrors.DoesNotExist.selector);
        lensHandles.getHandle(expectedTokenId);

        vm.prank(address(hub));
        uint256 handleId = lensHandles.mintHandle(address(this), numbersHandle);

        assertEq(handleId, expectedTokenId);

        string memory namespaceSuffix = string.concat('.', lensHandles.getNamespace());
        string memory handle = lensHandles.getHandle(handleId);
        assertEq(handle, string.concat(numbersHandle, namespaceSuffix));

        lensHandles.burn(handleId);

        vm.expectRevert(HandlesErrors.DoesNotExist.selector);
        lensHandles.getHandle(expectedTokenId);
    }

    function testGetTokenId(uint256 number) public {
        number = bound(number, 1, 10 ** (MAX_HANDLE_LENGTH) - 1);
        string memory numbersHandle = vm.toString(number);

        uint256 expectedTokenId = uint256(keccak256(bytes(numbersHandle)));
        assertEq(lensHandles.getTokenId(numbersHandle), expectedTokenId);
    }

    function testTokenURI() public {
        string memory handle = 'handle';

        vm.prank(address(hub));
        uint256 handleId = lensHandles.mintHandle(address(this), handle);

        string memory tokenURI = lensHandles.tokenURI(handleId);

        string memory base64prefix = 'data:application/json;base64,';

        string memory decodedTokenURI = string(Base64.decode(LibString.slice(tokenURI, bytes(base64prefix).length)));

        assertEq(decodedTokenURI.readString('.name'), string.concat('@', handle));
        assertEq(decodedTokenURI.readString('.description'), string.concat('Lens Protocol - @', handle));
        assertEq(decodedTokenURI.readUint('.attributes[0].value'), handleId);
        assertEq(decodedTokenURI.readString('.attributes[1].value'), lensHandles.symbol());
        assertEq(decodedTokenURI.readUint('.attributes[2].value'), bytes(handle).length);
    }

    function testBurn(address owner) public {
        vm.assume(owner != address(0));
        vm.assume(!_isLensHubProxyAdmin(owner));

        string memory handle = 'handle';

        vm.prank(address(hub));
        uint256 handleId = lensHandles.mintHandle(owner, handle);

        assertTrue(lensHandles.exists(handleId));
        assertEq(lensHandles.ownerOf(handleId), owner);

        vm.prank(owner);
        lensHandles.burn(handleId);

        assertFalse(lensHandles.exists(handleId));

        vm.expectRevert(HandlesErrors.DoesNotExist.selector);
        lensHandles.getLocalName(handleId);
    }

    function testMintHandle_IfOwner(address to, uint256 length, uint256 randomFuzz) public {
        _mintHandle(lensHandles.OWNER(), to, length, randomFuzz);
    }

    function testMintHandle_ifHub(address to, uint256 length, uint256 randomFuzz) public {
        _mintHandle(address(hub), to, length, randomFuzz);
    }

    function testMintHandle_ifWhitelistedProfileCreator(
        address whitelistedProfileCreator,
        address to,
        uint256 length,
        uint256 randomFuzz
    ) public {
        vm.assume(whitelistedProfileCreator != address(0));
        vm.assume(whitelistedProfileCreator != address(hub));
        vm.assume(whitelistedProfileCreator != lensHandles.OWNER());
        vm.assume(!_isLensHubProxyAdmin(whitelistedProfileCreator));

        vm.prank(governance);
        hub.whitelistProfileCreator(whitelistedProfileCreator, true);
        _mintHandle(whitelistedProfileCreator, to, length, randomFuzz);
    }

    function _mintHandle(address minter, address to, uint256 length, uint256 randomFuzz) internal {
        vm.assume(to != address(0));
        length = bound(length, 1, MAX_HANDLE_LENGTH);

        string memory randomHandle = _randomAlphanumericString(length, randomFuzz);
        uint256 expectedHandleId = lensHandles.getTokenId(randomHandle);

        vm.expectEmit(true, true, true, true, address(lensHandles));
        emit HandlesEvents.HandleMinted(
            randomHandle,
            lensHandles.getNamespace(),
            expectedHandleId,
            to,
            block.timestamp
        );

        vm.prank(minter);
        uint256 handleId = lensHandles.mintHandle(to, randomHandle);
        assertEq(handleId, expectedHandleId);
        assertEq(lensHandles.ownerOf(handleId), to);

        string memory localName = lensHandles.getLocalName(handleId);
        assertEq(localName, randomHandle);
    }

    function _randomAlphanumericString(uint256 length, uint256 randomFuzz) internal view returns (string memory) {
        bytes memory allowedChars = '0123456789abcdefghijklmnopqrstuvwxyz_-';

        string memory str = '';
        for (uint256 i = 0; i < length; i++) {
            uint8 charCode = uint8((randomFuzz >> (i * 8)) & 0xff);
            charCode = uint8(bound(charCode, 0, allowedChars.length - 1));
            if (i == 0 && (allowedChars[charCode] == '_' || allowedChars[charCode] == '-')) {
                charCode /= 2;
            }
            string memory char = string(abi.encodePacked(allowedChars[charCode]));
            str = string.concat(str, char);
        }
        return str;
    }
}
