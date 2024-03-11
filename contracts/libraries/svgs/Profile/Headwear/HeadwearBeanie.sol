// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from '../Headwear.sol';

library HeadwearBeanie {
    enum BeanieColors {
        GREEN,
        LIGHT,
        DARK,
        PURPLE,
        GOLD
    }

    // // we take the 12th byte from the left for beanie color
    // uint8 color = uint8((seed >> 160) & 0xFF) % 4;
    function getBeanie(
        BeanieColors beanieColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M98 66.5s4.2-.5 7-.5c2.6 0 6.8.5 6.8.5"/>',
                _getBeanieStyle(beanieColor),
                '<path class="beanieColor" d="M70.6 93c.2 0 .3 0 .4.2l-.3.7a10.6 10.6 0 0 0-3.5 10.1l-.3.8c-2.4-1.4-4.7-3-6.8-4.7-.5-4.4 1-8.8 4-11.3l.2.3c2 1.5 4.1 2.7 6.3 3.9Z"/><path class="beanieColor" d="M81 97.3c-2 3.4-3 7.4-3 11.4l-.2 1c-3.8-1.3-7.4-3-10.8-5l.3-.8a11 11 0 0 1 3.5-10.3l.3-.8c3.2 1.6 6.5 3 9.9 4v.5Z"/><path class="beanieColor" d="m81.2 96.8 2.7.7a72 72 0 0 0 8.1 1.6l-.1 1.4-1 11.5v.8a73 73 0 0 1-12.9-3.3l.3-1c0-4 1-8 2.8-11.2v-.5ZM105 100.6v13.2c-4.6 0-9.3-.3-14-1l.1-.8 1-11 .1-1.2c4.2.5 8.5.8 12.8.8ZM119 112v.7c-4.7.7-9.4 1-14 1v-13c4.3 0 8.6-.3 12.8-1l.2 1.4 1 11ZM131.7 108.5l.3 1a73.2 73.2 0 0 1-12.8 3.3l-.1-.7-1-11.6-.1-1.4a77 77 0 0 0 10.8-2.3v.5c2 3.3 3 7.2 3 11.2Z"/><path class="beanieColor" d="M143 104.7a60 60 0 0 1-10.7 5l-.3-1c0-4-1-8-2.9-11.3l-.1-.6c3.4-1 6.8-2.4 10-4l.3.8a11 11 0 0 1 3.4 10.4l.3.7Z"/><path class="beanieColor" d="M146 88.8c2.9 2.5 4.4 6.9 4 11.3a51.8 51.8 0 0 1-7 4.7l-.2-.7c.7-3.8-.7-8-3.5-10.2l-.3-.7.3-.2c2.3-1.2 4.4-2.4 6.4-3.9l.3-.3Z"/><path class="beanieColor" d="M145.6 89.2c-2 1.3-4.2 2.4-6.4 3.4l-.4-.9c.3-7.8-2-15.7-6.7-22a34.5 34.5 0 0 0-16.5-12.4 40.2 40.2 0 0 1 17 7.8c7 6 11.8 14.8 13.2 23.9l-.2.2Z"/><path class="beanieColor" d="m138.8 91.7.4 1h-.3a66.8 66.8 0 0 1-12.8 4.1l-.1-.6c.6-14.3-5-28.6-14.3-39.6a44.7 44.7 0 0 1 4 .7c6.5 2 12.7 7.2 16.4 12.3 4.6 6.4 7 14.3 6.7 22.1Z"/><path class="beanieColor" d="M104.7 56.2c2.4 0 4.7.2 7 .4 9.3 11 15 25.3 14.3 39.6v.6a91.2 91.2 0 0 1-21.3 2.2V56.2ZM104.7 99a105.1 105.1 0 0 1-21-2.1l.2-.7c-.7-14.4 5-28.6 14.3-39.6 2.1-.3 4.3-.4 6.5-.4V99Z"/><path class="beanieColor" d="m83.7 96.9-2.7-.7c-3.5-.9-6.8-2-10-3.4l-.4-.2.5-.9c-.3-7.8 2-15.7 6.6-22A34 34 0 0 1 95 57l3.3-.5c-9.3 11-15 25.2-14.3 39.6l-.2.7Z"/><path class="beanieColor" d="M77.7 69.6c-4.6 6.4-7 14.3-6.6 22.1l-.5 1c-2.2-1-4.3-2.2-6.3-3.5L64 89A39.8 39.8 0 0 1 77.3 65a34.6 34.6 0 0 1 17.6-8 34 34 0 0 0-17.2 12.5Z"/><path class="hwline4" d="M85.7 59.7c-3 1.4-5.7 3.2-8.3 5.5a42.7 42.7 0 0 0-13.3 25.2 11.7 11.7 0 0 0-4 10.5 57.4 57.4 0 0 0 17.8 8.8 81.3 81.3 0 0 0 27.1 4 96.2 96.2 0 0 0 27.1-4A65.1 65.1 0 0 0 150 101c.5-4.1-1-8.2-4-10.5a42.7 42.7 0 0 0-13.3-25.2c-2.6-2.3-5.3-4-8.3-5.5"/><path class="hwline4" d="M64.3 89.2c2 1.3 4.1 2.4 6.3 3.4l.4.2a66.5 66.5 0 0 0 21 5.5c4.2.5 8.5.7 12.7.7"/><path class="hwline3" d="M71 93.8a9.9 9.9 0 0 0-3.8 10M81 96.8c-2 3.2-3 7.1-3 11M92 99.8l-1 11M98.4 56.4s0 0 0 0l-.2.2c-9.3 11-15 25.2-14.3 39.6"/><path class="hwline3" d="M71 91.7c-.3-7.8 2.1-15.7 6.7-22A34 34 0 0 1 95 57c1.2-.4 2.3-.6 3.5-.7"/><path class="hwline4" d="M145.6 89.2c-2 1.3-4.2 2.4-6.4 3.4l-.3.2a66.8 66.8 0 0 1-21 5.4c-4.5.6-8.9.8-13.2.8h0"/><path class="hwline3" d="M139 93.8c3 2.1 4.6 6.3 3.8 10M129 96.8c2 3.2 3 7.1 3 11M118 99.8l1 11M111.4 56.4s0 0 0 0l.3.2c9.3 11 15 25.3 14.3 39.6"/><path class="hwline3" d="M138.8 91.7c.3-7.8-2-15.7-6.7-22a34.5 34.5 0 0 0-16.5-12.4s0 0 0 0c-1.4-.5-2.8-.8-4.1-.9M105 55.8v57"/><path fill="white" d="m116.5 62.3-11.5.5-10.5-.5s-6-3.7-9-2.4l-.2-.5a5 5 0 0 1 2.6-6.9 7 7 0 0 1 .4-7.5 7.4 7.4 0 0 1 7.4-2.5c1.1-3.2 5.8-4.7 9.3-4.7 3.4 0 8 1.5 9.1 4.7 2.9-.6 5.8.4 7.4 2.5a7 7 0 0 1 .5 7.5 5 5 0 0 1 2.5 7l-.2.5c-2.7-1.2-7.8 2.3-7.8 2.3Z"/><path class="hwline4" d="M85.3 59.4a5 5 0 0 1 2.6-6.9 7 7 0 0 1 .4-7.5 7.4 7.4 0 0 1 7.4-2.5c1.1-3.2 5.8-4.7 9.3-4.7 3.4 0 8 1.5 9.1 4.7 2.9-.6 5.8.4 7.4 2.5a7 7 0 0 1 .5 7.5 5 5 0 0 1 2.5 7"/><path class="hwline3" d="M85.3 59.4s5.1 3.4 19.7 3.4c14.5 0 19.5-3.4 19.5-3.4"/></svg>'
            ),
            Headwear.HeadwearVariants.BEANIE,
            _getHeadwearColor(beanieColor)
        );
    }

    function _getBeanieStyle(BeanieColors beanieColor) internal pure returns (string memory) {
        return
            string.concat(
                '<style>.beanieColor { fill: ',
                _getBeanieColor(beanieColor),
                ' }.hwline3 {stroke: black; stroke-linecap: round; stroke-linejoin: round; stroke-width: 3}.hwline4 {stroke: black; stroke-linecap: round; stroke-linejoin: round; stroke-width: 4}</style>'
            );
    }

    function _getBeanieColor(BeanieColors beanieColor) internal pure returns (string memory) {
        if (beanieColor == BeanieColors.GREEN) {
            return '#F4FFDC';
        } else if (beanieColor == BeanieColors.LIGHT) {
            return '#FFFFFF';
        } else if (beanieColor == BeanieColors.DARK) {
            return '#575757';
        } else if (beanieColor == BeanieColors.PURPLE) {
            return '#F3EAFF';
        } else if (beanieColor == BeanieColors.GOLD) {
            return '#FFEE93';
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(BeanieColors beanieColor) internal pure returns (Headwear.HeadwearColors) {
        if (beanieColor == BeanieColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (beanieColor == BeanieColors.LIGHT) {
            return Headwear.HeadwearColors.LIGHT;
        } else if (beanieColor == BeanieColors.DARK) {
            return Headwear.HeadwearColors.DARK;
        } else if (beanieColor == BeanieColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (beanieColor == BeanieColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
