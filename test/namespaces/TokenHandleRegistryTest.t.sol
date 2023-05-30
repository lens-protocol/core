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
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(otherAddress != proxyAdmin);

        vm.expectRevert(RegistryErrors.OnlyLensHub.selector);

        vm.prank(otherAddress);
        tokenHandleRegistry.migrationLink(profileId, handleId);
    }

    function testCannot_Link_IfNotHoldingProfile(address otherAddress) public {
        vm.assume(otherAddress != hub.ownerOf(profileId));
        vm.assume(otherAddress != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(otherAddress != proxyAdmin);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, otherAddress, handleId);

        vm.expectRevert(RegistryErrors.NotTokenOwner.selector);

        vm.prank(otherAddress);
        tokenHandleRegistry.link(handleId, profileId);
    }

    function testCannot_Link_IfNotHoldingHandle(address otherAddress) public {
        vm.assume(otherAddress != lensHandles.ownerOf(handleId));
        vm.assume(otherAddress != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(otherAddress != proxyAdmin);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, otherAddress, profileId);

        vm.expectRevert(RegistryErrors.NotHandleOwner.selector);

        vm.prank(otherAddress);
        tokenHandleRegistry.link(handleId, profileId);
    }

    function testCannot_Unlink_IfNotHoldingProfileOrHandle(address otherAddress) public {
        vm.assume(otherAddress != lensHandles.ownerOf(handleId));
        vm.assume(otherAddress != hub.ownerOf(profileId));
        vm.assume(otherAddress != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(otherAddress != proxyAdmin);

        vm.prank(address(hub));
        tokenHandleRegistry.migrationLink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        vm.expectRevert(RegistryErrors.NotHandleNorTokenOwner.selector);

        vm.prank(otherAddress);
        tokenHandleRegistry.unlink(handleId, profileId);
    }

    function testResolve() public {
        assertEq(tokenHandleRegistry.resolve(handleId), 0);

        vm.prank(address(hub));
        tokenHandleRegistry.migrationLink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);

        address newProfileHolder = makeAddr('NEW_PROFILE_HOLDER');
        address newHandleHolder = makeAddr('NEW_HANDLE_HOLDER');

        vm.prank(address(initialProfileHolder));
        hub.transferFrom(initialProfileHolder, newProfileHolder, profileId);

        vm.prank(address(initialHandleHolder));
        lensHandles.transferFrom(initialHandleHolder, newHandleHolder, handleId);

        // Still resolves after both tokens were moved to new owners.
        assertEq(tokenHandleRegistry.resolve(handleId), profileId);

        vm.prank(address(newProfileHolder));
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

        vm.prank(address(initialProfileHolder));
        hub.transferFrom(initialProfileHolder, newProfileHolder, profileId);

        vm.prank(address(initialHandleHolder));
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

        vm.prank(address(initialProfileHolder));
        hub.burn(profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.getDefaultHandle(profileId);
    }

    function testGetDefaultHandle_IfBurnt() public {
        vm.prank(address(hub));
        tokenHandleRegistry.migrationLink(handleId, profileId);

        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        vm.prank(address(initialHandleHolder));
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
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(holder != proxyAdmin);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleLinked(handle, token, block.timestamp);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);
    }

    function testLink_AfterHandleWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(firstHolder != proxyAdmin);
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(newHolder != proxyAdmin);
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        vm.prank(firstHolder);
        lensHandles.transferFrom(firstHolder, newHolder, handleId);

        uint256 newProfileId = _createProfile(newHolder);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, block.timestamp);

        RegistryTypes.Token memory newToken = RegistryTypes.Token({collection: address(hub), id: newProfileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleLinked(handle, newToken, block.timestamp);

        vm.prank(newHolder);
        tokenHandleRegistry.link(handleId, newProfileId);

        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
        assertEq(tokenHandleRegistry.resolve(handleId), newProfileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(newProfileId), handleId);
    }

    function testLink_AfterProfileWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(firstHolder != proxyAdmin);
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(newHolder != proxyAdmin);
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        vm.prank(firstHolder);
        hub.transferFrom(firstHolder, newHolder, profileId);

        uint256 newHandleId = lensHandles.mintHandle(newHolder, 'newhandle');

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, block.timestamp);

        RegistryTypes.Handle memory newHandle = RegistryTypes.Handle({
            collection: address(lensHandles),
            id: newHandleId
        });

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleLinked(newHandle, token, block.timestamp);

        vm.prank(newHolder);
        tokenHandleRegistry.link(newHandleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.resolve(newHandleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), newHandleId);
    }

    function testLink_AfterBothProfileAndHandleWereMoved(address firstHolder, address newHolder) public {
        address thirdHolder = makeAddr('THIRD_HOLDER');

        vm.assume(firstHolder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(firstHolder != proxyAdmin);
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);
        vm.assume(firstHolder != thirdHolder);

        vm.assume(newHolder != address(0));
        vm.assume(newHolder != proxyAdmin);
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);
        vm.assume(newHolder != thirdHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        vm.prank(firstHolder);
        hub.transferFrom(firstHolder, newHolder, profileId);

        uint256 newHandleId = lensHandles.mintHandle(thirdHolder, 'newhandle');
        uint256 newProfileId = _createProfile(thirdHolder);

        vm.prank(thirdHolder);
        tokenHandleRegistry.link(newHandleId, newProfileId);

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
        emit RegistryEvents.HandleUnlinked(newHandle, newToken, block.timestamp);

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(oldHandle, oldToken, block.timestamp);

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleLinked(newHandle, oldToken, block.timestamp);

        vm.prank(newHolder);
        tokenHandleRegistry.link(newHandleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(newProfileId), 0);

        assertEq(tokenHandleRegistry.resolve(newHandleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), newHandleId);
    }

    function testUnlink(address holder) public {
        vm.assume(holder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(holder != proxyAdmin);
        vm.assume(holder != initialProfileHolder);
        vm.assume(holder != initialHandleHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, block.timestamp);

        vm.prank(holder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_ByProfileOwner_IfHandleWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(firstHolder != proxyAdmin);
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(newHolder != proxyAdmin);
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        vm.prank(firstHolder);
        lensHandles.transferFrom(firstHolder, newHolder, handleId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, block.timestamp);

        vm.prank(firstHolder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_ByNewHandleOwner_IfHandleWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(firstHolder != proxyAdmin);
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(newHolder != proxyAdmin);
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        vm.prank(firstHolder);
        lensHandles.transferFrom(firstHolder, newHolder, handleId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, block.timestamp);

        vm.prank(newHolder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_ByHandleOwner_IfProfileWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(firstHolder != proxyAdmin);
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(newHolder != proxyAdmin);
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        vm.prank(firstHolder);
        hub.transferFrom(firstHolder, newHolder, profileId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, block.timestamp);

        vm.prank(firstHolder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_ByNewProfileOwner_IfProfileWasMoved(address firstHolder, address newHolder) public {
        vm.assume(firstHolder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(firstHolder != proxyAdmin);
        vm.assume(firstHolder != initialProfileHolder);
        vm.assume(firstHolder != initialHandleHolder);

        vm.assume(newHolder != address(0));
        vm.assume(newHolder != proxyAdmin);
        vm.assume(newHolder != initialProfileHolder);
        vm.assume(newHolder != initialHandleHolder);

        vm.assume(newHolder != firstHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, firstHolder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, firstHolder, profileId);

        vm.prank(firstHolder);
        tokenHandleRegistry.link(handleId, profileId);

        vm.prank(firstHolder);
        hub.transferFrom(firstHolder, newHolder, profileId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, block.timestamp);

        vm.prank(newHolder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_IfHandleWasBurned(address holder) public {
        vm.assume(holder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(holder != proxyAdmin);
        vm.assume(holder != initialProfileHolder);
        vm.assume(holder != initialHandleHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        vm.prank(holder);
        lensHandles.burn(handleId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, block.timestamp);

        vm.prank(holder);
        tokenHandleRegistry.unlink(handleId, profileId);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.resolve(handleId);

        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_IfProfileWasBurned(address holder) public {
        vm.assume(holder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(holder != proxyAdmin);
        vm.assume(holder != initialProfileHolder);
        vm.assume(holder != initialHandleHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        vm.prank(holder);
        hub.burn(profileId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, block.timestamp);

        vm.prank(holder);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.getDefaultHandle(profileId);
    }

    function testUnlink_IfHandleWasBurned_CalledByNotOwner(address holder) public {
        vm.assume(holder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(holder != proxyAdmin);
        vm.assume(holder != initialProfileHolder);
        vm.assume(holder != initialHandleHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        vm.prank(holder);
        lensHandles.burn(handleId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, block.timestamp);

        address otherAddress = makeAddr('OTHER_ADDRESS');
        vm.prank(otherAddress);
        tokenHandleRegistry.unlink(handleId, profileId);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.resolve(handleId);

        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), 0);
    }

    function testUnlink_IfProfileWasBurned_CalledByNotOwner(address holder) public {
        vm.assume(holder != address(0));
        address proxyAdmin = address(uint160(uint256(vm.load(address(tokenHandleRegistry), ADMIN_SLOT))));
        vm.assume(holder != proxyAdmin);
        vm.assume(holder != initialProfileHolder);
        vm.assume(holder != initialHandleHolder);

        vm.prank(initialHandleHolder);
        lensHandles.transferFrom(initialHandleHolder, holder, handleId);

        vm.prank(initialProfileHolder);
        hub.transferFrom(initialProfileHolder, holder, profileId);

        vm.prank(holder);
        tokenHandleRegistry.link(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), profileId);
        assertEq(tokenHandleRegistry.getDefaultHandle(profileId), handleId);

        vm.prank(holder);
        hub.burn(profileId);

        RegistryTypes.Handle memory handle = RegistryTypes.Handle({collection: address(lensHandles), id: handleId});
        RegistryTypes.Token memory token = RegistryTypes.Token({collection: address(hub), id: profileId});

        vm.expectEmit(true, true, true, true, address(tokenHandleRegistry));
        emit RegistryEvents.HandleUnlinked(handle, token, block.timestamp);

        address otherAddress = makeAddr('OTHER_ADDRESS');
        vm.prank(otherAddress);
        tokenHandleRegistry.unlink(handleId, profileId);

        assertEq(tokenHandleRegistry.resolve(handleId), 0);

        vm.expectRevert(RegistryErrors.DoesNotExist.selector);
        tokenHandleRegistry.getDefaultHandle(profileId);
    }

    // TODO:
    // - test migrationLink scenarios
}
