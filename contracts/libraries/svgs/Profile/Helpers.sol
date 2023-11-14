// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Helpers {
    enum ComponentBytes {
        BACKGROUND,
        SKIN,
        FACE,
        HEAD,
        BODY,
        HANDS,
        LEGS,
        SHOES,
        LOGO,
        HEADWEAR
    }

    // Seed:
    // 0xCC00LL00RR__BBYYTTEESS________________VVAARRIIAANNTT__BBYYTTEESS

    // We take variants from the right bytes of the seed
    function getVariant(uint256 seed, ComponentBytes componentByte) internal pure returns (uint8) {
        return uint8((seed >> (uint8(componentByte) * 8)) & 0xFF);
    }

    // We take colors from the left bytes of the seed
    function getColor(uint256 seed, ComponentBytes componentByte) internal pure returns (uint8) {
        return uint8((seed >> ((31 - uint8(componentByte)) * 8)) & 0xFF);
    }
}

library Background {
    enum BackgroundColors {
        GREEN,
        PURPLE,
        BLUE,
        GOLD
    }

    function getBackgroundColor(BackgroundColors backgroundColor) internal pure returns (string memory) {
        if (backgroundColor == BackgroundColors.GREEN) {
            return '#green';
        } else if (backgroundColor == BackgroundColors.PURPLE) {
            return '#purple';
        } else if (backgroundColor == BackgroundColors.BLUE) {
            return '#blue';
        } else if (backgroundColor == BackgroundColors.GOLD) {
            return '#yellow';
        } else {
            revert(); // Avoid warnings.
        }
    }
}

library Skin {
    enum SkinColors {
        GREEN,
        PURPLE,
        BLUE,
        GOLD
    }

    function getSkinColor(SkinColors skinColor) internal pure returns (string memory) {
        if (skinColor == SkinColors.GREEN) {
            return '#A0D170';
        } else if (skinColor == SkinColors.PURPLE) {
            return '#EAD7FF';
        } else if (skinColor == SkinColors.BLUE) {
            return '#D9E0FF';
        } else if (skinColor == SkinColors.GOLD) {
            return '#F8C944';
        } else {
            revert(); // Avoid warnings.
        }
    }
}

library GoldSparkles {
    function getGoldSparkles() internal pure returns (string memory) {
        return
            '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><path fill="#fff" stroke="#B96326" stroke-linecap="square" stroke-linejoin="round" stroke-width="3.5" d="M13.3 89c.1-.3.5-.3.6 0 2 5.5 6 10 11.3 11.9v.1l-.5.2c-5 1.8-8.9 6-10.6 11.3v.1c-.1.2-.5.2-.5 0v0a19 19 0 0 0-11.4-12.1v0-.2h.3c5-1.8 9-6 10.8-11.4v0Z"/><path fill="#fff" stroke="#B96326" stroke-linecap="square" stroke-linejoin="round" stroke-width="3" d="M19.6 120.5c0-.2.3-.2.4 0a12 12 0 0 0 7 7.5v0c.1 0 .1.1 0 .1l-.3.1a11.1 11.1 0 0 0-6.7 7.2h0c0 .2-.2.2-.3 0v0a12.1 12.1 0 0 0-7.1-7.6v0-.1l.1-.1a11 11 0 0 0 6.9-7.1v0Z"/></svg>';
    }
}
