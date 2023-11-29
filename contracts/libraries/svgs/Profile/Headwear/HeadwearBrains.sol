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
                '<path fill="#fff" d="M151 95.3c.5 3.3-.6 6.7-3.2 8.7a13 13 0 0 1-3.5 2 211 211 0 0 1-38.5 3.6h-.2c-9.7 0-33.8-1.7-38.6-3.6a13 13 0 0 1-3.5-2 9.2 9.2 0 0 1-3.1-8.7l.5-3c.4 1.1 2 2 4.5 2.7a63 63 0 0 0 9.6 1.6 406.9 406.9 0 0 0 30.6 1.3h.2a407.3 407.3 0 0 0 30.6-1.3c3.7-.4 7-1 9.5-1.6 2.5-.7 4.2-1.6 4.5-2.7l.5 3Z"/><path class="headwearColorL" d="M138.7 81.1c4 3.2 6.6 8 7 13l.2.9a62 62 0 0 1-9.5 1.6l-.1-.8a19 19 0 0 0-4.8-8.6l-1 .5c-3.4 1.9-6.1 5-7.3 8.8v1c-7.1.4-13.9.4-17.4.4h-.2c-3.6 0-10.3 0-17.5-.3v-1.1c-1.1-3.7-3.8-7-7.3-8.8l-1-.5a19 19 0 0 0-4.7 8.6l-.1.8c-3.7-.4-7-1-9.6-1.6l.3-1c.3-5 3-9.7 7-12.9h-.1a13.5 13.5 0 0 1 11.8-15v.3c.3 1.8.2 3.7-.2 5.7h.4a17 17 0 0 1 7.7 9.4h.2a21 21 0 0 1 12-.2h2.3a21 21 0 0 1 12 .1h.2c1.4-3.8 4.1-7.3 7.7-9.3h.4a22 22 0 0 1-.2-5.7v-.3a15 15 0 0 1 9 5c2.2 2.8 3.3 6.5 2.8 10Z"/><path class="headwearColorL" d="m136.3 95.8.1.8c-4.1.5-8.7.8-13.2 1v-1.1c1.2-3.7 3.9-7 7.3-8.8l1-.5a19 19 0 0 1 4.8 8.6Zm-30.7-33h.2a20.7 20.7 0 0 1 20.8 3.3h.3v.3a22 22 0 0 0 .2 5.7h-.4c-3.6 2-6.3 5.5-7.7 9.4h-.1a21 21 0 0 0-12.1-.2h-2.2a21 21 0 0 0-12.1.1h-.2c-1.3-3.8-4-7.3-7.7-9.3h-.4c.4-2 .5-3.9.2-5.7v-.3h.4c5.4-4.8 14-6 20.8-3.3ZM88.2 96.5v1c-4.5-.1-9.1-.4-13.2-.9v-.8a19 19 0 0 1 4.9-8.6l1 .5c3.4 1.9 6 5 7.3 8.8Z"/><path class="hwStr1" stroke-width="4" d="M65.7 94a18.5 18.5 0 0 1 9.5-14.6"/><path class="hwStr1" stroke-width="4" d="M72.6 81.1a13.5 13.5 0 0 1 11.8-15h.4c5.4-4.8 14-6 20.8-3.3h-.2m-9.9 7.4c2.9 2.1 6.5 3.2 10 3.1"/><path class="hwStr1" stroke-width="4" d="M84.4 66.4c.3 1.8.2 3.7-.2 5.7l-3.3 3.2m3.7-3.3a17.2 17.2 0 0 1 8.5 13.5m-.6-4.1a21 21 0 0 1 12 0m-6.8 8.8a12 12 0 0 0-3.4 6.5m-6.1-.2c-1.2-3.7-4-7-7.4-8.8"/><path class="hwStr1" stroke-width="4" d="M86.2 82.8a19 19 0 0 0-11.1 13m70.6-1.8a18.5 18.5 0 0 0-9.5-14.6"/><path class="hwStr1" stroke-width="4" d="M138.7 81.1a13.6 13.6 0 0 0-11.8-15h-.3c-5.4-4.8-14.1-6-20.8-3.3h.2m9.8 7.4a16.3 16.3 0 0 1-10 3.1"/><path class="hwStr1" stroke-width="4" d="M126.9 66.4a22 22 0 0 0 .2 5.7l3.3 3.2m-3.7-3.3a17.3 17.3 0 0 0-8.5 13.5"/><path class="hwStr1" stroke-width="4" d="M118.9 81.4a21 21 0 0 0-12.1 0m6.8 8.8c1.8 1.7 3 4 3.4 6.5m6.2-.2c1.2-3.7 3.9-7 7.3-8.8"/><path class="hwStr1" stroke-width="4" d="M125.1 82.8a19 19 0 0 1 11.2 13m-30.5-33V98M61 92.3c.3 1.1 2 2 4.4 2.7a63 63 0 0 0 9.6 1.6 415.4 415.4 0 0 0 30.8 1.3"/><path class="hwStr1" stroke-width="4" d="M150.4 92.3c-.3 1.1-2 2-4.5 2.7a62 62 0 0 1-9.5 1.6 407.3 407.3 0 0 1-30.6 1.3"/><g clip-path="url(#a)"><path fill="#fff" fill-opacity=".3" d="M105.4 47C80.4 47 60 64.8 60 86.4c0 2.3.2 4 .6 6 .4 1.1 2 2 4.5 2.7a63 63 0 0 0 9.6 1.6 415.4 415.4 0 0 0 61.4 0c3.7-.4 7-1 9.5-1.6 2.5-.7 4.2-1.6 4.5-2.7.5-2 .7-3.7.7-6 0-21.6-20.3-39.2-45.4-39.2Z"/></g><path stroke="#000" stroke-width="4" d="M60.9 92.9c-.4-2.1-.6-4.3-.6-6.6 0-21.6 20.3-39.2 45.4-39.2 25 0 45.4 17.6 45.4 39.2 0 2.3-.2 4.5-.7 6.6"/><path class="hwStr1" stroke-width="4" d="M61 92.3c.3 1.1 2 2 4.4 2.7a63 63 0 0 0 9.6 1.6 415.4 415.4 0 0 0 61.4 0c3.7-.4 7-1 9.5-1.6 2.5-.7 4.2-1.6 4.5-2.7"/><path stroke="#000" stroke-opacity=".3" stroke-width="2" d="M62.3 101.2s16.2 3.4 43.4 3.4c27.1 0 43.4-3.4 43.4-3.4"/><defs><clipPath id="a"><path fill="#fff" d="M60 47h90.8v51H60z"/></clipPath></defs></svg>'
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
