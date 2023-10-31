// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';
import {IModuleRegistry} from 'contracts/interfaces/IModuleRegistry.sol';
import {ILensModule} from 'contracts/modules/interfaces/ILensModule.sol';
import {IPublicationActionModule} from 'contracts/interfaces/IPublicationActionModule.sol';
import {IFollowModule} from 'contracts/interfaces/IFollowModule.sol';
import {IReferenceModule} from 'contracts/interfaces/IReferenceModule.sol';
import {ModuleRegistry} from 'contracts/misc/ModuleRegistry.sol';
import {MockCurrency} from 'test/mocks/MockCurrency.sol';

contract ModuleRegistryTest is BaseTest {
    bytes4 constant LENS_MODULE_INTERFACE_ID = bytes4(keccak256(abi.encodePacked('LENS_MODULE')));
    bytes4 constant PUBLICATION_ACTION_MODULE_INTERFACE_ID = type(IPublicationActionModule).interfaceId;
    bytes4 constant FOLLOW_MODULE_INTERFACE_ID = type(IFollowModule).interfaceId;
    bytes4 constant REFERENCE_MODULE_INTERFACE_ID = type(IReferenceModule).interfaceId;

    function setUp() public override {
        super.setUp();
        moduleRegistry = new ModuleRegistry();
    }

    function testCannotRegisterModule_IfDoesNotSupportLensModuleInterface() public {
        address module = makeAddr('module');
        uint256 moduleType = uint256(IModuleRegistry.ModuleType.PUBLICATION_ACTION_MODULE);

        _mockSupportsInterface(module, LENS_MODULE_INTERFACE_ID, false);

        vm.expectRevert(ModuleRegistry.NotLensModule.selector);

        moduleRegistry.registerModule(module, moduleType);
    }

    function testCannotRegisterModule_IfModuleDoesNotSupportType() public {
        address module = makeAddr('module');
        uint256 moduleType = uint256(IModuleRegistry.ModuleType.PUBLICATION_ACTION_MODULE);

        _mockSupportsInterface(module, LENS_MODULE_INTERFACE_ID, true);
        _mockSupportsInterface(module, PUBLICATION_ACTION_MODULE_INTERFACE_ID, false);

        vm.expectRevert(abi.encodeWithSelector(ModuleRegistry.ModuleDoesNotSupportType.selector, moduleType));

        moduleRegistry.registerModule(module, moduleType);
    }

    function testCannotRegisterModule_TwiceAsTheSameType() public {
        address module = makeAddr('module');
        uint256 moduleType = uint256(IModuleRegistry.ModuleType.PUBLICATION_ACTION_MODULE);

        _mockSupportsInterface(module, LENS_MODULE_INTERFACE_ID, true);
        _mockSupportsInterface(module, PUBLICATION_ACTION_MODULE_INTERFACE_ID, true);
        _mockModuleMetadataURI(module, '');

        bool registrationWasPerformed = moduleRegistry.registerModule(module, moduleType);
        assertTrue(registrationWasPerformed);

        registrationWasPerformed = moduleRegistry.registerModule(module, moduleType);
        assertEq(registrationWasPerformed, false);
    }

    function testCannotRegisterModule_IfModuleTypeIsZero() public {
        address module = makeAddr('module');
        uint256 moduleType = 0;

        vm.expectRevert('Module Type out of bounds');

        moduleRegistry.registerModule(module, moduleType);
    }

    function testCannotRegisterModule_IfModuleTypeIsBiggerThanMax(uint256 moduleType) public {
        address module = makeAddr('module');
        moduleType = bound(moduleType, uint256(type(uint8).max) + 1, type(uint256).max);

        vm.expectRevert('Module Type out of bounds');

        moduleRegistry.registerModule(module, moduleType);
    }

    function testCannotRegisterErc20Currency_Twice() public {
        address currencyAddress = address(new MockCurrency());

        bool registrationWasPerformed = moduleRegistry.registerErc20Currency(currencyAddress);
        assertTrue(registrationWasPerformed);

        registrationWasPerformed = moduleRegistry.registerErc20Currency(currencyAddress);
        assertEq(registrationWasPerformed, false);
    }

    function testCannotIsModuleRegisteredAs_IfModuleTypeIsBiggerThanMax(uint256 moduleType) public {
        address module = makeAddr('module');
        moduleType = bound(moduleType, uint256(type(uint8).max) + 1, type(uint256).max);

        vm.expectRevert();

        moduleRegistry.isModuleRegisteredAs(module, moduleType);
    }

    function testRegisterModule_IfSupportsPublicationActionModule(address module) public {
        vm.assume(module != address(0));
        uint256 moduleType = uint256(IModuleRegistry.ModuleType.PUBLICATION_ACTION_MODULE);

        _mockSupportsInterface(module, LENS_MODULE_INTERFACE_ID, true);
        _mockSupportsInterface(module, PUBLICATION_ACTION_MODULE_INTERFACE_ID, true);
        _mockModuleMetadataURI(module, '');

        bool registrationWasPerformed = moduleRegistry.registerModule(module, moduleType);
        assertTrue(registrationWasPerformed);

        assertTrue(moduleRegistry.isModuleRegistered(module));
        assertTrue(moduleRegistry.isModuleRegisteredAs(module, moduleType));
        assertEq(moduleRegistry.getModuleTypes(module), 1 << moduleType);
    }

    function testRegisterModule_IfSupportsFollowModule(address module) public {
        vm.assume(module != address(0));
        uint256 moduleType = uint256(IModuleRegistry.ModuleType.FOLLOW_MODULE);

        _mockSupportsInterface(module, LENS_MODULE_INTERFACE_ID, true);
        _mockSupportsInterface(module, FOLLOW_MODULE_INTERFACE_ID, true);
        _mockModuleMetadataURI(module, '');

        bool registrationWasPerformed = moduleRegistry.registerModule(module, moduleType);
        assertTrue(registrationWasPerformed);

        assertTrue(moduleRegistry.isModuleRegistered(module));
        assertTrue(moduleRegistry.isModuleRegisteredAs(module, moduleType));
        assertEq(moduleRegistry.getModuleTypes(module), 1 << moduleType);
    }

    function testRegisterModule_IfSupportsReferenceModule(address module) public {
        vm.assume(module != address(0));
        uint256 moduleType = uint256(IModuleRegistry.ModuleType.REFERENCE_MODULE);

        _mockSupportsInterface(module, LENS_MODULE_INTERFACE_ID, true);
        _mockSupportsInterface(module, REFERENCE_MODULE_INTERFACE_ID, true);
        _mockModuleMetadataURI(module, '');

        bool registrationWasPerformed = moduleRegistry.registerModule(module, moduleType);
        assertTrue(registrationWasPerformed);

        assertTrue(moduleRegistry.isModuleRegistered(module));
        assertTrue(moduleRegistry.isModuleRegisteredAs(module, moduleType));
        assertEq(moduleRegistry.getModuleTypes(module), 1 << moduleType);
    }

    function testGetModuleTypes_WhenRegisteredAsMultipleTypes() public {
        address module = makeAddr('module');

        _mockSupportsInterface(module, LENS_MODULE_INTERFACE_ID, true);
        _mockModuleMetadataURI(module, '');

        _mockSupportsInterface(module, PUBLICATION_ACTION_MODULE_INTERFACE_ID, true);
        uint256 pubModuleType = uint256(IModuleRegistry.ModuleType.PUBLICATION_ACTION_MODULE);
        moduleRegistry.registerModule(module, pubModuleType);

        _mockSupportsInterface(module, REFERENCE_MODULE_INTERFACE_ID, true);
        uint256 referenceModuleType = uint256(IModuleRegistry.ModuleType.REFERENCE_MODULE);
        moduleRegistry.registerModule(module, referenceModuleType);

        uint256 expectedResult = (1 << pubModuleType) + (1 << referenceModuleType);
        assertEq(moduleRegistry.getModuleTypes(module), expectedResult);
    }

    function testRegisterErc20Currency() public {
        address currencyAddress = address(new MockCurrency());
        bool registrationWasPerformed = moduleRegistry.registerErc20Currency(currencyAddress);
        assertTrue(registrationWasPerformed);
        assertTrue(moduleRegistry.isErc20CurrencyRegistered(currencyAddress));
    }

    function _mockSupportsInterface(address module, bytes4 interfaceId, bool isSupported) private {
        bytes memory data = abi.encodeCall(ILensModule.supportsInterface, (interfaceId));
        bytes memory retdata = abi.encode(isSupported);
        vm.mockCall(module, 0, data, retdata);
    }

    function _mockModuleMetadataURI(address module, string memory metadataURI) private {
        bytes memory data = abi.encodeCall(ILensModule.getModuleMetadataURI, ());
        bytes memory retdata = abi.encode(metadataURI);
        vm.mockCall(module, 0, data, retdata);
    }
}
