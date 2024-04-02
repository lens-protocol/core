// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from 'contracts/libraries/svgs/Profile/Headwear.sol';
import {LensColors} from 'contracts/libraries/svgs/Profile/LensColors.sol';

library HeadwearBirdie {
    enum BirdieColors {
        GREEN,
        PINK,
        PURPLE,
        BLUE,
        GOLD
    }

    function getBirdie(
        BirdieColors birdieColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getBirdieStyle(birdieColor),
                '<path fill="#fff" d="M130.8 106.3c.3 6.9-2.9 11.5-7.2 13.8a62.3 62.3 0 0 1-18 2.2c-6.4 0-12.2-.5-18-2.2-4.2-2.3-7.4-7-7-13.8.1-6 3.5-11.8 8-15.7a27 27 0 0 1 17-5.9 27 27 0 0 1 17 5.9c4.6 4 8 9.7 8.2 15.7Z"/><path class="headwearColorB" d="M110.6 26.7a6.7 6.7 0 0 1-4.8 6.6h-.3a6.7 6.7 0 0 1-4.7-6.6 7.3 7.3 0 0 1 4.9-6.5c2.7.9 4.8 3.6 4.9 6.5Z"/><path class="headwearColorL" d="M105.8 33.3a14.8 14.8 0 0 1 12.9 7.5c1 1.8 1.4 3.8 1.4 5.8l.2 15.5c9 2.7 17.3 9.5 21.8 17.7a28 28 0 0 1 0 27 30.4 30.4 0 0 1-18.4 13.3c4.2-2.3 7.4-7 7.1-13.8-.2-6-3.6-11.8-8.1-15.7a27 27 0 0 0-17-5.9 27 27 0 0 0-17 5.9c-4.6 4-8 9.7-8.2 15.7-.3 6.9 3 11.5 7.2 13.8l-2.4-.7a30.4 30.4 0 0 1-16-12.7 28 28 0 0 1 0-26.9c4.4-8.2 12.8-15 21.7-17.7l.2-15.5c0-2 .5-4 1.5-5.8a14.4 14.4 0 0 1 12.8-7.5h.3Z"/><path class="hwStr1" stroke-width="4" d="M105.5 33.3h.2m0-13.1a7.3 7.3 0 0 0-5 6.5 6.7 6.7 0 0 0 4.8 6.6"/><path class="hwStr1" stroke-width="3" d="M87.7 120.1c-4.3-2.3-7.5-7-7.2-13.8.2-6 3.6-11.8 8.2-15.7a27 27 0 0 1 17-5.9"/><path class="hwStr1" stroke-width="4" d="M105.8 33.3h-.1m0-13.1c2.7.9 4.8 3.6 4.9 6.5a6.7 6.7 0 0 1-4.8 6.6"/><path class="hwStr1" stroke-width="4" d="M105.7 33.3h-.2a14.4 14.4 0 0 0-12.8 7.5c-1 1.8-1.4 3.8-1.5 5.8v8.9c-.1 3.9-2.7 7.2-6.2 9a38.1 38.1 0 0 0-15.7 15.3 28 28 0 0 0 0 27A30.4 30.4 0 0 0 87.6 120a62.3 62.3 0 0 0 18 2.2m0-89h.1a14.8 14.8 0 0 1 12.9 7.5c1 1.8 1.4 3.8 1.4 5.8l.1 8.9c0 3.9 2.7 7.2 6.1 9A38.2 38.2 0 0 1 142 79.7a28 28 0 0 1 0 27 30.4 30.4 0 0 1-18.4 13.3 62.3 62.3 0 0 1-18 2.2"/><path class="hwStr1" stroke-width="3" d="M123.7 120.1c4.2-2.3 7.4-7 7.1-13.8-.2-6-3.6-11.8-8.1-15.7a27 27 0 0 0-17-5.9"/><path class="headwearColorB" d="m111.8 53.3-.3.3-5.9 3.4-6-3.4-.2-.3c2-1.7 4-3.1 6.2-4.7 2.2 1.6 4.2 3 6.2 4.7Z"/><path class="headwearColorB" d="M105.6 63.6c-2.4-2.7-5-6.5-7.1-9.5l1-.8.2.3 6 3.4 5.8-3.4.3-.3 1 .8c-2.1 3-4.8 6.8-7.2 9.5Z"/><path class="hwStr1" stroke-width="3" d="M108 50.4a4 4 0 0 0-4.8 0l-3.8 2.9v0c-.5.4-.6 1.2-.2 1.8a94 94 0 0 0 6.4 8.5"/><path class="hwStr1" stroke-width="3" d="M103.2 50.4a4 4 0 0 1 4.8 0l3.8 2.9v0c.5.4.6 1.2.2 1.8a93 93 0 0 1-6.4 8.5"/><path class="hwStr1" stroke-width="2.5" d="m99.7 53.6 6 3.4 5.8-3.4"/><circle cx="99.7" cy="45.1" r="2" fill="#000"/><circle cx="111.7" cy="45.1" r="2" fill="#000"/></svg>'
            ),
            Headwear.HeadwearVariants.BIRDIE,
            _getHeadwearColor(birdieColor)
        );
    }

    function _getBirdieStyle(BirdieColors birdieColor) internal pure returns (string memory) {
        (string memory lightColor, string memory baseColor) = _getBirdieColor(birdieColor);
        return
            string.concat(
                '<style>.headwearColorL { fill:',
                lightColor,
                '}.headwearColorB { fill:',
                baseColor,
                '}.hwStr1 {stroke: #000;stroke-linecap: round;stroke-linejoin: round;}</style>'
            );
    }

    function _getBirdieColor(BirdieColors birdieColor) internal pure returns (string memory, string memory) {
        if (birdieColor == BirdieColors.GREEN) {
            return (LensColors.lightGreen, LensColors.baseGreen);
        } else if (birdieColor == BirdieColors.PURPLE) {
            return (LensColors.lightPurple, LensColors.basePurple);
        } else if (birdieColor == BirdieColors.BLUE) {
            return (LensColors.lightBlue, LensColors.baseBlue);
        } else if (birdieColor == BirdieColors.PINK) {
            return (LensColors.lightPink, LensColors.basePink);
        } else if (birdieColor == BirdieColors.GOLD) {
            return (LensColors.lightGold, LensColors.baseGold);
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(BirdieColors birdieColor) internal pure returns (Headwear.HeadwearColors) {
        if (birdieColor == BirdieColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (birdieColor == BirdieColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (birdieColor == BirdieColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (birdieColor == BirdieColors.PINK) {
            return Headwear.HeadwearColors.PINK;
        } else if (birdieColor == BirdieColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
