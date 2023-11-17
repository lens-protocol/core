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
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none" id="container" x="52" viewBox="0 0 260 415" >',
                _generateSvgElements(chosenElements, headwearSvg),
                '</svg><defs><radialGradient id="green" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#DFFFBF"/><stop offset="1" stop-color="#EFD"/></radialGradient><radialGradient id="purple" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#F1E4FF"/><stop offset="1" stop-color="#F8F1FF"/></radialGradient><radialGradient id="blue" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#E6EAFF"/><stop offset="1" stop-color="#EFF2FF"/></radialGradient><radialGradient id="yellow" cx="0" cy="0" r="1" gradientTransform="matrix(275 -275 362 362 0 275)" gradientUnits="userSpaceOnUse"><stop stop-color="#FFE7A5"/><stop offset="1" stop-color="#FFF2CE"/></radialGradient></defs></svg>'
            );
    }

    function _getTraits(ChosenElements memory chosenElements) internal pure returns (string memory) {
        string memory traits;
        {
            traits = string.concat(
                _getTrait(chosenElements.backgroundColor),
                _getTrait(chosenElements.skinColor),
                _getTrait(chosenElements.legColor),
                _getTrait(chosenElements.shoeColor),
                _getTrait(chosenElements.handsVariant),
                _getTrait(chosenElements.bodyVariant),
                _getTrait(chosenElements.bodyColor)
            );
        }
        return
            string.concat(
                traits,
                _getTrait(chosenElements.logoVariant),
                _getTrait(chosenElements.logoColor),
                _getTrait(chosenElements.faceVariant), // Doesn't have an ending comma
                _getTrait(chosenElements.headwearVariant), // The rest has comma in the beginning
                _getTrait(chosenElements.headwearColor)
            );
    }

    function _getTrait(Background.BackgroundColors backgroundColor) internal pure returns (string memory) {
        string memory stringBackgroundColor;
        if (backgroundColor == Background.BackgroundColors.GREEN) {
            stringBackgroundColor = 'Green';
        } else if (backgroundColor == Background.BackgroundColors.PURPLE) {
            stringBackgroundColor = 'Purple';
        } else if (backgroundColor == Background.BackgroundColors.BLUE) {
            stringBackgroundColor = 'Blue';
        } else if (backgroundColor == Background.BackgroundColors.GOLD) {
            stringBackgroundColor = 'Gold';
        }
        return string.concat('{"trait_type":"Background","value":"', stringBackgroundColor, '"},');
    }

    function _getTrait(Skin.SkinColors skinColor) internal pure returns (string memory) {
        string memory stringSkinColor;
        if (skinColor == Skin.SkinColors.GREEN) {
            stringSkinColor = 'Green';
        } else if (skinColor == Skin.SkinColors.PURPLE) {
            stringSkinColor = 'Purple';
        } else if (skinColor == Skin.SkinColors.BLUE) {
            stringSkinColor = 'Blue';
        } else if (skinColor == Skin.SkinColors.GOLD) {
            stringSkinColor = 'Gold';
        }
        return string.concat('{"trait_type":"Skin","value":"', stringSkinColor, '"},');
    }

    function _getTrait(Legs.LegColors legColor) internal pure returns (string memory) {
        string memory stringLegColor;
        if (legColor == Legs.LegColors.GREEN) {
            stringLegColor = 'Green';
        } else if (legColor == Legs.LegColors.DARK) {
            stringLegColor = 'Dark';
        } else if (legColor == Legs.LegColors.LIGHT) {
            stringLegColor = 'Light';
        }
        return string.concat('{"trait_type":"Legs","value":"', stringLegColor, '"},');
    }

    function _getTrait(Shoes.ShoeColors shoeColor) internal pure returns (string memory) {
        string memory stringShoeColor;
        if (shoeColor == Shoes.ShoeColors.GREEN) {
            stringShoeColor = 'Green';
        } else if (shoeColor == Shoes.ShoeColors.DARK) {
            stringShoeColor = 'Dark';
        } else if (shoeColor == Shoes.ShoeColors.LIGHT) {
            stringShoeColor = 'Light';
        }
        return string.concat('{"trait_type":"Shoes","value":"', stringShoeColor, '"},');
    }

    function _getTrait(Hands.HandsVariants handsVariant) internal pure returns (string memory) {
        string memory stringHandsVariant;
        if (handsVariant == Hands.HandsVariants.HANDSDOWN) {
            return '';
        } else if (handsVariant == Hands.HandsVariants.PEACEDOUBLE) {
            stringHandsVariant = 'Double Peace';
        } else if (handsVariant == Hands.HandsVariants.PEACESINGLE) {
            stringHandsVariant = 'Peace';
        }
        return string.concat('{"trait_type":"Hands","value":"', stringHandsVariant, '"},');
    }

    function _getTrait(Body.BodyVariants bodyVariant) internal pure returns (string memory) {
        string memory stringBodyVariant;
        if (bodyVariant == Body.BodyVariants.HOODIE) {
            stringBodyVariant = 'Hoodie';
        } else if (bodyVariant == Body.BodyVariants.JACKET) {
            stringBodyVariant = 'Jacket';
        } else if (bodyVariant == Body.BodyVariants.TANKTOP) {
            stringBodyVariant = 'Tanktop';
        } else if (bodyVariant == Body.BodyVariants.TSHIRT) {
            stringBodyVariant = 'Tshirt';
        }
        return string.concat('{"trait_type":"Body","value":"', stringBodyVariant, '"},');
    }

    function _getTrait(Body.BodyColors bodyColor) internal pure returns (string memory) {
        string memory stringBodyColor;
        if (bodyColor == Body.BodyColors.GREEN) {
            stringBodyColor = 'Green';
        } else if (bodyColor == Body.BodyColors.LIGHT) {
            stringBodyColor = 'Light';
        } else if (bodyColor == Body.BodyColors.DARK) {
            stringBodyColor = 'Dark';
        } else if (bodyColor == Body.BodyColors.PURPLE) {
            stringBodyColor = 'Purple';
        } else if (bodyColor == Body.BodyColors.BLUE) {
            stringBodyColor = 'Blue';
        }
        return string.concat('{"trait_type":"Body Color","value":"', stringBodyColor, '"},');
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
        }
        return string.concat('{"trait_type":"Logo","value":"', stringLogoVariant, '"},');
    }

    function _getTrait(Logo.LogoColors logoColor) internal pure returns (string memory) {
        string memory stringLogoColor;
        if (logoColor == Logo.LogoColors.GREEN) {
            stringLogoColor = 'Green';
        } else if (logoColor == Logo.LogoColors.PURPLE) {
            stringLogoColor = 'Purple';
        } else if (logoColor == Logo.LogoColors.BLUE) {
            stringLogoColor = 'Blue';
        } else if (logoColor == Logo.LogoColors.LIGHT) {
            stringLogoColor = 'Light';
        } else if (logoColor == Logo.LogoColors.DARK) {
            stringLogoColor = 'Dark';
        }
        return string.concat('{"trait_type":"Logo Color","value":"', stringLogoColor, '"},');
    }

    function _getTrait(Face.FaceVariants faceVariant) internal pure returns (string memory) {
        string memory stringFaceVariant;
        if (faceVariant == Face.FaceVariants.BUBBLEGUM) {
            stringFaceVariant = 'Bubblegum';
        } else if (faceVariant == Face.FaceVariants.GRIN_TONGUE) {
            stringFaceVariant = 'Grin Tongue';
        } else if (faceVariant == Face.FaceVariants.GRIN) {
            stringFaceVariant = 'Grin';
        } else if (faceVariant == Face.FaceVariants.LAUGH) {
            stringFaceVariant = 'Laugh';
        } else if (faceVariant == Face.FaceVariants.LOVE) {
            stringFaceVariant = 'Love';
        } else if (faceVariant == Face.FaceVariants.OOPS) {
            stringFaceVariant = 'Oops';
        } else if (faceVariant == Face.FaceVariants.SLEEPY) {
            stringFaceVariant = 'Sleepy';
        } else if (faceVariant == Face.FaceVariants.SMILE_TEETH) {
            stringFaceVariant = 'Smile Teeth';
        } else if (faceVariant == Face.FaceVariants.SMILE) {
            stringFaceVariant = 'Smile';
        } else if (faceVariant == Face.FaceVariants.SMIRK) {
            stringFaceVariant = 'Smirk';
        } else if (faceVariant == Face.FaceVariants.TONGUE) {
            stringFaceVariant = 'Tongue';
        } else if (faceVariant == Face.FaceVariants.WINK) {
            stringFaceVariant = 'Wink';
        } else if (faceVariant == Face.FaceVariants.WOW_TONGUE) {
            stringFaceVariant = 'Wow Tongue';
        } else if (faceVariant == Face.FaceVariants.WOW) {
            stringFaceVariant = 'Wow';
        }
        return string.concat('{"trait_type":"Face","value":"', stringFaceVariant, '"}');
    }

    function _getTrait(Headwear.HeadwearVariants headwearVariant) internal pure returns (string memory) {
        string memory stringHeadwearVariant;
        if (headwearVariant == Headwear.HeadwearVariants.NONE) {
            return '';
        } else if (headwearVariant == Headwear.HeadwearVariants.BEANIE) {
            stringHeadwearVariant = 'Beanie';
        } else if (headwearVariant == Headwear.HeadwearVariants.HAT) {
            stringHeadwearVariant = 'Hat';
        } else if (headwearVariant == Headwear.HeadwearVariants.LEAFS) {
            stringHeadwearVariant = 'Leafs';
        } else if (headwearVariant == Headwear.HeadwearVariants.PLANTS) {
            stringHeadwearVariant = 'Plants';
        } else if (headwearVariant == Headwear.HeadwearVariants.SPARKLES) {
            stringHeadwearVariant = 'Sparkles';
        } else if (headwearVariant == Headwear.HeadwearVariants.CROWN) {
            stringHeadwearVariant = 'Crown';
        } else if (headwearVariant == Headwear.HeadwearVariants.FLORAL) {
            stringHeadwearVariant = 'Floral';
        } else if (headwearVariant == Headwear.HeadwearVariants.GLASSES) {
            stringHeadwearVariant = 'Glasses';
        } else if (headwearVariant == Headwear.HeadwearVariants.MUSHROOM) {
            stringHeadwearVariant = 'Mushroom';
        } else if (headwearVariant == Headwear.HeadwearVariants.NIGHTCAP) {
            stringHeadwearVariant = 'Nightcap';
        } else if (headwearVariant == Headwear.HeadwearVariants.PARTYHAT) {
            stringHeadwearVariant = 'Partyhat';
        } else if (headwearVariant == Headwear.HeadwearVariants.ICECREAM) {
            stringHeadwearVariant = 'Icecream';
        }
        return string.concat(',{"trait_type":"Headwear","value":"', stringHeadwearVariant, '"}');
    }

    function _getTrait(Headwear.HeadwearColors headwearColor) internal pure returns (string memory) {
        string memory stringHeadwearColor;
        if (headwearColor == Headwear.HeadwearColors.NONE) {
            return '';
        } else if (headwearColor == Headwear.HeadwearColors.GREEN) {
            stringHeadwearColor = 'Green';
        } else if (headwearColor == Headwear.HeadwearColors.LIGHT) {
            stringHeadwearColor = 'Light';
        } else if (headwearColor == Headwear.HeadwearColors.DARK) {
            stringHeadwearColor = 'Dark';
        } else if (headwearColor == Headwear.HeadwearColors.PURPLE) {
            stringHeadwearColor = 'Purple';
        } else if (headwearColor == Headwear.HeadwearColors.BLUE) {
            stringHeadwearColor = 'Blue';
        } else if (headwearColor == Headwear.HeadwearColors.GOLD) {
            stringHeadwearColor = 'Gold';
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
