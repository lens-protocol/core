// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from 'contracts/libraries/svgs/Profile/Headwear.sol';

library HeadwearMushroom {
    enum MushroomColors {
        GREEN,
        PURPLE,
        BLUE,
        PINK,
        GOLD
    }

    function getMushroom(
        MushroomColors mushroomColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="211" height="335" fill="none">',
                _getMushroomStyle(mushroomColor),
                '<path class="mushroomSparkles" stroke-width="3" d="M9.4 46.1a4.4 4.4 0 1 1 0 8.9 4.4 4.4 0 0 1 0-8.9Z"/><path class="mushroomSparkles" stroke-width="3.5" d="M33.4 32.3a8 8 0 0 0 4.4 3.3 12 12 0 0 0-7.6 8.7 12 12 0 0 0-7.2-9c3.8-1.3 6.8-4.5 7.9-8.3a20 20 0 0 0 2.5 5.3Z"/><path class="mushroomSparkles" stroke-width="3" d="M178.6 23.4a4.4 4.4 0 1 1 0 8.7 4.4 4.4 0 0 1 0-8.7Z"/><path class="mushroomSparkles" stroke-width="3.5" d="M193 39.6c1 5.1 4.8 9.3 9.6 10.5-5 1.3-9.1 6-9.7 11.2a14 14 0 0 0-9.9-11.2c4.8-1.6 8.6-5.7 10-10.5Z"/><path class="mushroomSparkles" stroke-width="3"  d="M148.2 6a5.7 5.7 0 1 1 0 11.5 5.7 5.7 0 0 1 0-11.5Z"/><path class="mushroomColor1" d="M105.5 63.6a393.7 393.7 0 0 0-21.7.7c-5 .4-9.7 1-15.1 1.8l-1.3.2a138.2 138.2 0 0 0-26.4 7 16 16 0 0 0 2-14.4c2-2.3 4.3-4.6 6.7-6.6l1-.9c4.8-4 10.6-7.5 17.3-10a99 99 0 0 1 33.4-6.3v.4a21 21 0 0 0 27.8 2.3v-.6a84 84 0 0 1 13.2 3.8l.3.7-.7.3c-1.2 2.7.8 8 8.8 12.8 7.7 4.7 11.4 4.7 15.4 2.3v-.2a47 47 0 0 1 13 23c-1-2.2-4-4.2-7.8-6a82.3 82.3 0 0 0-13.5-4.7 139.6 139.6 0 0 0-15-3 227 227 0 0 0-37.3-2.6V74 63.6Zm19.8-8.8c.4-1.4-.4-2.9-1.6-3.8a7.7 7.7 0 0 0-6.4-1.3c-1.2.3-2.5 1-2.9 2.3-.4 1 0 2.4.8 3.2a7 7 0 0 0 3 1.8c1.4.4 2.8.6 4.2.3 1.3-.3 2.6-1.2 3-2.5Zm-52.6 0c1-1.3 1-3.3-.1-4.6-1.1-1.2-3-1.5-4.8-1-1 .4-2 1-2.8 1.8-.7.8-1 2-.8 3.1.3 1.1 1.2 2 2.3 2.4 1 .4 2.3.4 3.4.1a5 5 0 0 0 2.8-1.7Z"/><path class="mushroomColor2" d="M166.2 57v.1c-4 2.4-7.7 2.4-15.4-2.3-8-4.9-10-10-8.8-12.8l.7-.3a17.7 17.7 0 0 1 15.2 1.5c6.2 3.8 7.6 8.4 8.3 13.7Zm-36.9-19.8-.1.6a21 21 0 0 1-27.8-2.3V35h4.2c8 0 16 .5 23.7 2.1ZM123.7 51c1.2 1 2 2.4 1.6 3.8-.3 1.3-1.6 2.2-3 2.5a9 9 0 0 1-4-.3 7 7 0 0 1-3-1.8c-.9-.8-1.3-2.1-.9-3.2.4-1.2 1.7-2 2.9-2.3a8 8 0 0 1 6.4 1.3Zm-51.1-.8a4 4 0 0 1 .1 4.7 5 5 0 0 1-2.8 1.7c-1.1.3-2.4.3-3.4 0a4 4 0 0 1-2.3-2.5c-.3-1 .1-2.3.8-3.1.7-.9 1.7-1.4 2.8-1.7 1.7-.6 3.7-.3 4.8 1ZM68 41.3c-6.7 2.6-12.5 6-17.3 10.1l-.6-.7c-.3-4.2 2-8.5 5.7-10.6 3.7-2 8.6-1.8 12 .7l.2.5ZM43 59c1.7 4.6.9 10.2-2 14.2v.1l-1.5.7c-3.8 1.7-6.6 3.8-7.7 6 1.6-8 5.8-15 11.2-21Z"/><path class="mushroomColor1" d="m136.7 85.3 4 .7 2 6.2.3 1.4c0 .5.4 2 .5 3.5l.3 5.1s6.8-7.5 17-10.5c3-1 8.4-1.4 8.4-1.4l3.8-2.4 2-3 4.5-4-8.2-6.7-16.7-5.3-23.7-4.2H89.7L55 69l-17 5.3-4 6.2-.2 3.3s.7 1.8 1.8 3.1c1.1 1.5 3.4 3.6 3.5 3.5 0 0 7-.2 15 2.7a41.1 41.1 0 0 1 13.5 9.3s0-3 .2-4.8l.6-4.2.2-1 2-6.4 8.2-.6 10.8-4.5h32l15.1 4.5Z"/><path fill="#000" fill-opacity=".2" d="m136.7 85.3 4 .7 2 6.2.3 1.4c0 .5.4 2 .5 3.5l.3 5.1s6.8-7.5 17-10.5c3-1 8.4-1.4 8.4-1.4l3.8-2.4 2-3 4.5-4-8.2-6.7-16.7-5.3-23.7-4.2H89.7L55 69l-17 5.3-4 6.2-.2 3.3s.7 1.8 1.8 3.1c1.1 1.5 3.4 3.6 3.5 3.5 0 0 7-.2 15 2.7a41.1 41.1 0 0 1 13.5 9.3s0-3 .2-4.8l.6-4.2.2-1 2-6.4 8.2-.6 10.8-4.5h32l15.1 4.5Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M105.5 63.6c-17.1 0-34.5 1.1-51.2 5.3-6.4 1.7-18.4 4-22 10.4-2.3 4 2.3 9.4 6 12.3"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M31.8 80c1.6-8 5.8-15 11.2-21a53 53 0 0 1 6.7-6.7l1-.9c4.8-4 10.6-7.5 17.3-10a99 99 0 0 1 37.5-6.4m.1 28.6c22.9-.2 45.9 1.8 66.9 10.8 3 1 6 3 7 7-2.2 3.7-4 6.7-9.6 10.5M142.4 41a84 84 0 0 0-13.1-3.8c-7.8-1.6-15.8-2.2-23.7-2.2"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M179.4 81c-1.8-9-7-17.7-13.1-24.1"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M94.7 64.4c1.7 4 4.7 11 7 14.7m-19-14.4c2.7 4.8 8.4 11 11.8 15M68.7 66.4a73.5 73.5 0 0 0 18.2 14.7M53.7 69.4c7.8 7 15.5 11.3 25.5 14M40 74a55 55 0 0 0 31.4 12.8m-39-6.5a69.4 69.4 0 0 0 37.8 12.5m-11.4 4.5s3.3.8 5.4 1.1c2 .3 5.2.3 5.2.3m82.9-1.4s-3.2.8-5.4 1.1c-2 .3-5.2.3-5.2.3"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M43 59c1.7 4.6.9 10.2-2 14.2m26.8-23.9A6 6 0 0 0 65 51c-.7.8-1 2-.8 3.1.3 1.1 1.2 2 2.3 2.4 1 .4 2.3.4 3.4.1a5 5 0 0 0 2.8-1.7c1-1.4 1-3.4-.1-4.7-1.1-1.2-3-1.5-4.8-1ZM50 50.7c-.2-4.2 2.1-8.5 5.8-10.6 3.7-2 8.6-1.8 12 .7m33.6-5.3a21 21 0 0 0 27.8 2.3M123.7 51a7.7 7.7 0 0 0-6.4-1.3c-1.2.3-2.5 1-2.9 2.3-.4 1 0 2.4.8 3.2a7 7 0 0 0 3 1.8c1.4.4 2.8.6 4.2.3 1.3-.3 2.6-1.2 3-2.5.3-1.4-.5-2.9-1.7-3.8Zm19-9.3-.7.3c-1.2 2.7.8 8 8.8 12.8 7.7 4.7 11.4 4.7 15.4 2.3v-.2c-.7-5.3-2.1-10-8.3-13.7a17.7 17.7 0 0 0-15.2-1.5Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M117 64.1c-1.8 4.1-5.4 11.4-7.7 15M129 64.4c-2.9 5-8 11.5-11.7 15.6M143 66.2a71.6 71.6 0 0 1-18 15m33-12a57.3 57.3 0 0 1-25.4 14.3m38.9-9.7a53.4 53.4 0 0 1-31.4 13m39.2-6.8a77.3 77.3 0 0 1-37.8 12.8m-35.9-29.2V79"/><path stroke="#000" stroke-linecap="round" stroke-width="3.5" d="M71 87.4s11.8-8.2 34.6-8.2S140 87 140 87"/></svg>'
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
            return ('#F3EAFF', '#EAD7FF');
        } else if (mushroomColor == MushroomColors.BLUE) {
            return ('#ECF0FF', '#D9E0FF');
        } else if (mushroomColor == MushroomColors.PINK) {
            return ('#FFE7F0', '#FFD2DD');
        } else if (mushroomColor == MushroomColors.GOLD) {
            return ('#FFEE93', '#F8C944');
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
        } else if (mushroomColor == MushroomColors.PINK) {
            return Headwear.HeadwearColors.PINK;
        } else if (mushroomColor == MushroomColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
