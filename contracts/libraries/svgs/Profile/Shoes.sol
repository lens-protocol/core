// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Shoes {
    enum ShoeColors {
        GREEN,
        DARK,
        LIGHT
    }

    // // we take the 7th byte from the left for shoes color
    // uint8 color = uint8((seed >> 200) & 0xFF) % 3;
    function getShoes(ShoeColors shoeColor) external pure returns (string memory) {
        (string memory shoeColorHex1, string memory shoeColorHex2) = _getShoeColorHex(shoeColor);

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><style>.shColor1{fill:',
                shoeColorHex1,
                ';}.shColor2{fill:',
                shoeColorHex2,
                ';}.shStroke{stroke:#000;stroke-linecap:round;stroke-miterlimit:10;}</style><path class="shColor1" d="M75.4 281.7c1-.2 3.3 3.7 13.8 4 9.7.2 15.8-4.9 15.8-4.9s6.1 5 15.8 4.9c10.5-.3 12.7-4.2 13.6-4 2.9.4 7.2 3 6 6.4 3.7 4 6 8.4 7.4 14.2l.1.4.2 2c0-.4-.5 4.8-.8 4.6a19.3 19.3 0 0 0-9-3c-6.8.7-15.7 2-18.3 7.8-1.7 3.6-2.5 4.2-2 5.7-4.6-1-6.3-2-9.8-5.1-.5-.5-2.8-2.5-3.2-3.6-.5 1-2.6 3.1-3.1 3.6-3.7 3.1-4.5 4-9.2 5.1.4-1.5-1.4-2.1-3-5.7-2.7-5.8-10.5-7-17.4-7.7-2.5-.3-6.7 1.6-9 2.9-.3.2-1.4-5.1-1.4-4.7 0-.8.1-1.6.3-2.3a29.2 29.2 0 0 1 8.1-14.2c-1.3-3.3 2.2-6 5.1-6.4Z"/><path class="shColor2" d="m148.5 304.5 2.2 11c.6 2 .6 2.2-.8 4.6-1 1.5-7.1 9-21.2 9.4-14.5.6-21.8-5.6-23-7.5l-.1-9.2c.4 1 3.4 2.3 4 2.7 3.5 3.1 6.7 5.2 11.4 6.3l2 .2c6 1.2 11.6-1.5 16.8-4.6 2.9-1.6 5.4-2 7-4.6 1-1.9 2-4 2-6.4 0-.7-.2-1.3-.3-2ZM61.5 304.5l-2.2 11c-.6 2-.6 2.2.8 4.6 1 1.5 7.1 9 21.2 9.4 14.5.6 21.8-5.6 23-7.5l.1-9.2c-.4 1-3.4 2.3-4 2.7-3.5 3.1-6.7 5.2-11.4 6.3l-2 .2c-6 1.2-11.6-1.5-16.8-4.6-2.9-1.6-5.4-2-7-4.6-1-1.9-2-4-2-6.4 0-.7.2-1.3.3-2Z"/><path class="shColor2" d="M146.9 310.7a9.2 9.2 0 0 1-3.1 4.8c-2 2-5 4-8 4.8-5.3 1.5-10.8 2.9-15.8.4l-2.5-1.3c0-1.5 2.2-4.3 4.5-7.1a17.8 17.8 0 0 1 16.3-6c2.3.5 5.4.5 7 2.1.2.3 1.6 1.9 1.6 2.3ZM63.5 310.7a9.2 9.2 0 0 0 3.1 4.8c2 2 5 4 8 4.8 5.3 1.5 10.8 2.9 15.8.4l2.5-1.3c0-1.5-2.2-4.3-4.5-7.1a17.8 17.8 0 0 0-16.3-6c-2.3.5-5.4.5-7 2.1-.2.3-1.6 1.9-1.6 2.3Z"/><path class="shStroke" stroke-width="3" d="M105 321.8v-25"/><path class="shStroke" stroke-width="2" d="M98 293c2.5.2 5.2-.5 7-2"/><path class="shStroke" stroke-width="2.5" d="M74.8 281.6a24 24 0 0 0 29.8-.7"/><path class="shStroke" stroke-width="3" d="M62.6 310.4c4.4 6.7 12.4 11 20.5 11.2 8.2.1 16.3-3.8 21-10.3"/><path class="shStroke" stroke-width="2" d="M92.4 319.2a19.4 19.4 0 0 0-12-11.8c-5.7-1.8-12.1-1-17 2.2"/><path class="shStroke" stroke-width="4" d="M74 280.8a9.4 9.4 0 0 0-4 9.4c-5 4.3-8 11-8 17.7 0 1.4-.8 2.8-1.6 4-.6.9-1 2-1 3l-.2 1.7a9 9 0 0 0 2.9 7 31.3 31.3 0 0 0 41.7-1m32.3-41.8a9.5 9.5 0 0 1 4 9.4c5 4.3 8 11 8 17.7 0 1.4.8 2.8 1.5 4 .6.9 1 2 1.1 3l.2 1.7a9 9 0 0 1-3 7 31.3 31.3 0 0 1-41.6-1"/><path class="shStroke" stroke-width="2" d="M112 293c-2.5.2-5.2-.5-7-2"/><path class="shStroke" stroke-width="2.5" d="M135.3 281.6a24.7 24.7 0 0 1-30.2-.7"/><path class="shStroke" stroke-width="3" d="M147.4 310.4a25.6 25.6 0 0 1-20.5 11.2c-8.1.1-16.3-3.8-21-10.3"/><path class="shStroke" stroke-width="2" d="M117.6 319.2c2-5.5 6.5-10 12.1-11.8 5.6-1.8 12-1 17 2.2"/><path class="shColor2" d="M76.6 295.2a4 4 0 0 1 4.3-3c3.4.3 6.7 1.2 9.9 2.6 1.7.8 2.6 2.7 2.1 4.6l-.3 1.2c-.6 2-2.9 3.1-4.8 2.3a26 26 0 0 0-8.5-2.3 3.4 3.4 0 0 1-3-4.2l.3-1.2ZM133.5 295.2a4 4 0 0 0-4.3-3c-3.4.3-6.7 1.2-9.9 2.6a3.9 3.9 0 0 0-2.1 4.6l.3 1.2c.6 2 2.9 3.1 4.8 2.3a26 26 0 0 1 8.5-2.3 3.4 3.4 0 0 0 3-4.2l-.3-1.2Z"/><path class="shStroke" stroke-width="2" d="M76.6 295.2a4 4 0 0 1 4.3-3v0c3.4.3 6.7 1.2 9.9 2.6v0c1.7.8 2.6 2.7 2.1 4.6l-.3 1.2c-.6 2-2.9 3.1-4.8 2.3v0a26 26 0 0 0-8.5-2.3v0a3.4 3.4 0 0 1-3-4.2l.3-1.2ZM133.5 295.2a4 4 0 0 0-4.3-3v0c-3.4.3-6.7 1.2-9.9 2.6v0a3.9 3.9 0 0 0-2.1 4.6l.3 1.2c.6 2 2.9 3.1 4.8 2.3v0a26 26 0 0 1 8.5-2.3v0a3.4 3.4 0 0 0 3-4.2l-.3-1.2Z"/></svg>'
            );
    }

    function _getShoeColorHex(ShoeColors shoeColor) internal pure returns (string memory, string memory) {
        if (shoeColor == ShoeColors.GREEN) {
            return ('#93A97D', '#F4FFDC');
        } else if (shoeColor == ShoeColors.DARK) {
            return ('#575757', '#DBDBDB');
        } else if (shoeColor == ShoeColors.LIGHT) {
            return ('#EAEAEA', '#FFFFFF');
        } else {
            revert(); // Avoid warnings.
        }
    }
}
