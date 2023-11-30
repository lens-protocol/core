// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from 'contracts/libraries/svgs/Profile/Headwear.sol';
import {LensColors} from 'contracts/libraries/svgs/Profile/LensColors.sol';

library HeadwearBear {
    enum BearColors {
        GREEN,
        PINK,
        PURPLE,
        BLUE,
        GOLD
    }

    function getBear(
        BearColors bearColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="250" height="335" x="-18.6" fill="none">',
                _getBearStyle(bearColor),
                '<path class="headwearColorL" d="M205.8 92.3a35 35 0 0 0 14.5 13.8c-9.6-3.6-23-5.1-41.4-8-18-2.8-36.8-3.7-55.2-3.7-18.5 0-37.2.9-55.2 3.7-18.4 2.9-31.8 4.4-41.5 8a34.4 34.4 0 0 0 14.5-13.8c3-5.5 13.6-21 13.6-21S58.6 51.9 71.7 46c15.1-6.7 28 3.6 28 3.6s17.5-2.4 24-2.4c6.4 0 23.9 2.4 23.9 2.4s14.8-10.9 30.2-3.6c11.7 3.6 14.5 25.4 14.5 25.4s10.6 15.4 13.5 21Z"/><path class="headwearColorL" d="M241.2 115.7c2.6 2.8 4.3 6.6 3.6 10.4.5-3.3-2.7-5.8-5.7-7.3-8.7-4.6-18.3-3.4-27.9-5.6-28.8-6.5-61-10-87.5-10-26.6 0-58.8 3.5-87.6 10-9.6 2.2-19.3 2.6-28 7.1-3 1.5-6 2.6-5.5 5.8-.8-3.7.7-7.9 3.3-10.6 2.5-2.6 9-4.6 21-8.7 9.7-3.3 23.2-4.8 41.6-7.4a374.7 374.7 0 0 1 110.4 0c18.3 2.6 31.9 3.8 41.6 7 12 4.2 18.2 6.8 20.7 9.3Z"/><path class="hwStr1" stroke-width="4" d="M123.7 104.5c-26.6 0-58.8 2.9-87.6 7.9a140 140 0 0 0-27.9 7.1c-3 1.2-6.1 3.1-5.6 5.7.3 1.5 5 5.3 19.2 7.2m101.9-27.9c26.5 0 58.7 2.9 87.5 7.9a140 140 0 0 1 28 7.1c2.9 1.2 6 3.1 5.6 5.7-.4 1.5-5 5.3-19.3 7.2"/><path class="hwStr1" stroke-width="4" d="M2.6 123.1s0 0 0 0c-.8-3 1-6.2 3.6-8.4 2.5-2 8.7-5.3 20.8-8.6m217.8 17s0 0 0 0c.7-3-1-6.2-3.6-8.4-2.5-2-8.7-5.3-20.9-8.6"/><path class="headwearColorL" d="M4.5 124.7c-2-2.6 17.4-7.4 17.4-7.4s-1.3 4-1.8 6.8c-.3 2.3-.4 6-.4 6s-12-1.3-15.2-5.4Zm238.4 0c2-2.6-17.4-7.4-17.4-7.4s1.3 4 1.7 6.8c.4 2.3.5 6 .5 6s12-1.3 15.2-5.4Z"/><path fill="#000" fill-opacity=".3" d="M4.5 124.7c-2-2.6 17.4-7.4 17.4-7.4s-1.3 4-1.8 6.8c-.3 2.3-.4 6-.4 6s-12-1.3-15.2-5.4Zm238.4 0c2-2.6-17.4-7.4-17.4-7.4s1.3 4 1.7 6.8c.4 2.3.5 6 .5 6s12-1.3 15.2-5.4Z"/><path class="hwStr1" stroke-width="3" d="M27 106.6c9.7-2.7 23.1-5.4 41.5-7.5a476 476 0 0 1 110.4 0c18.3 2.1 31.8 4.8 41.4 7.5"/><path stroke="#000" stroke-dasharray="9 9" stroke-linecap="round" stroke-linejoin="round" stroke-opacity=".2" stroke-width="2.5" d="M37.5 98.7c8.3-1.8 18.5-3.5 31-5a476 476 0 0 1 110.4 0c12.9 1.5 23.4 3.3 31.8 5.1"/><path class="headwearColorB" d="M172.6 53.5a27 27 0 0 1 10.8 13.8c-8.9-4.8-18-9-27.5-12.4 4.2-4.3 11.5-4.4 16.7-1.4Z"/><path fill="#000" d="M98.6 60a2.1 2.1 0 1 1 0 4.1 2.1 2.1 0 0 1 0-4.2Z"/><path class="headwearColorB" d="M74.8 53.5c5.2-3 12.4-2.9 16.6 1.4C82 58.3 72.8 62.5 64 67.3a26.5 26.5 0 0 1 10.8-13.8Z"/><path class="hwStr1" stroke-width="3" d="M64 67.3c8.8-4.8 18-9 27.4-12.4-4.2-4.3-11.4-4.4-16.6-1.4-5.2 3-8.7 8.3-10.8 13.8Z"/><path class="hwStr1" stroke-width="4" d="M27 106s0 0 0 0a34.4 34.4 0 0 0 14.5-13.7c3-5.5 5.4-11.4 9.2-16.2 1.5-1.8 3.1-3.4 4.9-4.9A27.5 27.5 0 0 1 70.4 46a27.5 27.5 0 0 1 29 3.8 60 60 0 0 1 24-4m97 60.3s0 0 0 0a34.4 34.4 0 0 1-14.6-13.8c-3-5.5-5.3-11.4-9.2-16.2a33 33 0 0 0-4.7-4.7c.3-10.3-5.6-21-15-25.4a27.5 27.5 0 0 0-29 3.8 60 60 0 0 0-24-4"/><path class="hwStr1" stroke-width="3" d="M183.4 67.3c-8.9-4.8-18-9-27.5-12.4 4.2-4.3 11.5-4.4 16.7-1.4a27 27 0 0 1 10.8 13.8Z"/><path fill="#fff" d="M123.7 68c1.1-.9 2.3-1.7 3-2.6.2-.3.4-.6.4-1 0-.6-1-1.3-1.6-1.4-.6-.2-1.2-.1-1.8-.1h-1.9c-.6.2-1.5.9-1.5 1.5 0 .4.2.7.4 1 .7.9 1.8 1.7 3 2.5Zm15.1 3.7c.5 3.2-2 6.3-5 7.6a22 22 0 0 1-9.6 1h-1c-3.3.2-6.7.2-9.7-1-3-1.3-5.5-4.4-5-7.6a7 7 0 0 1 4.3-5.2 11 11 0 0 1 3.8-6.4c2-1.6 4.4-2.5 7-2.6h.2c2.5.1 5 1 7 2.6a11 11 0 0 1 3.7 6.4 7 7 0 0 1 4.3 5.2Z"/><path class="headwearColorB" d="M127 64.4c0 .4-.1.7-.4 1-.6.9-1.8 1.7-3 2.5-1-.8-2.2-1.6-2.9-2.5-.2-.3-.4-.6-.4-1 0-.6.9-1.3 1.5-1.4.7-.2 1.2-.1 1.9-.1h1.8c.6.2 1.6.9 1.6 1.5Z"/><path class="hwStr1" stroke-width="4" d="M96.5 64a2.1 2.1 0 1 1 4.2 0 2.1 2.1 0 0 1-4.2 0Z"/><path class="hwStr1" stroke-width="3" d="M123.5 57.5c-2.5.1-5 1-6.9 2.6a11 11 0 0 0-3.8 6.4 7 7 0 0 0-4.3 5.2c-.5 3.2 2 6.3 5 7.6 3 1.2 6.4 1.2 9.6 1"/><path class="hwStr1" stroke-width="3" d="M123.7 73.7c-2.1.8-4.9-.3-6-2.2m6-8.6h-1.9c-.6.2-1.5.9-1.5 1.5 0 .4.2.7.4 1 .7.9 1.8 1.7 3 2.5"/><path fill="#000" class="hwStr1" stroke-width="4" d="M150.8 64a2.1 2.1 0 1 0-4.2 0 2.1 2.1 0 0 0 4.2 0Z"/><path class="hwStr1" stroke-width="3" d="M123.8 57.5c2.5.1 5 1 7 2.6a11 11 0 0 1 3.7 6.4 7 7 0 0 1 4.3 5.2c.5 3.2-2 6.3-5 7.6a22 22 0 0 1-9.6 1"/><path class="hwStr1" stroke-width="3" d="M123.7 62.9h1.8c.6.2 1.6.9 1.6 1.5 0 .4-.2.7-.5 1-.6.9-1.8 1.7-3 2.5v5.8c2.2.8 5-.3 6-2.2"/></svg>'
            ),
            Headwear.HeadwearVariants.BEAR,
            _getHeadwearColor(bearColor)
        );
    }

    function _getBearStyle(BearColors bearColor) internal pure returns (string memory) {
        (string memory lightColor, string memory baseColor) = _getBearColor(bearColor);
        return
            string.concat(
                '<style>.headwearColorL { fill:',
                lightColor,
                '}.headwearColorB { fill:',
                baseColor,
                '}.hwStr1 {stroke: #000;stroke-linecap: round;stroke-linejoin: round;}</style>'
            );
    }

    function _getBearColor(BearColors bearColor) internal pure returns (string memory, string memory) {
        if (bearColor == BearColors.GREEN) {
            return (LensColors.lightGreen, LensColors.baseGreen);
        } else if (bearColor == BearColors.PURPLE) {
            return (LensColors.lightPurple, LensColors.basePurple);
        } else if (bearColor == BearColors.BLUE) {
            return (LensColors.lightBlue, LensColors.baseBlue);
        } else if (bearColor == BearColors.PINK) {
            return (LensColors.lightPink, LensColors.basePink);
        } else if (bearColor == BearColors.GOLD) {
            return (LensColors.lightGold, LensColors.baseGold);
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(BearColors bearColor) internal pure returns (Headwear.HeadwearColors) {
        if (bearColor == BearColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (bearColor == BearColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (bearColor == BearColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (bearColor == BearColors.PINK) {
            return Headwear.HeadwearColors.PINK;
        } else if (bearColor == BearColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
