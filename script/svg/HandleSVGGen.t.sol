// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

import {HandleSVG} from 'contracts/libraries/svgs/Handle/HandleSVG.sol';

contract HandleNFT {
    function tryWithName(string memory name) external pure returns (string memory) {
        return HandleSVG.getHandleSVG(name);
    }
}

contract HandleSVGGen is Test {
    HandleNFT handleNFT;
    string constant dir = 'svgs/';

    function setUp() public {
        handleNFT = new HandleNFT();
    }

    function testHandles() public {
        vm.writeFile(string.concat(dir, 'handles/handle_1_black.svg'), handleNFT.tryWithName('x'));
        vm.writeFile(string.concat(dir, 'handles/handle_2_gold.svg'), handleNFT.tryWithName('gm'));
        vm.writeFile(string.concat(dir, 'handles/handle_3_blue.svg'), handleNFT.tryWithName('eth'));
        vm.writeFile(string.concat(dir, 'handles/handle_4_purple.svg'), handleNFT.tryWithName('aave'));
        vm.writeFile(string.concat(dir, 'handles/handle_5_peach.svg'), handleNFT.tryWithName('stani'));
        vm.writeFile(string.concat(dir, 'handles/handle_6_green.svg'), handleNFT.tryWithName('victor'));
        vm.writeFile(string.concat(dir, 'handles/handle_7.svg'), handleNFT.tryWithName('abcdefg'));
        vm.writeFile(string.concat(dir, 'handles/handle_8.svg'), handleNFT.tryWithName('abcdefgh'));
        vm.writeFile(string.concat(dir, 'handles/handle_9.svg'), handleNFT.tryWithName('abcdefghj'));
        vm.writeFile(string.concat(dir, 'handles/handle_10.svg'), handleNFT.tryWithName('abcdefghjk'));
        vm.writeFile(string.concat(dir, 'handles/handle_11.svg'), handleNFT.tryWithName('abcdefghjkl'));
        vm.writeFile(string.concat(dir, 'handles/handle_12.svg'), handleNFT.tryWithName('abcdefghjklm'));
        vm.writeFile(string.concat(dir, 'handles/handle_13.svg'), handleNFT.tryWithName('abcdefghjklmn'));
        vm.writeFile(string.concat(dir, 'handles/handle_14.svg'), handleNFT.tryWithName('abcdefghjklmno'));
        vm.writeFile(string.concat(dir, 'handles/handle_15.svg'), handleNFT.tryWithName('abcdefghjklmnop'));
        vm.writeFile(string.concat(dir, 'handles/handle_16.svg'), handleNFT.tryWithName('abcdefghjklmnopq'));
        vm.writeFile(string.concat(dir, 'handles/handle_17.svg'), handleNFT.tryWithName('abcdefghjklmnopqr'));
        vm.writeFile(string.concat(dir, 'handles/handle_18.svg'), handleNFT.tryWithName('abcdefghjklmnopqrs'));
        vm.writeFile(string.concat(dir, 'handles/handle_19.svg'), handleNFT.tryWithName('abcdefghjklmnopqrst'));
        vm.writeFile(string.concat(dir, 'handles/handle_20.svg'), handleNFT.tryWithName('abcdefghjklmnopqrstu'));
        vm.writeFile(string.concat(dir, 'handles/handle_21.svg'), handleNFT.tryWithName('abcdefghjklmnopqrstuv'));
        vm.writeFile(string.concat(dir, 'handles/handle_22.svg'), handleNFT.tryWithName('abcdefghjklmnopqrstuvw'));
        vm.writeFile(string.concat(dir, 'handles/handle_23.svg'), handleNFT.tryWithName('abcdefghjklmnopqrstuvwx'));
        vm.writeFile(string.concat(dir, 'handles/handle_24.svg'), handleNFT.tryWithName('abcdefghjklmnopqrstuvwxy'));
        vm.writeFile(string.concat(dir, 'handles/handle_25.svg'), handleNFT.tryWithName('abcdefghjklmnopqrstuvwxyz'));
        vm.writeFile(string.concat(dir, 'handles/handle_26.svg'), handleNFT.tryWithName('abcdefghijklmnopqrstuvwxyz'));
        vm.writeFile(string.concat(dir, 'handles/handle_10_numbers.svg'), handleNFT.tryWithName('0123456789'));
        vm.writeFile(string.concat(dir, 'handles/handle_13_mix.svg'), handleNFT.tryWithName('abc0123456789'));
        vm.writeFile(
            string.concat(dir, 'handles/handle_26_superlong.svg'),
            handleNFT.tryWithName('mmmmmmmm1-234567mmmmm01234')
        );
    }

    function testRealHandles() public {
        vm.writeFile(string.concat(dir, 'handles/handle_real_01.svg'), handleNFT.tryWithName('bradorbradley'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_02.svg'), handleNFT.tryWithName('creatorfundincubator'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_03.svg'), handleNFT.tryWithName('ameerna17958863'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_04.svg'), handleNFT.tryWithName('lensprotocol'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_05.svg'), handleNFT.tryWithName('mariariivari'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_06.svg'), handleNFT.tryWithName('thesmurfssociety'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_07.svg'), handleNFT.tryWithName('donosonaumczuk'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_08.svg'), handleNFT.tryWithName('timeswap_labs'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_09.svg'), handleNFT.tryWithName('millionrecords'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_10.svg'), handleNFT.tryWithName('cointelegraph'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_11.svg'), handleNFT.tryWithName('christian_ronaldo'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_12.svg'), handleNFT.tryWithName('zombieshepherd'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_13.svg'), handleNFT.tryWithName('beautifuldestinations'));
        vm.writeFile(string.concat(dir, 'handles/handle_real_14.svg'), handleNFT.tryWithName('shellprotocol_touchan'));
    }

    function testWWW() public {
        for (uint256 i = 1; i <= 26; i++) {
            string memory name = '';
            for (uint256 j = 0; j < i; j++) {
                name = string.concat(name, 'w');
            }
            vm.writeFile(
                string.concat(dir, 'handles/handle_www_', vm.toString(i), '.svg'),
                handleNFT.tryWithName(name)
            );
        }
    }
}
