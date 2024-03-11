// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from '../Headwear.sol';

library HeadwearMushroom {
    enum MushroomColors {
        GREEN,
        PURPLE,
        BLUE,
        GOLD
    }

    function getMushroom(
        MushroomColors mushroomColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getMushroomStyle(mushroomColor),
                '<path class="mushroomColor1" d="M41.9 87.6a4.4 4.4 0 1 1 0 8.8 4.4 4.4 0 0 1 0-8.8Z"/><path class="mushroomSparkles" stroke-width="3" d="M37.4 92a4.4 4.4 0 1 1 8.9 0 4.4 4.4 0 0 1-8.9 0Z"/><path class="mushroomColor1" d="M19.7 73.5a8.4 8.4 0 0 0 4.5 3.4 12 12 0 0 0-7.7 8.7c-.6-4-3.4-7.5-7.1-9 3.7-1.3 6.7-4.5 7.8-8.3a28 28 0 0 0 2.5 5.2Z"/><path class="mushroomSparkles" stroke-width="3.5" d="M17.2 68.3c-1 3.8-4 7-7.8 8.2a12 12 0 0 1 7.1 9 12 12 0 0 1 7.7-8.6 8.2 8.2 0 0 1-4.5-3.4c-1-1.5-1.7-3.3-2.5-5.2Z"/><path class="mushroomColor1" d="M178 36a4.4 4.4 0 1 1 0 8.8 4.4 4.4 0 0 1 0-8.8Z"/><path class="mushroomSparkles" stroke-width="3" d="M173.6 40.4a4.4 4.4 0 1 1 8.7 0 4.4 4.4 0 0 1-8.7 0Z"/><path class="mushroomColor1" d="M188 85.6c1 5.1 4.8 9.3 9.5 10.5-5 1.3-9 6-9.6 11.2-.9-5.2-4.9-9.7-10-11.2 4.8-1.6 8.7-5.7 10-10.5Z"/><path class="mushroomSparkles" stroke-width="3.5" d="M188 85.6a16.1 16.1 0 0 1-10 10.5c5 1.5 9 6 9.9 11.2.5-5.2 4.6-9.9 9.6-11.2a13.4 13.4 0 0 1-9.6-10.5Z"/><path class="mushroomColor2" d="M178.6 69a40.7 40.7 0 0 1-16.5 6.7c-8.6 2-17.3 3.2-26.1 3.8.9 1.3 1.7 2.7 2.4 4.1 9.4-.6 18.8-2.3 27.8-5 4.9-1.5 14.4-5.4 12.4-9.6Z"/><path class="mushroomColor2" d="M178.6 69c-1-2.3-4-4.3-7.8-6.1a62.9 62.9 0 0 1-21 9.8 99.4 99.4 0 0 1-17 3c1.2 1.2 2.2 2.5 3.2 3.8 8.8-.6 17.5-1.9 26.1-3.8a40 40 0 0 0 16.5-6.7Z"/><path class="mushroomColor1" d="M104.9 52.6a393.7 393.7 0 0 0-21.8.7c-5 .4-9.7 1-15 1.8l-1.4.2a138.2 138.2 0 0 0-26.4 7c3-4.1 3.7-9.7 2-14.4 2-2.3 4.4-4.6 6.8-6.6l1-.9c4.8-4 10.5-7.5 17.3-10a99 99 0 0 1 33.3-6.3v.4a21.2 21.2 0 0 0 27.8 2.3l.1-.6a84 84 0 0 1 13.2 3.8l.2.7-.6.3c-1.2 2.7.8 8 8.7 12.8 7.7 4.7 11.4 4.7 15.4 2.3v-.2a47 47 0 0 1 13.1 23c-1.1-2.2-4-4.2-7.8-6a82.3 82.3 0 0 0-13.6-4.7 139.6 139.6 0 0 0-15-3 227 227 0 0 0-37.3-2.6V63 52.6Zm19.8-8.8c.4-1.4-.4-2.9-1.7-3.8a7.7 7.7 0 0 0-6.4-1.3c-1.2.3-2.4 1-2.9 2.3-.4 1 0 2.4.9 3.2a7 7 0 0 0 3 1.8c1.3.4 2.7.6 4 .3 1.4-.3 2.7-1.2 3-2.5Zm-52.6 0c1-1.3.9-3.3-.2-4.6-1.1-1.2-3-1.5-4.8-1-1 .4-2 1-2.8 1.8-.7.8-1 2-.8 3.1.3 1.1 1.2 2 2.3 2.4 1 .4 2.3.4 3.4.1a5 5 0 0 0 2.9-1.7Z"/><path class="mushroomColor2" d="M165.5 46v.1c-4 2.4-7.7 2.4-15.4-2.3-8-4.9-10-10-8.7-12.8l.6-.3a17.7 17.7 0 0 1 15.2 1.5c6.2 3.8 7.6 8.4 8.3 13.7Zm-8.3 12.2a64.1 64.1 0 0 1-27.8 14.1 33 33 0 0 1 3.5 3.3 98 98 0 0 0 16.9-2.9 63 63 0 0 0 21-9.8 82.3 82.3 0 0 0-13.6-4.7Z"/><path class="mushroomColor2" d="M129.4 72.3a64.2 64.2 0 0 0 27.8-14c-5-1.4-10-2.4-14.1-3l-.8-.1a63.8 63.8 0 0 1-17.5 14c1.6.9 3.2 2 4.6 3.1Z"/><path class="mushroomColor2" d="M124.8 69.1a63.7 63.7 0 0 0 17.5-14c-5-.7-9.5-1.2-14-1.6A67.9 67.9 0 0 1 117.5 66c2.6.8 5 1.8 7.3 3.1Zm3.8-42.9v.6a21.2 21.2 0 0 1-27.8-2.3V24h4.1c8 0 16 .5 23.7 2.1ZM123 40c1.3 1 2 2.4 1.7 3.8-.4 1.3-1.7 2.2-3 2.5-1.4.3-2.8 0-4-.3a7 7 0 0 1-3.1-1.8c-.8-.8-1.3-2.1-.9-3.2.5-1.2 1.7-2 3-2.3A8 8 0 0 1 123 40Z"/><path class="mushroomColor2" d="M112.3 65c1.8.2 3.5.6 5.2 1 4-3.7 7.7-8 10.7-12.5-3.7-.4-7.5-.6-12-.7v.3c-1.8 4-4 7.8-6.5 11.4l2.6.5Z"/><path class="mushroomColor2" d="M109.7 64.5a75 75 0 0 0 6.6-11.4v-.3l-11.4-.2v11.6c1.6 0 3.3.1 4.8.3Zm-4.9-.3h.1V52.6c-4 0-7.6 0-10.9.2v.6c1.8 3.9 4 7.6 6.4 11.1l4.4-.3Z"/><path class="mushroomColor2" d="M100.4 64.5A74.3 74.3 0 0 1 94 53.4v-.6l-10.9.5-.9.6c3 4.4 6.4 8.4 10.2 12 2.6-.8 5.3-1.3 8-1.4Z"/><path class="mushroomColor2" d="M85 69.1c2.4-1.3 4.8-2.4 7.4-3.2a73.5 73.5 0 0 1-10.2-12l1-.6c-5.1.4-9.8 1-15.2 1.8v.3a63.6 63.6 0 0 0 17 13.7ZM75.3 77 74 79c-12.1-.3-13.9-.3-25.7-3-5.9-1.3-11.8-3-16.5-6.6H31l.2-.3c1-2.2 3.9-4.3 7.7-6h.5a63 63 0 0 0 21.1 10l14.8 4Z"/><path class="mushroomColor2" d="m77.4 74.8.6-.5.7-.8-1-1.4c-11.4-2-16-6-24.6-13.7l-.1-.3A88.4 88.4 0 0 0 38.9 63h.5a63 63 0 0 0 21.1 10c7.5 2 9 1.9 16.6 2.2.2-.1.1-.2.3-.4Zm-5.5-35.6c1 1.3 1.1 3.3.2 4.7a5 5 0 0 1-2.9 1.7c-1.1.3-2.3.3-3.4 0-1-.5-2-1.4-2.3-2.5-.2-1 .1-2.3.8-3.1.7-.9 1.7-1.4 2.8-1.7 1.7-.6 3.7-.3 4.8 1Z"/><path class="mushroomColor2" d="M85 69.1a64 64 0 0 1-17-13.7v-.3l-1.3.2c-4 .6-9 1.6-13.7 2.8v.3a64.3 64.3 0 0 0 27.2 14c1.5-1.2 3.2-2.3 4.8-3.3ZM67.4 30.3c-6.7 2.6-12.5 6-17.4 10.1l-.6-.7c-.3-4.2 2-8.5 5.8-10.6 3.7-2 8.6-1.8 12 .7l.2.5ZM42.3 48c1.7 4.6 1 10.2-2 14.2v.1L39 63c-3.8 1.7-6.7 3.8-7.7 6 1.5-8 5.7-15 11.1-21Zm1.2 30.6c-4.8-1.5-14-5.3-12.5-9.3h.7a40.5 40.5 0 0 0 16.5 6.6 340 340 0 0 0 24.6 4.5l-1.1 2s-14.8.2-28.2-3.8Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M104.9 52.6a211 211 0 0 0-51.3 5.3c-6.4 1.7-18.4 4-22 10.4-3 5 6.3 8.3 9.8 9.5 9.1 3.3 21.5 5.8 31.1 6.5"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M31.2 69c1.5-8 5.7-15 11.1-21 2-2.4 4.4-4.7 6.8-6.7l1-.9c4.8-4 10.6-7.5 17.3-10a99 99 0 0 1 37.5-6.4m0 28.6c22.9-.2 45.9 1.8 66.9 10.8 3 1 6 3 7 7-9 11-28.1 12.7-41.1 14.8m4.1-55.2a84 84 0 0 0-13.2-3.8c-7.8-1.6-15.8-2.2-23.7-2.2"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M178.6 69a47.2 47.2 0 0 0-13-23.1"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M94 53.4c1.7 4 3.7 8 6 11.7M82 53.7c2.8 4.8 5.8 9.2 9.3 13.2M68 55.4a70.8 70.8 0 0 0 17.8 14.5M53 58.4a67 67 0 0 0 27.2 15M39.4 63a77.9 77.9 0 0 0 38.1 13.3m-45.8-7c13 8.8 28.2 8.8 43.6 11.2"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M42.3 47.8v.1c1.7 4.7 1 10.3-2 14.3m26.8-23.9a6 6 0 0 0-2.8 1.7c-.7.8-1 2-.8 3.1.3 1.1 1.2 2 2.3 2.4 1 .4 2.3.4 3.4.1a5 5 0 0 0 2.9-1.7c1-1.4.9-3.4-.2-4.7-1.1-1.2-3-1.5-4.8-1Zm-17.7 1.4c-.3-4.2 2-8.5 5.8-10.6 3.7-2 8.6-1.8 12 .7m33.5-5.3a21.2 21.2 0 0 0 27.8 2.3M123 40a7.7 7.7 0 0 0-6.4-1.3c-1.2.3-2.4 1-2.9 2.3-.4 1 0 2.4.9 3.2a7 7 0 0 0 3 1.8c1.3.4 2.7.6 4 .3 1.4-.3 2.7-1.2 3-2.5.5-1.4-.3-2.9-1.5-3.8Zm19-9.3-.6.3c-1.2 2.7.8 8 8.7 12.8 7.7 4.7 11.4 4.7 15.4 2.3v-.2c-.7-5.3-2.1-10-8.3-13.7a17.7 17.7 0 0 0-15.2-1.5Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M116.3 53.1c-1.7 4.1-3.7 8-6 11.7m18-11.4c-2.9 5-6.1 9.6-9.7 13.7m23.7-11.9a69.9 69.9 0 0 1-18 14.7m32.9-11.7a67.8 67.8 0 0 1-27.8 15.2m41.5-10.6a77.7 77.7 0 0 1-39 13.5m46.7-7.3A97.8 97.8 0 0 1 135 80.5m-30-27.9V64"/><path class="mushroomColor1" d="M169.1 72.9a5.7 5.7 0 1 1 0 11.4 5.7 5.7 0 0 1 0-11.4Z"/><path class="mushroomSparkles" stroke-width="3" d="M163.4 78.6a5.7 5.7 0 1 1 11.5 0 5.7 5.7 0 0 1-11.5 0Z"/></svg>'
            ),
            Headwear.HeadwearVariants.MUSHROOM,
            _getHeadwearColor(mushroomColor)
        );
    }

    function _getMushroomStyle(MushroomColors mushroomColor) internal pure returns (string memory) {
        (string memory primaryColor, string memory secondaryColor) = _getMushroomColor(mushroomColor);
        (string memory sparklesFill, string memory sparklesStroke) = _getMushroomSparklesColors(mushroomColor);
        return
            string.concat(
                '<style>.mushroomColor1 { fill:',
                primaryColor,
                '}.mushroomColor2 { fill:',
                secondaryColor,
                '}.mushroomSparkles {fill:',
                sparklesFill,
                '; stroke:',
                sparklesStroke,
                '; stroke-linecap: round; stroke-linejoin: round;}</style>'
            );
    }

    function _getMushroomSparklesColors(
        MushroomColors mushroomColor
    ) internal pure returns (string memory, string memory) {
        if (mushroomColor == MushroomColors.GOLD) {
            return ('#fff', '#B96326');
        } else {
            (string memory primaryColor, ) = _getMushroomColor(mushroomColor);
            return (primaryColor, '#000');
        }
    }

    function _getMushroomColor(MushroomColors mushroomColor) internal pure returns (string memory, string memory) {
        if (mushroomColor == MushroomColors.GREEN) {
            return ('#F4FFDC', '#A0D170');
        } else if (mushroomColor == MushroomColors.PURPLE) {
            return ('#F9F4FF', '#EAD7FF');
        } else if (mushroomColor == MushroomColors.BLUE) {
            return ('#F4F6FF', '#D9E0FF');
        } else if (mushroomColor == MushroomColors.GOLD) {
            return ('#FFEE93', '#FFCD3D');
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(MushroomColors mushroomColor) internal pure returns (Headwear.HeadwearColors) {
        if (mushroomColor == MushroomColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (mushroomColor == MushroomColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (mushroomColor == MushroomColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (mushroomColor == MushroomColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
