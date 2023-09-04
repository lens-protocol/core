// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {RegistryErrors} from 'contracts/namespaces/constants/Errors.sol';
import {RegistryEvents} from 'contracts/namespaces/constants/Events.sol';
import {RegistryTypes} from 'contracts/namespaces/constants/Types.sol';

contract TokenHandleRegistryTest is BaseTest {
    uint256 profileId;
    uint256 handleId;

    address initialProfileHolder = makeAddr('INITIAL_PROFILE_HOLDER');
    address initialHandleHolder = makeAddr('INITIAL_HANDLE_HOLDER');

    function setUp() public override {
        super.setUp();

        profileId = _createProfile(initialProfileHolder);

        vm.prank(governance);
        handleId = lensHandles.mintHandle(initialHandleHolder, 'handle');
    }

    function testCannot_MigrationLink_IfNotHub(address otherAddress) public {
        vm.assume(otherAddress != address(hub));
        vm.assume(otherAddress != address(0));
        vm.assume(!_isLensHubProxyAdmin(otherAddress));

        vm.expectRevert(RegistryErrors.OnlyLensHub.selector);

        vm.prank(otherAddress);
        tokenHandleRegistry.migrationLink(profileId, handleId);
    }

    function testCannot_Link_IfNotHoldingProfile(address otherAddress) public {
        vm.assume(otherAddress != hub.ownerOf(profileId));
        vm.assume(otherAddress != address(0));
        vm.assume(!_isLensHubProxyAdmin(otherAddress));

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, otherAddress, handleId);

        vm.expectRevert(RegistryErrors.DoesNotHavePermissions.selector);

        vm.prank(otherAddress);
        tokenHandleRegistry.link(handleId, profileId);
    }

    function testCannot_Link_IfNotHoldingHandle(address otherAddress) public {
        vm.assume(otherAddress != lensHandles.ownerOf(handleId));
        vm.assume(otherAddress != address(0));
        vm.assume(!_isLensHubProxyAdmin(otherAddress));

        _effectivelyDisableProfileGuardian(initialProfileHolder);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, otherAddress, profileId);

        vm.expectRevert(RegistryErrors.DoesNotHavePermissions.selector);

        vm.prank(otherAddress);
        tokenHandleRegistry.link(handleId, profileId);
    }

    function testCannot_Link_IfHandleDoesNotExist(uint256 nonexistingHandleId) public {
        vm.assume(!lensHandles.exists(nonexistingHandleId));

        vm.expectRevert('ERC721: invalid token ID');

        vm.prank(initialProfileHolder);
        tokenHandleRegistry.link(nonexistingHandleId, profileId);
    }

    function testCannot_Link_IfProfileDoesNotExist(uint256 nonexistingProfileId) public {
        vm.assume(!hub.exists(nonexistingProfileId));

        vm.expectRevert(Errors.TokenDoesNotExist.selector);

        vm.prank(initialHandleHolder);
        tokenHandleRegistry.link(handleId, nonexistingProfileId);
    }

    function testCannot_Unlink_IfNotHoldingProfileOrHandle(address otherAddress) public {
        vm.assume(otherAddress != lensHandles.ownerOf(handleId));
        vm.assume(otherAddress != hub.ownerOf(profileId));
        vm.assume(otherAddress != address(0));
        vm.assume(!_isLensHubProxyAdmin(otherAddress));

        vm.prank(address(hub));
        tokenHandleRegistry.migrationLink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        vm.expectRevert(RegistryErrors.NotHandleNorTokenOwner.selector);

        vm.prank(otherAddress);
        tokenHandleRegistry.unlink(handleId, profileId);
    }

    function testCannot_Unlink_WithPassingZero(address otherAddress) public {
        vm.assume(otherAddress != lensHandles.ownerOf(handleId));
        vm.assume(otherAddress != hub.ownerOf(profileId));
        vm.assume(otherAddress != address(0));
        vm.assume(!_isLensHubProxyAdmin(otherAddress));

        vm.prank(address(hub));
        tokenHandleRegistry.migrationLink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        vm.prank(otherAddress);
        tokenHandleRegistry.unlink(handleId, 0);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        vm.prank(otherAddress);
        tokenHandleRegistry.unlink(0, profileId);

        console.log('0, 0');
        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        vm.prank(otherAddress);
        tokenHandleRegistry.unlink(0, 0);
    }

    function testResolve() public {
        assertEq(tokenHandleRegistry.resolve(handleId), 0);

        vm.prank(address(hub));
        tokenHandleRegistry.migrationLink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);

        address newProfileHolder = makeAddr('NEW_PROFILE_HOLDER');
        address newHandleHolder = makeAddr('NEW_HANDLE_HOLDER');

        _effectivelyDisableProfileGuardian(initialProfileHolder);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, newProfileHolder, profileId);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, newHandleHolder, handleId);

        // Still resolves after both tokens were moved to new owners.
        assertEq(tokenHandleRegistry.resolve(handleId), profileId);

        vm.prank(newProfileHolder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
    }

    function testGetDefaultHandle() public {
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);

        vm.prank(address(hub));
        tokenHandleRegistry.migrationLink(handleId, profileId);

        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        address newProfileHolder = makeAddr('NEW_PROFILE_HOLDER');
        address newHandleHolder = makeAddr('NEW_HANDLE_HOLDER');

        _effectivelyDisableProfileGuardian(initialProfileHolder);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, newProfileHolder, profileId);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, newHandleHolder, handleId);

        // Still gets default handle after both tokens were moved to new owners.
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        vm.prank(address(newHandleHolder));
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testCannot_Resolve_IfHandleDoesNotExist(uint256 nonexistingHandleId) public {
        vm.assume(!lensHandles.exists(nonexistingHandleId));

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.resolve(nonexistingHandleId);
    }

    function testCannot_GetDefaultHandle_IfProfileDoesNotExist(uint256 nonexistingProfileId) public {
        vm.assume(!hub.exists(nonexistingProfileId));

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.getDefaultHandle(nonexistingProfileId);
    }

    function testResolve_IfBurnt() public {
        vm.prank(address(hub));
        tokenHandleRegistry.migrationLink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);

        vm.prank(initialProfileHolder);
        hub.burn(profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.getDefaultHandle(profileId);
    }

    function testGetDefaultHandle_IfBurnt() public {
        vm.prank(address(hub));
        tokenHandleRegistry.migrationLink(handleId, profileId);

        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);

        vm.prank(initialHandleHolder);
        lensHandles.burn(handleId);

        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testCannot_Unlink_IfNotLinked() public {
        vm.expectRevert(RegistryErrors.NotLinked.selector);

        vm.prank(initialProfileHolder);
        tokenHandleRegistry.unlink(handleId, profileId);
    }

    function testFreshLink(address holder) public {
        vm.assume(holder != address(0));
        vm.assume(!_isLensHubProxyAdmin(holder));

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleLinked(handle, token, holder, block.timestamp);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);
    }

    function testLink_AfterHandleWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(firstHolder));
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(newHolder));
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        _effectivelyDisableGuardian(address(lensHandles), firstHolder);
        vm.prank(firstHolder);
        lensHandles.transferFrom(firstHolder, newHolder, handleId);

        uint256 newProfileId = _createProfile(newHolder);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, newHolder, block.timestamp);

        RegistryTypes.Token memory newToken = RegistryTypes.Token({collection: address(hub), id: newProfileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleLinked(handle, newToken, newHolder, block.timestamp);

        vm.prank(newHolder);
        tokenHandleRegistry.link(handleId, newProfileId);

        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
        assertEq(tokenHandleRegistry.resolve(handleId), newProfileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(newProfileId), handleId);
    }

    function testLink_AfterProfileWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(firstHolder));
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(newHolder));
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        _effectivelyDisableProfileGuardian(firstHolder);
        vm.prank(firstHolder);
        hub.transferFrom(firstHolder, newHolder, profileId);

        uint256 newHandleId = lensHandles.mintHandle(newHolder, 'newhandle');

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, newHolder, block.timestamp);

        RegistryTypes.Handle memory newHandle = RegistryTypes.Handle({
            collection: address(lensHandles),
            id: newHandleId
        });

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleLinked(newHandle, token, newHolder, block.timestamp);

        vm.prank(newHolder);
        tokenHandleRegistry.link(newHandleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.resolve(newHandleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), newHandleId);
    }

    function testLink_AfterBothProfileAndHandleWereMoved(address firstHolder, address newHolder) public {
        address thirdHolder = makeAddr('THIRD_HOLDER');

        vm.assume(firstHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(firstHolder));
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);
        vm.assume(firstHolder != thirdHolder);

        vm.assume(newHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(newHolder));
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);
        vm.assume(newHolder != thirdHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        _effectivelyDisableProfileGuardian(firstHolder);
        vm.prank(firstHolder);
        hub.transferFrom(firstHolder, newHolder, profileId);

        uint256 newHandleId = lensHandles.mintHandle(thirdHolder, 'newhandle');
        uint256 newProfileId = _createProfile(thirdHolder);

        vm.prank(thirdHolder);
        tokenHandleRegistry.link(newHandleId, newProfileId);

        _effectivelyDisableGuardian(address(lensHandles), thirdHolder);
        vm.prank(thirdHolder);
        lensHandles.transferFrom(thirdHolder, newHolder, newHandleId);

        RegistryTypes.Handle memory oldHandle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory oldToken = RegistryTypes.Token({collection: address(hub), id: profileId});

        RegistryTypes.Handle memory newHandle = RegistryTypes.Handle({
            collection: address(lensHandles),
            id: newHandleId
        });
        RegistryTypes.Token memory newToken = RegistryTypes.Token({collection: address(hub), id: newProfileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(newHandle, newToken, newHolder, block.timestamp);

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(oldHandle, oldToken, newHolder, block.timestamp);

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleLinked(newHandle, oldToken, newHolder, block.timestamp);

        vm.prank(newHolder);
        tokenHandleRegistry.link(newHandleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(newProfileId), 0);

        assertEq(tokenHandleRegistry.resolve(newHandleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), newHandleId);
    }

    function testUnlink(address holder) public {
        vm.assume(holder != address(0));
        vm.assume(!_isLensHubProxyAdmin(holder));
        vm.assume(holder != initialProfileHolder);
        vm.assume(holder != initialHandleHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, holder, block.timestamp);

        vm.prank(holder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_ByProfileOwner_IfHandleWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(firstHolder));
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(newHolder));
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        _effectivelyDisableGuardian(address(lensHandles), firstHolder);
        vm.prank(firstHolder);
        lensHandles.transferFrom(firstHolder, newHolder, handleId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, firstHolder, block.timestamp);

        vm.prank(firstHolder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_ByNewHandleOwner_IfHandleWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(firstHolder));
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(newHolder));
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        _effectivelyDisableGuardian(address(lensHandles), firstHolder);
        vm.prank(firstHolder);
        lensHandles.transferFrom(firstHolder, newHolder, handleId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, newHolder, block.timestamp);

        vm.prank(newHolder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_ByHandleOwner_IfProfileWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(firstHolder));
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(newHolder));
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        _effectivelyDisableProfileGuardian(firstHolder);
        vm.prank(firstHolder);
        hub.transferFrom(firstHolder, newHolder, profileId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, firstHolder, block.timestamp);

        vm.prank(firstHolder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_ByNewProfileOwner_IfProfileWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(firstHolder));
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(!_isLensHubProxyAdmin(newHolder));
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        _effectivelyDisableProfileGuardian(firstHolder);
        vm.prank(firstHolder);
        hub.transferFrom(firstHolder, newHolder, profileId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, newHolder, block.timestamp);

        vm.prank(newHolder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_IfHandleWasBurned(address holder) public {
        vm.assume(holder != address(0));
        vm.assume(!_isLensHubProxyAdmin(holder));
        vm.assume(holder != initialProfileHolder);
        vm.assume(holder != initialHandleHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        _effectivelyDisableGuardian(address(lensHandles), holder);
        vm.prank(holder);
        lensHandles.burn(handleId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, holder, block.timestamp);

        vm.prank(holder);
        tokenHandleRegistry.unlink(handleId, profileId);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.resolve(handleId);

        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_IfProfileWasBurned(address holder) public {
        vm.assume(holder != address(0));
        vm.assume(!_isLensHubProxyAdmin(holder));
        vm.assume(holder != initialProfileHolder);
        vm.assume(holder != initialHandleHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        _effectivelyDisableProfileGuardian(holder);
        vm.prank(holder);
        hub.burn(profileId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, holder, block.timestamp);

        vm.prank(holder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.getDefaultHandle(profileId);
    }

    function testUnlink_IfHandleWasBurned_CalledByNotOwner(address holder) public {
        vm.assume(holder != address(0));
        vm.assume(!_isLensHubProxyAdmin(holder));
        vm.assume(holder != initialProfileHolder);
        vm.assume(holder != initialHandleHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        _effectivelyDisableGuardian(address(lensHandles), holder);
        vm.prank(holder);
        lensHandles.burn(handleId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        address otherAddress = makeAddr('OTHER_ADDRESS');

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, otherAddress, block.timestamp);

        vm.prank(otherAddress);
        tokenHandleRegistry.unlink(handleId, profileId);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.resolve(handleId);

        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_IfProfileWasBurned_CalledByNotOwner(address holder) public {
        vm.assume(holder != address(0));
        vm.assume(!_isLensHubProxyAdmin(holder));
        vm.assume(holder != initialProfileHolder);
        vm.assume(holder != initialHandleHolder);

        _effectivelyDisableGuardian(address(lensHandles), initialHandleHolder);
        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        _effectivelyDisableProfileGuardian(initialProfileHolder);
        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        _effectivelyDisableProfileGuardian(holder);
        vm.prank(holder);
        hub.burn(profileId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        address otherAddress = makeAddr('OTHER_ADDRESS');

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, otherAddress, block.timestamp);

        vm.prank(otherAddress);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.getDefaultHandle(profileId);
    }
}
