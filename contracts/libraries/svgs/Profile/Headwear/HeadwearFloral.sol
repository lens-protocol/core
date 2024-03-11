// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from '../Headwear.sol';

library HeadwearFloral {
    enum FloralColors {
        GREEN,
        PURPLE,
        BLUE,
        GOLD
    }

    function getFloral(
        FloralColors floralColor
    ) internal pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getFloralStyle(floralColor),
                '<path class="floralColor2" d="M170.3 62.5a9 9 0 0 1-3.6 15.2 9 9 0 0 1-8-1.6l-12.8 7.1c-2.8-.2-5.6.3-8.4 1.3 4.2-1.7 7.6-5.2 9.2-9.4l9.8-5c-.9-3.5.9-7.4 4-9 3.1-1.7 7.3-1 9.8 1.4ZM64.1 83.2l-12.8-7.1a9 9 0 0 1-8 1.5 9 9 0 0 1-5.7-5.4 9.3 9.3 0 0 1 2-9.7 9 9 0 0 1 9.9-1.4 8.2 8.2 0 0 1 4 9l9.8 5c1.6 4.2 5 7.7 9.2 9.4-2.8-1-5.6-1.5-8.4-1.3Z"/><path class="floralColor1" d="M67.6 93.7c.7-3.6 1.8-6.8 3.2-9.7a17.1 17.1 0 0 0-11.9.4 18.8 18.8 0 0 0-8.7 7.8c.6.2 2.9.2 8 3.2 5.2 3 8.7 7 8.7 7s0-5.2.7-8.7Zm74.7 0c-.6-3.5-1.7-6.8-3.2-9.7a20 20 0 0 1 6.8-.8c1.8.1 3.6.5 5.3 1.2 3.5 1.4 6.7 4.5 8.6 7.8-.6.2-2.9.2-8 3.2s-8.7 6.9-8.7 6.9-.1-5-.8-8.6ZM79.3 73a39.6 39.6 0 0 1 25.7-9c9.3 0 18.6 3 25.8 9 3.3 3 6.2 6.5 8.3 10.7a16.8 16.8 0 0 0 8.2-10.4c1.1-5-.4-10.6-4.2-14a14.6 14.6 0 0 0-15-2.4l2-3 8.2-12.4c4.7.5 8.6-3.3 9.5-7.3 1-4-1.3-8.4-5-10.2a9.4 9.4 0 0 0-11 2.6 8.6 8.6 0 0 0-.1 10.9l-9.5 14.9a19 19 0 0 0-17.2-9 19.4 19.4 0 0 0-17.2 9 1861 1861 0 0 1-9.5-15 8.7 8.7 0 0 0 0-10.8A9.4 9.4 0 0 0 67.1 24a9.4 9.4 0 0 0-5 10.2c.9 4 4.8 7.8 9.5 7.3L80 53.8l2 3.1a14.6 14.6 0 0 0-15 2.3 14.8 14.8 0 0 0-3.6 16c1.4 3.6 4.2 6.7 7.6 8.5 2.1-4.2 5-7.7 8.4-10.6Z"/><path class="floralColor2" d="m71.7 42.1 17.3 25 3.3-1.2 3.6-1L79 38.4v-1.8l1-6.2-2.9-6-5.4-1.5-4.9 1.5-4 4.3-1 4.7 2.4 5 7.5 3.8Zm66.3 0-17.3 25-3.2-1.2-3.6-1 16.8-26.6v-1.8l-.9-6.2 2.8-6 5.5-1.5 4.8 1.5 4 4.3 1.1 4.7-2.4 5-7.5 3.8Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M49.5 93.6s0 0 0 0a17.4 17.4 0 0 1 23-9 16.8 16.8 0 0 1-9.8-11.3c-1.2-5 .4-10.6 4.2-14a14.6 14.6 0 0 1 15-2.4m-8 11.5 5.5 5.8m-28.1 1.9 12.8 7.1"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M63.3 75.1s0 0 0 0l-9.8-5c.9-3.5-1-7.4-4-9a8.7 8.7 0 0 0-9.8 1.4 9.3 9.3 0 0 0-2.1 9.7 9 9 0 0 0 5.7 5.4 9 9 0 0 0 8-1.5m20.4-34.6L82 56.9l7.4 11.3"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="m96.7 66.3-9-14-9.4-14.8a8.7 8.7 0 0 0-.1-10.9 9.4 9.4 0 0 0-11-2.6 9.4 9.4 0 0 0-5 10.2c.9 4 4.8 7.8 9.5 7.3"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M87.8 52.4a19 19 0 0 1 17.2-9m0 9v13.2m55.5 28s0 0 0 0a17.4 17.4 0 0 0-23-9 16.8 16.8 0 0 0 9.7-11.3c1.2-5-.3-10.6-4.1-14a14.6 14.6 0 0 0-15-2.4m8 11.5-5.5 5.8m28.1 1.9-12.8 7.1"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="m146.7 75.1 9.8-5c-.9-3.5.9-7.4 4-9 3.1-1.7 7.3-1 9.8 1.4a9 9 0 0 1-3.6 15.2 9 9 0 0 1-8-1.6m-20.4-34.6L128 56.9l-7.5 11.3"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="m122.2 52.4 9.5-15a8.6 8.6 0 0 1 0-10.8 9.4 9.4 0 0 1 11.1-2.6 9.4 9.4 0 0 1 5 10.2c-.9 4-4.8 7.8-9.5 7.3m-25 24.8 9-14m-.1.1a19 19 0 0 0-17.2-9"/></svg>'
            ),
            Headwear.HeadwearVariants.FLORAL,
            _getHeadwearColor(floralColor)
        );
    }

    function _getFloralStyle(FloralColors floralColor) internal pure returns (string memory) {
        (string memory primaryColor, string memory secondaryColor) = _getFloralColor(floralColor);
        return
            string.concat(
                '<style>.floralColor1 { fill:',
                primaryColor,
                '}.floralColor2 { fill:',
                secondaryColor,
                '}</style>'
            );
    }

    function _getFloralColor(FloralColors floralColor) internal pure returns (string memory, string memory) {
        if (floralColor == FloralColors.GREEN) {
            return ('#F4FFDC', '#A0D170');
        } else if (floralColor == FloralColors.PURPLE) {
            return ('#F9F4FF', '#EAD7FF');
        } else if (floralColor == FloralColors.BLUE) {
            return ('#F4F6FF', '#D9E0FF');
        } else if (floralColor == FloralColors.GOLD) {
            return ('#FFEE93', '#FFCD3D');
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(FloralColors floralColor) internal pure returns (Headwear.HeadwearColors) {
        if (floralColor == FloralColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (floralColor == FloralColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (floralColor == FloralColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (floralColor == FloralColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
