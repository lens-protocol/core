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

    function getProfileSVG(uint256 profileId, bytes32 blockSeed) public pure returns (string memory, string memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(profileId, blockSeed)));
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
                '<svg xmlns="http://www.w3.org/2000/svg" width="250" height="335" fill="none" id="container" x="32" viewBox="0 0 260 415" >',
                _generateSvgElements(chosenElements, headwearSvg),
                '</svg><defs><radialGradient id="green" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#DFFFBF"/><stop offset="1" stop-color="#EFD"/></radialGradient><radialGradient id="pink" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#FFE7F0"/><stop offset="1" stop-color="#FFF3F8"/></radialGradient><radialGradient id="purple" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#F1E4FF"/><stop offset="1" stop-color="#F8F1FF"/></radialGradient><radialGradient id="blue" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#E6EAFF"/><stop offset="1" stop-color="#EFF2FF"/></radialGradient><radialGradient id="yellow" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#FFE7A5"/><stop offset="1" stop-color="#FFF2CE"/></radialGradient></defs></svg>'
            );
    }

    function _getTraits(ChosenElements memory chosenElements) internal pure returns (string memory) {
        string memory traits;
        {
            traits = string.concat(
                _getTrait(chosenElements.skinColor), // Color
                _getTrait(chosenElements.legColor), // Pants
                _getTrait(chosenElements.shoeColor), // Sneakers
                _getTrait(chosenElements.handsVariant), // Hands
                _getTrait(chosenElements.bodyVariant) // Clothing
            );
        }
        return
            string.concat(
                traits,
                _getTrait(chosenElements.logoVariant), // Clothing Logo
                _getTrait(chosenElements.faceVariant), // Mood - Doesn't have an ending comma
                _getTrait(chosenElements.headwearVariant) // Headwear - Has comma at the beginning
            );
    }

    function _getTrait(Skin.SkinColors skinColor) internal pure returns (string memory) {
        string memory stringSkinColor;
        if (skinColor == Skin.SkinColors.GREEN) {
            stringSkinColor = 'Forest';
        } else if (skinColor == Skin.SkinColors.PINK) {
            stringSkinColor = 'Blush';
        } else if (skinColor == Skin.SkinColors.PURPLE) {
            stringSkinColor = 'Berry';
        } else if (skinColor == Skin.SkinColors.BLUE) {
            stringSkinColor = 'Ice';
        } else if (skinColor == Skin.SkinColors.GOLD) {
            stringSkinColor = 'Gold';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Color","value":"', stringSkinColor, '"},');
    }

    function _getTrait(Legs.LegColors legColor) internal pure returns (string memory) {
        string memory stringLegColor;
        if (legColor == Legs.LegColors.GREEN) {
            stringLegColor = 'Green';
        } else if (legColor == Legs.LegColors.DARK) {
            stringLegColor = 'Dark';
        } else if (legColor == Legs.LegColors.LIGHT) {
            stringLegColor = 'Light';
        } else if (legColor == Legs.LegColors.PURPLE) {
            stringLegColor = 'Purple';
        } else if (legColor == Legs.LegColors.BLUE) {
            stringLegColor = 'Blue';
        } else if (legColor == Legs.LegColors.PINK) {
            stringLegColor = 'Pink';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Pants","value":"', stringLegColor, '"},');
    }

    function _getTrait(Shoes.ShoeColors shoeColor) internal pure returns (string memory) {
        string memory stringShoeColor;
        if (shoeColor == Shoes.ShoeColors.GREEN) {
            stringShoeColor = 'Green';
        } else if (shoeColor == Shoes.ShoeColors.DARK) {
            stringShoeColor = 'Dark';
        } else if (shoeColor == Shoes.ShoeColors.LIGHT) {
            stringShoeColor = 'Light';
        } else if (shoeColor == Shoes.ShoeColors.PURPLE) {
            stringShoeColor = 'Purple';
        } else if (shoeColor == Shoes.ShoeColors.BLUE) {
            stringShoeColor = 'Blue';
        } else if (shoeColor == Shoes.ShoeColors.PINK) {
            stringShoeColor = 'Pink';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Sneakers","value":"', stringShoeColor, '"},');
    }

    function _getTrait(Hands.HandsVariants handsVariant) internal pure returns (string memory) {
        string memory stringHandsVariant;
        if (handsVariant == Hands.HandsVariants.HANDSDOWN) {
            stringHandsVariant = 'Chilling';
        } else if (handsVariant == Hands.HandsVariants.PEACEDOUBLE) {
            stringHandsVariant = 'Double Peace';
        } else if (handsVariant == Hands.HandsVariants.PEACESINGLE) {
            stringHandsVariant = 'Peace';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Hands","value":"', stringHandsVariant, '"},');
    }

    function _getTrait(Body.BodyVariants bodyVariant) internal pure returns (string memory) {
        string memory stringBodyVariant;
        if (bodyVariant == Body.BodyVariants.HOODIE) {
            stringBodyVariant = 'Hoodie';
        } else if (bodyVariant == Body.BodyVariants.JACKET) {
            stringBodyVariant = 'Varsity';
        } else if (bodyVariant == Body.BodyVariants.TANKTOP) {
            stringBodyVariant = 'Tank';
        } else if (bodyVariant == Body.BodyVariants.TSHIRT) {
            stringBodyVariant = 'Tee';
        } else if (bodyVariant == Body.BodyVariants.SHIBUYA) {
            stringBodyVariant = 'Shibuya';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Clothing","value":"', stringBodyVariant, '"},');
    }

    function _getTrait(Logo.LogoVariants logoVariant) internal pure returns (string memory) {
        string memory stringLogoVariant;
        if (logoVariant == Logo.LogoVariants.HAPPY) {
            stringLogoVariant = 'Happy';
        } else if (logoVariant == Logo.LogoVariants.HEART) {
            stringLogoVariant = 'Heart';
        } else if (logoVariant == Logo.LogoVariants.LENS) {
            stringLogoVariant = 'Lens';
        } else if (logoVariant == Logo.LogoVariants.PEACE) {
            stringLogoVariant = 'Peace';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Clothing Logo","value":"', stringLogoVariant, '"},');
    }

    function _getTrait(Face.FaceVariants faceVariant) internal pure returns (string memory) {
        string memory stringFaceVariant;
        if (faceVariant == Face.FaceVariants.BUBBLEGUM) {
            stringFaceVariant = 'Bubble Gum';
        } else if (faceVariant == Face.FaceVariants.GRIN_TONGUE) {
            stringFaceVariant = 'Silly';
        } else if (faceVariant == Face.FaceVariants.GRIN) {
            stringFaceVariant = 'Happy';
        } else if (faceVariant == Face.FaceVariants.LAUGH) {
            stringFaceVariant = 'LOL';
        } else if (faceVariant == Face.FaceVariants.LOVE) {
            stringFaceVariant = 'In Love';
        } else if (faceVariant == Face.FaceVariants.OOPS) {
            stringFaceVariant = 'Oops';
        } else if (faceVariant == Face.FaceVariants.SLEEPY) {
            stringFaceVariant = 'ZZZ';
        } else if (faceVariant == Face.FaceVariants.SMILE_TEETH) {
            stringFaceVariant = 'Cheesin';
        } else if (faceVariant == Face.FaceVariants.SMILE) {
            stringFaceVariant = 'OG';
        } else if (faceVariant == Face.FaceVariants.SMIRK) {
            stringFaceVariant = 'Slick';
        } else if (faceVariant == Face.FaceVariants.TONGUE) {
            stringFaceVariant = 'Playful';
        } else if (faceVariant == Face.FaceVariants.WINK) {
            stringFaceVariant = 'Wink';
        } else if (faceVariant == Face.FaceVariants.WOW_TONGUE) {
            stringFaceVariant = 'Excited';
        } else if (faceVariant == Face.FaceVariants.WOW) {
            stringFaceVariant = 'Lucy';
        } else if (faceVariant == Face.FaceVariants.BABY) {
            stringFaceVariant = 'Baby';
        } else if (faceVariant == Face.FaceVariants.KAWAII) {
            stringFaceVariant = 'Kawaii';
        } else if (faceVariant == Face.FaceVariants.PIXIE) {
            stringFaceVariant = 'Pixie';
        } else if (faceVariant == Face.FaceVariants.TODDLER) {
            stringFaceVariant = 'Toddler';
        } else if (faceVariant == Face.FaceVariants.VAMP) {
            stringFaceVariant = 'Vamp';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Mood","value":"', stringFaceVariant, '"}');
    }

    function _getTrait(Headwear.HeadwearVariants headwearVariant) internal pure returns (string memory) {
        string memory stringHeadwearVariant;
        if (headwearVariant == Headwear.HeadwearVariants.NONE) {
            return '';
        } else if (headwearVariant == Headwear.HeadwearVariants.BEANIE) {
            stringHeadwearVariant = 'Brrr';
        } else if (headwearVariant == Headwear.HeadwearVariants.HAT) {
            stringHeadwearVariant = 'Cap';
        } else if (headwearVariant == Headwear.HeadwearVariants.PLANTS) {
            stringHeadwearVariant = 'Lily';
        } else if (headwearVariant == Headwear.HeadwearVariants.SPARKLES) {
            stringHeadwearVariant = 'Sparkle';
        } else if (headwearVariant == Headwear.HeadwearVariants.CROWN) {
            stringHeadwearVariant = 'King';
        } else if (headwearVariant == Headwear.HeadwearVariants.FLORAL) {
            stringHeadwearVariant = 'Queen';
        } else if (headwearVariant == Headwear.HeadwearVariants.GLASSES) {
            stringHeadwearVariant = 'Shady';
        } else if (headwearVariant == Headwear.HeadwearVariants.MUSHROOM) {
            stringHeadwearVariant = 'Mushie';
        } else if (headwearVariant == Headwear.HeadwearVariants.NIGHTCAP) {
            stringHeadwearVariant = 'gn';
        } else if (headwearVariant == Headwear.HeadwearVariants.PARTYHAT) {
            stringHeadwearVariant = 'Birthday';
        } else if (headwearVariant == Headwear.HeadwearVariants.ICECREAM) {
            stringHeadwearVariant = 'Sweet';
        } else if (headwearVariant == Headwear.HeadwearVariants.BEAR) {
            stringHeadwearVariant = 'Bear';
        } else if (headwearVariant == Headwear.HeadwearVariants.BEE) {
            stringHeadwearVariant = 'Bee';
        } else if (headwearVariant == Headwear.HeadwearVariants.BIRDIE) {
            stringHeadwearVariant = 'Birdie';
        } else if (headwearVariant == Headwear.HeadwearVariants.BRAINS) {
            stringHeadwearVariant = 'Brains';
        } else if (headwearVariant == Headwear.HeadwearVariants.BULL) {
            stringHeadwearVariant = 'Bull';
        } else if (headwearVariant == Headwear.HeadwearVariants.EARRINGS) {
            stringHeadwearVariant = 'Earrings';
        } else if (headwearVariant == Headwear.HeadwearVariants.LOTUS) {
            stringHeadwearVariant = 'Lotus';
        } else if (headwearVariant == Headwear.HeadwearVariants.MAJOR) {
            stringHeadwearVariant = 'Major Lenny';
        } else if (headwearVariant == Headwear.HeadwearVariants.SCOUT) {
            stringHeadwearVariant = 'Scout';
        } else if (headwearVariant == Headwear.HeadwearVariants.SHAMAN) {
            stringHeadwearVariant = 'Shaman';
        } else {
            revert();
        }
        return string.concat(',{"trait_type":"Headwear","value":"', stringHeadwearVariant, '"}');
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
                Face.getFace(
                    chosenElements.faceVariant,
                    chosenElements.isGold ? Face.FaceColors.GOLD : Face.FaceColors.NORMAL,
                    chosenElements.skinColor
                ),
                headwearSvg,
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
