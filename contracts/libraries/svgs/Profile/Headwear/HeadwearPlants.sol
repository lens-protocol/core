// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from '../Headwear.sol';

library HeadwearPlants {
    enum PlantsColors {
        GREEN,
        BLUE,
        PURPLE,
        GOLD
    }

    // // we take the 16th byte from the left for plants color
    // uint8 color = uint8((seed >> 128) & 0xFF) % 3;
    function getPlants(
        PlantsColors plantsColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        // plants (4 colors: green, purple, blue, gold)
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getPlantsStyle(plantsColor),
                '<path class="color1" d="m64.3 81 10.3-1.4-3.4 8.8L69 96v6l-1.4 2.6-6.7 2.1-9-1.3-6.6-3.5 2-4.5 6-8.9 11-7.5Z"/><path class="color2" d="M56.8 106h7.6l-1 2.1-2 2-3.1 1.5-4 1.7h-5.8l-4.5-1.1-3.9-3.2-2.2-5 .6-2.8 1.6-1.2 4 1.2 5.5 2.2 7.2 2.5Z"/><path class="color1" d="m96.3 59.3 2.5 7.3 6.2-1.2v-12l-2.3-5-4.6-4.3-4.8-4.6-7.1-3.7-8.2-1.5h-7l-7.4 2.4-8 6L51 50v1.9h5.3l3.6-1 2.6-4 3.5-2 5-1.5 7 .8 7.2 2.8 6.3 4.9 4.7 7.5Z"/><path class="color2" d="m71.8 64 3.6 6.3-3.6 2.9-3.7 1-5.3-1.7v-2.2l-.3-5.7v-11l5.2 3.6 4 6.9Zm-29.4 6-3.6 6.2 3.6 2.8 3.6 1 9.7-3.8-2-2.5-2-3.2-1.6-7.6L48 54l-5.6 4v12Z"/><path class="color2" d="m50.1 63.4-1.5-8.2 3.6-2.9 3.7-1 4.8 3.2 2.7 3.2-.7 4V70l-2 7.5-7.5-4.6-3.1-9.5Zm-9.3 10 1.4-7.3v-3.9l-.7-5.2-5.1 8v5.7l.5 1.5 3.9 1.2Z"/><path class="hwline4" d="M98.3 66.6c-1-6.1-3.7-12-8-16.4A23.7 23.7 0 0 0 73.5 43c-6.2 0-10.4 3-13.9 8.2"/><path class="hwline4" d="M104.8 53.1c-3.6-7-9.4-13-16.6-16.3a29.5 29.5 0 0 0-23-.8c-7.4 3-13.3 9.5-15 17.2"/><path class="hwline4" d="M57.4 52c-2.6-1.3-6 .4-7.3 3-1.3 2.6-1 5.8-.3 8.6a28.3 28.3 0 0 0 8.7 14l1 .5c.6 0 1-.7 1.3-1.3 4-8.2 4.1-21-3.4-24.8h0ZM38 77.2a15.1 15.1 0 0 0 17-1.8"/><path class="hwline4" d="M58.8 52.6c2.9-.7 5.9 1 7.8 3.3 1.8 2.3 2.8 5.1 4 7.8 1.2 2.8 2.7 5.5 5.1 7.2-3 3.4-8.4 4.4-12.4 2.3M49.2 53.6c-2.5-.3-5.1 1-6.9 2.9-1.8 1.9-3 4.3-4 6.6-1 2.4-2 4.9-3.7 6.9a9.7 9.7 0 0 0 4 4.3m6.6 26.5c3.3-5.5 6.7-11 11.5-15.1 4.8-4.2 12-6.5 18.3-5.6 0 0-4.3 6.5-5.8 14.2-.8 4.1-.8 10.3-.8 10.3"/><path class="hwline4" d="M68.4 104.6a23.7 23.7 0 0 1-14.2 1c-3.8-1.3-7.4-3.3-11-5-1.5-.8-3.4-1.4-4.8-.4-1 .9-1.1 2.5-.9 3.8a12 12 0 0 0 7.6 8.6c3.7 1.5 8 1.2 11.7-.2 3.7-1.4 9.3-4.7 11.6-7.8Z"/><path class="hwline3" d="M74.4 80A35.2 35.2 0 0 0 58 97.4m-8-43.1c-3-.6-6 2-7.2 5-1.2 2.9-1 6.2-1.3 9.3-.3 3.2-1 6.6-3.6 8.6"/><path class="color1" d="m145.5 81-10.4-1.4 3.5 8.8 2.2 7.5v6l1.5 2.6 6.7 2.1 9-1.3 6.5-3.5-2-4.5-6-8.9-11-7.5Z"/><path class="color2" d="M153 106h-7.6l1 2.1 2 2 3.1 1.5 4 1.7h5.8l4.4-1.1 4-3.2 2.1-5-.6-2.8-1.6-1.2-3.9 1.2-5.5 2.2-7.3 2.5Z"/><path class="color1" d="m113.5 59.3-2.5 7.3-6.2-1.2v-12l2.3-5 4.6-4.3 4.7-4.6 7.2-3.7 8.1-1.5h7l7.5 2.4 8 6 4.5 7.2v1.9h-5.3l-3.7-1-2.6-4-3.4-2-5-1.5-7 .8-7.2 2.8-6.3 4.9-4.7 7.5Z"/><path class="color2" d="m138 64-3.6 6.3 3.6 2.9 3.6 1 5.4-1.7v-2.2l.3-5.7v-11l-5.2 3.6-4 6.9Zm29.4 6 3.6 6.2-3.6 2.8-3.7 1-9.7-3.8 2.2-2.5 2-3.2 1.5-7.6 2.1-8.8 5.6 4V70Z"/><path class="color2" d="m159.7 63.4 1.5-8.2-3.7-2.9-3.6-1-4.8 3.2-2.7 3.2.7 4V70l2 7.5 7.5-4.6 3-9.5Zm9.3 10-1.4-7.3v-3.9l.7-5.2 5.1 8v5.7l-.6 1.5-3.8 1.2Z"/><path class="hwline4" d="M111.5 66.4c1-6.1 3.7-11.8 8-16.2a23.7 23.7 0 0 1 16.7-7.1c6.2 0 10.4 3 13.9 8.2"/><path class="hwline4" d="M103.3 56.5c4-9.3 11.1-16.4 18.3-19.7a29.5 29.5 0 0 1 23-.8c7.4 3 13.3 9.5 15 17.2"/><path class="hwline4" d="M152.4 52c2.6-1.3 6 .4 7.3 3 1.3 2.6 1 5.8.3 8.6a28.3 28.3 0 0 1-8.8 14c-.2.2-.5.4-.9.5-.6 0-1-.7-1.4-1.3-3.8-8.2-4-21 3.5-24.8h0Zm19.5 25.2a15.1 15.1 0 0 1-17.3-1.8"/><path class="hwline4" d="M151 52.6c-2.9-.7-6 1-7.8 3.3-1.8 2.3-2.9 5.1-4 7.8A15.6 15.6 0 0 1 134 71c3 3.4 8.3 4.4 12.4 2.3m14.2-19.7c2.5-.3 5.1 1 6.9 2.9 1.8 1.9 2.9 4.3 4 6.6 1 2.4 2 4.9 3.7 6.9a9.7 9.7 0 0 1-4 4.3m-6.6 26.5c-3.3-5.5-6.7-11-11.5-15.1-4.8-4.2-12-6.5-18.3-5.6 0 0 4.2 6.5 5.8 14.2.8 4.1.8 10.3.8 10.3"/><path class="hwline4" d="M141.4 104.6a23.7 23.7 0 0 0 14.2 1c3.8-1.3 7.3-3.3 11-5 1.5-.8 3.4-1.4 4.7-.4 1 .9 1.2 2.5 1 3.8a12 12 0 0 1-7.6 8.6c-3.7 1.5-8 1.2-11.7-.2a29.3 29.3 0 0 1-11.6-7.8Z"/><path class="hwline3" d="M135.4 80a35.2 35.2 0 0 1 16.4 17.4m7.9-43.1c3.2-.6 6.1 2 7.3 5 1.1 2.9 1 6.2 1.3 9.3.2 3.2 1 6.6 3.6 8.6"/><path fill="#000" fill-opacity=".1" d="m111.5 66 1.9-8s-4.8 3.1-8.4 3.1c-3.6 0-8.4-3-8.4-3l1.5 8h13.4Z"/><path class="hwline4" d="M98 66.5s4.2-.5 7-.5c2.6 0 6.8.5 6.8.5"/></svg>'
            ),
            Headwear.HeadwearVariants.PLANTS,
            _getHeadwearColor(plantsColor)
        );
    }

    function _getPlantsStyle(PlantsColors plantsColor) internal pure returns (string memory) {
        (string memory leafsColor1, string memory leafsColor2) = _getPlantsColor(plantsColor);

        return
            string.concat(
                '<style>.color1 { fill: ',
                leafsColor1,
                ' }.color2 { fill: ',
                leafsColor2,
                ' }.hwline3 {stroke: black; stroke-linecap: round; stroke-linejoin: round; stroke-width: 3}.hwline4 {stroke: black; stroke-linecap: round; stroke-linejoin: round; stroke-width: 4}</style>'
            );
    }

    function _getPlantsColor(PlantsColors plantsColor) internal pure returns (string memory, string memory) {
        if (plantsColor == PlantsColors.GREEN) {
            return ('#A0D170', '#FFF');
        } else if (plantsColor == PlantsColors.PURPLE) {
            return ('#EAD7FF', '#FFF');
        } else if (plantsColor == PlantsColors.BLUE) {
            return ('#D9E0FF', '#FFF');
        } else if (plantsColor == PlantsColors.GOLD) {
            return ('#FFCD3D', '#FFF');
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(PlantsColors plantsColor) internal pure returns (Headwear.HeadwearColors) {
        if (plantsColor == PlantsColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (plantsColor == PlantsColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (plantsColor == PlantsColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (plantsColor == PlantsColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
