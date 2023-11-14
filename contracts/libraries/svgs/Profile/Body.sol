// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Hands} from './Hands.sol';
import {Skin} from './Helpers.sol';
import {BodyJacket} from './Body/BodyJacket.sol';
import {BodyHoodie} from './Body/BodyHoodie.sol';
import {BodyTanktop} from './Body/BodyTanktop.sol';
import {BodyTShirt} from './Body/BodyTShirt.sol';

library Body {
    enum BodyVariants {
        HOODIE,
        JACKET,
        TANKTOP,
        TSHIRT
    }

    enum BodyColors {
        GREEN,
        LIGHT,
        DARK,
        PURPLE,
        BLUE
    }

    function getBody(
        BodyVariants bodyVariant,
        BodyColors bodyColor,
        Hands.HandsVariants handsVariant,
        Hands.HandsColors handsColor
    ) public pure returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getStyleTag(bodyVariant, bodyColor, handsColor),
                _getBody(bodyVariant, handsVariant)
            );
    }

    function _getBody(
        BodyVariants bodyVariant,
        Hands.HandsVariants handsVariant
    ) internal pure returns (string memory) {
        if (bodyVariant == BodyVariants.HOODIE) {
            return BodyHoodie.getBody(handsVariant);
        } else if (bodyVariant == BodyVariants.JACKET) {
            return BodyJacket.getBody(handsVariant);
        } else if (bodyVariant == BodyVariants.TANKTOP) {
            return BodyTanktop.getBody(handsVariant);
        } else if (bodyVariant == BodyVariants.TSHIRT) {
            return BodyTShirt.getBody(handsVariant);
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getStyleTag(
        BodyVariants bodyVariant,
        BodyColors bodyColor,
        Hands.HandsColors handsColor
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<style>.bodyColor1 {fill: ',
                getPrimaryBodyColor(bodyVariant, bodyColor),
                '}.bodyColor2 {fill: ',
                getSecondaryBodyColor(bodyColor),
                '}.handsColor {fill: ',
                Skin.getSkinColor(Skin.SkinColors(uint8(handsColor))),
                '}.bStr1 {stroke: #000;stroke-linecap: round;stroke-miterlimit: 10;}.bStr2 {stroke: #000;stroke-linecap: round;stroke-linejoin: round;}.bStr3 {stroke: #000;stroke-linecap: round;stroke-opacity: .1;stroke-width: 2;}</style>'
            );
    }

    function getPrimaryBodyColor(BodyVariants bodyVariant, BodyColors bodyColor) public pure returns (string memory) {
        if (bodyColor == BodyColors.GREEN) {
            return '#F4FFDC';
        } else if (bodyColor == BodyColors.LIGHT) {
            return '#FFFFFF';
        } else if (bodyColor == BodyColors.DARK) {
            if (bodyVariant == BodyVariants.JACKET) {
                return '#EAEAEA';
            } else {
                return '#575757';
            }
        } else if (bodyColor == BodyColors.PURPLE) {
            if (bodyVariant == BodyVariants.HOODIE) {
                return '#EAD7FF';
            } else {
                return '#F3EAFF';
            }
        } else if (bodyColor == BodyColors.BLUE) {
            if (bodyVariant == BodyVariants.HOODIE) {
                return '#D9E0FF';
            } else {
                return '#ECF0FF';
            }
        } else {
            revert(); // Avoid warnings.
        }
    }

    // We don't need variant because this is only used in Jacket
    function getSecondaryBodyColor(BodyColors bodyColor) public pure returns (string memory) {
        if (bodyColor == BodyColors.GREEN) {
            return '#93A97D';
        } else if (bodyColor == BodyColors.LIGHT) {
            return '#EAEAEA';
        } else if (bodyColor == BodyColors.DARK) {
            return '#575757';
        } else if (bodyColor == BodyColors.PURPLE) {
            return '#EAD7FF';
        } else if (bodyColor == BodyColors.BLUE) {
            return '#D9E0FF';
        } else {
            revert(); // Avoid warnings.
        }
    }
}
