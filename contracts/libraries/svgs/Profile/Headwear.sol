// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Helpers} from "./Helpers.sol";
import {HeadwearBeanie} from "./Headwear/HeadwearBeanie.sol";
import {HeadwearHat} from "./Headwear/HeadwearHat.sol";
import {HeadwearIcecream} from "./Headwear/HeadwearIcecream.sol";
import {HeadwearLeafs} from "./Headwear/HeadwearLeafs.sol";
import {HeadwearPlants} from "./Headwear/HeadwearPlants.sol";
import {HeadwearSparkles} from "./Headwear/HeadwearSparkles.sol";
import {HeadwearCrown} from "./Headwear/HeadwearCrown.sol";
import {HeadwearFloral} from "./Headwear/HeadwearFloral.sol";
import {HeadwearGlasses} from "./Headwear/HeadwearGlasses.sol";
import {HeadwearMushroom} from "./Headwear/HeadwearMushroom.sol";
import {HeadwearNightcap} from "./Headwear/HeadwearNightcap.sol";
import {HeadwearPartyhat} from "./Headwear/HeadwearPartyhat.sol";

library Headwear {
    enum HeadwearVariants {
        NONE,
        BEANIE,
        HAT,
        LEAFS,
        PLANTS,
        SPARKLES,
        CROWN,
        FLORAL,
        GLASSES,
        MUSHROOM,
        NIGHTCAP,
        PARTYHAT,
        ICECREAM
    }

    function getHeadwear(uint256 seed, bool isGold) public pure returns (string memory) {
        // We don't do +1 here to make icecream rare
        HeadwearVariants variant = HeadwearVariants(
            Helpers.getVariant(seed, Helpers.ComponentBytes.HEADWEAR) % (uint8(type(HeadwearVariants).max))
        );

        if (Helpers.getVariant(seed, Helpers.ComponentBytes.HEADWEAR) == 69) {
            // lucky guy
            variant = HeadwearVariants.ICECREAM;
        }

        if (variant == HeadwearVariants.NONE) {
            return "";
        } else if (variant == HeadwearVariants.BEANIE) {
            HeadwearBeanie.BeanieColors beanieColor = HeadwearBeanie.BeanieColors(
                Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                    (uint8(type(HeadwearBeanie.BeanieColors).max) + (isGold ? 1 : 0))
            );
            return HeadwearBeanie.getBeanie(beanieColor);
        } else if (variant == HeadwearVariants.HAT) {
            HeadwearHat.HatColors hatColor = HeadwearHat.HatColors(
                Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                    (uint8(type(HeadwearHat.HatColors).max) + (isGold ? 1 : 0))
            );
            return HeadwearHat.getHat(hatColor);
        } else if (variant == HeadwearVariants.ICECREAM) {
            HeadwearIcecream.IcecreamColors icecreamColor = HeadwearIcecream.IcecreamColors(
                Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                    (uint8(type(HeadwearIcecream.IcecreamColors).max) + (isGold ? 1 : 0))
            );
            return HeadwearIcecream.getIcecream(icecreamColor);
        } else if (variant == HeadwearVariants.LEAFS) {
            HeadwearLeafs.LeafsColors leafsColor = HeadwearLeafs.LeafsColors(
                Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                    (uint8(type(HeadwearLeafs.LeafsColors).max) + (isGold ? 1 : 0))
            );
            return HeadwearLeafs.getLeafs(leafsColor);
        } else if (variant == HeadwearVariants.PLANTS) {
            HeadwearPlants.PlantsColors plantsColor = HeadwearPlants.PlantsColors(
                Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                    (uint8(type(HeadwearPlants.PlantsColors).max) + (isGold ? 1 : 0))
            );
            return HeadwearPlants.getPlants(plantsColor);
        } else if (variant == HeadwearVariants.SPARKLES) {
            return
                HeadwearSparkles.getSparkles(
                    isGold ? HeadwearSparkles.SparklesColors.GOLD : HeadwearSparkles.SparklesColors.WHITE
                );
        } else if (variant == HeadwearVariants.CROWN) {
            HeadwearCrown.CrownColors crownColor = HeadwearCrown.CrownColors(
                Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                    (uint8(type(HeadwearCrown.CrownColors).max) + (isGold ? 1 : 0))
            );
            return HeadwearCrown.getCrown(crownColor);
        } else if (variant == HeadwearVariants.FLORAL) {
            HeadwearFloral.FloralColors floralColor = HeadwearFloral.FloralColors(
                Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                    (uint8(type(HeadwearFloral.FloralColors).max) + (isGold ? 1 : 0))
            );
            return HeadwearFloral.getFloral(floralColor);
        } else if (variant == HeadwearVariants.GLASSES) {
            HeadwearGlasses.GlassesColors glassesColor = HeadwearGlasses.GlassesColors(
                Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                    (uint8(type(HeadwearGlasses.GlassesColors).max) + (isGold ? 1 : 0))
            );
            return HeadwearGlasses.getGlasses(glassesColor);
        } else if (variant == HeadwearVariants.MUSHROOM) {
            HeadwearMushroom.MushroomColors mushroomColor = HeadwearMushroom.MushroomColors(
                Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                    (uint8(type(HeadwearMushroom.MushroomColors).max) + (isGold ? 1 : 0))
            );
            return HeadwearMushroom.getMushroom(mushroomColor);
        } else if (variant == HeadwearVariants.NIGHTCAP) {
            HeadwearNightcap.NightcapColors nightcapColor = HeadwearNightcap.NightcapColors(
                Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                    (uint8(type(HeadwearNightcap.NightcapColors).max) + (isGold ? 1 : 0))
            );
            return HeadwearNightcap.getNightcap(nightcapColor);
        } else if (variant == HeadwearVariants.PARTYHAT) {
            HeadwearPartyhat.PartyhatColors partyhatColor = HeadwearPartyhat.PartyhatColors(
                Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                    (uint8(type(HeadwearPartyhat.PartyhatColors).max) + (isGold ? 1 : 0))
            );
            return HeadwearPartyhat.getPartyhat(partyhatColor);
        }
    }
}
