// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ForkManagement} from 'script/helpers/ForkManagement.sol';
import 'forge-std/Script.sol';

import {ProfileTokenURI} from 'contracts/misc/token-uris/ProfileTokenURI.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract NFTMinter is ProfileTokenURI, ERC721 {
    constructor() ERC721('Test Protocol', 'TEST') {}

    function mintMany(uint256 tokenIdFrom, uint256 tokenIdTo) external {
        for (uint256 i = tokenIdFrom; i < tokenIdTo; i++) {
            _mint(msg.sender, i);
        }
    }

    function mintFuzz(uint256 seed, uint256 n) external {
        for (uint256 i = 0; i < n; i++) {
            uint256 tokenId = uint256(keccak256(abi.encodePacked(seed, i))) % 130000;
            if (!_exists(tokenId)) {
                _mint(msg.sender, tokenId);
            }
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return ProfileTokenURI.getTokenURI(tokenId, block.timestamp);
    }
}

contract DeployTestProfiles is Script, ForkManagement {
    using stdJson for string;

    struct LensAccount {
        uint256 ownerPk;
        address owner;
        uint256 profileId;
    }

    LensAccount _deployer;

    string mnemonic;

    NFTMinter nftMinter;

    function loadPrivateKeys() internal {
        if (isEnvSet('MNEMONIC')) {
            mnemonic = vm.envString('MNEMONIC');
        }

        if (bytes(mnemonic).length == 0) {
            revert('Missing mnemonic');
        }

        console.log('\n');

        (_deployer.owner, _deployer.ownerPk) = deriveRememberKey(mnemonic, 0);
        console.log('Deployer address: %s', address(_deployer.owner));

        console.log('\n');

        console.log('Current block:', block.number);
    }

    function deploy() internal {
        console.log('\n');
        console.log('Deploying NFTMinter contract...');
        vm.startBroadcast(_deployer.ownerPk);
        nftMinter = new NFTMinter();
        vm.stopBroadcast();
        console.log('NFTMinter address: %s', address(nftMinter));
        console.log('\n');
    }

    function interact() internal {
        nftMinter = NFTMinter(0x9358Fe2E2Ec00bd24eeee491DFd3d57333A88FBB);
        vm.startBroadcast(_deployer.ownerPk);
        nftMinter.mintMany(100, 101);
        nftMinter.mintMany(200, 201);
        nftMinter.mintMany(300, 301);
        nftMinter.mintMany(400, 401);
        nftMinter.mintMany(500, 501);
        nftMinter.mintMany(600, 601);
        nftMinter.mintMany(700, 701);
        nftMinter.mintMany(800, 801);
        nftMinter.mintMany(900, 901);
        nftMinter.mintMany(1001, 1010);

        // nftMinter.mintMany(1, 100);
        // nftMinter.mintMany(101, 200);
        // nftMinter.mintMany(201, 300);
        // nftMinter.mintMany(301, 400);
        // nftMinter.mintMany(401, 500);
        // nftMinter.mintMany(501, 600);
        // nftMinter.mintMany(601, 700);
        // nftMinter.mintMany(701, 800);
        // nftMinter.mintMany(801, 900);
        // nftMinter.mintMany(901, 1001);
        nftMinter.mintFuzz(1, 200);
        nftMinter.mintFuzz(2, 200);
        nftMinter.mintFuzz(3, 200);
        nftMinter.mintFuzz(4, 200);
        nftMinter.mintFuzz(5, 200);
        nftMinter.mintFuzz(6, 200);
        nftMinter.mintFuzz(7, 200);
        nftMinter.mintFuzz(8, 200);
        nftMinter.mintFuzz(9, 200);
        nftMinter.mintFuzz(10, 200);
        vm.stopBroadcast();
    }

    function run(string memory targetEnv_) external {
        targetEnv = targetEnv_;
        loadJson();
        checkNetworkParams();
        loadBaseAddresses();
        loadPrivateKeys();
        // deploy();
        interact();
    }
}
