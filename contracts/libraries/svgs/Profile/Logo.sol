// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Body} from './Body.sol';

library Logo {
    enum LogoVariants {
        HAPPY,
        HEART,
        LENS,
        PEACE
    }

    enum LogoColors {
        GREEN,
        PURPLE,
        BLUE,
        LIGHT,
        DARK
    }

    function getLogo(
        LogoVariants logoVariant,
        LogoColors logoColor,
        Body.BodyVariants bodyVariant,
        Body.BodyColors bodyColor
    ) public pure returns (string memory) {
        // Don't display Light & Dark Logos on non-Light & non-Dark bodies
        if (bodyColor != Body.BodyColors.LIGHT && bodyColor != Body.BodyColors.DARK) {
            if (logoColor == LogoColors.LIGHT) {
                logoColor = LogoColors.BLUE;
            } else if (logoColor == LogoColors.DARK) {
                logoColor = LogoColors.PURPLE;
            }
        }

        if (bodyVariant == Body.BodyVariants.HOODIE) {
            return getLogoHoodie(logoVariant, logoColor);
        } else if (bodyVariant == Body.BodyVariants.TANKTOP) {
            return getLogoTshirtTanktop(logoVariant, logoColor);
        } else if (bodyVariant == Body.BodyVariants.TSHIRT) {
            return getLogoTshirtTanktop(logoVariant, logoColor);
        } else if (bodyVariant == Body.BodyVariants.JACKET) {
            return getLogoJacket(logoVariant, logoColor);
        } else {
            revert(); // Avoid warnings.
        }
    }

    function getLogoHoodie(LogoVariants logoVariant, LogoColors logoColor) public pure returns (string memory) {
        if (logoVariant == LogoVariants.HAPPY) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><circle cx="105" cy="210.176" r="6" fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752"/><circle cx="102.75" cy="209.426" r=".75" fill="#000"/><circle cx="107.25" cy="209.426" r=".75" fill="#000"/><path stroke="#000" stroke-linecap="round" stroke-width="1.5" d="M102.8 211.7s.7 1.1 2.2 1.1 2.3-1.1 2.3-1.1"/></svg>'
                );
        } else if (logoVariant == LogoVariants.HEART) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><path fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752" d="M105.6 206c5.4-5.5 12.8 1 7.5 6.9-2 2.3-5.2 3.6-8.3 3.6a11 11 0 0 1-8.2-3.6c-5-6 2.5-12.4 7.8-6.8.4.5.7.5 1.2 0Z"/></svg>'
                );
        } else if (logoVariant == LogoVariants.LENS) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><path fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752" d="m108.8 207.7-.3.2v-.6c0-4.5-7-4.5-7 0v.6l-.3-.2a8.5 8.5 0 0 0-.2-.2c-3.3-3.1-8.1 1.7-5 5l.2.2c3.8 3.7 8.8 3.7 8.8 3.7s5 0 8.8-3.7l.2-.2c3.1-3.3-1.7-8.1-5-5l-.2.2Z"/></svg>'
                );
        } else if (logoVariant == LogoVariants.PEACE) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><circle cx="105" cy="210.176" r="6" fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752"/><path stroke="#000" stroke-width="1.5" d="M105 204.2v12m0-4.9-4.5 2.6m4.5-2.6 4.5 2.6"/></svg>'
                );
        } else {
            revert(); // Avoid warnings.
        }
    }

    function getLogoTshirtTanktop(LogoVariants logoVariant, LogoColors logoColor) public pure returns (string memory) {
        if (logoVariant == LogoVariants.HAPPY) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><circle cx="105" cy="227.19" r="8" fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752"/><circle cx="102" cy="226.19" r="1" fill="#000"/><circle cx="108" cy="226.19" r="1" fill="#000"/><path stroke="#000" stroke-linecap="round" stroke-width="1.5" d="M102 229.2s1 1.5 3 1.5 3-1.5 3-1.5"/></svg>'
                );
        } else if (logoVariant == LogoVariants.HEART) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><path fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752" d="M105.8 222.2c6.5-6.7 15.4 1 9 8.1a13.6 13.6 0 0 1-10 4.5c-3.7-.1-7.4-1.6-9.8-4.5-6-7 3-14.8 9.4-8 .5.5.8.5 1.4 0Z"/></svg>'
                );
        } else if (logoVariant == LogoVariants.LENS) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><path fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752" d="m109.5 223.7-.3.3v-.8c-.1-5.4-8.3-5.4-8.4 0v.8l-.3-.3a10.6 10.6 0 0 0-.3-.2c-4-3.7-9.7 2-6 6l.3.2c4.5 4.5 10.5 4.5 10.5 4.5s6 0 10.5-4.5l.3-.3c3.7-3.9-2-9.6-6-6l-.3.3Z"/></svg>'
                );
        } else if (logoVariant == LogoVariants.PEACE) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><circle cx="105" cy="227.19" r="8" fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752"/><path stroke="#000" stroke-width="1.5" d="M105 219.2v16m0-6.5-6 3.5m6-3.5 6 3.5"/></svg>'
                );
        } else {
            revert(); // Avoid warnings.
        }
    }

    function getLogoJacket(LogoVariants logoVariant, LogoColors logoColor) public pure returns (string memory) {
        if (logoVariant == LogoVariants.HAPPY) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><circle cx="127.993" cy="211.494" r="5" fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752"/><circle cx="126.493" cy="210.994" r=".5" fill="#000"/><circle cx="129.493" cy="210.994" r=".5" fill="#000"/><path stroke="#000" stroke-linecap="round" stroke-width=".75" d="M126.5 212.5s.5.7 1.5.7 1.5-.7 1.5-.7"/></svg>'
                );
        } else if (logoVariant == LogoVariants.HEART) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><path fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752" d="M128.5 208c4.4-4.6 10.5.8 6.2 5.7a9 9 0 0 1-6.9 3 9 9 0 0 1-6.7-3c-4.2-4.9 2-10.3 6.4-5.6.4.4.6.4 1 0Z"/></svg>'
                );
        } else if (logoVariant == LogoVariants.LENS) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><path fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752" d="M131 209.1v.2-.5c-.2-3.7-5.8-3.7-6 0v.5l-.1-.2-.2-.2c-2.7-2.5-6.7 1.4-4.1 4.1l.2.2c3 3.1 7.2 3.1 7.2 3.1s4.1 0 7.2-3l.2-.3c2.6-2.7-1.4-6.6-4.1-4l-.2.1Z"/></svg>'
                );
        } else if (logoVariant == LogoVariants.PEACE) {
            return
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none"><circle cx="127.993" cy="211.494" r="5" fill="',
                    _getLogoColor(logoColor),
                    '" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.752"/><path fill="#000" fill-rule="evenodd" d="M127.5 212.2v-5.7h1v5.7l3.5 2-.5.8-3-1.8v3.3h-1v-3.3l-3 1.8-.5-.8 3.5-2Z" clip-rule="evenodd"/></svg>'
                );
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getLogoColor(LogoColors logoColor) internal pure returns (string memory) {
        if (logoColor == LogoColors.GREEN) {
            return '#A0D170';
        } else if (logoColor == LogoColors.PURPLE) {
            return '#EAD7FF';
        } else if (logoColor == LogoColors.BLUE) {
            return '#D9E0FF';
        } else if (logoColor == LogoColors.LIGHT) {
            return '#EAEAEA';
        } else if (logoColor == LogoColors.DARK) {
            return '#DBDBDB';
        } else {
            revert(); // Avoid warnings.
        }
    }
}
