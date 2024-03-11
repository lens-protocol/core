// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from '../Headwear.sol';

library HeadwearHat {
    enum HatColors {
        GREEN,
        LIGHT,
        DARK,
        BLUE,
        PURPLE,
        GOLD
    }

    // // we take the 13th byte from the left for hat color
    // uint8 color = uint8((seed >> 152) & 0xFF) % 5;
    function getHat(
        HatColors hatColor
    ) internal pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getHatStyle(hatColor),
                '<path class="hatLine" stroke-width="4" d="M98 66.5s4.2-.5 7-.5c2.6 0 6.8.5 6.8.5"/><path class="hatColor1" d="m153.6 113-.8 2.6-3.3-.8-5.3-4.2-7.8-5-9.2-4.9-9.1-1-10.6-1h-10l-11 2L77 104l-10.6 5.2-8 6.5-2-.8 3-5.7.8-4.2 2.5-3.2 7.1-4.1 8.4-3.6 13.1-3.3 14.6-.9h10.3l23.3 6.8 8.1 5 2 4 4.1 7.4Z"/><path class="hatColor2" d="m62.5 90.8-2.2 13.8 3.5-3c3-2.4 6.2-4.4 9.6-5.9l1.3-.5 7.2-2.6 7.2-1.9 3.2-.5a91 91 0 0 1 13-.9h4c5.4.4 10.8 1.2 16 2.5l1 .2 8.9 3 3.2 1.5c3.3 1.6 6.2 3.7 8.9 6.2l2.2 1.9-1.9-13.8-2-7.8a30.6 30.6 0 0 0-5-10.9l-.6-.7c-2-2.8-4.4-5.2-7-7.4l-.3-.2c-2.4-2-5-3.6-7.8-5l-1.1-.5a37.2 37.2 0 0 0-16.3-3.7H102.8a36.9 36.9 0 0 0-15 3.2l-1.9.8a39.4 39.4 0 0 0-15.1 12L69.6 72a29.2 29.2 0 0 0-5.1 10.8l-2 8Z"/><path fill="#000" fill-opacity=".1" d="m66.2 99.9-6.1 5.9 2.3-14.2 2.6-8.8 4.4-9.4L80.5 62s-8.4 10.6-11 17.5c-3.6 9.2-3.3 20.4-3.3 20.4ZM143.9 98.9l6 5.9-2.3-14.2-2.6-8.8-4.4-9.4-11-11.4s8.3 10.6 11 17.5C144.1 87.7 144 99 144 99Z"/><path class="hatColor2" d="M105.3 54.4h-4a1.4 1.4 0 0 1-1-2.2l.2-.4c.3-.3.6-.5 1-.6l.5-.3c.7-.3 1.5-.4 2.2-.4H105.9c.7 0 1.3 0 2 .3l.7.3c.4.2.8.5 1.2 1l.2.2a1.3 1.3 0 0 1-1 2.1h-3.7Z"/><path class="hatLine" stroke-width="4" d="M99.8 54.4v-1.9c0-.4 0-.8.2-1.2.2-.4.5-.8 1-1l.1-.2a9.4 9.4 0 0 1 8 0l.2.1c.4.3.7.7.9 1.1l.2 1.2v2M85 58.6l-1.1.6a39.2 39.2 0 0 0-20.4 26.2c-1.5 6.3-1.8 12.8-3 19l-.4 2.2-3.8 6.9c-.8 1.5 1 3 2.2 2l8.1-6.4 2.5-1.7c4.5-2.5 9.2-4.6 14-6.3l.8-.2.4-.1a85.7 85.7 0 0 1 41.9 0h.3l.8.3a89.5 89.5 0 0 1 16.4 8l8 6.4c1.3 1 3-.5 2.2-2l-3.8-7-.3-2.5c-1.2-6-1.4-12.2-2.8-18.2a39.3 39.3 0 0 0-20.5-26.7l-1-.5c-5.7-2.9-12-4.4-18.3-4.4h-3.8c-6.4 0-12.7 1.5-18.4 4.4Z"/><path class="hatColor1 hatLine" stroke-width="2.5" d="m109.7 71.2-.2.2v-.7c-.2-5.4-8.4-5.4-8.5 0v.7l-.3-.3-.3-.2c-4-3.7-9.7 2-6 6l.3.2a16.3 16.3 0 0 0 10.5 4.5s6 0 10.5-4.5l.3-.3c3.7-3.9-2-9.6-6-6 0 .2-.2.3-.3.4Z"/><path class="hatLine" stroke-width="3" d="M60.9 106.5s13.6-17.7 45-17.7c31.3 0 43.6 17.7 43.6 17.7"/><path class="hatLine" stroke-opacity=".1" stroke-width="4" d="M58.6 115.6s17.5-14 46.7-14c29.3 0 45 14 45 14"/></svg>'
            ),
            Headwear.HeadwearVariants.HAT,
            _getHeadwearColor(hatColor)
        );
    }

    function _getHatStyle(HatColors hatColor) internal pure returns (string memory) {
        (string memory hatColor1, string memory hatColor2) = _getHatColor(hatColor);
        return
            string.concat(
                '<style>.hatColor1 { fill: ',
                hatColor1,
                ' }.hatColor2 { fill: ',
                hatColor2,
                ' }.hatLine {stroke: black; stroke-linecap: round; stroke-linejoin: round}</style>'
            );
    }

    function _getHatColor(HatColors hatColor) internal pure returns (string memory, string memory) {
        if (hatColor == HatColors.GREEN) {
            return ('#A0B884', '#F4FFDC');
        } else if (hatColor == HatColors.LIGHT) {
            return ('#EAEAEA', '#FFFFFF');
        } else if (hatColor == HatColors.DARK) {
            return ('#DBDBDB', '#575757');
        } else if (hatColor == HatColors.BLUE) {
            return ('#F3EAFF', '#EAD7FF');
        } else if (hatColor == HatColors.PURPLE) {
            return ('#ECF0FF', '#D9E0FF');
        } else if (hatColor == HatColors.GOLD) {
            return ('#FFCF3D', '#FFEE93');
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(HatColors hatColor) internal pure returns (Headwear.HeadwearColors) {
        if (hatColor == HatColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (hatColor == HatColors.LIGHT) {
            return Headwear.HeadwearColors.LIGHT;
        } else if (hatColor == HatColors.DARK) {
            return Headwear.HeadwearColors.DARK;
        } else if (hatColor == HatColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (hatColor == HatColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (hatColor == HatColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
