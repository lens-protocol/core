// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from '../Headwear.sol';

library HeadwearGlasses {
    enum GlassesColors {
        GREEN,
        PURPLE,
        BLUE,
        GOLD
    }

    function getGlasses(
        GlassesColors glassesColor
    ) internal pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getGlassesStyle(glassesColor),
                '<path class="glassesColor1" d="M163.7 84.8a52.2 52.2 0 0 1-2 19.5c-1 2.6-2.1 5.2-3.6 7.5a31.5 31.5 0 0 1-22.3 14.6c-9.1 1.1-19-3-23.8-10.8-1.9-3-3.4-7.7-7-7.7s-5.1 4.6-7 7.7a25 25 0 0 1-23.8 10.8c-9.1-1-17.4-6.9-22.3-14.6a42.8 42.8 0 0 1-5.4-16c-.5-3.7-.5-7.4-.2-11h117.4ZM147 111.9c5.1-5 7.1-12.4 7.9-19.5-14.4-.4-29-.5-43.5-.5a24.3 24.3 0 0 0 11.4 22.7c7.5 4.3 18 3.4 24.2-2.7Zm-60 2.7c7.6-4.3 12-13.3 11.4-22.7-14.5 0-29.1 0-43.5.5.8 7.1 2.8 14.5 8 19.5 6.2 6 16.6 7 24.1 2.7Z"/><path fill="#000" fill-opacity=".5" d="M155 92.4a31.3 31.3 0 0 1-8 19.5c-6.2 6-16.6 7-24.1 2.7A24.3 24.3 0 0 1 111.5 92c14.6 0 29.1 0 43.5.5Zm-56.5-.5c.6 9.4-3.8 18.4-11.4 22.7A20.7 20.7 0 0 1 63 112c-5.1-5-7.1-12.4-7.9-19.5 14.4-.4 29-.5 43.5-.5Z"/><path class="glassesColor1" d="m49.6 101.3-.9.6-38.1 12.2c-1.3.5-2.6.9-4 .8-1.3 0-2.7-.7-3.3-1.9-.7-1.4 0-3.2 1-4.3a13 13 0 0 1 4.2-2.2c11.6-4.3 23.3-8.3 35-12.1l1.8-.8c1.2 2.7 2.6 5.3 4.3 7.7Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M46 93.8a971.8 971.8 0 0 0-37.5 12.7c-1.5.5-3 1.1-4.1 2.2-1.1 1.1-1.8 3-1 4.3.5 1.2 2 1.8 3.3 1.9 1.3 0 2.6-.3 3.9-.8l37.1-11.8"/><path class="glassesColor1" d="m160.4 101.3.9.6 38.1 12.2c1.3.5 2.6.9 4 .8 1.3 0 2.7-.7 3.3-1.9.7-1.4 0-3.2-1-4.3a11.2 11.2 0 0 0-4.2-2.2 939.7 939.7 0 0 0-35-12.1l-1.8-.8a42.8 42.8 0 0 1-4.3 7.7Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M164 93.8a1069 1069 0 0 1 37.5 12.7c1.5.5 3 1.1 4.1 2.2 1.1 1.1 1.8 3 1 4.3-.5 1.2-2 1.8-3.3 1.9-1.3 0-2.6-.3-3.9-.8l-37.1-11.8M105 84.8H46.3a52.2 52.2 0 0 0 2.1 19.5 31.4 31.4 0 0 0 25.8 22.1c9.1 1.1 19-3 23.8-10.8 1.9-3 3.4-7.7 7-7.7"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M98.5 91.9c-14.5 0-29.1 0-43.5.5.8 7.1 2.8 14.5 8 19.5 6.2 6 16.6 7 24.1 2.7 7.6-4.3 12-13.3 11.4-22.7Zm6.5-7.1h58.7a52.2 52.2 0 0 1-2 19.5c-1 2.6-2.1 5.2-3.6 7.5a31.5 31.5 0 0 1-22.3 14.6c-9.1 1.1-19-3-23.8-10.8-1.9-3-3.4-7.7-7-7.7"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M111.5 91.9c14.6 0 29.1 0 43.5.5a31.3 31.3 0 0 1-8 19.5c-6.2 6-16.6 7-24.1 2.7A24.3 24.3 0 0 1 111.5 92Z"/></svg>'
            ),
            Headwear.HeadwearVariants.GLASSES,
            _getHeadwearColor(glassesColor)
        );
    }

    function _getGlassesStyle(GlassesColors glassesColor) internal pure returns (string memory) {
        (string memory primaryColor, string memory secondaryColor) = _getGlassesColor(glassesColor);
        return
            string.concat(
                '<style>.glassesColor1 { fill:',
                primaryColor,
                '}.glassesColor2 { fill:',
                secondaryColor,
                '}</style>'
            );
    }

    function _getGlassesColor(GlassesColors glassesColor) internal pure returns (string memory, string memory) {
        if (glassesColor == GlassesColors.GREEN) {
            return ('#F4FFDC', '#A0D170');
        } else if (glassesColor == GlassesColors.PURPLE) {
            return ('#F9F4FF', '#EAD7FF');
        } else if (glassesColor == GlassesColors.BLUE) {
            return ('#F4F6FF', '#D9E0FF');
        } else if (glassesColor == GlassesColors.GOLD) {
            return ('#FFEE93', '#FFCD3D');
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(GlassesColors glassesColor) internal pure returns (Headwear.HeadwearColors) {
        if (glassesColor == GlassesColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (glassesColor == GlassesColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (glassesColor == GlassesColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (glassesColor == GlassesColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
