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
    struct ChosenElements {
        Background.BackgroundColors backgroundColor;
        Skin.SkinColors skinColor;
        Legs.LegColors legColor;
        Shoes.ShoeColors shoeColor;
        Hands.HandsVariants handsVariant;
        Body.BodyVariants bodyVariant;
        Body.BodyColors bodyColor;
        Logo.LogoVariants logoVariant;
        Logo.LogoColors logoColor;
        Head.HeadColors headColor;
        Headwear.HeadwearVariants headwearVariant;
        Headwear.HeadwearColors headwearColor;
        Face.FaceVariants faceVariant;
        bool isGold;
    }

    function getProfileSVG(uint256 profileId) public pure returns (string memory, string memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(profileId)));
        bool isGold = profileId <= 1000;
        (ChosenElements memory chosenElements, string memory headwearSvg) = _chooseElements(seed, isGold);

        return (_getSVG(chosenElements, headwearSvg), _getTraits(chosenElements));
    }

    function _getSVG(
        ChosenElements memory chosenElements,
        string memory headwearSvg
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="275" height="275" fill="none"><g>',
                '<path fill="url(',
                Background.getBackgroundColor(chosenElements.backgroundColor),
                ')" d="M0 0h275v415H0z"/></g>',
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none" id="container" x="52" viewBox="0 0 260 415" >',
                _generateSvgElements(chosenElements, headwearSvg),
                '</svg><defs><radialGradient id="green" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#DFFFBF"/><stop offset="1" stop-color="#EFD"/></radialGradient><radialGradient id="purple" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#F1E4FF"/><stop offset="1" stop-color="#F8F1FF"/></radialGradient><radialGradient id="blue" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#E6EAFF"/><stop offset="1" stop-color="#EFF2FF"/></radialGradient><radialGradient id="yellow" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#FFE7A5"/><stop offset="1" stop-color="#FFF2CE"/></radialGradient></defs></svg>'
            );
    }

    function _getTraits(ChosenElements memory chosenElements) internal pure returns (string memory) {
        return '';
    }

    function _chooseElements(
        uint256 seed,
        bool isGold
    ) internal pure returns (ChosenElements memory chosenElements, string memory headwearSvg) {
        chosenElements.backgroundColor = isGold
            ? Background.BackgroundColors.GOLD
            : Background.BackgroundColors(
                uint8(Helpers.getColor(seed, Helpers.ComponentBytes.BACKGROUND)) %
                    uint8(type(Background.BackgroundColors).max)
            );

        chosenElements.skinColor = isGold
            ? Skin.SkinColors.GOLD
            : Skin.SkinColors(
                uint8(Helpers.getColor(seed, Helpers.ComponentBytes.SKIN)) % uint8(type(Skin.SkinColors).max)
            );

        chosenElements.legColor = Legs.LegColors(
            uint8(Helpers.getColor(seed, Helpers.ComponentBytes.LEGS)) % (uint8(type(Legs.LegColors).max) + 1)
        );

        chosenElements.shoeColor = Shoes.ShoeColors(
            uint8(Helpers.getColor(seed, Helpers.ComponentBytes.SHOES)) % (uint8(type(Shoes.ShoeColors).max) + 1)
        );

        chosenElements.handsVariant = Hands.HandsVariants(
            uint8(Helpers.getVariant(seed, Helpers.ComponentBytes.HANDS)) % (uint8(type(Hands.HandsVariants).max) + 1)
        );

        chosenElements.bodyVariant = Body.BodyVariants(
            uint8(Helpers.getVariant(seed, Helpers.ComponentBytes.BODY)) % (uint8(type(Body.BodyVariants).max) + 1)
        );

        chosenElements.bodyColor = Body.BodyColors(
            uint8(Helpers.getColor(seed, Helpers.ComponentBytes.BODY)) % (uint8(type(Body.BodyColors).max) + 1)
        );

        chosenElements.logoVariant = Logo.LogoVariants(
            uint8(Helpers.getVariant(seed, Helpers.ComponentBytes.LOGO)) % (uint8(type(Logo.LogoVariants).max) + 1)
        );

        chosenElements.logoColor = Logo.LogoColors(
            uint8(Helpers.getColor(seed, Helpers.ComponentBytes.LOGO)) % (uint8(type(Logo.LogoColors).max) + 1)
        );

        chosenElements.faceVariant = Face.FaceVariants(
            uint8(Helpers.getVariant(seed, Helpers.ComponentBytes.FACE)) % (uint8(type(Face.FaceVariants).max) + 1)
        );

        chosenElements.isGold = isGold;

        (headwearSvg, chosenElements.headwearVariant, chosenElements.headwearColor) = Headwear.getHeadwear(
            seed,
            isGold
        );

        return (chosenElements, headwearSvg);
    }

    function _generateSvgElements(
        ChosenElements memory chosenElements,
        string memory headwearSvg
    ) internal pure returns (string memory) {
        return
            string.concat(
                Legs.getLegs(chosenElements.legColor),
                Shoes.getShoes(chosenElements.shoeColor),
                Body.getBody(
                    chosenElements.bodyVariant,
                    chosenElements.bodyColor,
                    chosenElements.handsVariant,
                    Hands.HandsColors(uint8(chosenElements.skinColor))
                ),
                Logo.getLogo(
                    chosenElements.logoVariant,
                    chosenElements.logoColor,
                    chosenElements.bodyVariant,
                    chosenElements.bodyColor
                ),
                Head.getHead(Head.HeadColors(uint8(chosenElements.skinColor))),
                headwearSvg,
                Face.getFace(
                    chosenElements.faceVariant,
                    chosenElements.isGold ? Face.FaceColors.GOLD : Face.FaceColors.NORMAL
                ),
                Hands.getHands(
                    chosenElements.handsVariant,
                    Hands.HandsColors(uint8(chosenElements.skinColor)),
                    chosenElements.bodyVariant,
                    chosenElements.bodyColor
                ),
                chosenElements.isGold ? GoldSparkles.getGoldSparkles() : ''
            );
    }
}
