// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GintoNordFontSVG} from './GintoNordFontSVG.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

library HandleSVG {
    using Strings for uint256;
    uint256 constant MAX_WIDTH = 275;

    enum FaceColors {
        GREEN,
        PEACH,
        PURPLE,
        BLUE,
        GOLD,
        BLACK
    }

    function getHandleSVG(string memory localName) public pure returns (string memory) {
        FaceColors baseColor = getBaseColor(localName);
        if (baseColor == FaceColors.GOLD) {
            return getGoldHandleSVG(localName);
        } else if (baseColor == FaceColors.BLACK) {
            return getBlackHandleSVG(localName);
        } else {
            return getBaseHandleSVG(localName, baseColor);
        }
    }

    function getGoldHandleSVG(string memory localName) internal pure returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="275" height="275" fill="none"><style>text {fill: #B96326}</style><g><path fill="url(#b)" d="M197.7 162.1a2 2 0 0 1-3.5-1.4v-5.3c-2-72.3-111.4-72.3-113.4 0v5.3a2 2 0 0 1-3.5 1.4l-3.7-3.7c-52.8-49.7-130 27.4-80.2 80l3.7 3.7c60.2 60 140.4 60 140.4 60s80.2 0 140.4-60a156 156 0 0 0 3.7-3.8c49.8-52.5-27.5-129.6-80.1-79.9a115 115 0 0 0-3.8 3.7Z"/><circle cx="6.3" cy="6.3" r="6.3" fill="#fff" fill-opacity=".5" transform="matrix(-1 0 0 1 285.5 195.5)"/><path fill="#fff" fill-opacity=".5" d="M279.6 182a7.7 7.7 0 0 1-14 6.4l-.2-.3a34.7 34.7 0 0 0-2.2-4 28 28 0 0 0-11.5-11l-2.8-1.5a4.7 4.7 0 0 1-2.1-6.3l.2-.4c1.1-2.3 0-5.1-2.5-5.5-2.9-.4-5.3-.5-7.9-.3a2.8 2.8 0 0 1-.6-5.5 37 37 0 0 1 26.1 7.5 46 46 0 0 1 17.2 20.3l.3.4v.1"/><path stroke="#B96326" stroke-linecap="square" stroke-linejoin="round" stroke-width="6.3" d="M197.7 162.1v0a2 2 0 0 1-3.5-1.4v0-5.3c-2-72.3-111.4-72.3-113.4 0v5.3a2 2 0 0 1-3.5 1.4v0l-3.7-3.7c-52.8-49.7-130 27.4-80.2 80l3.7 3.7c60.2 60 140.4 60 140.4 60s80.2 0 140.4-60a156 156 0 0 0 3.7-3.8c49.8-52.5-27.5-129.6-80.1-79.9a115 115 0 0 0-3.8 3.7Z"/><path stroke="#B96326" stroke-linecap="round" stroke-width="4.7" d="M115.5 247.2s6.8 9.4 22 9.4 22-9.4 22-9.4"/><path stroke="#B96326" stroke-linecap="round" stroke-linejoin="round" stroke-width="3.9" d="M112.4 247.2a7.3 7.3 0 0 0 3.1-3.2m47.1 3.2a7.3 7.3 0 0 1-3.1-3.2"/><path fill="#B96326" fill-rule="evenodd" d="M120.4 215.7c1-.5 1.7-1.7 1.3-2.7-2.2-5.8-7-9.8-12.7-9.8-7.7 0-13.9 7.3-13.9 16.3S101.3 236 109 236c5.4 0 10.2-3.7 12.4-9.2.5-1-.1-2.3-1.2-2.7l-5.6-2.4a1.9 1.9 0 0 1 0-3.5l5.8-2.4Zm32.6 3.8c0-9 6.3-16.3 14-16.3 5.7 0 10.7 4.3 12.8 10.3.4 1-.2 2.2-1.3 2.6l-4.7 2a1.9 1.9 0 0 0 0 3.5l4.5 2c1 .4 1.7 1.5 1.3 2.6-2.2 5.7-7 9.7-12.7 9.7-7.6 0-13.9-7.3-13.9-16.4Z" clip-rule="evenodd"/><path fill="#DF772C" fill-opacity=".3" d="M90 239.6a2.3 2.3 0 1 1-4-2.3 2.3 2.3 0 0 1 4 2.3Zm8 4.6a2.3 2.3 0 1 1-4-2.3 2.3 2.3 0 0 1 4 2.3Zm-7.1 3.1a2.3 2.3 0 1 1-4-2.3 2.3 2.3 0 0 1 4 2.3Zm87-5.3a2.3 2.3 0 1 1-4 2.2 2.3 2.3 0 0 1 4-2.3Zm8-4.7a2.3 2.3 0 1 1-4 2.3 2.3 2.3 0 0 1 4-2.3Zm-.9 7.7a2.3 2.3 0 1 1-4 2.3 2.3 2.3 0 0 1 4-2.3Z"/><path fill="#fff" stroke="#B96326" stroke-linecap="square" stroke-linejoin="round" stroke-width="5.5" d="M-1.8 135.6c.2-.4.9-.4 1 0A30 30 0 0 0 17 154.4c.2 0 .2.2 0 .2l-.8.3c-7.8 2.8-14 9.3-16.7 17.8h0c-.1.4-.6.4-.8 0-3-8.8-9.4-16-17.7-19a.2.2 0 0 1 0-.3h.4a28.1 28.1 0 0 0 17-17.8Z"/><path fill="#fff" stroke="#B96326" stroke-linecap="square" stroke-linejoin="round" stroke-width="4.7" d="M8 185.1c.2-.3.6-.2.7 0A19 19 0 0 0 19.9 197v.1l-.6.2c-5 1.8-8.8 6-10.5 11.2v.1c0 .2-.4.2-.5 0a19 19 0 0 0-11.2-12v-.2h.2c5-1.8 9-6 10.8-11.3Z"/><path fill="url(#c)" d="M0 .5h275v275H0z"/><path fill="url(#e)" d="M197.7 162.1a2 2 0 0 1-3.5-1.4v-5.3c-2-72.3-111.4-72.3-113.4 0v5.3a2 2 0 0 1-3.5 1.4l-3.7-3.7c-52.8-49.7-130 27.4-80.2 80l3.7 3.7c60.2 60 140.4 60 140.4 60s80.2 0 140.4-60a156 156 0 0 0 3.7-3.8c49.8-52.5-27.5-129.6-80.1-79.9a115 115 0 0 0-3.8 3.7Z"/><circle cx="6.3" cy="6.3" r="6.3" fill="#fff" fill-opacity=".5" transform="matrix(-1 0 0 1 285.5 195.5)"/><path fill="#fff" fill-opacity=".5" d="M279.6 182a7.7 7.7 0 0 1-14 6.4l-.2-.3a34.7 34.7 0 0 0-2.2-4 28 28 0 0 0-11.5-11l-2.8-1.5a4.7 4.7 0 0 1-2.1-6.3l.2-.4c1.1-2.3 0-5.1-2.5-5.5-2.9-.4-5.3-.5-7.9-.3a2.8 2.8 0 0 1-.6-5.5 37 37 0 0 1 26.1 7.5 46 46 0 0 1 17.2 20.3l.3.4v.1"/><path stroke="#B96326" stroke-linecap="square" stroke-linejoin="round" stroke-width="6.3" d="M197.7 162.1v0a2 2 0 0 1-3.5-1.4v0-5.3c-2-72.3-111.4-72.3-113.4 0v5.3a2 2 0 0 1-3.5 1.4v0l-3.7-3.7c-52.8-49.7-130 27.4-80.2 80l3.7 3.7c60.2 60 140.4 60 140.4 60s80.2 0 140.4-60a156 156 0 0 0 3.7-3.8c49.8-52.5-27.5-129.6-80.1-79.9a115 115 0 0 0-3.8 3.7Z"/><path stroke="#B96326" stroke-linecap="round" stroke-width="4.7" d="M115.5 247.2s6.8 9.4 22 9.4 22-9.4 22-9.4"/><path stroke="#B96326" stroke-linecap="round" stroke-linejoin="round" stroke-width="3.9" d="M112.4 247.2a7.3 7.3 0 0 0 3.1-3.2m47.1 3.2a7.3 7.3 0 0 1-3.1-3.2"/><path fill="#B96326" fill-rule="evenodd" d="M120.4 215.7c1-.5 1.7-1.7 1.3-2.7-2.2-5.8-7-9.8-12.7-9.8-7.7 0-13.9 7.3-13.9 16.3S101.3 236 109 236c5.4 0 10.2-3.7 12.4-9.2.5-1-.1-2.3-1.2-2.7l-5.6-2.4a1.9 1.9 0 0 1 0-3.5l5.8-2.4Zm32.6 3.8c0-9 6.3-16.3 14-16.3 5.7 0 10.7 4.3 12.8 10.3.4 1-.2 2.2-1.3 2.6l-4.7 2a1.9 1.9 0 0 0 0 3.5l4.5 2c1 .4 1.7 1.5 1.3 2.6-2.2 5.7-7 9.7-12.7 9.7-7.6 0-13.9-7.3-13.9-16.4Z" clip-rule="evenodd"/><path fill="#fff" stroke="#B96326" stroke-linecap="square" stroke-linejoin="round" stroke-width="6" d="M24.3 123.8c.1-.5.8-.5.9 0a28.1 28.1 0 0 0 16.6 17.5v.2l-.8.3c-7.4 2.7-13 8.7-15.6 16.6v.1c-.2.4-.6.4-.8 0-2.7-8.3-8.8-15-16.6-17.8a.1.1 0 0 1 0-.3h.4a25.8 25.8 0 0 0 15.9-16.6Z"/><path fill="#fff" stroke="#B96326" stroke-linecap="square" stroke-linejoin="round" stroke-width="4" d="M35 174.4c0-.3.5-.3.5 0 1.8 5.2 5.7 9.3 10.5 11v.2l-.5.2a16.3 16.3 0 0 0-9.8 10.5h0c-.1.2-.4.3-.5 0a17.8 17.8 0 0 0-10.5-11.2v-.2h.2c4.7-1.7 8.4-5.5 10-10.5Z"/>',
                getTextElement(localName),
                '</g><defs>',
                GintoNordFontSVG.getFontStyle(),
                '<radialGradient id="b" cx="0" cy="0" r="1" gradientTransform="scale(320 201) rotate(90 0 .5)" gradientUnits="userSpaceOnUse"><stop stop-color="#FFDB76"/><stop offset="1" stop-color="#F8C944"/></radialGradient><radialGradient id="c" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275.5)" gradientUnits="userSpaceOnUse"><stop stop-color="#FFE7A5"/><stop offset="1" stop-color="#FFF2CE"/></radialGradient><radialGradient id="e" cx="0" cy="0" r="1" gradientTransform="scale(320 201) rotate(90 0 .5)" gradientUnits="userSpaceOnUse"><stop stop-color="#FFDB76"/><stop offset="1" stop-color="#F8C944"/></radialGradient></defs></svg>'
            );
    }

    function getBlackHandleSVG(string memory localName) internal pure returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="275" height="275" fill="none"><style>text {fill: #fff}</style><g><path fill="url(#b)" d="M0 0h275v275H0z"/><path fill="url(#d)" fill-opacity=".7" d="M197.7 161.5a2 2 0 0 1-3.5-1.5v-5.2c-2-72.4-111.4-72.4-113.4 0v5.2a2 2 0 0 1-3.5 1.5l-3.7-3.7c-52.8-49.8-130 27.4-80.2 79.9l3.7 3.8c60.2 60 140.4 60 140.4 60s80.2 0 140.4-60l3.7-3.8c49.8-52.6-27.4-129.7-80.1-80l-3.8 3.8Z"/><circle cx="6.3" cy="6.3" r="6.3" fill="#fff" fill-opacity=".5" transform="matrix(-1 0 0 1 285.5 194.8)"/><path fill="#fff" fill-opacity=".5" d="M279.6 181.3a7.7 7.7 0 0 1-14 6.4l-.2-.2a34.7 34.7 0 0 0-2.2-4.1 28 28 0 0 0-11.5-11l-2.8-1.4a4.7 4.7 0 0 1-2.1-6.3l.2-.5c1.1-2.2 0-5-2.5-5.4-2.9-.5-5.3-.6-7.9-.3a2.8 2.8 0 0 1-.6-5.5 37 37 0 0 1 26.1 7.5 46 46 0 0 1 17.2 20.3c.2.1.2.3.3.4v.1"/><path stroke="#1D1D1D" stroke-linecap="square" stroke-linejoin="round" stroke-width="6.3" d="M197.7 161.5v0a2 2 0 0 1-3.5-1.5v0-5.2c-2-72.4-111.4-72.4-113.4 0v5.2a2 2 0 0 1-3.5 1.5v0l-3.7-3.7c-52.8-49.8-130 27.4-80.2 79.9l3.7 3.8c60.2 60 140.4 60 140.4 60s80.2 0 140.4-60l3.7-3.8c49.8-52.6-27.4-129.7-80.1-80l-3.8 3.8Z"/><path stroke="#1D1D1D" stroke-linecap="round" stroke-width="4.7" d="M115.5 246.5s6.8 9.5 22 9.5 22-9.5 22-9.5"/><path stroke="#1D1D1D" stroke-linecap="round" stroke-linejoin="round" stroke-width="3.9" d="M112.4 246.5a7.3 7.3 0 0 0 3.1-3.1m47.1 3.1a7.3 7.3 0 0 1-3.1-3.1"/><path fill="#1D1D1D" fill-rule="evenodd" d="M120.4 215c1-.4 1.7-1.6 1.3-2.7-2.2-5.7-7-9.7-12.7-9.7-7.7 0-13.9 7.3-13.9 16.3s6.2 16.3 13.9 16.3c5.5 0 10.2-3.7 12.4-9.1.5-1.1-.1-2.3-1.2-2.8l-5.6-2.4a1.9 1.9 0 0 1 0-3.4l5.8-2.5Zm32.6 3.9c0-9 6.3-16.3 14-16.3 5.7 0 10.7 4.2 12.8 10.2.4 1.1-.2 2.2-1.3 2.7l-4.7 2a1.9 1.9 0 0 0 0 3.4l4.5 2c1 .4 1.7 1.6 1.3 2.7-2.2 5.7-7 9.6-12.7 9.6-7.6 0-13.9-7.3-13.9-16.3Z" clip-rule="evenodd"/><path fill="#fff" stroke="#1D1D1D" stroke-linecap="square" stroke-linejoin="round" stroke-width="6" d="M27.7 123.8c.1-.5.7-.5.9 0a28.1 28.1 0 0 0 16.6 17.5v.2l-.8.3c-7.4 2.7-13 8.7-15.6 16.6v.1c-.2.4-.6.4-.8 0-2.7-8.3-8.8-15-16.6-17.8a.1.1 0 0 1 0-.3h.4a25.8 25.8 0 0 0 15.9-16.6Z"/><path fill="#fff" stroke="#1D1D1D" stroke-linecap="square" stroke-linejoin="round" stroke-width="4" d="M38.3 174.4c.1-.3.6-.3.6 0 1.8 5.2 5.7 9.3 10.5 11v.2l-.5.2a16.3 16.3 0 0 0-9.8 10.5h0c-.1.2-.4.3-.5 0A17.8 17.8 0 0 0 28 185.1v-.2h.2c4.7-1.7 8.4-5.5 10-10.5Z"/>',
                getTextElement(localName),
                '</g><defs>',
                GintoNordFontSVG.getFontStyle(),
                '<radialGradient id="b" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275.5)" gradientUnits="userSpaceOnUse"><stop stop-color="#1D1D1D"/><stop offset="1" stop-color="#313131"/></radialGradient><radialGradient id="d" cx="0" cy="0" r="1" gradientTransform="matrix(0 -266 424 0 169.6 372.4)" gradientUnits="userSpaceOnUse"><stop stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#fff"/></radialGradient></defs></svg>'
            );
    }

    function getBaseHandleSVG(string memory localName, FaceColors baseColor) internal pure returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="275" height="275" fill="none"><g>',
                getBaseBg(baseColor),
                getLensBaseFace(baseColor),
                getTextElement(localName),
                '</g><defs>',
                GintoNordFontSVG.getFontStyle(),
                getBaseGradients(),
                '</defs></svg>'
            );
    }

    function getBaseColor(string memory localName) internal pure returns (FaceColors) {
        uint256 chars = bytes(localName).length;
        FaceColors[] memory colors = new FaceColors[](6);
        colors[0] = FaceColors.GREEN;
        colors[1] = FaceColors.BLACK;
        colors[2] = FaceColors.GOLD;
        colors[3] = FaceColors.BLUE;
        colors[4] = FaceColors.PURPLE;
        colors[5] = FaceColors.PEACH;
        if (chars < 6) {
            return colors[chars];
        } else {
            return FaceColors.GREEN;
        }
    }

    function getBaseBg(FaceColors faceColor) internal pure returns (string memory) {
        string memory bgName;
        if (faceColor == FaceColors.GREEN) {
            bgName = 'green';
        } else if (faceColor == FaceColors.PEACH) {
            bgName = 'peach';
        } else if (faceColor == FaceColors.PURPLE) {
            bgName = 'purple';
        } else if (faceColor == FaceColors.BLUE) {
            bgName = 'blue';
        }
        return string.concat('<path fill="url(#', bgName, ')" d="M0 0h275v275H0z"/>');
    }

    function getLensBaseFace(FaceColors faceColor) internal pure returns (string memory) {
        return
            string.concat(
                '<path fill="',
                getBaseFaceColor(faceColor),
                '" d="M197.7 161.5a2 2 0 0 1-3.5-1.5v-5.2c-2-72.4-111.4-72.4-113.4 0v5.2a2 2 0 0 1-3.5 1.5l-3.7-3.7c-52.8-49.8-130 27.4-80.2 79.9l3.7 3.8c60.2 60 140.4 60 140.4 60s80.2 0 140.4-60l3.7-3.8c49.8-52.6-27.5-129.7-80.1-80a115 115 0 0 0-3.8 3.8Z"/><circle cx="6.3" cy="6.3" r="6.3" fill="#fff" fill-opacity=".5" transform="matrix(-1 0 0 1 285.5 194.8)"/><path fill="#fff" fill-opacity=".5" d="M279.6 181.3a7.7 7.7 0 0 1-14 6.4 11.3 11.3 0 0 0-.6-1.1c-.5-.8-1-2-1.8-3.2a27.9 27.9 0 0 0-11.5-11l-2.8-1.4a4.7 4.7 0 0 1-2.1-6.3l.2-.5c1.1-2.2 0-5-2.5-5.4-2.9-.5-5.3-.6-7.9-.3a2.8 2.8 0 0 1-.6-5.5 37 37 0 0 1 26.1 7.5 46 46 0 0 1 17.2 20.3l.3.4v.1"/><path stroke="#000" stroke-linecap="square" stroke-linejoin="round" stroke-width="6.3" d="M197.7 161.5v0a2 2 0 0 1-3.5-1.5v0-5.2c-2-72.4-111.4-72.4-113.4 0v5.2a2 2 0 0 1-3.5 1.5v0l-3.7-3.7c-52.8-49.8-130 27.4-80.2 79.9l3.7 3.8c60.2 60 140.4 60 140.4 60s80.2 0 140.4-60l3.7-3.8c49.8-52.6-27.5-129.7-80.1-80a115 115 0 0 0-3.8 3.8Z"/><path stroke="#000" stroke-linecap="round" stroke-width="4.7" d="M115.5 246.5s6.8 9.5 22 9.5 22-9.5 22-9.5"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="3.9" d="M112.4 246.5a7.3 7.3 0 0 0 3.1-3.1m47.1 3.1a7.3 7.3 0 0 1-3.1-3.1"/><path fill="#000" fill-rule="evenodd" d="M120.4 215c1-.4 1.7-1.6 1.3-2.7-2.2-5.7-7-9.7-12.7-9.7-7.7 0-13.9 7.3-13.9 16.3s6.2 16.3 13.9 16.3c5.4 0 10.2-3.7 12.4-9.1.5-1.1-.1-2.3-1.2-2.8l-5.6-2.4a1.9 1.9 0 0 1 0-3.4l5.8-2.5Zm32.6 3.9c0-9 6.3-16.3 14-16.3 5.7 0 10.7 4.2 12.8 10.2.4 1.1-.2 2.2-1.3 2.7l-4.7 2a1.9 1.9 0 0 0 0 3.4l4.5 2c1 .4 1.7 1.6 1.3 2.7-2.2 5.7-7 9.6-12.7 9.6-7.6 0-13.9-7.3-13.9-16.3Z" clip-rule="evenodd"/>'
            );
    }

    function getTextElement(string memory localName) internal pure returns (string memory) {
        uint256 textWidth = getTextWidth(string.concat('@', localName));
        string memory fontSize = '20';

        if (textWidth > MAX_WIDTH) {
            uint256 sampleTextWidthAt20 = getWidthFromFontsize(20);
            uint256 scalingFactor = (textWidth * 1000) / sampleTextWidthAt20;
            uint256 equivalentSampleTextWidth = (((MAX_WIDTH * 10000) / scalingFactor) + 5) / 10;
            uint256 fontSize10x = getFontsizeFromWidth10x(equivalentSampleTextWidth);
            fontSize = string.concat((fontSize10x / 10).toString(), '.', (fontSize10x % 10).toString());
        }
        return
            string.concat(
                '<text fill="black" xml:space="preserve" style="white-space: pre" x="50%" y="60" text-anchor="middle" font-family="Ginto Nord Medium" font-size="',
                fontSize,
                '" font-weight="500" letter-spacing="-0.7px">@',
                localName,
                '</text>'
            );
    }

    function getBaseFaceColor(FaceColors faceColor) internal pure returns (string memory) {
        if (faceColor == FaceColors.GREEN) {
            return '#A0D170';
        } else if (faceColor == FaceColors.PEACH) {
            return '#FFD5D2';
        } else if (faceColor == FaceColors.PURPLE) {
            return '#EAD7FF';
        } else if (faceColor == FaceColors.BLUE) {
            return '#D9E0FF';
        } else {
            revert(); // Avoid warnings.
        }
    }

    function getBaseGradients() internal pure returns (string memory) {
        return
            '<radialGradient id="green" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#DFFFBF"/><stop offset="1" stop-color="#EFD"/></radialGradient><radialGradient id="peach" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#FFDFDD"/><stop offset="1" stop-color="#FFF0EF"/></radialGradient><radialGradient id="purple" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#F1E4FF"/><stop offset="1" stop-color="#F8F1FF"/></radialGradient><radialGradient id="blue" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#E6EAFF"/><stop offset="1" stop-color="#EFF2FF"/></radialGradient>';
    }

    struct CharWidth {
        bytes1 char;
        uint256 width;
    }

    function getCharWidth(bytes1 char) internal pure returns (uint256) {
        CharWidth[] memory chars = new CharWidth[](39);
        chars[0] = CharWidth('0', 16);
        chars[1] = CharWidth('1', 9);
        chars[2] = CharWidth('2', 16);
        chars[3] = CharWidth('3', 16);
        chars[4] = CharWidth('4', 16);
        chars[5] = CharWidth('5', 16);
        chars[6] = CharWidth('6', 16);
        chars[7] = CharWidth('7', 16);
        chars[8] = CharWidth('8', 16);
        chars[9] = CharWidth('9', 16);
        chars[10] = CharWidth('a', 16);
        chars[11] = CharWidth('b', 16);
        chars[12] = CharWidth('c', 16);
        chars[13] = CharWidth('d', 16);
        chars[14] = CharWidth('e', 16);
        chars[15] = CharWidth('f', 16);
        chars[16] = CharWidth('g', 16);
        chars[17] = CharWidth('h', 16);
        chars[18] = CharWidth('i', 7);
        chars[19] = CharWidth('j', 7);
        chars[20] = CharWidth('k', 16);
        chars[21] = CharWidth('l', 7);
        chars[22] = CharWidth('m', 23);
        chars[23] = CharWidth('n', 16);
        chars[24] = CharWidth('o', 16);
        chars[25] = CharWidth('p', 16);
        chars[26] = CharWidth('q', 16);
        chars[27] = CharWidth('r', 11);
        chars[28] = CharWidth('s', 16);
        chars[29] = CharWidth('t', 11);
        chars[30] = CharWidth('u', 16);
        chars[31] = CharWidth('v', 16);
        chars[32] = CharWidth('w', 23);
        chars[33] = CharWidth('x', 16);
        chars[34] = CharWidth('y', 16);
        chars[35] = CharWidth('z', 16);
        chars[36] = CharWidth('@', 21);
        chars[37] = CharWidth('_', 16);
        chars[38] = CharWidth('-', 11);
        for (uint i = 0; i < chars.length; i++) {
            if (chars[i].char == char) {
                return chars[i].width;
            }
        }
        revert(); // Avoid warnings.
    }

    function getWidthFromFontsize(uint256 fontSize) internal pure returns (uint256) {
        return (((fontSize * 1244242 - 1075758 + 50000) / 10000) + 5) / 10;
    }

    function getFontsizeFromWidth10x(uint256 width) internal pure returns (uint256) {
        return (((width * 10000000 + 107575800) / 1244242) + 5) / 10;
    }

    function getTextWidth(string memory text) internal pure returns (uint256) {
        uint256 length = 0;
        for (uint i = 0; i < bytes(text).length; i++) {
            length += getCharWidth(bytes(text)[i]);
        }
        return length;
    }

    function getFittingLength(string memory text, uint256 maxWidth) internal pure returns (uint256) {
        uint256 length = 0;
        for (uint i = 0; i < bytes(text).length; i++) {
            length += getCharWidth(bytes(text)[i]);
            if (length > maxWidth) {
                return i;
            }
        }
        return bytes(text).length;
    }

    function splitTextToFit(string memory text) internal pure returns (string memory, string memory) {
        uint256 length1 = getFittingLength(text, MAX_WIDTH - 21); // 21px is @ width
        bytes memory text1Bytes = new bytes(length1);
        for (uint i = 0; i < length1; i++) {
            text1Bytes[i] = bytes(text)[i];
        }
        string memory text1 = string.concat('@', string(text1Bytes));

        uint256 length2 = bytes(text).length - length1;
        bytes memory text2Bytes = new bytes(length2);
        for (uint i = 0; i < length2; i++) {
            text2Bytes[i] = bytes(text)[length1 + i];
        }
        string memory text2 = string(text2Bytes);

        if (getTextWidth(text2) <= MAX_WIDTH) {
            return (text1, text2);
        } else {
            uint256 length3 = getFittingLength(text2, MAX_WIDTH - 18); // 18px is ... width
            bytes memory text3Bytes = new bytes(length3);
            for (uint i = 0; i < length3; i++) {
                text3Bytes[i] = bytes(text2)[i];
            }
            string memory text3 = string.concat(string(text3Bytes), '...');

            return (text1, text3);
        }
    }
}
