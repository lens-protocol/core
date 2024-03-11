// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from '../Headwear.sol';

library HeadwearPartyhat {
    enum PartyhatColors {
        GREEN,
        PURPLE,
        BLUE,
        GOLD
    }

    function getPartyhat(
        PartyhatColors partyhatColor
    ) internal pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getPartyhatStyle(partyhatColor),
                '<path class="partyhatColor2" d="M99 34.9a12 12 0 0 0 10.7.8l2.2.6 9.5 16.9a50 50 0 0 1-24.8-14c.5-1 1-2 1.7-3L99 35Z"/><path fill="#fff" d="M99 34.9a11.5 11.5 0 0 1-4.7-12.3c1.2-4.5 5.5-8 10.2-8.3 4.7-.3 9.4 2.8 11 7.2 1.7 4.4.3 9.7-3.3 12.7-.8.6-1.6 1-2.5 1.5a11.5 11.5 0 0 1-10.7-.8Z"/><path class="partyhatColor1" d="M141.3 90.5a108.7 108.7 0 0 1-56-31l11.3-20.2c6.3 7 15.6 11.6 24.8 13.9 6.7 12.2 13.4 24.6 20 37.3Z"/><path class="partyhatColor2" d="M72.4 83.3c4.3-8 8.5-16 12.9-23.8a108.7 108.7 0 0 0 56 31l6.3 12.2a57.5 57.5 0 0 1-21.3 10.2 95 95 0 0 1-53.9-29.6Z"/><path class="partyhatColor1" d="m62.4 102.7 10-19.4a95 95 0 0 0 54 29.6 93.5 93.5 0 0 1-21.3 1.9c-20.2 0-29.7-3-42.7-12.1Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="m98.3 36.3-1.7 3a1648.8 1648.8 0 0 0-34.2 63.4c13 9.2 22.5 12.1 42.7 12.1m36.2-24.3 6.3 12.2a57.5 57.5 0 0 1-21.3 10.2 93.5 93.5 0 0 1-21.2 1.9m6.9-78.5a1948.7 1948.7 0 0 1 29.3 54.2m-31.6-54.8c.9-.4 1.7-1 2.5-1.5 3.6-3 5-8.4 3.4-12.7a11.5 11.5 0 0 0-11.1-7.2c-4.7.3-9 3.8-10.2 8.3C93 27.3 95 32.5 99 35a12 12 0 0 0 10.7.8Z"/><path stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M96.6 39.3c6.3 7 15.6 11.6 24.8 13.9m-36.1 6.3a108.7 108.7 0 0 0 56 31h0m-68.9-7.2a95 95 0 0 0 54 29.6h0"/><path fill="#fff" d="M35.1 89.7c5.2-1 9.6-5.5 10.7-10.7C48 84 52 88.5 57 90.3a16.6 16.6 0 0 0-11.3 12.3c-.8-5.8-5-11-10.6-12.9Z"/><path class="partyhatSparkles" d="M45.8 79c-1 5.2-5.5 9.6-10.7 10.7 5.5 2 9.8 7.1 10.6 13A16.6 16.6 0 0 1 57 90.2c-5-1.8-9-6.2-11.2-11.3Z"/><path fill="#fff" d="M151.6 50.2a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z"/><path class="partyhatSparkles" d="M151.6 50.2a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z"/><path fill="#fff" d="M55.7 55.6a6.7 6.7 0 1 0 0-13.4 6.7 6.7 0 0 0 0 13.4Z"/><path class="partyhatSparkles" d="M55.7 55.6a6.7 6.7 0 1 0 0-13.4 6.7 6.7 0 0 0 0 13.4Z"/><path fill="#fff" d="M172.9 71.2c-.2-4.7-4.1-9-8.8-9.7 4.3-.3 8.2-4 8.6-8.3a11 11 0 0 0 8.6 8.3 10 10 0 0 0-8.4 9.7Z"/><path class="partyhatSparkles" d="M172.7 53.2c-.4 4.3-4.3 8-8.6 8.3 4.7.7 8.6 5 8.8 9.7 0-4.7 3.8-9 8.4-9.7a11 11 0 0 1-8.6-8.3Z"/><path fill="#fff" d="M17.8 69.2a4.4 4.4 0 1 1 8.7 0 4.4 4.4 0 0 1-8.7 0Z"/><path class="partyhatSparkles" d="M17.783 70.18a4.374 4.374 0 0 1 4.37-4.37c2.41 0 4.38 1.96 4.38 4.38a4.37 4.37 0 0 1-4.38 4.37c-2.42 0-4.37-1.96-4.37-4.37v-.01Z"/></svg>'
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
                partyhatColor == PartyhatColors.GOLD ? '#B96326' : '#000',
                ';stroke-linecap: round;stroke-linejoin: round;stroke-width: 4}</style>'
            );
    }

    function _getPartyhatColor(PartyhatColors partyhatColor) internal pure returns (string memory, string memory) {
        if (partyhatColor == PartyhatColors.GREEN) {
            return ('#F4FFDC', '#A0D170');
        } else if (partyhatColor == PartyhatColors.PURPLE) {
            return ('#F9F4FF', '#EAD7FF');
        } else if (partyhatColor == PartyhatColors.BLUE) {
            return ('#F4F6FF', '#D9E0FF');
        } else if (partyhatColor == PartyhatColors.GOLD) {
            return ('#FFEE93', '#FFCD3D');
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
        } else if (partyhatColor == PartyhatColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
