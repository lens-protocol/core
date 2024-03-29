// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Hands} from '../Hands.sol';

library BodyTShirt {
    function getBody(Hands.HandsVariants handsVariant) public pure returns (string memory) {
        if (handsVariant == Hands.HandsVariants.HANDSDOWN) {
            return
                '<path class="handsColor" d="m55.9 209.2 13.9 6.7-4.5 17.8 2 12-3 5.8-8.4 1.4H44.4l-9.4-7.2 1.5-13.4 10.4-6.8 9-16.3ZM154.2 210.2l-14 6.7 4.5 17.8-2 12 3 4.8 8.5 2.4h11.4l9.4-7.2-1.5-13.5-10.4-6.7-9-16.3Z"/><path class="bodyColor1" d="M73.7 186.1S92.5 182 105 182a186 186 0 0 1 31.3 4.1l8.4 6.3 11.4 13-15.6 9 4.2 28.4-8.4 8.7-15.4 4.8-15.9 1.4-15.9-1.4-15.4-4.8-8.4-8.7 4.2-28.3-14.1-9.2 9.9-13 8.4-6.2Z"/><path class="bStr1 bStr3" stroke-dasharray="5 5" d="M125 191.3c0 9.2-9 16.7-20 16.7s-20-7.5-20-16.7 9-9.3 20-9.3 20 0 20 9.3Z"/><path class="bStr1" stroke-width="4" d="M55.9 209.4c-2.6 4.3-5.1 8.6-7.7 13.5a16.2 16.2 0 0 1-6 5.8 15 15 0 0 0-7 10.1 13.6 13.6 0 0 0 7.4 14.1c4.2 2 9.5 1.4 13.3-1.2"/><path class="bStr1" stroke-width="2" d="M57.8 247.6a11.2 11.2 0 0 1-5 4.8M152.2 247.6c1.5 2.4 2.4 3.4 5 4.8"/><path class="bStr1" stroke-width="4" d="M56 251.7a8 8 0 0 0 7.9 0 7.1 7.1 0 0 0 3.7-6.5"/><path class="bStr1" stroke-width="3" d="m70.1 218.2 3.1-10.7M139.8 218.2l-3-10.7M67.8 245.3a55.3 55.3 0 0 0 36.7 12.4"/><path class="bStr1" stroke-width="4" d="M74.1 250.8c-2-2-4.1-3.3-5.9-5a10 10 0 0 1-3.2-6c-.2-1.6.2-3.2.6-4.8l4.7-19.4a25.6 25.6 0 0 1-13.7-8.2c-1.1-1.3-1-3.1 0-4.5 2.8-4 5.9-8 9.6-11.6 4.5-4.2 10-7.4 16.3-8h45c6.2.6 11.8 3.8 16.2 8 3.8 3.5 6.8 7.7 9.7 11.6 1 1.4 1 3.2 0 4.5-3.4 4-8.3 7-13.7 8.2l4.7 19.4c.4 1.6.7 3.2.6 4.8a10 10 0 0 1-3.3 6c-1.7 1.7-3.8 3-5.9 5"/><path class="bStr1" stroke-width="3" d="M142.2 245.3a58.7 58.7 0 0 1-37.7 12.4"/><path class="bStr1" stroke-width="4" d="M154 209.4c2.5 4.3 5 8.6 7.6 13.5 1.3 2.5 3.7 4.3 6.1 5.8a15 15 0 0 1 7 10.1c.9 5.6-2.2 11.6-7.4 14.1-4.2 2-9.6 1.4-13.3-1.2M153.8 251.7a8 8 0 0 1-7.8 0c-2.4-1.4-3.9-3.3-3.8-6"/><path class="handsColor" d="M121 190.6c0 7.5-7.2 13.5-16 13.5s-16-6-16-13.5 7.2-7.6 16-7.6 16 0 16 7.6Z"/><path class="bStr1" stroke-width="2.5" d="M121 190.6c0 7.5-7.2 13.5-16 13.5s-16-6-16-13.5 7.2-7.6 16-7.6 16 0 16 7.6Z"/></svg>';
        } else if (handsVariant == Hands.HandsVariants.PEACEDOUBLE) {
            return
                '<path class="bodyColor1" d="M73.7 186.1S92.5 182 105 182a186 186 0 0 1 31.3 4.1l8.4 6.3 11.4 13-15.6 9 4.2 28.4-8.4 8.7-15.4 4.8-15.9 1.4-15.9-1.4-15.4-4.8-8.4-8.7 4.2-28.3-14.1-9.2 9.9-13 8.4-6.2Z"/><path class="bStr1 bStr3" stroke-dasharray="5 5" d="M125 191.3c0 9.2-9 16.7-20 16.7s-20-7.5-20-16.7 9-9.3 20-9.3 20 0 20 9.3Z"/><path class="bStr1" stroke-width="3" d="m70.1 218.2 3.1-10.7m66.6 10.7-3-10.7m-69 37.8a55.3 55.3 0 0 0 36.7 12.4"/><path class="bStr1" stroke-width="4" d="M74.1 250.8c-2-2-4.1-3.3-5.9-5a10 10 0 0 1-3.2-6c-.2-1.6.2-3.2.6-4.8l4.7-19.4a25.6 25.6 0 0 1-13.7-8.2c-1.1-1.3-1-3.1 0-4.5 2.8-4 5.9-8 9.6-11.6a28 28 0 0 1 16.3-8h45c6.2.6 11.8 3.8 16.2 8 3.8 3.5 6.8 7.7 9.7 11.6 1 1.4 1 3.2 0 4.5-3.4 4-8.3 7-13.7 8.2l4.7 19.4c.4 1.6.7 3.2.6 4.8a10 10 0 0 1-3.3 6c-1.7 1.7-3.8 3-5.9 5"/><path class="bStr1" stroke-width="3" d="M142.2 245.3a58.7 58.7 0 0 1-37.7 12.4"/><path class="handsColor" d="M121 190.6c0 7.5-7.2 13.5-16 13.5s-16-6-16-13.5 7.2-7.6 16-7.6 16 0 16 7.6Z"/><path class="bStr1" stroke-width="2.5" d="M121 190.6c0 7.5-7.2 13.5-16 13.5s-16-6-16-13.5 7.2-7.6 16-7.6 16 0 16 7.6Z"/></svg>';
        } else if (handsVariant == Hands.HandsVariants.PEACESINGLE) {
            return
                '<path class="handsColor" d="m55.9 209.2 13.9 6.7-4.5 17.8 2 12-3 5.8-8.4 1.4H44.4l-9.4-7.2 1.5-13.4 10.4-6.8 9-16.3Z"/><path class="bodyColor1" d="M73.7 186.1S92.5 182 105 182a186 186 0 0 1 31.3 4.1l8.4 6.3 11.4 13-15.6 9 4.2 28.4-8.4 8.7-15.4 4.8-15.9 1.4-15.9-1.4-15.4-4.8-8.4-8.7 4.2-28.3-14.1-9.2 9.9-13 8.4-6.2Z"/><path class="bStr1 bStr3" stroke-dasharray="5 5" d="M125 191.3c0 9.2-9 16.7-20 16.7s-20-7.5-20-16.7 9-9.3 20-9.3 20 0 20 9.3Z"/><path class="bStr1" stroke-width="4" d="M55.9 209.4c-2.6 4.3-5.1 8.6-7.7 13.5a16.2 16.2 0 0 1-6 5.8 15 15 0 0 0-7 10.1 13.6 13.6 0 0 0 7.4 14.1c4.2 2 9.5 1.4 13.3-1.2"/><path class="bStr1" stroke-width="2" d="M57.8 247.6a11.2 11.2 0 0 1-5 4.8"/><path class="bStr1" stroke-width="4" d="M56 251.7a8 8 0 0 0 7.9 0 7.1 7.1 0 0 0 3.7-6.5"/><path class="bStr1" stroke-width="3" d="m70.1 218.2 3.1-10.7m66.6 10.7-3-10.7m-69 37.8a55.3 55.3 0 0 0 36.7 12.4"/><path class="bStr1" stroke-width="4" d="M74.1 250.8c-2-2-4.1-3.3-5.9-5a10 10 0 0 1-3.2-6c-.2-1.6.2-3.2.6-4.8l4.7-19.4a25.6 25.6 0 0 1-13.7-8.2c-1.1-1.3-1-3.1 0-4.5 2.8-4 5.9-8 9.6-11.6a28 28 0 0 1 16.3-8h45c6.2.6 11.8 3.8 16.2 8 3.8 3.5 6.8 7.7 9.7 11.6 1 1.4 1 3.2 0 4.5-3.4 4-8.3 7-13.7 8.2l4.7 19.4c.4 1.6.7 3.2.6 4.8a10 10 0 0 1-3.3 6c-1.7 1.7-3.8 3-5.9 5"/><path class="bStr1" stroke-width="3" d="M142.2 245.3a58.7 58.7 0 0 1-37.7 12.4"/><path class="handsColor" d="M121 190.6c0 7.5-7.2 13.5-16 13.5s-16-6-16-13.5 7.2-7.6 16-7.6 16 0 16 7.6Z"/><path class="bStr1" stroke-width="2.5" d="M121 190.6c0 7.5-7.2 13.5-16 13.5s-16-6-16-13.5 7.2-7.6 16-7.6 16 0 16 7.6Z"/></svg>';
        } else {
            revert(); // Avoid warnings.
        }
    }
}
