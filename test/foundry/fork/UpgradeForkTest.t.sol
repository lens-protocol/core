// This test should upgrade the forked Polygon deployment, and run a series of tests.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '../base/BaseTest.t.sol';

contract UpgradeForkTest is BaseTest {
    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    address constant POLYGON_HUB_PROXY = 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;
    address constant MUMBAI_HUB_PROXY = 0x60Ae865ee4C725cd04353b5AAb364553f56ceF82;
    uint256 polygonForkId;
    uint256 mumbaiForkId;

    function setUp() public override {
        string memory polygonForkUrl = vm.envString('POLYGON_RPC_URL');
        string memory mumbaiForkUrl = vm.envString('MUMBAI_RPC_URL');

        polygonForkId = vm.createFork(polygonForkUrl);
        mumbaiForkId = vm.createFork(mumbaiForkUrl);
    }

    function testUpgradePolygon() public {
        vm.selectFork(polygonForkId);
        super.setUp();
        ILensHub oldHub = ILensHub(POLYGON_HUB_PROXY);
        TransparentUpgradeableProxy oldHubAsProxy = TransparentUpgradeableProxy(
            payable(POLYGON_HUB_PROXY)
        );

        // First, get the previous data.
        address gov = oldHub.getGovernance();
        address proxyAdmin = address(uint160(uint256(vm.load(POLYGON_HUB_PROXY, ADMIN_SLOT))));

        // Second, upgrade the hub.
        vm.prank(proxyAdmin);
        oldHubAsProxy.upgradeTo(address(hubImpl));

        // Third, get the data and ensure it's equal to the old data (getters access the same slots).
        assertEq(oldHub.getGovernance(), gov);

        // Fourth, set new data and ensure getters return the new data (proper slots set).
        vm.prank(gov);
        oldHub.setGovernance(me);
        assertEq(oldHub.getGovernance(), me);
    }
}
