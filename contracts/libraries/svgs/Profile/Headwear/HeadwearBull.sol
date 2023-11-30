// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from 'contracts/libraries/svgs/Profile/Headwear.sol';
import {LensColors} from 'contracts/libraries/svgs/Profile/LensColors.sol';

library HeadwearBull {
    enum BullColors {
        GREEN,
        PINK,
        PURPLE,
        BLUE,
        GOLD
    }

    function getBull(
        BullColors bullColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="250" height="335" x="-18.6" fill="none">',
                _getBullStyle(bullColor),
                '<path class="headwearColorL" d="M203.8 88.7s11.1 15 16.5 17.4c-9.6-3.6-23-5.1-41.4-8-18-2.8-36.8-3.7-55.2-3.7-18.5 0-37.2.9-55.2 3.7-18.4 2.9-31.8 4.4-41.5 8 5.4-2.4 16.7-17.6 16.7-17.6S35.2 76.2 41 69c6-7.6 20.7-2.9 20.7-2.9S91.8 49.6 104.9 48a141 141 0 0 1 37.5 0c13.1 1.7 42 17.8 42 17.8s16.5-3.8 21.8 3c6.9 8.6-2.4 20-2.4 20Z"/><path class="headwearColorL" d="M241.2 115.7c2.6 2.8 4.3 6.6 3.6 10.4.5-3.3-2.7-5.8-5.7-7.3-8.7-4.6-18.3-3.4-27.9-5.6-28.8-6.5-61-10-87.5-10-26.6 0-58.8 3.5-87.6 10-9.6 2.2-19.3 2.6-28 7.1-3 1.5-6 2.6-5.5 5.8-.8-3.7.7-7.9 3.3-10.6 2.5-2.6 9-4.6 21-8.7 9.7-3.3 23.2-4.8 41.6-7.4a374.7 374.7 0 0 1 110.4 0c18.3 2.6 31.9 3.8 41.6 7 12 4.2 18.2 6.8 20.7 9.3Z"/><path class="hwStr1" stroke-width="4" d="M123.7 104.5c-26.6 0-58.8 2.9-87.6 7.9a140 140 0 0 0-27.9 7.1c-3 1.2-6.1 3.1-5.6 5.7.3 1.5 5 5.3 19.2 7.2M27 106s0 0 0 0a34.4 34.4 0 0 0 16.5-17.6m80.2 16.1c26.5 0 58.7 2.9 87.5 7.9a140 140 0 0 1 28 7.1c2.9 1.2 6 3.1 5.6 5.7-.4 1.5-5 5.3-19.3 7.2"/><path class="hwStr1" stroke-width="4" d="M2.6 123.1s0 0 0 0c-.8-3 1-6.2 3.6-8.4 2.5-2 8.7-5.3 20.8-8.6m217.8 17s0 0 0 0c.7-3-1-6.2-3.6-8.4-2.5-2-8.7-5.3-20.9-8.6m.1-.1s0 0 0 0A34.4 34.4 0 0 1 204 88.7"/><path class="headwearColorL" d="M4.5 124.7c-2-2.6 17.4-7.4 17.4-7.4s-1.3 4-1.8 6.8c-.3 2.3-.4 6-.4 6s-12-1.3-15.2-5.4Zm238.4 0c2-2.6-17.4-7.4-17.4-7.4s1.3 4 1.7 6.8c.4 2.3.5 6 .5 6s12-1.3 15.2-5.4Z"/><path fill="#000" fill-opacity=".3" d="M4.5 124.7c-2-2.6 17.4-7.4 17.4-7.4s-1.3 4-1.8 6.8c-.3 2.3-.4 6-.4 6s-12-1.3-15.2-5.4Zm238.4 0c2-2.6-17.4-7.4-17.4-7.4s1.3 4 1.7 6.8c.4 2.3.5 6 .5 6s12-1.3 15.2-5.4Z"/><path class="hwStr1" stroke-width="3" d="M27 106.6c9.7-2.7 23.1-5.4 41.5-7.5a476 476 0 0 1 110.4 0c18.3 2.1 31.8 4.8 41.4 7.5"/><path stroke="#000" stroke-dasharray="9 9" stroke-linecap="round" stroke-linejoin="round" stroke-opacity=".2" stroke-width="2.5" d="M37.5 98.7c8.3-1.8 18.5-3.5 31-5a476 476 0 0 1 110.4 0c12.9 1.5 23.4 3.3 31.8 5.1"/><path fill="#fff" d="m184.4 66.2-.4.7c-5 1.4-10.7.7-15.2-1.9a19 19 0 0 1-9.3-12.5 34.3 34.3 0 0 0 16.9-30 35 35 0 0 1 8 43.7ZM71 22.5a34.4 34.4 0 0 0 16.8 30A19 19 0 0 1 78.6 65a20.4 20.4 0 0 1-15.2 2l-.4-.8c-4-7.1-5.3-15.3-4-23.1a35 35 0 0 1 12-20.6Z"/><path class="hwStr1" stroke-width="4" d="M88.7 51.8a98 98 0 0 1 34.7-5.3M63 66.2l.4.7c5 1.4 10.6.7 15.2-1.9 4.5-2.6 8-7 9.2-12.5l-1-.6A34.4 34.4 0 0 1 71 22.5a35 35 0 0 0-8 43.7Z"/><path class="hwStr1" stroke-width="3" d="M71.6 59a25 25 0 0 0 11.3-9m-12.2-6.7c1.7 0 3.5-.4 5-1.3M64 43.6h1.7"/><path class="hwStr1" stroke-width="4" d="M158.6 51.8a98 98 0 0 0-34.7-5.3m35.6 6a34.3 34.3 0 0 0 16.9-30 35 35 0 0 1 7.6 44.4c-5 1.4-10.7.7-15.2-1.9a19 19 0 0 1-9.3-12.5Z"/><path class="hwStr1" stroke-width="3" d="M175.7 59a24.8 24.8 0 0 1-11.3-9m12.3-6.7a10 10 0 0 1-5.1-1.3m11.7 1.6h-1.6"/><path fill="#000" class="hwStr1" stroke-width="4" d="M96.7 64a2.1 2.1 0 1 1 4.2 0 2.1 2.1 0 0 1-4.2 0Zm54 0a2.1 2.1 0 1 0-4.2 0 2.1 2.1 0 0 0 4.2 0Z"/><path fill="#fff" d="M133.9 66.9c2.2 1.2 3.2 4.1 2.6 6.6a8.4 8.4 0 0 1-5 5.4c-2.4 1-5.2.7-7.8.7-2.7 0-5.5.3-7.8-.7-2.4-1-4.4-3-5-5.4-.7-2.5.3-5.4 2.6-6.6 1.5-.8 3.3-.8 5-.7 1.7.2 3.3.3 5 .3h.3a50 50 0 0 0 5-.3c1.8-.1 3.6-.1 5 .7Zm-4.3 7.5c.2-.2.3-.4.3-.7a2 2 0 0 0-.2-.7l-.5-1c-.3-.2-.6-.3-1-.3-.3 0-.5.3-.6.5v.7a2 2 0 0 0 1 1.4c.2.2.7.3 1 0Zm-9.8-1.5v-.7c-.2-.2-.4-.5-.7-.5-.4 0-.7.1-1 .4-.2.2-.3.6-.4.9a2 2 0 0 0-.2.7c0 .3 0 .5.2.7.3.2.8.1 1.1 0 .5-.4 1-1 1-1.5Z"/><path class="hwStr1" stroke-width="3" d="M123.6 66.5a50 50 0 0 1-5.1-.3 8.6 8.6 0 0 0-5 .7c-2.3 1.2-3.3 4.1-2.6 6.6a8.4 8.4 0 0 0 5 5.4c2.3 1 5.1.7 7.8.7"/><path class="hwStr1" stroke-width="3" d="M119 71.7a1 1 0 0 0-.8.4c-.3.2-.4.6-.5.9a2 2 0 0 0-.2.7c0 .3 0 .5.2.7.3.2.8.1 1.1 0 .5-.4 1-1 1-1.5v-.7c-.2-.2-.4-.5-.7-.5Zm4.8-5.2a50 50 0 0 0 5-.3c1.8-.1 3.6-.1 5 .7 2.3 1.2 3.3 4.1 2.7 6.6a8.4 8.4 0 0 1-5 5.4c-2.4 1-5.2.7-7.8.7"/><path class="hwStr1" stroke-width="3" d="M128.3 71.7c.3 0 .6.1.9.4l.5.9.2.7c0 .3 0 .5-.3.7-.3.2-.8.1-1 0-.6-.4-1-1-1-1.5v-.7c.1-.2.3-.5.7-.5Z"/><path class="hwStr1" stroke-width="4" d="M43.3 88.2S33 77.2 40.8 69c7.6-8 15.2-2.4 21.2-3m142.3 22.1s10-11 2.3-19c-7.6-8.2-15.3-2.5-21.3-3.2"/><path class="headwearColorB" d="M46 72.8a8 8 0 0 1 8.6-2.4c-3.7 3.3-6.7 7-9 11.3a7.5 7.5 0 0 1 .4-8.9Z"/><path class="hwStr1" stroke-width="2.5" d="M45.7 81.7a40 40 0 0 1 8.9-11.3 8 8 0 0 0-8.6 2.4 7.4 7.4 0 0 0-.3 8.9Z"/><path class="headwearColorB" d="M201.3 72.8a8 8 0 0 0-8.5-2.4c3.6 3.3 6.6 7 8.9 11.3a7.5 7.5 0 0 0-.4-8.9Z"/><path class="hwStr1" stroke-width="2.5" d="M201.7 81.7c-2.3-4.2-5.3-8-9-11.3 3-1 6.6 0 8.6 2.4s2.3 6.2.4 8.9Z"/></svg>'
            ),
            Headwear.HeadwearVariants.BULL,
            _getHeadwearColor(bullColor)
        );
    }

    function _getBullStyle(BullColors bullColor) internal pure returns (string memory) {
        (string memory lightColor, string memory baseColor) = _getBullColor(bullColor);
        return
            string.concat(
                '<style>.headwearColorL { fill:',
                lightColor,
                '}.headwearColorB { fill:',
                baseColor,
                '}.hwStr1 {stroke: #000;stroke-linecap: round;stroke-linejoin: round;}</style>'
            );
    }

    function _getBullColor(BullColors bullColor) internal pure returns (string memory, string memory) {
        if (bullColor == BullColors.GREEN) {
            return (LensColors.lightGreen, LensColors.baseGreen);
        } else if (bullColor == BullColors.PURPLE) {
            return (LensColors.lightPurple, LensColors.basePurple);
        } else if (bullColor == BullColors.BLUE) {
            return (LensColors.lightBlue, LensColors.baseBlue);
        } else if (bullColor == BullColors.PINK) {
            return (LensColors.lightPink, LensColors.basePink);
        } else if (bullColor == BullColors.GOLD) {
            return (LensColors.lightGold, LensColors.baseGold);
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(BullColors bullColor) internal pure returns (Headwear.HeadwearColors) {
        if (bullColor == BullColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (bullColor == BullColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (bullColor == BullColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (bullColor == BullColors.PINK) {
            return Headwear.HeadwearColors.PINK;
        } else if (bullColor == BullColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
