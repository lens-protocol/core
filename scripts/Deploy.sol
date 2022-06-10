// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ModuleGlobals} from '../contracts/core/modules/ModuleGlobals.sol';
import {LensHub} from '../contracts/core/LensHub.sol';
import {FollowNFT} from '../contracts/core/FollowNFT.sol';
import {CollectNFT} from '../contracts/core/CollectNFT.sol';
import {TransparentUpgradeableProxy} from '../contracts/upgradeability/TransparentUpgradeableProxy.sol';

import 'forge-std/Script.sol';

contract Deploy is Script {
    uint16 constant TREASURY_FEE_BPS = 50;
    string constant LENS_HUB_NFT_NAME = 'Lens Protocol Profiles';
    string constant LENS_HUB_NFT_SYMBOL = 'LPP';

    // TODO: Replace with loading in addresses from mnemonic?
    address immutable user = vm.addr(1);
    address immutable userTwo = vm.addr(2);
    address immutable userThree = vm.addr(3);
    address immutable governance = vm.addr(4);
    address immutable treasury = vm.addr(5);

    function run() external {
        vm.startBroadcast();

        ModuleGlobals moduleGlobals = new ModuleGlobals(governance, treasury, TREASURY_FEE_BPS);

        uint256 deployerNonce = vm.getNonce(msg.sender);

        uint256 followNFTNonce = deployerNonce + 1;
        uint256 collectNFTNonce = deployerNonce + 2;
        uint256 hubProxyNonce = deployerNonce + 3;

        address followNFTImplAddress = addressFrom(msg.sender, followNFTNonce);
        address collectNFTImplAddress = addressFrom(msg.sender, collectNFTNonce);
        address hubProxyAddress = addressFrom(msg.sender, hubProxyNonce);

        LensHub lensHubImpl = new LensHub(followNFTImplAddress, collectNFTImplAddress);

        FollowNFT followNFT = new FollowNFT(hubProxyAddress);
        CollectNFT collectNFT = new CollectNFT(hubProxyAddress);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(lensHubImpl),
            msg.sender,
            abi.encodeWithSelector(
                LensHub.initialize.selector,
                LENS_HUB_NFT_NAME,
                LENS_HUB_NFT_SYMBOL,
                governance
            )
        );

        LensHub lensHub = LensHub(address(proxy));

        vm.stopBroadcast();
    }

    function addressFrom(address _origin, uint256 _nonce) internal pure returns (address _address) {
        bytes memory data;
        if (_nonce == 0x00)
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80));
        else if (_nonce <= 0x7f)
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce));
        else if (_nonce <= 0xff)
            data = abi.encodePacked(
                bytes1(0xd7),
                bytes1(0x94),
                _origin,
                bytes1(0x81),
                uint8(_nonce)
            );
        else if (_nonce <= 0xffff)
            data = abi.encodePacked(
                bytes1(0xd8),
                bytes1(0x94),
                _origin,
                bytes1(0x82),
                uint16(_nonce)
            );
        else if (_nonce <= 0xffffff)
            data = abi.encodePacked(
                bytes1(0xd9),
                bytes1(0x94),
                _origin,
                bytes1(0x83),
                uint24(_nonce)
            );
        else
            data = abi.encodePacked(
                bytes1(0xda),
                bytes1(0x94),
                _origin,
                bytes1(0x84),
                uint32(_nonce)
            );
        bytes32 hash = keccak256(data);
        assembly {
            mstore(0, hash)
            _address := mload(0)
        }
    }
}
