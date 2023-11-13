// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Background, Skin, GoldSparkles, Helpers} from './Helpers.sol';
import {Headwear} from './Headwear.sol';
import {Face} from './Face.sol';
import {Head} from './Head.sol';
import {Legs} from './Legs.sol';
import {Shoes} from './Shoes.sol';
import {Body} from './Body.sol';
import {Hands} from './Hands.sol';
import {Logo} from './Logo.sol';

library ProfileSVG {
    function getProfileSVG(uint256 profileId) public pure returns (string memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(profileId)));
        bool isGold = profileId <= 1000;
        return _getSVG(seed, isGold);
    }

    function _getSVG(uint256 seed, bool isGold) internal pure returns (string memory) {
        Background.BackgroundColors backgroundColor = isGold
            ? Background.BackgroundColors.GOLD
            : Background.BackgroundColors(
                uint8(Helpers.getColor(seed, Helpers.ComponentBytes.BACKGROUND)) %
                    uint8(type(Background.BackgroundColors).max)
            );

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="275" height="275" fill="none"><g>',
                '<path fill="url(',
                Background.getBackgroundColor(backgroundColor),
                ')" d="M0 0h275v275H0z"/></g>',
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none" id="container" x="30" y="0">',
                _getElements(seed, isGold),
                '</svg><defs><radialGradient id="green" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#DFFFBF"/><stop offset="1" stop-color="#EFD"/></radialGradient><radialGradient id="purple" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#F1E4FF"/><stop offset="1" stop-color="#F8F1FF"/></radialGradient><radialGradient id="blue" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#E6EAFF"/><stop offset="1" stop-color="#EFF2FF"/></radialGradient><radialGradient id="yellow" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#FFE7A5"/><stop offset="1" stop-color="#FFF2CE"/></radialGradient></defs></svg>'
            );
    }

    function _getElements(uint256 seed, bool isGold) internal pure returns (string memory str) {
        Skin.SkinColors skinColor = isGold
            ? Skin.SkinColors.GOLD
            : Skin.SkinColors(
                uint8(Helpers.getColor(seed, Helpers.ComponentBytes.SKIN)) % uint8(type(Skin.SkinColors).max)
            );

        {
            Legs.LegColors legColor = Legs.LegColors(
                uint8(Helpers.getColor(seed, Helpers.ComponentBytes.LEGS)) % (uint8(type(Legs.LegColors).max) + 1)
            );

            Shoes.ShoeColors shoeColor = Shoes.ShoeColors(
                uint8(Helpers.getColor(seed, Helpers.ComponentBytes.SHOES)) % (uint8(type(Shoes.ShoeColors).max) + 1)
            );

            str = string.concat(str, Legs.getLegs(legColor), Shoes.getShoes(shoeColor));
        }

        Hands.HandsVariants handsVariant = Hands.HandsVariants(
            uint8(Helpers.getVariant(seed, Helpers.ComponentBytes.HANDS)) % (uint8(type(Hands.HandsVariants).max) + 1)
        );

        Body.BodyVariants bodyVariant = Body.BodyVariants(
            uint8(Helpers.getVariant(seed, Helpers.ComponentBytes.BODY)) % (uint8(type(Body.BodyVariants).max) + 1)
        );

        Body.BodyColors bodyColor = Body.BodyColors(
            uint8(Helpers.getColor(seed, Helpers.ComponentBytes.BODY)) % (uint8(type(Body.BodyColors).max) + 1)
        );

        {
            Logo.LogoVariants logoVariant = Logo.LogoVariants(
                uint8(Helpers.getVariant(seed, Helpers.ComponentBytes.LOGO)) % (uint8(type(Logo.LogoVariants).max) + 1)
            );

            Logo.LogoColors logoColor = Logo.LogoColors(
                uint8(Helpers.getColor(seed, Helpers.ComponentBytes.LOGO)) % (uint8(type(Logo.LogoColors).max) + 1)
            );

            str = string.concat(
                str,
                Body.getBody(bodyVariant, bodyColor, handsVariant, Hands.HandsColors(uint8(skinColor))),
                Logo.getLogo(logoVariant, logoColor, bodyVariant, bodyColor),
                Head.getHead(Head.HeadColors(uint8(skinColor))),
                Headwear.getHeadwear(seed, isGold)
            );
        }

        Face.FaceVariants faceVariant = Face.FaceVariants(
            uint8(Helpers.getVariant(seed, Helpers.ComponentBytes.FACE)) % (uint8(type(Face.FaceVariants).max) + 1)
        );

        return
            string.concat(
                str,
                Face.getFace(faceVariant, isGold ? Face.FaceColors.GOLD : Face.FaceColors.NORMAL),
                Hands.getHands(handsVariant, Hands.HandsColors(uint8(skinColor)), bodyVariant, bodyColor),
                isGold ? GoldSparkles.getGoldSparkles() : ''
            );
    }
}
