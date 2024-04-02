// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from 'contracts/libraries/svgs/Profile/Headwear.sol';
import {LensColors} from 'contracts/libraries/svgs/Profile/LensColors.sol';

library HeadwearLotus {
    enum LotusColors {
        GREEN,
        PINK,
        PURPLE,
        BLUE,
        GOLD
    }

    function getLotus(
        LotusColors lotusColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getLotusStyle(lotusColor),
                '<path class="headwearColorL" d="M169.2 68.6c2 0 3.5 1.8 3.5 3.8A35 35 0 0 1 161.9 97a39.6 39.6 0 0 1-30.8 9.3 28 28 0 0 0 4.8-3.7c2.2-2 2-5 .3-7.4a53.9 53.9 0 0 0-11.6-12 64.7 64.7 0 0 1 44.6-14.6Z"/><path class="headwearColorL" d="M161 49.4c1 6.2-.2 12.8-2.8 18.7l.1.8c-7.3.8-14.4 2.9-21 6l-.3-1a49.6 49.6 0 0 0-26.2-11.4v-.3a89.4 89.4 0 0 1 45.6-16.6 4.4 4.4 0 0 1 4.6 3.8Z"/><path class="headwearColorB" d="m137 74 .3 1a60 60 0 0 0-12.7 8.2 38.1 38.1 0 0 0-18.6-8.8h-.2c-3.7 0-11.3 3.1-18.6 8.8-4.2-3.6-9-6.6-14-8.9l1.6-.4a49.6 49.6 0 0 1 31-11.7h.2a49.6 49.6 0 0 1 31 11.7Z"/><path class="headwearColorL" d="M136.2 95.2c1.7 2.4 1.9 5.4-.3 7.4a32 32 0 0 1-4.8 3.7 47.5 47.5 0 0 1-25.1 6.5h-.2c-8.5 0-17.7-1.8-25.1-6.5a32 32 0 0 1-4.8-3.7c-2.2-2-2-5-.3-7.4a53 53 0 0 1 11.6-12 38.1 38.1 0 0 1 18.6-8.8h.2c3.7 0 11.3 3.1 18.6 8.8a53 53 0 0 1 11.6 12ZM106 39c4.8 0 14.6 8.4 18.6 15-4.8 2.3-9.4 5-13.7 8.2v.3a41.4 41.4 0 0 0-9.9 0v-.3c-4.4-3.1-9-5.9-13.8-8.2 4-6.6 13.8-15 18.6-15h.2Z"/><path class="headwearColorL" d="M101 62.2v.3c-9.6 1-19 5.3-26.2 11.4l-1.6.4A64.6 64.6 0 0 0 53.5 69l.1-.8a34.6 34.6 0 0 1-2.9-18.7 4.4 4.4 0 0 1 4.7-3.8 87.2 87.2 0 0 1 45.5 16.6Z"/><path class="headwearColorL" d="M87.2 83.2a54.3 54.3 0 0 0-11.6 12c-1.7 2.4-1.9 5.4.3 7.4a32 32 0 0 0 4.8 3.7A39.5 39.5 0 0 1 49.9 97a35 35 0 0 1-10.8-24.6c0-2 1.5-3.7 3.5-3.8a66 66 0 0 1 30.6 5.7c5 2.3 9.8 5.3 14 8.9Z"/><path class="hwStr1" stroke-width="4" d="M105.8 112.8c-8.5 0-17.7-1.8-25.1-6.5a32 32 0 0 1-4.8-3.7c-2.2-2-2-5-.3-7.4a53 53 0 0 1 11.6-12 38.1 38.1 0 0 1 18.6-8.8"/><path class="hwStr1" stroke-width="4" d="M87.2 83.2a64.6 64.6 0 0 0-44.6-14.6c-2 0-3.5 1.8-3.5 3.8A35 35 0 0 0 50 97c7.6 7 20.5 11 30.8 9.3m-6-32.3a49.6 49.6 0 0 1 31-11.8m-4.8 0a88.6 88.6 0 0 0-45.6-16.6 4.4 4.4 0 0 0-4.7 3.8c-.9 6.2.3 12.8 2.9 18.7"/><path class="hwStr1" stroke-width="4" d="M87.2 54c4-6.6 13.8-15 18.6-15m0 73.8h.2c8.5 0 17.6-1.8 25.1-6.5a32 32 0 0 0 4.8-3.7c2.2-2 2-5 .3-7.4a53.9 53.9 0 0 0-11.6-12 38.1 38.1 0 0 0-18.6-8.8"/><path class="hwStr1" stroke-width="4" d="M124.6 83.2a64.7 64.7 0 0 1 44.6-14.6c2 0 3.5 1.8 3.5 3.8A35 35 0 0 1 161.9 97a39.6 39.6 0 0 1-30.8 9.3M137 74a49.6 49.6 0 0 0-31-11.8m4.9 0a89.4 89.4 0 0 1 45.5-16.6 4.4 4.4 0 0 1 4.6 3.8c1 6.2-.2 12.8-2.8 18.7"/><path class="hwStr1" stroke-width="4" d="M124.6 54c-4-6.6-13.8-15-18.6-15"/><path class="hwStr1" stroke-opacity=".1" stroke-width="3" d="M105.9 88.3v24.5"/><path class="hwStr1" stroke-opacity=".1" stroke-width="2.5" d="M105.9 51.4v11.5"/><path class="hwStr1" stroke-opacity=".1" stroke-width="3" d="M68.2 60.2s3.7 3.5 6.4 5.3c2.2 1.4 5.9 3.2 5.9 3.2m62.5-8.5s-3.7 3.5-6.4 5.3a62 62 0 0 1-6 3.2m-77 19.4s2.4 6 6.1 10.5c5.4 6.7 17.5 8.8 17.5 8.8m81-19.3s-2.4 6-6.1 10.5c-5.4 6.7-17.5 8.8-17.5 8.8"/></svg>'
            ),
            Headwear.HeadwearVariants.LOTUS,
            _getHeadwearColor(lotusColor)
        );
    }

    function _getLotusStyle(LotusColors lotusColor) internal pure returns (string memory) {
        (string memory lightColor, string memory baseColor) = _getLotusColor(lotusColor);
        return
            string.concat(
                '<style>.headwearColorL { fill:',
                lightColor,
                '}.headwearColorB { fill:',
                baseColor,
                '}.hwStr1 {stroke: #000;stroke-linecap: round;stroke-linejoin: round;}</style>'
            );
    }

    function _getLotusColor(LotusColors lotusColor) internal pure returns (string memory, string memory) {
        if (lotusColor == LotusColors.GREEN) {
            return (LensColors.lightGreen, LensColors.baseGreen);
        } else if (lotusColor == LotusColors.PURPLE) {
            return (LensColors.lightPurple, LensColors.basePurple);
        } else if (lotusColor == LotusColors.BLUE) {
            return (LensColors.lightBlue, LensColors.baseBlue);
        } else if (lotusColor == LotusColors.PINK) {
            return (LensColors.lightPink, LensColors.basePink);
        } else if (lotusColor == LotusColors.GOLD) {
            return (LensColors.lightGold, LensColors.baseGold);
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(LotusColors lotusColor) internal pure returns (Headwear.HeadwearColors) {
        if (lotusColor == LotusColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (lotusColor == LotusColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (lotusColor == LotusColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (lotusColor == LotusColors.PINK) {
            return Headwear.HeadwearColors.PINK;
        } else if (lotusColor == LotusColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
