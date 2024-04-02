// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from 'contracts/libraries/svgs/Profile/Headwear.sol';
import {LensColors} from 'contracts/libraries/svgs/Profile/LensColors.sol';

library HeadwearPartyhat {
    enum PartyhatColors {
        GREEN,
        PURPLE,
        BLUE,
        PINK,
        GOLD
    }

    function getPartyhat(
        PartyhatColors partyhatColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="211" height="335" fill="none">',
                _getPartyhatStyle(partyhatColor),
                '<path class="partyhatColor2" d="M99.7 34.9c3.1 2 7.3 2.2 10.7.8l2.2.6 9.4 16.9c-9.2-2.3-18.4-7-24.8-14l1.7-3 .8-1.3Z"/><path fill="#fff" d="M99.7 34.9c-4-2.5-6-7.7-4.7-12.2 1.1-4.6 5.5-8.1 10.1-8.4 4.8-.2 9.4 2.8 11.1 7.2 1.7 4.4.3 9.7-3.4 12.7-.7.6-1.5 1-2.4 1.5a11.5 11.5 0 0 1-10.7-.8Z"/><path class="partyhatColor1" d="M142 90.5a108.7 108.7 0 0 1-56-31l11.2-20.2c6.4 7 15.6 11.6 24.8 13.9 6.8 12.2 13.4 24.6 20 37.3Z"/><path class="partyhatColor2" d="M73 83.3c4.3-8 8.6-16 13-23.8a108.7 108.7 0 0 0 56 31l6.3 12.2a57.5 57.5 0 0 1-21.3 10.2 95.1 95.1 0 0 1-54-29.6Z"/><path class="partyhatColor1" d="m63 102.7 10-19.4a95 95 0 0 0 54 29.6 93.5 93.5 0 0 1-21.2 1.9c-20.3 0-29.7-3-42.7-12.1Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="m99 36.3-1.8 3a1648.8 1648.8 0 0 0-34.1 63.4c13 9.2 22.4 12.1 42.7 12.1M142 90.5l6.3 12.2a57.5 57.5 0 0 1-21.3 10.2 93.5 93.5 0 0 1-21.2 1.9m6.8-78.5A1948.7 1948.7 0 0 1 142 90.5m-31.6-54.8c.9-.4 1.7-1 2.4-1.5 3.7-3 5.1-8.3 3.4-12.7a11.5 11.5 0 0 0-11-7.2c-4.7.3-9 3.8-10.2 8.4-1.2 4.5.8 9.7 4.7 12.2 3.1 2 7.3 2.2 10.7.8Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M97.2 39.3c6.4 7 15.6 11.6 24.8 13.9m-36 6.3a108.7 108.7 0 0 0 56 31h0m-69-7.2a95 95 0 0 0 54 29.6h0"/><path fill="#fff" d="M56.4 23.6c4.6-1 8.4-4.7 9.3-9.3a18 18 0 0 0 9.8 9.9 14.5 14.5 0 0 0-9.8 10.7c-.8-5-4.5-9.6-9.3-11.3Z"/><path class="partyhatSparkles" d="M65.7 14.3c-1 4.6-4.7 8.4-9.3 9.3 4.8 1.7 8.5 6.2 9.3 11.3 1-5 5-9.3 9.8-10.7a18 18 0 0 1-9.8-9.9Z"/><path fill="#fff" d="M152.3 50.2a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z"/><path class="partyhatSparkles" d="M152.3 50.2a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z"/><path fill="#fff" d="M56.4 68.9a6.7 6.7 0 1 0 0-13.4 6.7 6.7 0 0 0 0 13.4Z"/><path class="partyhatSparkles" d="M56.4 68.9a6.7 6.7 0 1 0 0-13.4 6.7 6.7 0 0 0 0 13.4Z"/><path fill="#fff" d="M173.5 71.2c-.2-4.7-4-9-8.7-9.7 4.3-.3 8.1-4 8.5-8.3a11 11 0 0 0 8.7 8.3c-4.7.6-8.4 5-8.5 9.7Z"/><path class="partyhatSparkles" d="M173.3 53.2c-.4 4.3-4.2 8-8.5 8.3 4.7.7 8.5 5 8.7 9.7.1-4.7 3.8-9 8.5-9.7a11 11 0 0 1-8.7-8.3Z"/><path fill="#fff" d="M23.9 42.2a4.4 4.4 0 1 1 8.7 0 4.4 4.4 0 0 1-8.7 0Z"/><path class="partyhatSparkles" d="M23.9 42.2a4.4 4.4 0 1 1 8.7 0 4.4 4.4 0 0 1-8.7 0Z"/></svg>'
            ),
            Headwear.HeadwearVariants.PARTYHAT,
            _getHeadwearColor(partyhatColor)
        );
    }

    function _getPartyhatStyle(PartyhatColors partyhatColor) internal pure returns (string memory) {
        (string memory primaryColor, string memory secondaryColor) = _getPartyhatColor(partyhatColor);
        return
            string.concat(
                '<style>.partyhatColor1 { fill:',
                primaryColor,
                '}.partyhatColor2 { fill:',
                secondaryColor,
                '}.partyhatSparkles { stroke:',
                partyhatColor == PartyhatColors.GOLD ? LensColors.darkGold : LensColors.black,
                ';stroke-linecap: round;stroke-linejoin: round;stroke-width: 4}</style>'
            );
    }

    function _getPartyhatColor(PartyhatColors partyhatColor) internal pure returns (string memory, string memory) {
        if (partyhatColor == PartyhatColors.GREEN) {
            return (LensColors.lightGreen, LensColors.baseGreen);
        } else if (partyhatColor == PartyhatColors.PURPLE) {
            return (LensColors.lightPurple, LensColors.basePurple);
        } else if (partyhatColor == PartyhatColors.BLUE) {
            return (LensColors.lightBlue, LensColors.baseBlue);
        } else if (partyhatColor == PartyhatColors.PINK) {
            return (LensColors.lightPink, LensColors.basePink);
        } else if (partyhatColor == PartyhatColors.GOLD) {
            return (LensColors.lightGold, LensColors.baseGold);
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(PartyhatColors partyhatColor) internal pure returns (Headwear.HeadwearColors) {
        if (partyhatColor == PartyhatColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (partyhatColor == PartyhatColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (partyhatColor == PartyhatColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (partyhatColor == PartyhatColors.PINK) {
            return Headwear.HeadwearColors.PINK;
        } else if (partyhatColor == PartyhatColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
