// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from 'contracts/libraries/svgs/Profile/Headwear.sol';
import {LensColors} from 'contracts/libraries/svgs/Profile/LensColors.sol';

library HeadwearBrains {
    enum BrainsColors {
        GREEN,
        PINK,
        PURPLE,
        BLUE,
        GOLD
    }

    function getBrains(
        BrainsColors brainsColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getBrainsStyle(brainsColor),
                '<path fill="#fff" d="M150.3 95.3c.5 3.3-.6 6.7-3.2 8.7a13 13 0 0 1-3.4 2 213 213 0 0 1-38.6 3.6h-.2c-9.7 0-33.8-1.7-38.6-3.6a13 13 0 0 1-3.4-2 9.2 9.2 0 0 1-3.2-8.7l.6-3c.3 1.1 2 2 4.5 2.7a63 63 0 0 0 9.5 1.6A406.9 406.9 0 0 0 105 98h.2a407.3 407.3 0 0 0 30.6-1.3c3.7-.4 7-1 9.5-1.6 2.5-.7 4.2-1.6 4.6-2.7l.5 3Z"/><path class="headwearColorL" d="M138 81.1c4 3.2 6.6 8 7 13l.2.9a62 62 0 0 1-9.5 1.6v-.8a19 19 0 0 0-4.9-8.6l-1 .5c-3.4 1.9-6.1 5-7.3 8.8v1c-7.1.4-13.8.4-17.4.4h-.2c-3.6 0-10.3 0-17.5-.3v-1.1a15 15 0 0 0-7.2-8.8l-1-.5a19 19 0 0 0-4.8 8.6v.8c-3.8-.4-7.2-1-9.6-1.6l.2-1c.4-5 3-9.7 7-12.9a13.5 13.5 0 0 1 11.7-15v.3c.3 1.8.2 3.7-.2 5.7h.4a17 17 0 0 1 7.7 9.4h.2a21 21 0 0 1 12.1-.2h2.2a21 21 0 0 1 12.1.1h.2c1.3-3.8 4-7.3 7.7-9.3h.4c-.4-2-.5-3.9-.3-5.7v-.3c3.7.6 6.9 2.4 9 5a14 14 0 0 1 2.9 10Z"/><path class="headwearColorL" d="m135.6 95.8.1.8c-4 .5-8.7.8-13.1 1v-1.1a15 15 0 0 1 7.2-8.8l1-.5a19 19 0 0 1 4.8 8.6Zm-30.7-33h.2a20.7 20.7 0 0 1 20.8 3.3h.4v.3c-.3 1.8-.2 3.7.2 5.7h-.4a17 17 0 0 0-7.7 9.4h-.2a21 21 0 0 0-12.1-.2h-2.2a21 21 0 0 0-12.1.1h-.2c-1.3-3.8-4-7.3-7.7-9.3h-.4c.4-2 .5-3.9.3-5.7v-.3h.3c5.4-4.9 14.1-6 20.8-3.3ZM87.5 96.5v1c-4.5-.1-9-.4-13.2-.9v-.8a19 19 0 0 1 4.9-8.6l1 .5c3.4 1.9 6 5 7.3 8.8Z"/><path class="hwStr1" stroke-width="4" d="M65 94a18.5 18.5 0 0 1 9.5-14.6"/><path class="hwStr1" stroke-width="4" d="M72 81.1a13.5 13.5 0 0 1 11.7-15h.4c5.4-4.9 14.1-6 20.8-3.3h-.2m-9.8 7.4a16 16 0 0 0 10 3.1"/><path class="hwStr1" stroke-width="4" d="M83.8 66.4c.2 1.8.1 3.7-.3 5.7l-3.3 3.2M84 72a17.2 17.2 0 0 1 8.5 13.5"/><path class="hwStr1" stroke-width="4" d="M91.8 81.4a21 21 0 0 1 12.1 0M97 90.2a12 12 0 0 0-3.4 6.5m-6.1-.2c-1.2-3.7-3.9-7-7.3-8.8"/><path class="hwStr1" stroke-width="4" d="M85.5 82.8a19 19 0 0 0-11.1 13M145 94a18.5 18.5 0 0 0-9.5-14.6"/><path class="hwStr1" stroke-width="4" d="M138 81.1a13.6 13.6 0 0 0-12.1-15c-5.4-4.9-14-6-20.8-3.3h.2m9.8 7.4a16 16 0 0 1-10 3.1"/><path class="hwStr1" stroke-width="4" d="M126.2 66.4c-.2 1.8-.1 3.7.3 5.7l3.3 3.2M126 72a17.3 17.3 0 0 0-8.5 13.5"/><path class="hwStr1" stroke-width="4" d="M118.2 81.4a21 21 0 0 0-12.1 0m6.9 8.8c1.7 1.7 3 4 3.4 6.5m6.1-.2c1.2-3.7 3.9-7 7.3-8.8"/><path class="hwStr1" stroke-width="4" d="M124.5 82.8a19 19 0 0 1 11.1 13m-30.5-33V98"/><path fill="#000" fill-rule="evenodd" d="M149.8 90.3a2 2 0 0 1 1.9 1.5v.4h.1v.4h.1v.3l.1.1.1.3v.3l.2.2c.6 4.2-.7 8.5-3.8 11.3a14 14 0 0 1-4 2.5c-5.2 2.2-14.3 4.5-39.4 4.5-25.1 0-34.4-2.3-39.5-4.5a12.4 12.4 0 0 1-7.4-15.2l.1-.5a2 2 0 0 1 3.8-.2l.6.5 2.6 1c2.3.6 5.6 1.1 9.2 1.5a413.5 413.5 0 0 0 48 1 171.8 171.8 0 0 0 22.2-2.5l2.6-1 .6-.5a2 2 0 0 1 1.9-1.3ZM61.6 96a8.3 8.3 0 0 0 5.5 7.9c4.4 1.8 13 4.1 38 4.1s33.4-2.3 37.8-4.1c1-.5 2-1.1 3-1.9a8.3 8.3 0 0 0 2.5-6l-2.6.9-.6-2 .6 2c-2.7.7-6.1 1.3-9.8 1.7-4.2.5-8.9.8-13.3 1l-.1-2v2a409.2 409.2 0 0 1-35.2 0v-2 2c-4.5-.2-9.1-.5-13.3-1l.2-2-.2 2A64.8 64.8 0 0 1 61.6 96Z" clip-rule="evenodd"/><g clip-path="url(#a)"><path fill="#fff" fill-opacity=".3" d="M104.7 47c-25 0-45.4 17.7-45.4 39.3 0 2.3.3 4 .7 6 .3 1.1 2 2 4.5 2.7a63 63 0 0 0 9.5 1.6 415.4 415.4 0 0 0 61.4 0c3.8-.4 7-1 9.6-1.6 2.5-.7 4.1-1.6 4.5-2.7.4-2 .6-3.7.6-6 0-21.6-20.3-39.2-45.4-39.2Z"/></g><path stroke="#000" stroke-width="4" d="M60.2 92.9c-.4-2.1-.6-4.3-.6-6.6 0-21.6 20.3-39.2 45.4-39.2 25 0 45.4 17.6 45.4 39.2 0 2.3-.2 4.5-.6 6.6"/><path class="hwStr1" stroke-width="4" d="M60.3 92.3c.3 1.1 2 2 4.5 2.7a63 63 0 0 0 9.5 1.6 415.4 415.4 0 0 0 61.4 0c3.7-.4 7-1 9.5-1.6 2.5-.7 4.2-1.6 4.6-2.7"/><path stroke="#000" stroke-opacity=".3" stroke-width="2" d="M61.6 101.2s16.2 3.4 43.4 3.4 43.4-3.4 43.4-3.4"/><defs><clipPath id="a"><path fill="#fff" d="M59.3 47h90.8v51H59.3z"/></clipPath></defs></svg>'
            ),
            Headwear.HeadwearVariants.BRAINS,
            _getHeadwearColor(brainsColor)
        );
    }

    function _getBrainsStyle(BrainsColors brainsColor) internal pure returns (string memory) {
        return
            string.concat(
                '<style>.headwearColorL { fill:',
                _getBrainsColor(brainsColor),
                '}.hwStr1 {stroke: #000;stroke-linecap: round;stroke-linejoin: round;}</style>'
            );
    }

    function _getBrainsColor(BrainsColors brainsColor) internal pure returns (string memory) {
        if (brainsColor == BrainsColors.GREEN) {
            return LensColors.lightGreen;
        } else if (brainsColor == BrainsColors.PURPLE) {
            return LensColors.lightPurple;
        } else if (brainsColor == BrainsColors.BLUE) {
            return LensColors.lightBlue;
        } else if (brainsColor == BrainsColors.PINK) {
            return LensColors.lightPink;
        } else if (brainsColor == BrainsColors.GOLD) {
            return LensColors.lightGold;
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(BrainsColors brainsColor) internal pure returns (Headwear.HeadwearColors) {
        if (brainsColor == BrainsColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (brainsColor == BrainsColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (brainsColor == BrainsColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (brainsColor == BrainsColors.PINK) {
            return Headwear.HeadwearColors.PINK;
        } else if (brainsColor == BrainsColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
