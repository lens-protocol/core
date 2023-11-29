// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from 'contracts/libraries/svgs/Profile/Headwear.sol';
import {LensColors} from 'contracts/libraries/svgs/Profile/LensColors.sol';

library HeadwearBee {
    enum BeeColors {
        GREEN,
        PINK,
        PURPLE,
        BLUE,
        GOLD
    }

    function getBee(
        BeeColors beeColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getBeeStyle(beeColor),
                '<path class="headwearColorB" d="m158.7 77 .3.3a35.6 35.6 0 0 1-8 5.6l-.1-.9c0-7-2.3-14-6.6-19.5v-.2c2.5-.7 4.9-1.8 7-3.3 4.3 4.8 7 10.3 7.4 18Z"/><path class="headwearColorL" d="M151 82.9a37 37 0 0 1-9.1 3l-.2-1.3c0-8-3-16.1-8.2-22.2l-.7-.3a21 21 0 0 1 8-2.6h.6a27 27 0 0 1-.6 3.4c1.2-.1 2.3-.3 3.4-.6v.2A31.8 31.8 0 0 1 151 82v.9Z"/><path class="headwearColorB" d="m141.7 84.6.2 1.3c-2 .3-4 .3-6 0a16 16 0 0 1-5.4-1.9l1.8-.2c.7-5.9-1-12-4.6-16.6l-.4-.3a21 21 0 0 1 5.5-4.8l.7.3a34.2 34.2 0 0 1 8.2 22.2Z"/><path class="headwearColorL" d="M130.5 84c-2.2-1.2-4-3-5.2-5.1a11.2 11.2 0 0 1-1.1-7.7h.5a19 19 0 0 1 2.6-4.3l.4.3a22.6 22.6 0 0 1 4.6 16.6l-1.8.2Z"/><path fill="#fff" d="M140.9 59.5a19.6 19.6 0 0 0-13.6 7.4 19 19 0 0 0-2.6 4.3h-.5a9.2 9.2 0 0 1 2.3-4.5 8.4 8.4 0 0 1-3-9.7 10 10 0 0 1 7.8-6.3 13 13 0 0 1 10 2.9c0-4.2.1-8.4 2.5-11.4l1.4-1.4.3.2a18 18 0 0 0-3.6 10.4c-.2 2.7-.2 5.4-.5 8.2h-.5Z"/><path fill="#fff" d="m140.8 62.9.6-3.3c.3-2.8.3-5.5.5-8.2a18 18 0 0 1 3.6-10.4l-.3-.2a9.2 9.2 0 0 1 9.7-1c3.3 1.8 5 5.6 4.5 9.2h-.3a21.7 21.7 0 0 1-18.3 13.9Z"/><path class="headwearColorL" d="M159 50.5c3.3.7 6 2.5 7.5 5.1 1.5 2.6 1.7 5.7 1 8.6-.6 2.8-2 5.5-3.8 7.9a35 35 0 0 1-4.7 5.2l-.3-.4c-.4-7.6-3-13.1-7.4-18a21 21 0 0 0 7.8-10l.3.1-.3 1.5Zm2.7 8.9c.1-.5-.6-1.4-1.1-1-.5.2-.6 1-.2 1.3.3.4 1.1.2 1.3-.3Z"/><path class="hwStr1" stroke-width="4" d="M49.9 86.4a15.2 15.2 0 0 1 .4-5.3m2.7-5.3 2.4-3.8m5.2-4c1-1 2.4-1.8 3.8-2.3m7-1.2c1.3-.4 2.8-.3 4.1 0m7.3 2.5 3.5 2.1m7 4 4 2m7.5 1.3c1.8.4 3.6.6 5.4.5m48.8.4a35 35 0 0 0 4.7-5.2c1.7-2.4 3.2-5 3.8-8 .7-2.8.5-6-1-8.5a11 11 0 0 0-7.4-5.1l.3-1.5a9.2 9.2 0 0 0-4.5-9.2 9.2 9.2 0 0 0-11.1 2.4c-2.4 3-2.5 7.2-2.5 11.4a13 13 0 0 0-10-2.9c-3.5.6-6.7 3-7.9 6.3a8.4 8.4 0 0 0 3.1 9.7 9.2 9.2 0 0 0-2.3 4.5c-.6 2.5-.2 5.4 1 7.7 1.3 2.2 3.1 3.9 5.3 5.1a16 16 0 0 0 5.4 1.9c2 .3 4 .3 6 0a28.2 28.2 0 0 0 9-3c3-1.5 5.7-3.4 8.1-5.6Z"/><path class="hwStr1" stroke-width="3" d="m145.6 40.8-.1.2a18 18 0 0 0-3.6 10.4c-.2 2.7-.2 5.4-.5 8.2a27 27 0 0 1-.6 3.3 21.9 21.9 0 0 0 18.3-14m-34.4 22.3a20.4 20.4 0 0 1 16.2-11.7"/><path class="hwStr1" stroke-width="3" d="M142 61.3c3.6-3.2 6.4-7.2 8.4-11.5M131.2 58c1.5 1 3.2 1.7 5 2.1m-8.5 7.1a22.6 22.6 0 0 1 4.6 16.6m1.2-21.4a34.2 34.2 0 0 1 8.2 22.2m2.6-22.1a31.8 31.8 0 0 1 6.6 19.5m.4-23s0 0 0 0c4.3 4.8 7 10.3 7.4 18"/><path fill="#000" d="M160.6 58.3c-.5.3-.6 1-.2 1.4.3.4 1.1.2 1.3-.3.1-.5-.6-1.4-1.1-1Z"/><path class="hwStr1" stroke-width="3" d="M160.6 58.3c-.5.3-.6 1-.2 1.4.3.4 1.1.2 1.3-.3.1-.5-.6-1.4-1.1-1Z"/></svg>'
            ),
            Headwear.HeadwearVariants.BEE,
            _getHeadwearColor(beeColor)
        );
    }

    function _getBeeStyle(BeeColors beeColor) internal pure returns (string memory) {
        (string memory lightColor, string memory baseColor) = _getBeeColor(beeColor);
        return
            string.concat(
                '<style>.headwearColorL { fill:',
                lightColor,
                '}.headwearColorB { fill:',
                baseColor,
                '}.hwStr1 {stroke: #000;stroke-linecap: round;stroke-linejoin: round;}</style>'
            );
    }

    function _getBeeColor(BeeColors beeColor) internal pure returns (string memory, string memory) {
        if (beeColor == BeeColors.GREEN) {
            return (LensColors.lightGreen, LensColors.baseGreen);
        } else if (beeColor == BeeColors.PURPLE) {
            return (LensColors.lightPurple, LensColors.basePurple);
        } else if (beeColor == BeeColors.BLUE) {
            return (LensColors.lightBlue, LensColors.baseBlue);
        } else if (beeColor == BeeColors.PINK) {
            return (LensColors.lightPink, LensColors.basePink);
        } else if (beeColor == BeeColors.GOLD) {
            return (LensColors.lightGold, LensColors.baseGold);
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(BeeColors beeColor) internal pure returns (Headwear.HeadwearColors) {
        if (beeColor == BeeColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (beeColor == BeeColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (beeColor == BeeColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (beeColor == BeeColors.PINK) {
            return Headwear.HeadwearColors.PINK;
        } else if (beeColor == BeeColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
