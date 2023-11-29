// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from 'contracts/libraries/svgs/Profile/Headwear.sol';
import {LensColors} from 'contracts/libraries/svgs/Profile/LensColors.sol';

library HeadwearMajor {
    enum MajorColors {
        GREEN,
        PINK,
        PURPLE,
        BLUE,
        GOLD
    }

    function getMajor(
        MajorColors majorColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getMajorStyle(majorColor),
                '<path fill="#000" d="M35.8 160.6 21.6 157l6.6 5.9 11 2.3-3.4-4.6Zm166.1 0L216 157l-6.6 5.9-11 2.3 3.5-4.6Z"/><path class="hwStr1" stroke-width="4" d="M75.5 192.9c4.2-1.2 8.8-2.5 13-3.1m73.5 3.1a94.6 94.6 0 0 0-13-3.1"/><path class="headwearColorB" fill-rule="evenodd" d="M148.4 191.2h-.2l-.6.2a178 178 0 0 1-9.7 2.2c-6 1.2-13.4 2.4-19.2 2.4a104 104 0 0 1-19.1-2.4 206.5 206.5 0 0 1-9.6-2.2l-.6-.1h-.7l-1 .1a51.5 51.5 0 0 0-5.8 1.4h-.3l-.5.2.4.2a14.3 14.3 0 0 0 .7.2 61.4 61.4 0 0 0 9.5 2.6 126 126 0 0 0 64-2.8h.2l.5-.2-.5-.1-.3-.1-.9-.2a72.3 72.3 0 0 0-6.2-1.4Zm7.5 2v-.2.2Zm-74.4 0v-.2.2Zm7.7-2v.2-.2Z" clip-rule="evenodd"/><path fill="#000" fill-opacity=".3" fill-rule="evenodd" d="M148.4 191.2h-.2l-.6.2a178 178 0 0 1-9.7 2.2c-6 1.2-13.4 2.4-19.2 2.4a104 104 0 0 1-19.1-2.4 206.5 206.5 0 0 1-9.6-2.2l-.6-.1h-.7l-1 .1a51.5 51.5 0 0 0-5.8 1.4h-.3l-.5.2.4.2a14.3 14.3 0 0 0 .7.2 61.4 61.4 0 0 0 9.5 2.6 126 126 0 0 0 64-2.8h.2l.5-.2-.5-.1-.3-.1-.9-.2a72.3 72.3 0 0 0-6.2-1.4Zm7.5 2v-.2.2Zm-74.4 0v-.2.2Zm7.7-2v.2-.2Z" clip-rule="evenodd"/><path fill="#fff" fill-opacity=".3" d="M75 192.9a124.3 124.3 0 0 1-44-23.7c-12.8-11.2-23.5-25-22.6-42a49.4 49.4 0 0 1 24-38.3c13-7.1 29.9-7 42.8.4a50.7 50.7 0 0 1 16.4-23 43 43 0 0 1 27-8.6 43 43 0 0 1 27 8.6 50.7 50.7 0 0 1 16.5 23c13-7.4 29.7-7.5 42.8-.4a49.4 49.4 0 0 1 24 38.3c.9 17-9.8 30.8-22.6 42a124.3 124.3 0 0 1-44.2 23.7 100 100 0 0 1-21.4 5.9A135.6 135.6 0 0 1 75 193v-.1Z"/><path class="hwStr1" stroke-width="4" d="M90 197.3c-5-1-10-2.6-14.7-4.4A124.4 124.4 0 0 1 31.1 169a99 99 0 0 1-9.6-9.6 46 46 0 0 1-13-32.5c.5-7.6 3.4-15.6 7.8-22.6a46 46 0 0 1 16.2-15.6c13.1-7.2 29.9-7 42.9.4a50.7 50.7 0 0 1 16.4-23 43 43 0 0 1 27-8.6 43 43 0 0 1 27 8.5 50.7 50.7 0 0 1 16.4 23.1c13-7.4 29.8-7.6 42.9-.4a46 46 0 0 1 16.2 15.6c4.4 7 7.3 15 7.7 22.6a45.6 45.6 0 0 1-13 32.5 99 99 0 0 1-9.6 9.6 124.4 124.4 0 0 1-44.1 23.8 100 100 0 0 1-21.5 5.8 135.6 135.6 0 0 1-50.8-1.4Z"/><path fill="#fff" d="M90 197.3c-5-1-10-2.6-14.7-4.4A124.4 124.4 0 0 1 31.1 169a99 99 0 0 1-9.6-9.6s38 20.7 97.3 20.7 97.2-20.7 97.2-20.7a99 99 0 0 1-9.6 9.6 124.4 124.4 0 0 1-44.1 23.8 100 100 0 0 1-21.5 5.8 135.6 135.6 0 0 1-50.8-1.4Z"/><path class="hwStr1" stroke-width="4" d="M90 197.3c-5-1-10-2.6-14.7-4.4A124.4 124.4 0 0 1 31.1 169a99 99 0 0 1-9.6-9.6s38 20.7 97.3 20.7 97.2-20.7 97.2-20.7a99 99 0 0 1-9.6 9.6 124.4 124.4 0 0 1-44.1 23.8 100 100 0 0 1-21.5 5.8 135.6 135.6 0 0 1-50.8-1.4Z"/><path class="hwStr1" stroke-opacity=".3" stroke-width="3" d="M49 180.5c11.7 3.6 28.6 7.7 48.2 9.6m91.2-9.8c-12 3.7-29.3 8-49.6 9.9"/><circle class="headwearColorB" cx="118.3" cy="192.3" r="2.7"/><circle cx="118.3" cy="192.3" r="2.7" stroke="#000" stroke-width="2.5"/><circle class="headwearColorB" cx="106.7" cy="191.8" r="2.2"/><circle cx="106.7" cy="191.8" r="2.2" stroke="#000" stroke-width="2.5"/><circle class="headwearColorB" cx="129.9" cy="191.8" r="2.2"/><circle cx="129.9" cy="191.8" r="2.2" stroke="#000" stroke-width="2.5"/><path fill="#fff" d="M3.2 115.6h7.5s-2 5.2-2 13.5 2 13.5 2 13.5H3.2s-2-4.2-2-13.5 2-13.5 2-13.5Z"/><path class="hwStr1" stroke-width="4" d="M3.1 118.8c.4-2 2.2-3.2 4.2-3.2h3.4S9 120.8 9 129.1s1.8 13.5 1.8 13.5H7.3c-2 0-3.8-1.3-4.2-3.2a56.1 56.1 0 0 1 .1-20.6Z"/><path fill="#fff" d="M234.1 115.6h-7.5s2 5.2 2 13.5-2 13.5-2 13.5h7.5s2-4.2 2-13.5-2-13.5-2-13.5Z"/><path class="hwStr1" stroke-width="4" d="M234.2 118.8c-.4-2-2.1-3.2-4.1-3.2h-3.5s1.8 5.2 1.8 13.5-1.8 13.5-1.8 13.5h3.5c2 0 3.7-1.3 4.1-3.2a51.6 51.6 0 0 0 0-20.6Z"/><path stroke="#000" stroke-linecap="round" stroke-width="4" d="M9 116V93.4M228.4 116V93.4"/><circle cx="8.9" cy="91" r="4.7" fill="#fff"/><circle cx="8.9" cy="91" r="6.7" stroke="#000" stroke-width="4"/><circle cx="228.4" cy="91" r="4.7" fill="#fff"/><circle cx="228.4" cy="91" r="6.7" stroke="#000" stroke-width="4"/></svg>'
            ),
            Headwear.HeadwearVariants.MAJOR,
            _getHeadwearColor(majorColor)
        );
    }

    function _getMajorStyle(MajorColors majorColor) internal pure returns (string memory) {
        return
            string.concat(
                '<style>.headwearColorB { fill:',
                _getMajorColor(majorColor),
                '}.hwStr1 {stroke: #000;stroke-linecap: round;stroke-linejoin: round;}</style>'
            );
    }

    function _getMajorColor(MajorColors majorColor) internal pure returns (string memory) {
        if (majorColor == MajorColors.GREEN) {
            return LensColors.baseGreen;
        } else if (majorColor == MajorColors.PURPLE) {
            return LensColors.basePurple;
        } else if (majorColor == MajorColors.BLUE) {
            return LensColors.baseBlue;
        } else if (majorColor == MajorColors.PINK) {
            return LensColors.basePink;
        } else if (majorColor == MajorColors.GOLD) {
            return LensColors.baseGold;
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(MajorColors majorColor) internal pure returns (Headwear.HeadwearColors) {
        if (majorColor == MajorColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (majorColor == MajorColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (majorColor == MajorColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (majorColor == MajorColors.PINK) {
            return Headwear.HeadwearColors.PINK;
        } else if (majorColor == MajorColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
