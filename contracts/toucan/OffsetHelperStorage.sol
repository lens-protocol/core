//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OffsetHelperStorage is OwnableUpgradeable {
    // token symbol => token address
    mapping(string => address) public eligibleTokenAddresses;
    address public contractRegistryAddress =
        0x263fA1c180889b3a3f46330F32a4a23287E99FC9;
    address public sushiRouterAddress =
        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    // user => (token => amount)
    mapping(address => mapping(address => uint256)) public balances;
    // user => amount
    mapping(address => uint256) public tco2Balance;
    // user => amount they've offset with this contract since it's been deployed
    mapping(address => uint256) public overallOffsetAmount;
}
