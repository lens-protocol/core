// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from '../Headwear.sol';

library HeadwearCrown {
    enum CrownColors {
        GREEN,
        PURPLE,
        BLUE,
        GOLD
    }

    function getCrown(
        CrownColors crownColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getCrownStyle(crownColor),
                '<path class="crownColor1" d="M54.4 56.4a6 6 0 0 1-3.4 8 6 6 0 0 1-7.2-3.5 6 6 0 0 1 3-7.3 6 6 0 0 1 7.6 2.8Zm28.9 4.7v.1c-1.8.7-4 .2-5.4-1.2a5 5 0 0 1-.9-5.6 5 5 0 0 1 5-2.7 5 5 0 0 1 4.1 3.8c.4 2-.3 4.7-2.7 5.7Zm25.6-20.3a6.9 6.9 0 0 1 2.5 7.3c-.7 2.4-3 4.2-6 4.6l-.9.1a6.9 6.9 0 0 1-6-4.9c-.7-2.6.4-5.7 2.7-7.2a6.8 6.8 0 0 1 7.7 0Zm17.7 20.4c-2.4-1-3.1-3.7-2.7-5.7a5 5 0 0 1 4.1-3.8c2-.2 4 1 5 2.7a5 5 0 0 1-.9 5.6 5.1 5.1 0 0 1-5.4 1.2h-.1Zm36.5-7.6a6 6 0 0 1 3.1 7.3 6 6 0 0 1-7.2 3.4 5.8 5.8 0 0 1-3.4-7.9 6 6 0 0 1 7.5-2.8Z"/><path fill="#fff" d="M131.3 94.7a5 5 0 0 1-2.7 5.2 5 5 0 0 1-5.8-1.2 5.2 5.2 0 0 1-.7-5.9c.8-1.5 2.6-2.5 5-2.2 2.1.2 4 2 4.2 4Z"/><path class="crownColor2" d="M112.8 91c-2.4 2.6-5.2 4.8-7.8 7.1-2.6-2.3-5.4-4.5-7.8-7.1 2.3-3.6 5.3-6.8 7.8-10.2 2.5 3.4 5.5 6.6 7.8 10.2Z"/><path fill="#fff" d="M87.9 92.8c1 1.8.8 4.3-.6 5.9a5.2 5.2 0 0 1-5.9 1.2 5 5 0 0 1-2.7-5.2 5 5 0 0 1 4.2-4.1c2.4-.3 4.2.7 5 2.2Z"/><path class="crownColor1" d="M105.6 53.6a97.7 97.7 0 0 0 9.6 22.5c1.2 2.1 2.6 4.3 4.6 5.8 2 1.5 4.6 2.2 7.1 2.3 4 .2 7.8-1 11.2-3 3.4-1.9 6.5-4.4 9.5-6.8 3.7-3.1 7.5-6.2 11-9.6-4 14-9.2 27.5-15.9 40.6a187.2 187.2 0 0 1-37.1 2.5h-1.2c-13.3 0-24.7 0-37.1-2.5a229.4 229.4 0 0 1-16-40.6c3.6 3.4 7.4 6.5 11.1 9.6 3 2.4 6 5 9.5 6.8 3.4 2 7.3 3.2 11.2 3 2.5 0 5-.8 7-2.3 2-1.5 3.5-3.7 4.7-5.8 4-7 7.2-14 9.6-22.5l.1-.8h1v.8Zm23 46.3a5 5 0 0 0 2.7-5.2 5 5 0 0 0-4.2-4.1c-2.4-.3-4.2.7-5 2.2-1 1.8-.8 4.3.7 5.9 1.4 1.6 3.8 2 5.8 1.2ZM105 98c2.6-2.3 5.4-4.5 7.8-7.1-2.3-3.6-5.3-6.8-7.8-10.2-2.5 3.4-5.5 6.6-7.8 10.2 2.4 2.6 5.2 4.8 7.8 7.1Zm-17.7.6c1.4-1.6 1.6-4 .6-5.9-.8-1.5-2.6-2.5-5-2.2a5 5 0 0 0-4.2 4 5 5 0 0 0 2.7 5.3c2 .9 4.4.4 5.9-1.2Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M104.4 53.6a98.2 98.2 0 0 1-9.6 22.5 18.4 18.4 0 0 1-4.6 5.8c-2 1.5-4.6 2.2-7.1 2.3-4 .2-7.8-1-11.2-3-3.4-1.9-6.5-4.4-9.5-6.8-3.7-3.1-7.5-6.2-11-9.6 4 14 9.2 27.5 15.9 40.6C79.7 108 91 108 104.4 108"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M83.1 71.7a62 62 0 0 0 1.2-8.5s0 0 0 0h.1c2.4 1.6 6 3.6 8.8 4.3m-9.9-5.3c-1.8.7-4 .2-5.4-1.2a5 5 0 0 1-.9-5.6 5 5 0 0 1 5-2.7 5 5 0 0 1 4.1 3.8c.4 2-.3 4.7-2.7 5.7 0 0 0 0 0 0h0ZM51 64.3a6 6 0 0 1-7.2-3.4 6 6 0 0 1 3-7.3 6 6 0 0 1 7.6 2.8 6 6 0 0 1-3.4 8Zm53.5-11.5a6.9 6.9 0 0 1-6-4.9c-.7-2.6.4-5.7 2.7-7.2a6.8 6.8 0 0 1 7.7 0 6.9 6.9 0 0 1 2.5 7.4c-.7 2.4-3 4.2-6 4.6l-.9.1ZM82.9 90.6a5 5 0 0 0-4.2 4 5 5 0 0 0 2.7 5.3c2 .9 4.4.4 5.9-1.2 1.4-1.6 1.6-4 .6-5.9-.8-1.5-2.6-2.5-5-2.2Zm22.1-9.8c-2.5 3.4-5.5 6.6-7.8 10.2 2.4 2.6 5.2 4.8 7.8 7.1m.6-44.5a97.7 97.7 0 0 0 9.6 22.5c1.2 2.1 2.6 4.3 4.6 5.8 2 1.5 4.6 2.2 7.1 2.3 4 .2 7.8-1 11.2-3 3.4-1.9 6.5-4.4 9.5-6.8 3.7-3.1 7.5-6.2 11-9.6-4 14-9.2 27.5-15.9 40.6a187.2 187.2 0 0 1-37.1 2.5"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M125.6 63.2a30 30 0 0 1-8.7 4.2m10 4.3a62 62 0 0 1-1.2-8.5s0 0 0 0h-.1m1.1-1c1.8.7 4 .2 5.4-1.2a5 5 0 0 0 .9-5.6 5 5 0 0 0-5-2.7 5 5 0 0 0-4.1 3.8c-.4 2 .3 4.7 2.7 5.7h0v0s0 0 0 0h0Zm32.3 2.1a6 6 0 0 0 7.2-3.4 6 6 0 0 0-3-7.3 6 6 0 0 0-7.6 2.8 5.8 5.8 0 0 0 3.4 8Zm-31.9 26.3c2.1.2 4 2 4.2 4a5 5 0 0 1-2.7 5.3 5 5 0 0 1-5.8-1.2 5.2 5.2 0 0 1-.7-5.9c.8-1.5 2.6-2.5 5-2.2ZM105 80.8c2.5 3.4 5.5 6.6 7.8 10.2-2.4 2.6-5.2 4.8-7.8 7.1"/></svg>'
            ),
            Headwear.HeadwearVariants.CROWN,
            _getHeadwearColor(crownColor)
        );
    }

    function _getCrownStyle(CrownColors crownColor) internal pure returns (string memory) {
        (string memory primaryColor, string memory secondaryColor) = _getCrownColor(crownColor);
        return
            string.concat(
                '<style>.crownColor1 { fill:',
                primaryColor,
                '}.crownColor2 { fill:',
                secondaryColor,
                '}</style>'
            );
    }

    function _getCrownColor(CrownColors crownColor) internal pure returns (string memory, string memory) {
        if (crownColor == CrownColors.GREEN) {
            return ('#F4FFDC', '#A0D170');
        } else if (crownColor == CrownColors.PURPLE) {
            return ('#F9F4FF', '#EAD7FF');
        } else if (crownColor == CrownColors.BLUE) {
            return ('#F4F6FF', '#D9E0FF');
        } else if (crownColor == CrownColors.GOLD) {
            return ('#FFEE93', '#FFCD3D');
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(CrownColors crownColor) internal pure returns (Headwear.HeadwearColors) {
        if (crownColor == CrownColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (crownColor == CrownColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (crownColor == CrownColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (crownColor == CrownColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
