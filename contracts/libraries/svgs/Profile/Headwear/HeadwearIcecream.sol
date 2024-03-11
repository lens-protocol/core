// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from '../Headwear.sol';

library HeadwearIcecream {
    enum IcecreamColors {
        GREEN,
        BLUE,
        PURPLE,
        GOLD
    }

    function getIcecream(
        IcecreamColors iceCreamColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><style>.iceColor {fill:',
                _getIcecreamColor(iceCreamColor),
                '}</style><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M98 66.5s4.2-.5 7-.5c2.6 0 6.8.5 6.8.5"/><path fill="#735C4C" d="M91.2 19.6c7.1 1.9 13 8.6 14.2 16-4-4.9-10-8.9-16-11 0-2.4.7-3.8 1.8-5Z"/><path fill="#fff" d="M146.8 91.9c13.3-6 30.5-4.6 42.4 3.9a43 43 0 0 1 17 26.7c-.5-2-1.2-4.1-2.2-6a20.3 20.3 0 0 0-13.3-10.6c-6.6-1.4-13.3 1-19.3 4-6.1 2.8-12.2 6.2-18.9 6.6-8.1.6-16-3.2-23.4-6.7-7.4-3.5-16-5.1-24.1-5.1h-1.6a57 57 0 0 0-22.5 5c-7.5 3.5-15.3 7.4-23.4 6.8-6.7-.4-12.8-3.8-18.9-6.7-6-2.8-12.7-5.3-19.3-4A20.3 20.3 0 0 0 6 116.6c-1 1.9-1.7 3.9-2.2 6a43 43 0 0 1 17-26.7A44.1 44.1 0 0 1 63.3 92 32.9 32.9 0 0 1 80 71.8l2 .7a5 5 0 0 1 3.6-.8c2.5.4 4.5 2.3 7 2.5 2.1.2 4.1-.9 6-1.8 1.7-.8 4-1.1 5.8-1.2h.8c2 0 4.2.3 6.1 1.2 2 1 4 2 6 1.8 2.6-.2 4.6-2 7.1-2.4a6 6 0 0 1 4.9 1.6l.7-1.6a31.3 31.3 0 0 1 16.8 20Z"/><path class="iceColor" d="M104.4 71.2a15 15 0 0 0-5.7 1.2c-2 1-4 2-6 1.8-2.6-.2-4.6-2.1-7.1-2.5-1.3-.1-2.5.1-3.7.8l-2-.7 1.2-.5a26.1 26.1 0 0 1 2-24.4A26.7 26.7 0 0 1 105 35.6 27 27 0 0 1 127 47a26.1 26.1 0 0 1 2 24.3l1 .5-.7 1.6a6 6 0 0 0-4.9-1.6c-2.5.3-4.5 2.2-7 2.4-2.1.2-4.1-.9-6-1.8-2-1-4.2-1.1-6.2-1.1h-.8Z"/><circle cx="2.5" cy="2.5" r="2.5" fill="#fff" fill-opacity=".5" transform="matrix(-1 0 0 1 126.2 59)"/><path fill="#fff" fill-opacity=".5" d="M123.8 53.6a3.1 3.1 0 0 1-5.7 2.6V56a14.8 14.8 0 0 0-1-1.7c-.6-1-1.5-2.2-2.3-2.9-1-.7-1.7-1.2-2.4-1.5l-1-.6c-1-.5-1.4-1.6-1-2.5l.2-.2c.4-1 0-2-1-2.2-1.2-.2-2.2-.2-3.2-.1a1.1 1.1 0 0 1-.3-2.3 15 15 0 0 1 10.6 3l2.1 1.6a18.6 18.6 0 0 1 4.9 6.7v.2"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M63.3 92A32.9 32.9 0 0 1 80 71.9l1-.5M61.9 99.8a33 33 0 0 1 1.4-7.7M3.8 122.5c.5-2.1 1.2-4.1 2.2-6 2.7-5.2 7.6-9.4 13.3-10.6 6.6-1.4 13.3 1 19.3 4 6.1 2.8 12.2 6.2 18.9 6.6 8.1.6 16-3.3 23.4-6.7a57 57 0 0 1 24-5.1M3.8 122.6v-.1"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M63.3 92h0a44.5 44.5 0 0 0-42.5 3.8 43 43 0 0 0-17 26.7"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="3.2" d="M79.5 72.4c2.5-1.3 4.8-.8 6.1-.7 2.5.4 4.5 2.3 7 2.5 2.1.2 4.1-.9 6-1.8 1.7-.8 4-1.1 5.8-1.2h.8"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M105 35.6c-8.5 0-17.3 4.2-22 11.3a26.1 26.1 0 0 0-2 24.4"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="3.2" d="M105.4 35.6c-1.2-7.4-7-14.1-14.2-16a7.2 7.2 0 0 0-1.9 5c6.1 2.1 12 6.1 16.1 11Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M148.1 99.8a37 37 0 0 0-1.3-8 31.3 31.3 0 0 0-16.8-20l-1-.5m77.2 51.2c-.5-2-1.2-4.1-2.2-6a20.3 20.3 0 0 0-13.3-10.6c-6.6-1.4-13.3 1-19.3 4-6.1 2.8-12.2 6.2-18.9 6.6-8.1.6-16-3.2-23.4-6.7-7.4-3.5-16-5.1-24.1-5.1m101.2 17.9s0 0 0 0"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M146.8 91.9c13.3-6 30.5-4.6 42.4 3.9a43 43 0 0 1 17 26.7"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="3.2" d="M132 73.1a11.1 11.1 0 0 0-7.6-1.3c-2.5.3-4.5 2.2-7 2.4-2.1.2-4.1-.9-6-1.8-2-1-4.2-1.1-6.2-1.1"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M105 35.6A27 27 0 0 1 127 47a26.1 26.1 0 0 1 2 24.3"/><path class="iceColor" stroke="#000" stroke-linecap="round" stroke-width="3.2" d="M74.6 77.8a3.1 3.1 0 0 0-5 3.8l2.8 3.6a3.1 3.1 0 0 0 4.9-3.8l-2.7-3.6Zm63.4.4a3.1 3.1 0 1 0-5.4-3.1l-2.2 3.9a3.1 3.1 0 1 0 5.3 3l2.3-3.8Zm-53.3 22.6a3.1 3.1 0 1 0-3 5.4l4 2.2a3.1 3.1 0 1 0 3-5.4l-4-2.2Zm20.5-13a3.1 3.1 0 0 0 2-5.9l-4.4-1.4a3.1 3.1 0 1 0-1.9 6l4.3 1.3Zm-68 4.6a3.1 3.1 0 0 0-2-5.9L30.8 88a3.1 3.1 0 1 0 2 5.8l4.3-1.4Zm126.8-1a3.1 3.1 0 1 0 4.2 4.6l3.3-3a3.1 3.1 0 0 0-4.1-4.6l-3.4 3ZM50.6 100a3.1 3.1 0 1 0-3 5.3l3.9 2.2a3.1 3.1 0 0 0 3-5.4l-4-2.2Zm85-1.5a3.1 3.1 0 1 1-5.8 2.4l-1.7-4.1a3.1 3.1 0 0 1 5.7-2.4l1.8 4.1Z"/></svg>'
            ),
            Headwear.HeadwearVariants.ICECREAM,
            _getHeadwearColor(iceCreamColor)
        );
    }

    function _getIcecreamColor(IcecreamColors icecreamColor) internal pure returns (string memory) {
        if (icecreamColor == IcecreamColors.GREEN) {
            return '#A0D170';
        } else if (icecreamColor == IcecreamColors.PURPLE) {
            return '#EAD7FF';
        } else if (icecreamColor == IcecreamColors.BLUE) {
            return '#D9E0FF';
        } else if (icecreamColor == IcecreamColors.GOLD) {
            return '#FFCD3D';
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(IcecreamColors icecreamColor) internal pure returns (Headwear.HeadwearColors) {
        if (icecreamColor == IcecreamColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (icecreamColor == IcecreamColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (icecreamColor == IcecreamColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (icecreamColor == IcecreamColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
