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
                _getTrait(chosenElements.backgroundColor), // Background
                _getTrait(chosenElements.skinColor), // Color
                _getTrait(chosenElements.legColor), // Pants
                _getTrait(chosenElements.shoeColor), // Sneakers
                _getTrait(chosenElements.handsVariant), // Hands
                _getTrait(chosenElements.bodyVariant), // Clothing
                _getTrait(chosenElements.bodyColor) // Clothing Color
            );
        }
        return
            string.concat(
                traits,
                _getTrait(chosenElements.logoVariant), // Clothing Logo
                _getTrait(chosenElements.logoColor), // Clothing Logo Color
                _getTrait(chosenElements.faceVariant), // Mood - Doesn't have an ending comma
                _getTrait(chosenElements.headwearVariant), // Headwear - Has comma at the beginning
                _getTrait(chosenElements.headwearColor) // Headwear Color - Has comma at the beginning
            );
    }

    function _getTrait(Background.BackgroundColors backgroundColor) internal pure returns (string memory) {
        string memory stringBackgroundColor;
        if (backgroundColor == Background.BackgroundColors.GREEN) {
            stringBackgroundColor = 'green';
        } else if (backgroundColor == Background.BackgroundColors.PINK) {
            stringBackgroundColor = 'pink';
        } else if (backgroundColor == Background.BackgroundColors.PURPLE) {
            stringBackgroundColor = 'purple';
        } else if (backgroundColor == Background.BackgroundColors.BLUE) {
            stringBackgroundColor = 'blue';
        } else if (backgroundColor == Background.BackgroundColors.GOLD) {
            stringBackgroundColor = 'gold';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Background","value":"', stringBackgroundColor, '"},');
    }

    function _getTrait(Skin.SkinColors skinColor) internal pure returns (string memory) {
        string memory stringSkinColor;
        if (skinColor == Skin.SkinColors.GREEN) {
            stringSkinColor = 'forest';
        } else if (skinColor == Skin.SkinColors.PINK) {
            stringSkinColor = 'blush';
        } else if (skinColor == Skin.SkinColors.PURPLE) {
            stringSkinColor = 'berry';
        } else if (skinColor == Skin.SkinColors.BLUE) {
            stringSkinColor = 'ice';
        } else if (skinColor == Skin.SkinColors.GOLD) {
            stringSkinColor = 'gold';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Color","value":"', stringSkinColor, '"},');
    }

    function _getTrait(Legs.LegColors legColor) internal pure returns (string memory) {
        string memory stringLegColor;
        if (legColor == Legs.LegColors.GREEN) {
            stringLegColor = 'green';
        } else if (legColor == Legs.LegColors.DARK) {
            stringLegColor = 'dark';
        } else if (legColor == Legs.LegColors.LIGHT) {
            stringLegColor = 'light';
        } else if (legColor == Legs.LegColors.PURPLE) {
            stringLegColor = 'purple';
        } else if (legColor == Legs.LegColors.BLUE) {
            stringLegColor = 'blue';
        } else if (legColor == Legs.LegColors.PINK) {
            stringLegColor = 'pink';
        } else if (legColor == Legs.LegColors.GOLD) {
            stringLegColor = 'gold';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Pants","value":"', stringLegColor, '"},');
    }

    function _getTrait(Shoes.ShoeColors shoeColor) internal pure returns (string memory) {
        string memory stringShoeColor;
        if (shoeColor == Shoes.ShoeColors.GREEN) {
            stringShoeColor = 'green';
        } else if (shoeColor == Shoes.ShoeColors.DARK) {
            stringShoeColor = 'dark';
        } else if (shoeColor == Shoes.ShoeColors.LIGHT) {
            stringShoeColor = 'light';
        } else if (shoeColor == Shoes.ShoeColors.PURPLE) {
            stringShoeColor = 'purple';
        } else if (shoeColor == Shoes.ShoeColors.BLUE) {
            stringShoeColor = 'blue';
        } else if (shoeColor == Shoes.ShoeColors.PINK) {
            stringShoeColor = 'pink';
        } else if (shoeColor == Shoes.ShoeColors.GOLD) {
            stringShoeColor = 'gold';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Sneakers","value":"', stringShoeColor, '"},');
    }

    function _getTrait(Hands.HandsVariants handsVariant) internal pure returns (string memory) {
        string memory stringHandsVariant;
        if (handsVariant == Hands.HandsVariants.HANDSDOWN) {
            stringHandsVariant = 'chilling';
        } else if (handsVariant == Hands.HandsVariants.PEACEDOUBLE) {
            stringHandsVariant = 'double peace';
        } else if (handsVariant == Hands.HandsVariants.PEACESINGLE) {
            stringHandsVariant = 'peace';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Hands","value":"', stringHandsVariant, '"},');
    }

    function _getTrait(Body.BodyVariants bodyVariant) internal pure returns (string memory) {
        string memory stringBodyVariant;
        if (bodyVariant == Body.BodyVariants.HOODIE) {
            stringBodyVariant = 'hoodie';
        } else if (bodyVariant == Body.BodyVariants.JACKET) {
            stringBodyVariant = 'varsity';
        } else if (bodyVariant == Body.BodyVariants.TANKTOP) {
            stringBodyVariant = 'tank';
        } else if (bodyVariant == Body.BodyVariants.TSHIRT) {
            stringBodyVariant = 'tee';
        } else if (bodyVariant == Body.BodyVariants.SHIBUYA) {
            stringBodyVariant = 'shibuya';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Clothing","value":"', stringBodyVariant, '"},');
    }

    function _getTrait(Body.BodyColors bodyColor) internal pure returns (string memory) {
        string memory stringBodyColor;
        if (bodyColor == Body.BodyColors.GREEN) {
            stringBodyColor = 'green';
        } else if (bodyColor == Body.BodyColors.LIGHT) {
            stringBodyColor = 'light';
        } else if (bodyColor == Body.BodyColors.DARK) {
            stringBodyColor = 'dark';
        } else if (bodyColor == Body.BodyColors.PURPLE) {
            stringBodyColor = 'purple';
        } else if (bodyColor == Body.BodyColors.BLUE) {
            stringBodyColor = 'blue';
        } else if (bodyColor == Body.BodyColors.PINK) {
            stringBodyColor = 'pink';
        } else if (bodyColor == Body.BodyColors.GOLD) {
            stringBodyColor = 'gold';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Clothing Color","value":"', stringBodyColor, '"},');
    }

    function _getTrait(Logo.LogoVariants logoVariant) internal pure returns (string memory) {
        string memory stringLogoVariant;
        if (logoVariant == Logo.LogoVariants.HAPPY) {
            stringLogoVariant = 'happy';
        } else if (logoVariant == Logo.LogoVariants.HEART) {
            stringLogoVariant = 'heart';
        } else if (logoVariant == Logo.LogoVariants.LENS) {
            stringLogoVariant = 'lens';
        } else if (logoVariant == Logo.LogoVariants.PEACE) {
            stringLogoVariant = 'peace';
        } else if (logoVariant == Logo.LogoVariants.NONE) {
            stringLogoVariant = 'none';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Clothing Logo","value":"', stringLogoVariant, '"},');
    }

    function _getTrait(Logo.LogoColors logoColor) internal pure returns (string memory) {
        string memory stringLogoColor;
        if (logoColor == Logo.LogoColors.GREEN) {
            stringLogoColor = 'green';
        } else if (logoColor == Logo.LogoColors.PINK) {
            stringLogoColor = 'pink';
        } else if (logoColor == Logo.LogoColors.PURPLE) {
            stringLogoColor = 'purple';
        } else if (logoColor == Logo.LogoColors.BLUE) {
            stringLogoColor = 'blue';
        } else if (logoColor == Logo.LogoColors.LIGHT) {
            stringLogoColor = 'light';
        } else if (logoColor == Logo.LogoColors.GOLD) {
            stringLogoColor = 'gold';
        } else if (logoColor == Logo.LogoColors.NONE) {
            stringLogoColor = 'none';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Clothing Logo Color","value":"', stringLogoColor, '"},');
    }

    function _getTrait(Face.FaceVariants faceVariant) internal pure returns (string memory) {
        string memory stringFaceVariant;
        if (faceVariant == Face.FaceVariants.BUBBLEGUM) {
            stringFaceVariant = 'bubble gum';
        } else if (faceVariant == Face.FaceVariants.GRIN_TONGUE) {
            stringFaceVariant = 'silly';
        } else if (faceVariant == Face.FaceVariants.GRIN) {
            stringFaceVariant = 'happy';
        } else if (faceVariant == Face.FaceVariants.LAUGH) {
            stringFaceVariant = 'lol';
        } else if (faceVariant == Face.FaceVariants.LOVE) {
            stringFaceVariant = 'in love';
        } else if (faceVariant == Face.FaceVariants.OOPS) {
            stringFaceVariant = 'oops';
        } else if (faceVariant == Face.FaceVariants.SLEEPY) {
            stringFaceVariant = 'zzz';
        } else if (faceVariant == Face.FaceVariants.SMILE_TEETH) {
            stringFaceVariant = 'cheesin';
        } else if (faceVariant == Face.FaceVariants.SMILE) {
            stringFaceVariant = 'OG';
        } else if (faceVariant == Face.FaceVariants.SMIRK) {
            stringFaceVariant = 'slick';
        } else if (faceVariant == Face.FaceVariants.TONGUE) {
            stringFaceVariant = 'playful';
        } else if (faceVariant == Face.FaceVariants.WINK) {
            stringFaceVariant = 'wink';
        } else if (faceVariant == Face.FaceVariants.WOW_TONGUE) {
            stringFaceVariant = 'excited';
        } else if (faceVariant == Face.FaceVariants.WOW) {
            stringFaceVariant = 'lucy';
        } else if (faceVariant == Face.FaceVariants.BABY) {
            stringFaceVariant = 'baby';
        } else if (faceVariant == Face.FaceVariants.KAWAII) {
            stringFaceVariant = 'kawaii';
        } else if (faceVariant == Face.FaceVariants.PIXIE) {
            stringFaceVariant = 'pixie';
        } else if (faceVariant == Face.FaceVariants.TODDLER) {
            stringFaceVariant = 'toddler';
        } else if (faceVariant == Face.FaceVariants.VAMP) {
            stringFaceVariant = 'vamp';
        } else {
            revert();
        }
        return string.concat('{"trait_type":"Mood","value":"', stringFaceVariant, '"}');
    }

    function _getTrait(Headwear.HeadwearVariants headwearVariant) internal pure returns (string memory) {
        string memory stringHeadwearVariant;
        if (headwearVariant == Headwear.HeadwearVariants.NONE) {
            stringHeadwearVariant = 'none';
        } else if (headwearVariant == Headwear.HeadwearVariants.BEANIE) {
            stringHeadwearVariant = 'brrr';
        } else if (headwearVariant == Headwear.HeadwearVariants.HAT) {
            stringHeadwearVariant = 'cap';
        } else if (headwearVariant == Headwear.HeadwearVariants.PLANTS) {
            stringHeadwearVariant = 'lily';
        } else if (headwearVariant == Headwear.HeadwearVariants.SPARKLES) {
            stringHeadwearVariant = 'sparkle';
        } else if (headwearVariant == Headwear.HeadwearVariants.CROWN) {
            stringHeadwearVariant = 'king';
        } else if (headwearVariant == Headwear.HeadwearVariants.FLORAL) {
            stringHeadwearVariant = 'queen';
        } else if (headwearVariant == Headwear.HeadwearVariants.GLASSES) {
            stringHeadwearVariant = 'shady';
        } else if (headwearVariant == Headwear.HeadwearVariants.MUSHROOM) {
            stringHeadwearVariant = 'mushie';
        } else if (headwearVariant == Headwear.HeadwearVariants.NIGHTCAP) {
            stringHeadwearVariant = 'gn';
        } else if (headwearVariant == Headwear.HeadwearVariants.PARTYHAT) {
            stringHeadwearVariant = 'birthday';
        } else if (headwearVariant == Headwear.HeadwearVariants.ICECREAM) {
            stringHeadwearVariant = 'sweet';
        } else if (headwearVariant == Headwear.HeadwearVariants.BEAR) {
            stringHeadwearVariant = 'bear';
        } else if (headwearVariant == Headwear.HeadwearVariants.BEE) {
            stringHeadwearVariant = 'bee';
        } else if (headwearVariant == Headwear.HeadwearVariants.BIRDIE) {
            stringHeadwearVariant = 'birdie';
        } else if (headwearVariant == Headwear.HeadwearVariants.BRAINS) {
            stringHeadwearVariant = 'brains';
        } else if (headwearVariant == Headwear.HeadwearVariants.BULL) {
            stringHeadwearVariant = 'bull';
        } else if (headwearVariant == Headwear.HeadwearVariants.EARRINGS) {
            stringHeadwearVariant = 'earrings';
        } else if (headwearVariant == Headwear.HeadwearVariants.LOTUS) {
            stringHeadwearVariant = 'lotus';
        } else if (headwearVariant == Headwear.HeadwearVariants.MAJOR) {
            stringHeadwearVariant = 'major lenny';
        } else if (headwearVariant == Headwear.HeadwearVariants.SCOUT) {
            stringHeadwearVariant = 'scout';
        } else if (headwearVariant == Headwear.HeadwearVariants.SHAMAN) {
            stringHeadwearVariant = 'shaman';
        } else {
            revert();
        }
        return string.concat(',{"trait_type":"Headwear","value":"', stringHeadwearVariant, '"}');
    }

    function _getTrait(Headwear.HeadwearColors headwearColor) internal pure returns (string memory) {
        string memory stringHeadwearColor;
        if (headwearColor == Headwear.HeadwearColors.NONE) {
            stringHeadwearColor = 'none';
        } else if (headwearColor == Headwear.HeadwearColors.GREEN) {
            stringHeadwearColor = 'green';
        } else if (headwearColor == Headwear.HeadwearColors.PURPLE) {
            stringHeadwearColor = 'purple';
        } else if (headwearColor == Headwear.HeadwearColors.BLUE) {
            stringHeadwearColor = 'blue';
        } else if (headwearColor == Headwear.HeadwearColors.PINK) {
            stringHeadwearColor = 'pink';
        } else if (headwearColor == Headwear.HeadwearColors.GOLD) {
            stringHeadwearColor = 'gold';
        } else {
            revert();
        }
        return string.concat(',{"trait_type":"Headwear Color","value":"', stringHeadwearColor, '"}');
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

        chosenElements.legColor = isGold
            ? Legs.LegColors.GOLD
            : Legs.LegColors(
                uint8(Helpers.getColor(seed, Helpers.ComponentBytes.LEGS)) % uint8(type(Legs.LegColors).max)
            );

        chosenElements.shoeColor = isGold
            ? Shoes.ShoeColors.GOLD
            : Shoes.ShoeColors(
                uint8(Helpers.getColor(seed, Helpers.ComponentBytes.SHOES)) % uint8(type(Shoes.ShoeColors).max)
            );

        chosenElements.handsVariant = Hands.HandsVariants(
            uint8(Helpers.getVariant(seed, Helpers.ComponentBytes.HANDS)) % (uint8(type(Hands.HandsVariants).max) + 1)
        );

        chosenElements.bodyVariant = Body.BodyVariants(
            uint8(Helpers.getVariant(seed, Helpers.ComponentBytes.BODY)) % (uint8(type(Body.BodyVariants).max) + 1)
        );

        chosenElements.bodyColor = isGold
            ? Body.BodyColors.GOLD
            : Body.BodyColors(
                uint8(Helpers.getColor(seed, Helpers.ComponentBytes.BODY)) % uint8(type(Body.BodyColors).max)
            );

        chosenElements.logoVariant = chosenElements.bodyVariant == Body.BodyVariants.SHIBUYA
            ? Logo.LogoVariants.NONE
            : Logo.LogoVariants(
                uint8(Helpers.getVariant(seed, Helpers.ComponentBytes.LOGO)) % (uint8(type(Logo.LogoVariants).max))
            );

        if (chosenElements.logoVariant == Logo.LogoVariants.NONE) {
            chosenElements.logoColor = Logo.LogoColors.NONE;
        } else {
            chosenElements.logoColor = isGold
                ? Logo.LogoColors.GOLD
                : Logo.LogoColors(
                    uint8(Helpers.getColor(seed, Helpers.ComponentBytes.LOGO)) % uint8(Logo.LogoColors.GOLD)
                );
        }

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
