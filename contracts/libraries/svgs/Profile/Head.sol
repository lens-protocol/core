// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Skin} from "./Helpers.sol";

library Head {
    enum HeadColors {
        GREEN,
        PURPLE,
        BLUE,
        GOLD
    }

    // // we take the 1th byte from the left for skin color
    // uint8 color = uint8((seed >> 248) & 0xFF) % 3;
    function getHead(HeadColors headColor) external pure returns (string memory) {
        if (headColor == HeadColors.GOLD) {
            return
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><path fill="url(#a)" d="M143.3 104.8c-.8.8-2.2.3-2.2-.9v-3.3c-1.3-46.1-71-46.1-72.2 0v3.3c0 1.1-1.4 1.7-2.2 1a145 145 0 0 0-2.4-2.4c-33.6-31.7-82.8 17.4-51 50.9l2.3 2.4A138.4 138.4 0 0 0 105 194s51 0 89.4-38.2l2.4-2.4c31.7-33.5-17.5-82.6-51-51l-2.5 2.4Z"/><circle cx="4" cy="4" r="4" fill="#fff" fill-opacity=".5" transform="matrix(-1 0 0 1 199.3 126)"/><path fill="#fff" fill-opacity=".5" d="M195.5 117.5a5 5 0 0 1-9 4 6.7 6.7 0 0 0-.3-.7l-1.2-2c-1-1.7-2.3-3.5-3.6-4.6-1.5-1.2-2.6-2-3.7-2.5l-1.7-.8a3 3 0 0 1-1.4-4l.1-.3c.8-1.5 0-3.3-1.5-3.5-1.9-.3-3.4-.3-5-.2h-.1a1.8 1.8 0 0 1-.3-3.5 23.6 23.6 0 0 1 16.6 4.8c1 .7 2.2 1.5 3.3 2.5a29.2 29.2 0 0 1 7.7 10.4v.3h.1"/><path stroke="#000" stroke-linecap="square" stroke-linejoin="round" stroke-width="4" d="M143.3 104.8v0c-.8.8-2.2.3-2.2-.9v0-3.3c-1.3-46.1-71-46.1-72.2 0v3.3c0 1.1-1.4 1.7-2.2 1v0a145 145 0 0 0-2.4-2.4c-33.6-31.7-82.8 17.4-51 50.9l2.3 2.4A138.4 138.4 0 0 0 105 194s51 0 89.4-38.2l2.4-2.4c31.7-33.5-17.5-82.6-51-51l-2.5 2.4Z"/><defs><radialGradient id="a" cx="0" cy="0" r="1" gradientTransform="matrix(0 128 -204 0 105 66)" gradientUnits="userSpaceOnUse"><stop stop-color="#FFDB76"/><stop offset="1" stop-color="#F8C944"/></radialGradient></defs></svg>';
        } else {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><path fill="',
                    _getHeadColorHex(headColor),
                    '" d="M143.3 104.8c-.8.8-2.2.3-2.2-.9v-3.3c-1.3-46.1-71-46.1-72.2 0v3.3c0 1.1-1.4 1.7-2.2 1a145 145 0 0 0-2.4-2.4c-33.6-31.7-82.8 17.4-51 50.9l2.3 2.4A138.4 138.4 0 0 0 105 194s51 0 89.4-38.2l2.4-2.4c31.7-33.5-17.5-82.6-51-51l-2.5 2.4Z"/><circle cx="4" cy="4" r="4" fill="#fff" fill-opacity=".5" transform="matrix(-1 0 0 1 199.3 126)"/><path fill="#fff" fill-opacity=".5" d="M195.5 117.5a5 5 0 0 1-9 4 6.7 6.7 0 0 0-.3-.7l-1.2-2c-1-1.7-2.3-3.5-3.6-4.6-1.5-1.2-2.6-2-3.7-2.5l-1.7-.8a3 3 0 0 1-1.4-4l.1-.3c.8-1.5 0-3.3-1.5-3.5-1.9-.3-3.4-.3-5-.2h-.1a1.8 1.8 0 0 1-.3-3.5 23.6 23.6 0 0 1 16.6 4.8c1 .7 2.2 1.5 3.3 2.5a29.2 29.2 0 0 1 7.7 10.4v.3h.1"/><path stroke="#000" stroke-linecap="square" stroke-linejoin="round" stroke-width="4" d="M143.3 104.8v0c-.8.8-2.2.3-2.2-.9v0-3.3c-1.3-46.1-71-46.1-72.2 0v3.3c0 1.1-1.4 1.7-2.2 1v0a145 145 0 0 0-2.4-2.4c-33.6-31.7-82.8 17.4-51 50.9l2.3 2.4A138.4 138.4 0 0 0 105 194s51 0 89.4-38.2l2.4-2.4c31.7-33.5-17.5-82.6-51-51l-2.5 2.4Z"/></svg>'
                );
        }
    }

    function _getHeadColorHex(HeadColors headColor) internal pure returns (string memory) {
        return Skin.getSkinColor(Skin.SkinColors(uint8(headColor)));
    }
}
