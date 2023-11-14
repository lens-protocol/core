// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Body} from './Body.sol';
import {Skin} from './Helpers.sol';

library Hands {
    enum HandsVariants {
        HANDSDOWN,
        PEACEDOUBLE,
        PEACESINGLE
    }

    enum HandsColors {
        GREEN,
        PURPLE,
        BLUE,
        GOLD
    }

    function getHands(
        HandsVariants handsVariant,
        HandsColors handsColor,
        Body.BodyVariants bodyVariant,
        Body.BodyColors bodyColor
    ) public pure returns (string memory) {
        if (handsVariant == HandsVariants.HANDSDOWN) {
            return '';
        }
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getHandsStyle(handsColor, bodyVariant, bodyColor),
                _getHandsElement(handsVariant, bodyVariant),
                '</svg>'
            );
    }

    function _getHandsElement(
        HandsVariants handsVariant,
        Body.BodyVariants bodyVariant
    ) internal pure returns (string memory) {
        string memory rightHand = _getRightHand(bodyVariant);
        if (handsVariant == HandsVariants.PEACESINGLE) {
            return rightHand;
        } else if (handsVariant == HandsVariants.PEACEDOUBLE) {
            return string.concat(rightHand, _getLeftHand(bodyVariant));
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getRightHand(Body.BodyVariants bodyVariant) internal pure returns (string memory) {
        if (bodyVariant == Body.BodyVariants.HOODIE) {
            return
                '<path class="handsColor" d="M180.8 202.2c.1.4-.5 3.7-2.3 7-1.1 2-2.7 4.2-4.8 5.5-5.6 3.6-10 3.5-17 1.9a25 25 0 0 1-11.9-6.7 17.5 17.5 0 0 1-3.6-6c-.6-1.6.3-3.8-.5-5.3-1.9-3.2.5-6.9.5-6.9l2-4.6 3.4-3.5c0-3 .4-5.4 0-11.7-.4-7.3-1-10.1 0-12.5 3.1-7.7 12.8-6.6 15.7 0 .8 1.9.6 7.8.6 7.8v15l4-15s1.7-7 3-8.6a7.8 7.8 0 0 1 14.2 4.2c.3 2.5-.7 4.7-3 11.6l-3.2 9.3c5.1 2.4 8.4 10.9 3.6 17.7l-.7.8Z"/><path class="armColor" d="M164.4 219.5c-1.2 1.8-2.1 5.2-3.6 7-4.3 4.9-14.5 1.4-14.5 1.4l-.2-4.5-1.5-2.5v-3.5l1.7-4.5s2.6 1.4 8.1 2.6c6 1.6 16.7 1 16.7 1s-2.5-3-5.4.7c-1 1.3 1 1.2-1.3 2.3Z"/><path class="hLine3" d="M149.6 202.6h.8c1.6 0 3.5-.4 5.3-1 5.3-2.1 10.2-6.8 6.3-12.9a7 7 0 0 0-6.1-3.2c-3.3.3-4.6 2.3-8 2.8m-1.2-4.7c0-3 0-5.3-.5-11.6-.5-7.3-1-10.2 0-12.5 3-7.7 12.7-7 15.5-.4.8 1.9 1 8.4 1 8.4v14.9m15.2 1.3 3.3-9.3c2.2-7 3.2-9 2.9-11.6-.9-8.2-10.4-9.6-14.7-3.8a40 40 0 0 0-2.8 8.3l-4 15m18.2 20 .7-1c4.8-6.7 1.5-15.2-3.6-17.6"/><path class="hLine3" d="M180.8 202.2c.1.4-.5 3.7-2.3 7-1.1 2-2.7 4.2-4.8 5.5-5.6 3.6-14.7 3.2-22.7 0"/><path class="hLine4" d="M165.6 218c-3 11-16.3 13-22.3 7.4"/><path class="hLine3" d="M146.6 183.6c-2.7.6-6.7 7.7-6 15 1.6 13.8 10.8 16.9 16 17.9m8.5-15.6c2 3.4 11.5 7 17-.5"/>';
        } else if (bodyVariant == Body.BodyVariants.JACKET) {
            return
                '<path class="handsColor" d="M180.8 202.2c.1.4-.5 3.7-2.3 7-1.1 2-2.7 4.2-4.8 5.5-5.6 3.6-10 3.5-17 1.9a25 25 0 0 1-11.9-6.7 17.5 17.5 0 0 1-3.6-6c-.6-1.6.3-3.8-.5-5.3-1.9-3.2.5-6.9.5-6.9l2-4.6 3.4-3.5c0-3 .4-5.4 0-11.7-.4-7.3-1-10.1 0-12.5 3.1-7.7 12.8-6.6 15.7 0 .8 1.9.6 7.8.6 7.8v15l4-15s1.7-7 3-8.6a7.8 7.8 0 0 1 14.2 4.2c.3 2.5-.7 4.7-3 11.6l-3.2 9.3c5.1 2.4 8.4 10.9 3.6 17.7l-.7.8Z"/><path class="armColor" d="M164.4 219.5c-1.2 1.8-2.1 5.2-3.6 7-4.3 4.9-14.5 1.4-14.5 1.4l-.2-4.5-1.5-2.5v-3.5l1.7-4.5s2.6 1.4 8.1 2.6c6 1.6 16.7 1 16.7 1s-2.5-3-5.4.7c-1 1.3 1 1.2-1.3 2.3Z"/><path class="hLine3" d="M149.6 202.6h.8c1.6 0 3.5-.4 5.3-1 5.3-2.1 10.2-6.8 6.3-12.9a7 7 0 0 0-6.1-3.2c-3.3.3-4.6 2.3-8 2.8m-1.2-4.7c0-3 0-5.3-.5-11.6-.5-7.3-1-10.2 0-12.5 3-7.7 12.7-7 15.5-.4.8 1.9 1 8.4 1 8.4v14.9m15.2 1.3 3.3-9.3c2.2-7 3.2-9 2.9-11.6-.9-8.2-10.4-9.6-14.7-3.8a40 40 0 0 0-2.8 8.3l-4 15m18.2 20 .7-1c4.8-6.7 1.5-15.2-3.6-17.6"/><path class="hLine3" d="M180.8 202.2c.1.4-.5 3.7-2.3 7-1.1 2-2.7 4.2-4.8 5.5-5.6 3.6-14.7 3.2-22.7 0"/><path class="hLine4" d="M165.6 218c-3 11-17 13-23 7.4"/><path class="hLine3" d="M146.6 183.6c-2.7.6-6.7 7.7-6 15 1.6 13.8 10.8 16.9 16 17.9m8.5-15.6c2 3.4 11.5 7 17-.5"/>';
        } else if (bodyVariant == Body.BodyVariants.TANKTOP) {
            return
                '<path class="handsColor" d="M181 202.7c.2.3-.4 3.6-2.2 7a16 16 0 0 1-4.9 5.5c-5.5 3.6-10 3.5-16.9 1.8a25 25 0 0 1-11.9-6.6 17.5 17.5 0 0 1-3.6-6c-.7-1.6.3-3.8-.6-5.3-1.8-3.2.6-7 .6-7l2-4.5 3.4-3.6c0-3 .4-5.3 0-11.7-.5-7.2-1-10 0-12.5 3-7.7 12.8-6.6 15.7 0 .7 1.9.5 7.8.5 7.8v15l4-15s1.8-7 3-8.6a7.8 7.8 0 0 1 14.3 4.3c.2 2.5-.7 4.6-3 11.6l-3.2 9.3c5 2.4 8.4 10.8 3.5 17.6l-.6.9Z"/><path class="handsColor" d="M164.6 220c-1 1.8-2 5.2-3.5 6.9-4.3 5-14.5 1.5-14.5 1.5l-2-3.5s-.4-1.2-1.3-6.6c-.7-3.8-1-9.4-1-9.4l4.3 4.5s2.6 1.4 8 2.6c6.1 1.5 10.1 1.6 15-1.7 1.8-1.2 3.2-3.1 4.2-5s-5 4.7-7.9 8.4c-1 1.2 1.1 1.2-1.3 2.3Z"/><path class="hLine3" d="M150 203h.7a15 15 0 0 0 5.3-1c5.3-2 10.2-6.7 6.3-12.8a7 7 0 0 0-6.1-3.3c-3.4.3-4.7 2.4-8 2.8M147 184c0-3-.1-5.2-.5-11.6-.5-7.2-1-10.1 0-12.5 3-7.7 12.7-7 15.5-.3.8 1.8.9 8.3.9 8.3v15m15.3 1.3 3.2-9.3c2.3-7 3.2-9.1 3-11.6-.9-8.2-10.4-9.6-14.7-3.9a41 41 0 0 0-2.9 8.4l-3.9 15"/><path class="hLine3" d="m181 202.7.7-.9c5-6.8 1.6-15.2-3.5-17.7m2.8 18.6c.2.3-.4 3.6-2.2 7a16 16 0 0 1-4.9 5.5c-5.5 3.6-14.6 3.2-22.6 0"/><path class="hLine4" d="M165.8 218.4c-3 11-17 13-23 7.4"/><path class="hLine3" d="M146.9 184c-2.8.6-6.7 7.7-6 15 1.5 13.9 10.8 17 15.9 18m8.5-15.6c2.1 3.3 11.5 7 17-.5"/>';
        } else if (bodyVariant == Body.BodyVariants.TSHIRT) {
            return
                '<path class="handsColor" d="M181.2 202.7c0 .3-.6 3.6-2.3 7a16 16 0 0 1-4.9 5.5c-5.5 3.6-10 3.5-16.9 1.8a25 25 0 0 1-12-6.6 17.5 17.5 0 0 1-3.5-6c-.7-1.6.3-3.8-.6-5.3-1.8-3.2.6-7 .6-7l2-4.5 3.4-3.6c0-3 .4-5.3 0-11.7-.5-7.2-1-10 0-12.5 3-7.7 12.8-6.6 15.6 0 .8 1.9.6 7.8.6 7.8v15a6798.2 6798.2 0 0 1 4-15s1.8-7 3-8.6a7.8 7.8 0 0 1 14.3 4.3c.2 2.5-.7 4.6-3 11.6l-3.2 9.3c5 2.4 8.4 10.8 3.5 17.6l-.6.9Z"/><path class="handsColor" d="M164.7 220c-1.1 1.8-2 5.2-3.5 6.9-4.3 5-14.5 1.5-14.5 1.5l-3.2-4.2-.8-2.7-1.5-6 5.5-2.1s2.6 1.4 8 2.6c6.1 1.5 10 1.6 15-1.7 1.8-1.2 3.2-3.1 4.2-5s-5 4.7-7.9 8.4c-1 1.2 1.1 1.2-1.3 2.3Z"/><path class="hLine3" d="M150 203c.3 0 .5.1.8 0 1.6 0 3.4-.3 5.3-1 5.2-2 10.1-6.7 6.3-12.8a7 7 0 0 0-6.2-3.3c-3.3.3-4.6 2.4-7.9 2.8m-1.2-4.7c0-3-.1-5.2-.5-11.6-.5-7.2-1-10.1 0-12.5 3-7.7 12.6-7 15.5-.3.8 1.8.9 8.3.9 8.3v15m15.3 1.3 3.2-9.3c2.3-7 3.2-9.1 3-11.6-.9-8.2-10.4-9.6-14.7-3.9a41 41 0 0 0-2.9 8.4l-3.9 15"/><path class="hLine3" d="m181.2 202.7.6-.9c4.9-6.8 1.6-15.2-3.5-17.7m2.9 18.6c0 .3-.6 3.6-2.3 7a16 16 0 0 1-4.9 5.5c-5.5 3.6-14.6 3.2-22.6 0"/><path class="hLine4" d="M166 218.4c-3.1 11-17.8 12.9-23.8 7.4"/><path class="hLine3" d="M147 184c-2.8.6-6.8 7.7-6 15 1.5 13.9 10.7 17 15.9 18m8.5-15.6c2.1 3.3 11.5 7 17-.5"/><path stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" d="M140.4 215.4s.8-1.2 2.5-2c3-1.5 4.7-.5 4.7-.5"/>';
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getLeftHand(Body.BodyVariants bodyVariant) internal pure returns (string memory) {
        if (bodyVariant == Body.BodyVariants.HOODIE) {
            return
                '<path class="handsColor" d="M28.3 202.2c0 .4.5 3.7 2.3 7 1.2 2 2.7 4.2 4.9 5.5 5.5 3.6 10 3.5 16.9 1.9a25 25 0 0 0 11.9-6.7c1.8-1.8 2.7-3.9 3.6-6 .7-1.6-.3-3.8.6-5.3 1.8-3.2-.6-6.9-.6-6.9l-2-4.6-3.4-3.5c0-3-.4-5.4 0-11.7.5-7.3 1-10.1 0-12.5-3-7.7-12.8-6.6-15.7 0-.7 1.9-.5 7.8-.5 7.8v15l-4-15s-1.8-7-3-8.6a7.8 7.8 0 0 0-14.3 4.2c-.2 2.5.7 4.7 3 11.6l3.2 9.3c-5 2.4-8.4 10.9-3.5 17.7l.6.8Z"/><path class="armColor" d="M44.8 219.5c1 1.8 2 5.2 3.5 7 4.3 4.9 14.5 1.4 14.5 1.4l.3-4.5 1.5-2.5v-3.5l-1.8-4.5s-2.6 1.4-8.1 2.6c-6 1.6-16.6 1-16.6 1s2.4-3 5.4.7c1 1.3-1.1 1.2 1.3 2.3Z"/><path class="hLine3" d="M59.5 202.6a15.7 15.7 0 0 1-6-1c-5.4-2.1-10.3-6.8-6.4-12.9a7 7 0 0 1 6.1-3.2c3.4.3 4.7 2.3 8 2.8m1.2-4.7c0-3 .1-5.3.5-11.6.5-7.3 1-10.2 0-12.5-3-7.7-12.7-7-15.5-.4a39 39 0 0 0-.9 8.4v14.9m-15.3 1.3-3.2-9.3c-2.3-7-3.2-9-3-11.6.9-8.2 10.4-9.6 14.7-3.8 1.2 1.6 2.9 8.3 2.9 8.3l3.9 15m-18.2 20a12 12 0 0 1-.6-1c-5-6.7-1.6-15.2 3.5-17.6"/><path class="hLine3" d="M28.3 202.2c0 .4.5 3.7 2.3 7 1.2 2 2.7 4.2 4.9 5.5 5.5 3.6 14.6 3.2 22.6 0"/><path class="hLine4" d="M43.6 218c3 11 16.9 13 22.9 7.4"/><path class="hLine3" d="M62.5 183.6c2.8.6 6.7 7.7 6 15-1.5 13.8-10.8 16.9-16 17.9m-8.4-15.6c-2.1 3.4-11.5 7-17-.5"/>';
        } else if (bodyVariant == Body.BodyVariants.JACKET) {
            return
                '<path class="handsColor" d="M29.7 202.2c0 .4.5 3.7 2.3 7 1.2 2 2.7 4.2 4.9 5.5 5.5 3.6 10 3.5 16.9 1.9a25 25 0 0 0 11.9-6.7c1.8-1.8 2.7-3.9 3.6-6 .7-1.6-.3-3.8.6-5.3 1.8-3.2-.6-6.9-.6-6.9l-2-4.6-3.4-3.5c0-3-.4-5.4 0-11.7.5-7.3 1-10.1 0-12.5-3-7.7-12.8-6.6-15.7 0-.7 1.9-.5 7.8-.5 7.8v15l-4-15s-1.8-7-3-8.6a7.8 7.8 0 0 0-14.3 4.2c-.2 2.5.7 4.7 3 11.6l3.2 9.3c-5 2.4-8.4 10.9-3.5 17.7l.6.8Z"/><path class="armColor" d="M46.2 219.5c1 1.8 2 5.2 3.5 7 4.3 4.9 14.5 1.4 14.5 1.4l.3-4.5L66 221v-3.5l-1.8-4.5s-2.6 1.4-8 2.6c-6.1 1.6-16.7 1-16.7 1s2.4-3 5.4.7c1 1.3-1.1 1.2 1.3 2.3Z"/><path class="hLine3" d="M60.9 202.6a15.7 15.7 0 0 1-6-1c-5.4-2.1-10.3-6.8-6.4-12.9a7 7 0 0 1 6.1-3.2c3.4.3 4.7 2.3 8 2.8m1.2-4.7c0-3 .1-5.3.5-11.6.5-7.3 1-10.2 0-12.5-3-7.7-12.7-7-15.5-.4a39 39 0 0 0-.9 8.4v14.9m-15.3 1.3-3.2-9.3c-2.3-7-3.2-9-3-11.6.9-8.2 10.4-9.6 14.7-3.8 1.2 1.6 2.9 8.3 2.9 8.3l3.9 15m-18.2 20a12 12 0 0 1-.6-1c-5-6.7-1.6-15.2 3.5-17.6"/><path class="hLine3" d="M29.7 202.2c0 .4.5 3.7 2.3 7 1.2 2 2.7 4.2 4.9 5.5 5.5 3.6 14.6 3.2 22.6 0"/><path class="hLine4" d="M45 218c3 11 17 13 23 7.4"/><path class="hLine3" d="M64 183.6c2.7.6 6.6 7.7 5.9 15-1.5 13.8-10.8 16.9-15.9 17.9m-8.5-15.6c-2.1 3.4-11.5 7-17-.5"/>';
        } else if (bodyVariant == Body.BodyVariants.TANKTOP) {
            return
                '<path class="handsColor" d="M29 202.7a19 19 0 0 0 7.1 12.5c5.5 3.6 10 3.5 16.9 1.8a25 25 0 0 0 12-6.6c1.7-1.8 2.7-4 3.6-6 .6-1.6-.4-3.8.5-5.3 1.8-3.2-.5-7-.5-7l-2-4.5-3.4-3.6c0-3-.5-5.3 0-11.7.4-7.2 1-10 0-12.5-3.1-7.7-12.9-6.6-15.7 0-.8 1.9-.6 7.8-.6 7.8v15l-4-15s-1.7-7-3-8.6a7.8 7.8 0 0 0-14.2 4.3c-.3 2.5.6 4.6 3 11.6l3.1 9.3c-5 2.4-8.4 10.8-3.5 17.6l.7.9Z"/><path class="handsColor" d="M45.4 220c1.1 1.8 2.1 5.2 3.5 6.9 4.3 5 14.6 1.5 14.6 1.5l2-3.5s.4-1.2 1.3-6.6c.6-3.8.9-9.4.9-9.4l-4.2 4.5s-2.6 1.4-8.1 2.6c-6 1.5-10 1.6-15-1.7a13.5 13.5 0 0 1-4.2-5s5 4.7 7.9 8.4c1 1.2-1 1.2 1.3 2.3Z"/><path class="hLine3" d="M60.1 203h-.7a15 15 0 0 1-5.3-1c-5.3-2-10.2-6.7-6.3-12.8a7 7 0 0 1 6-3.3c3.4.3 4.7 2.4 8 2.8m1.3-4.7c0-3 0-5.2.5-11.6.5-7.2 1-10.1 0-12.5-3.1-7.7-12.7-7-15.6-.3-.8 1.8-.9 8.3-.9 8.3v15m-15.3 1.3-3.2-9.3c-2.3-7-3.2-9.1-3-11.6 1-8.2 10.5-9.6 14.7-3.9 1.3 1.6 2.9 8.4 2.9 8.4l3.9 15"/><path class="hLine3" d="M29 202.7a12 12 0 0 1-.7-.9c-4.9-6.8-1.5-15.2 3.5-17.7M29 202.7a19 19 0 0 0 7.1 12.5c5.5 3.6 14.6 3.2 22.6 0"/><path class="hLine4" d="M44.2 218.4c3 11 17 13 23 7.4"/><path class="hLine3" d="M63.2 184c2.7.6 6.7 7.7 5.9 15-1.5 13.9-10.7 17-15.9 18m-8.5-15.6c-2 3.3-11.5 7-17-.5"/>';
        } else if (bodyVariant == Body.BodyVariants.TSHIRT) {
            return
                '<path class="handsColor" d="M28.8 202.7c0 .3.6 3.6 2.3 7a16 16 0 0 0 4.9 5.5c5.5 3.6 10 3.5 16.9 1.8a25 25 0 0 0 12-6.6c1.7-1.8 2.6-4 3.5-6 .7-1.6-.3-3.8.6-5.3 1.8-3.2-.6-7-.6-7l-2-4.5L63 184c0-3-.4-5.3 0-11.7.5-7.2 1-10 0-12.5-3-7.7-12.8-6.6-15.6 0-.8 1.9-.6 7.8-.6 7.8v15l-4-15s-1.8-7-3-8.6a7.8 7.8 0 0 0-14.3 4.3c-.2 2.5.7 4.6 3 11.6l3.2 9.3c-5 2.4-8.4 10.8-3.5 17.6l.6.9Z"/><path class="handsColor" d="M45.3 220c1.1 1.8 2 5.2 3.5 6.9 4.3 5 14.5 1.5 14.5 1.5l3.2-4.2.8-2.7 1.5-6-5.5-2.1s-2.6 1.4-8 2.6c-6.1 1.5-10 1.6-15-1.7a13.5 13.5 0 0 1-4.2-5s5 4.7 7.9 8.4c1 1.2-1.1 1.2 1.3 2.3Z"/><path class="hLine3" d="M60 203c-.3 0-.5.1-.8 0-1.6 0-3.4-.3-5.3-1-5.2-2-10.1-6.7-6.3-12.8a7 7 0 0 1 6.2-3.3c3.3.3 4.6 2.4 7.9 2.8m1.2-4.7c0-3 .1-5.2.5-11.6.5-7.2 1-10.1 0-12.5-3-7.7-12.6-7-15.5-.3-.8 1.8-.9 8.3-.9 8.3v15m-15.3 1.3-3.2-9.3c-2.3-7-3.2-9.1-3-11.6.9-8.2 10.4-9.6 14.7-3.9a42 42 0 0 1 2.9 8.4l3.9 15"/><path class="hLine3" d="M28.8 202.7a12 12 0 0 1-.6-.9c-4.9-6.8-1.6-15.2 3.5-17.7m-2.9 18.6c0 .3.6 3.6 2.3 7a16 16 0 0 0 4.9 5.5c5.5 3.6 14.6 3.2 22.6 0"/><path class="hLine4" d="M44 218.4c3.1 11 17.8 12.9 23.8 7.4"/><path class="hLine3" d="M63 184c2.8.6 6.8 7.7 6 15-1.5 13.9-10.7 17-15.9 18m-8.5-15.6c-2.1 3.3-11.5 7-17-.5"/><path stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" d="M69.6 215.4s-.8-1.2-2.5-2c-3-1.5-4.7-.5-4.7-.5"/>';
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHandsStyle(
        HandsColors handsColor,
        Body.BodyVariants bodyVariant,
        Body.BodyColors bodyColor
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<style>.handsColor {fill: ',
                Skin.getSkinColor(Skin.SkinColors(uint8(handsColor))),
                '}.armColor {fill: ',
                _getArmColor(handsColor, bodyVariant, bodyColor),
                '}.hLine3 {stroke: #000;stroke-linecap: round;stroke-linejoin: round;stroke-width: 3;}.hLine4 {stroke: #000;stroke-linecap: round;stroke-linejoin: round;stroke-width: 4;}</style>'
            );
    }

    function _getArmColor(
        HandsColors handsColor,
        Body.BodyVariants bodyVariant,
        Body.BodyColors bodyColor
    ) internal pure returns (string memory) {
        if (bodyVariant == Body.BodyVariants.HOODIE) {
            return Body.getPrimaryBodyColor(bodyVariant, bodyColor);
        } else if (bodyVariant == Body.BodyVariants.TSHIRT) {
            return Skin.getSkinColor(Skin.SkinColors(uint8(handsColor)));
        } else if (bodyVariant == Body.BodyVariants.TANKTOP) {
            return Skin.getSkinColor(Skin.SkinColors(uint8(handsColor)));
        } else if (bodyVariant == Body.BodyVariants.JACKET) {
            return Body.getSecondaryBodyColor(bodyColor);
        } else {
            revert(); // Avoid warnings.
        }
    }
}
