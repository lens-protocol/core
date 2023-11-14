// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Helpers} from './Helpers.sol';
import {HeadwearBeanie} from './Headwear/HeadwearBeanie.sol';
import {HeadwearHat} from './Headwear/HeadwearHat.sol';
import {HeadwearIcecream} from './Headwear/HeadwearIcecream.sol';
import {HeadwearLeafs} from './Headwear/HeadwearLeafs.sol';
import {HeadwearPlants} from './Headwear/HeadwearPlants.sol';
import {HeadwearSparkles} from './Headwear/HeadwearSparkles.sol';
import {HeadwearCrown} from './Headwear/HeadwearCrown.sol';
import {HeadwearFloral} from './Headwear/HeadwearFloral.sol';
import {HeadwearGlasses} from './Headwear/HeadwearGlasses.sol';
import {HeadwearMushroom} from './Headwear/HeadwearMushroom.sol';
import {HeadwearNightcap} from './Headwear/HeadwearNightcap.sol';
import {HeadwearPartyhat} from './Headwear/HeadwearPartyhat.sol';

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
            return '';
        } else if (variant == HeadwearVariants.BEANIE) {
            HeadwearBeanie.BeanieColors beanieColor = HeadwearBeanie.BeanieColors(
                isGold
                    ? HeadwearBeanie.BeanieColors.GOLD
                    : Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearBeanie.BeanieColors).max)
            );
            return HeadwearBeanie.getBeanie(beanieColor);
        } else if (variant == HeadwearVariants.HAT) {
            HeadwearHat.HatColors hatColor = HeadwearHat.HatColors(
                isGold
                    ? HeadwearHat.HatColors.GOLD
                    : Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) % uint8(type(HeadwearHat.HatColors).max)
            );
            return HeadwearHat.getHat(hatColor);
        } else if (variant == HeadwearVariants.ICECREAM) {
            HeadwearIcecream.IcecreamColors icecreamColor = HeadwearIcecream.IcecreamColors(
                isGold
                    ? HeadwearIcecream.IcecreamColors.GOLD
                    : Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearIcecream.IcecreamColors).max)
            );
            return HeadwearIcecream.getIcecream(icecreamColor);
        } else if (variant == HeadwearVariants.LEAFS) {
            HeadwearLeafs.LeafsColors leafsColor = HeadwearLeafs.LeafsColors(
                isGold
                    ? HeadwearLeafs.LeafsColors.GOLD
                    : Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearLeafs.LeafsColors).max)
            );
            return HeadwearLeafs.getLeafs(leafsColor);
        } else if (variant == HeadwearVariants.PLANTS) {
            HeadwearPlants.PlantsColors plantsColor = HeadwearPlants.PlantsColors(
                isGold
                    ? HeadwearPlants.PlantsColors.GOLD
                    : Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearPlants.PlantsColors).max)
            );
            return HeadwearPlants.getPlants(plantsColor);
        } else if (variant == HeadwearVariants.SPARKLES) {
            return
                HeadwearSparkles.getSparkles(
                    isGold ? HeadwearSparkles.SparklesColors.GOLD : HeadwearSparkles.SparklesColors.WHITE
                );
        } else if (variant == HeadwearVariants.CROWN) {
            HeadwearCrown.CrownColors crownColor = HeadwearCrown.CrownColors(
                isGold
                    ? HeadwearCrown.CrownColors.GOLD
                    : Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearCrown.CrownColors).max)
            );
            return HeadwearCrown.getCrown(crownColor);
        } else if (variant == HeadwearVariants.FLORAL) {
            HeadwearFloral.FloralColors floralColor = HeadwearFloral.FloralColors(
                isGole
                    ? HeadwearFloral.FloralColors.GOLD
                    : Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearFloral.FloralColors).max)
            );
            return HeadwearFloral.getFloral(floralColor);
        } else if (variant == HeadwearVariants.GLASSES) {
            HeadwearGlasses.GlassesColors glassesColor = HeadwearGlasses.GlassesColors(
                isGold
                    ? HeadwearGlasses.GlassesColors.GOLD
                    : Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearGlasses.GlassesColors).max)
            );
            return HeadwearGlasses.getGlasses(glassesColor);
        } else if (variant == HeadwearVariants.MUSHROOM) {
            HeadwearMushroom.MushroomColors mushroomColor = HeadwearMushroom.MushroomColors(
                isGold
                    ? HeadwearMushroom.MushroomColors.GOLD
                    : Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearMushroom.MushroomColors).max)
            );
            return HeadwearMushroom.getMushroom(mushroomColor);
        } else if (variant == HeadwearVariants.NIGHTCAP) {
            HeadwearNightcap.NightcapColors nightcapColor = HeadwearNightcap.NightcapColors(
                isGold
                    ? HeadwearNightcap.NightcapColors.GOLD
                    : Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearNightcap.NightcapColors).max)
            );
            return HeadwearNightcap.getNightcap(nightcapColor);
        } else if (variant == HeadwearVariants.PARTYHAT) {
            HeadwearPartyhat.PartyhatColors partyhatColor = HeadwearPartyhat.PartyhatColors(
                isGold
                    ? HeadwearPartyhat.PartyhatColors.GOLD
                    : Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearPartyhat.PartyhatColors).max)
            );
            return HeadwearPartyhat.getPartyhat(partyhatColor);
        } else {
            revert(); // Avoid warnings.
        }
    }
}
