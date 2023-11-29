// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from 'contracts/libraries/svgs/Profile/Headwear.sol';
import {LensColors} from 'contracts/libraries/svgs/Profile/LensColors.sol';

library HeadwearScout {
    enum ScoutColors {
        GREEN,
        PINK,
        PURPLE,
        BLUE,
        GOLD
    }

    function getScout(
        ScoutColors scoutColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getScoutStyle(scoutColor),
                '<path class="headwearColorL" d="M205.8 92.3a35 35 0 0 0 14.5 13.8c-9.6-3.6-23-5.1-41.4-8-18-2.8-36.8-3.7-55.2-3.7-18.5 0-37.2.9-55.2 3.7-18.4 2.9-31.8 4.4-41.5 8a34.4 34.4 0 0 0 14.5-13.8c3-5.5 5.4-11.4 9.2-16.2 4.5-5.5 10.6-9 16.8-12a124.5 124.5 0 0 1 56.2-12.3A124.5 124.5 0 0 1 179.9 64c6.1 3 12.2 6.5 16.7 12 3.9 4.8 6.3 10.7 9.2 16.2Z"/><path class="headwearColorB" d="M142.4 52.9c-6-.8-12.3-1.1-18.7-1.1 0-6.5 2.8-14 8.4-17.6a29 29 0 0 1 19.3-4c1 4.4 1.8 9 .7 13.3a13 13 0 0 1-9.7 9.4Zm-27.1-18.7c5.5 3.7 8.4 11.1 8.4 17.6-6.5 0-12.7.3-18.8 1-4.4-.6-8.6-5-9.7-9.3a30 30 0 0 1 .7-13.3 29 29 0 0 1 19.4 4Z"/><path class="headwearColorL" d="M241.2 115.7c2.6 2.8 4.3 6.6 3.6 10.4.5-3.3-2.7-5.8-5.7-7.3-8.7-4.6-18.3-3.4-27.9-5.6-28.8-6.5-61-10-87.5-10-26.6 0-58.8 3.5-87.6 10-9.6 2.2-19.3 2.6-28 7.1-3 1.5-6 2.6-5.5 5.8-.8-3.7.7-7.9 3.3-10.6 2.5-2.6 9-4.6 21-8.7 9.7-3.3 23.2-4.8 41.6-7.4a374.7 374.7 0 0 1 110.4 0c18.3 2.6 31.9 3.8 41.6 7 12 4.2 18.2 6.8 20.7 9.3Z"/><path class="hwStr1" stroke-width="4" d="M123.7 104.5c-26.6 0-58.8 2.9-87.6 7.9a140 140 0 0 0-27.9 7.1c-3 1.2-6.1 3.1-5.6 5.7.3 1.5 5 5.3 19.2 7.2M27 106s0 0 0 0a34.4 34.4 0 0 0 14.5-13.7c3-5.5 5.4-11.4 9.2-16.2a46.4 46.4 0 0 1 16.8-12 124.6 124.6 0 0 1 56.2-12.3"/><path class="hwStr1" stroke-width="4" d="M105 52.9c-4.5-.7-8.7-5-9.8-9.4a30 30 0 0 1 .7-13.3 29 29 0 0 1 19.4 4c5.5 3.7 8.4 11.1 8.4 17.6"/><path class="hwStr1" stroke-width="3" d="M107.4 42c4 1.8 7.3 5.3 9 9.5"/><path class="hwStr1" stroke-width="4" d="M123.7 104.5c26.5 0 58.7 2.9 87.5 7.9a140 140 0 0 1 28 7.1c2.9 1.2 6 3.1 5.6 5.7-.4 1.5-5 5.3-19.3 7.2"/><path class="hwStr1" stroke-width="4" d="M2.6 123.1s0 0 0 0c-.8-3 1-6.2 3.6-8.4 2.5-2 8.7-5.3 20.8-8.6m217.8 17s0 0 0 0c.7-3-1-6.2-3.6-8.4-2.5-2-8.7-5.3-20.9-8.6m.1-.1s0 0 0 0a34.4 34.4 0 0 1-14.6-13.7c-3-5.5-5.3-11.4-9.2-16.2a46.4 46.4 0 0 0-16.8-12 124.6 124.6 0 0 0-56.1-12.3"/><path class="hwStr1" stroke-width="4" d="M142.4 52.9a13 13 0 0 0 9.7-9.4c1-4.3.4-8.9-.7-13.3a29 29 0 0 0-19.3 4c-5.6 3.7-8.4 11.1-8.4 17.6"/><path class="hwStr1" stroke-width="3" d="M140 42a17.1 17.1 0 0 0-9 9.5"/><path class="headwearColorL" d="M4.5 124.7c-2-2.6 17.4-7.4 17.4-7.4s-1.3 4-1.8 6.8c-.3 2.3-.4 6-.4 6s-12-1.3-15.2-5.4Zm238.4 0c2-2.6-17.4-7.4-17.4-7.4s1.3 4 1.7 6.8c.4 2.3.5 6 .5 6s12-1.3 15.2-5.4Z"/><path fill="#000" fill-opacity=".3" d="M4.5 124.7c-2-2.6 17.4-7.4 17.4-7.4s-1.3 4-1.8 6.8c-.3 2.3-.4 6-.4 6s-12-1.3-15.2-5.4Zm238.4 0c2-2.6-17.4-7.4-17.4-7.4s1.3 4 1.7 6.8c.4 2.3.5 6 .5 6s12-1.3 15.2-5.4Z"/><path fill="#fff" d="M130.7 67.7c-.1.2-.4 0-.4-.1v-.7c-.2-8.4-13-8.4-13.3 0v.7c0 .2-.2.3-.4.1l-.4-.4c-6.2-5.8-15.2 3.2-9.4 9.3l.5.5c7 7 16.4 7 16.4 7s9.4 0 16.4-7l.4-.5c5.8-6.1-3.2-15.1-9.4-9.3l-.4.4Z"/><path stroke="#000" stroke-linecap="square" stroke-linejoin="round" stroke-width="3" d="M130.7 67.7v0c-.1.2-.4 0-.4-.1v0-.7c-.2-8.4-13-8.4-13.3 0v.7c0 .2-.2.3-.4.1v0l-.4-.4c-6.2-5.8-15.2 3.2-9.4 9.3l.5.5c7 7 16.4 7 16.4 7s9.4 0 16.4-7l.4-.5c5.8-6.1-3.2-15.1-9.4-9.3l-.4.4Z"/><path class="hwStr1" stroke-width="3" d="M27 106.6c9.7-2.7 23.1-5.4 41.5-7.5a476 476 0 0 1 110.4 0c18.3 2.1 31.8 4.8 41.4 7.5"/><path stroke="#000" stroke-dasharray="9 9" stroke-linecap="round" stroke-linejoin="round" stroke-opacity=".2" stroke-width="2.5" d="M37.5 98.7c8.3-1.8 18.5-3.5 31-5a476 476 0 0 1 110.4 0c12.9 1.5 23.4 3.3 31.8 5.1"/><path class="headwearColorL" fill-rule="evenodd" d="m30.6 113.6.9 1.5c9.6 13 8.5 26 6.1 38.4l-1.3 6.4c-2 10.2-4 19.7-1.6 29.2l.4 1.3a2 2 0 0 1-1.6 2.5l-4.3.7a2 2 0 0 1-2.3-1.4l-.4-1.7c-2.8-11-.5-22 1.7-32.2l1.2-5.9c2.3-12 3-23-5-33.6l-2.2-3 8.4-2.2Z" clip-rule="evenodd"/><path stroke="#000" stroke-linecap="round" stroke-width="3" d="m26 187.4 8-1.5"/><path class="hwStr1" stroke-width="3" d="m30.6 113.6.9 1.5c9.6 13 8.5 26 6.1 38.4l-1.3 6.4c-2 10.2-4 19.7-1.6 29.2l.4 1.3a2 2 0 0 1-1.6 2.5l-4.3.7a2 2 0 0 1-2.3-1.4l-.4-1.7c-2.8-11-.5-22 1.7-32.2l1.2-5.9c2.3-12 3-23-5-33.6l-2.2-3 8.4-2.2Z" clip-rule="evenodd"/><path fill="#000" fill-opacity=".2" d="m33.8 186.6-7.9 1.5 1.5 6h3.8l4-2.1-1.4-5.4Z"/><path class="headwearColorL" fill-rule="evenodd" d="m216.7 113.6-.8 1.5c-9.7 13-8.6 26-6.2 38.4l1.3 6.4c2.1 10.2 4 19.7 1.6 29.2l-.3 1.3a2 2 0 0 0 1.6 2.5l4.2.7c1 .2 2-.4 2.3-1.4l.4-1.7c2.8-11 .5-22-1.6-32.2l-1.2-5.9c-2.3-12-3-23 5-33.6l2.2-3-8.5-2.2Z" clip-rule="evenodd"/><path stroke="#000" stroke-linecap="round" stroke-width="3" d="m221.4 187.4-8-1.5"/><path class="hwStr1" stroke-width="3" d="m216.7 113.6-.8 1.5c-9.7 13-8.6 26-6.2 38.4l1.3 6.4c2.1 10.2 4 19.7 1.6 29.2l-.3 1.3a2 2 0 0 0 1.6 2.5l4.2.7c1 .2 2-.4 2.3-1.4l.4-1.7c2.8-11 .5-22-1.6-32.2l-1.2-5.9c-2.3-12-3-23 5-33.6l2.2-3-8.5-2.2Z" clip-rule="evenodd"/><path fill="#000" fill-opacity=".2" d="m213.5 186.6 7.9 1.5-1.5 6h-3.8l-3.9-2.1 1.3-5.4Z"/></svg>'
            ),
            Headwear.HeadwearVariants.SCOUT,
            _getHeadwearColor(scoutColor)
        );
    }

    function _getScoutStyle(ScoutColors scoutColor) internal pure returns (string memory) {
        (string memory lightColor, string memory baseColor) = _getScoutColor(scoutColor);
        return
            string.concat(
                '<style>.headwearColorL { fill:',
                lightColor,
                '}.headwearColorB { fill:',
                baseColor,
                '}.hwStr1 {stroke: #000;stroke-linecap: round;stroke-linejoin: round;}</style>'
            );
    }

    function _getScoutColor(ScoutColors scoutColor) internal pure returns (string memory, string memory) {
        if (scoutColor == ScoutColors.GREEN) {
            return (LensColors.lightGreen, LensColors.baseGreen);
        } else if (scoutColor == ScoutColors.PURPLE) {
            return (LensColors.lightPurple, LensColors.basePurple);
        } else if (scoutColor == ScoutColors.BLUE) {
            return (LensColors.lightBlue, LensColors.baseBlue);
        } else if (scoutColor == ScoutColors.PINK) {
            return (LensColors.lightPink, LensColors.basePink);
        } else if (scoutColor == ScoutColors.GOLD) {
            return (LensColors.lightGold, LensColors.baseGold);
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(ScoutColors scoutColor) internal pure returns (Headwear.HeadwearColors) {
        if (scoutColor == ScoutColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (scoutColor == ScoutColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (scoutColor == ScoutColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (scoutColor == ScoutColors.PINK) {
            return Headwear.HeadwearColors.PINK;
        } else if (scoutColor == ScoutColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
