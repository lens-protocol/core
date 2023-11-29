// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Helpers} from './Helpers.sol';
import {HeadwearBeanie} from './Headwear/HeadwearBeanie.sol';
import {HeadwearHat} from './Headwear/HeadwearHat.sol';
import {HeadwearIcecream} from './Headwear/HeadwearIcecream.sol';
import {HeadwearPlants} from './Headwear/HeadwearPlants.sol';
import {HeadwearSparkles} from './Headwear/HeadwearSparkles.sol';
import {HeadwearCrown} from './Headwear/HeadwearCrown.sol';
import {HeadwearFloral} from './Headwear/HeadwearFloral.sol';
import {HeadwearGlasses} from './Headwear/HeadwearGlasses.sol';
import {HeadwearMushroom} from './Headwear/HeadwearMushroom.sol';
import {HeadwearNightcap} from './Headwear/HeadwearNightcap.sol';
import {HeadwearPartyhat} from './Headwear/HeadwearPartyhat.sol';
import {HeadwearBear} from './Headwear/HeadwearBear.sol';
import {HeadwearBee} from './Headwear/HeadwearBee.sol';
import {HeadwearBirdie} from './Headwear/HeadwearBirdie.sol';
import {HeadwearBrains} from './Headwear/HeadwearBrains.sol';
import {HeadwearBull} from './Headwear/HeadwearBull.sol';
import {HeadwearEarrings} from './Headwear/HeadwearEarrings.sol';
import {HeadwearLotus} from './Headwear/HeadwearLotus.sol';
import {HeadwearMajor} from './Headwear/HeadwearMajor.sol';
import {HeadwearScout} from './Headwear/HeadwearScout.sol';
import {HeadwearShaman} from './Headwear/HeadwearShaman.sol';

library Headwear {
    enum HeadwearVariants {
        NONE,
        BEANIE,
        HAT,
        PLANTS,
        SPARKLES,
        CROWN,
        FLORAL,
        GLASSES,
        MUSHROOM,
        NIGHTCAP,
        PARTYHAT,
        ICECREAM,
        BEAR,
        BEE,
        BIRDIE,
        BRAINS,
        BULL,
        EARRINGS,
        LOTUS,
        MAJOR,
        SCOUT,
        SHAMAN
    }

    enum HeadwearColors {
        NONE,
        GREEN,
        PURPLE,
        BLUE,
        PINK,
        GOLD
    }

    function getHeadwear(
        uint256 seed,
        bool isGold
    ) public pure returns (string memory, HeadwearVariants, HeadwearColors) {
        // We don't do +1 here to make icecream rare
        HeadwearVariants variant = HeadwearVariants(
            Helpers.getVariant(seed, Helpers.ComponentBytes.HEADWEAR) % (uint8(type(HeadwearVariants).max))
        );

        if (Helpers.getVariant(seed, Helpers.ComponentBytes.HEADWEAR) == 69) {
            // lucky guy
            variant = HeadwearVariants.ICECREAM;
        }

        if (variant == HeadwearVariants.NONE) {
            return ('', HeadwearVariants.NONE, HeadwearColors.NONE);
        } else if (variant == HeadwearVariants.BEANIE) {
            HeadwearBeanie.BeanieColors beanieColor = isGold
                ? HeadwearBeanie.BeanieColors.GOLD
                : HeadwearBeanie.BeanieColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearBeanie.BeanieColors).max)
                );
            return HeadwearBeanie.getBeanie(beanieColor);
        } else if (variant == HeadwearVariants.HAT) {
            HeadwearHat.HatColors hatColor = isGold
                ? HeadwearHat.HatColors.GOLD
                : HeadwearHat.HatColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) % uint8(type(HeadwearHat.HatColors).max)
                );
            return HeadwearHat.getHat(hatColor);
        } else if (variant == HeadwearVariants.ICECREAM) {
            HeadwearIcecream.IcecreamColors icecreamColor = isGold
                ? HeadwearIcecream.IcecreamColors.GOLD
                : HeadwearIcecream.IcecreamColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearIcecream.IcecreamColors).max)
                );
            return HeadwearIcecream.getIcecream(icecreamColor);
        } else if (variant == HeadwearVariants.PLANTS) {
            HeadwearPlants.PlantsColors plantsColor = isGold
                ? HeadwearPlants.PlantsColors.GOLD
                : HeadwearPlants.PlantsColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearPlants.PlantsColors).max)
                );
            return HeadwearPlants.getPlants(plantsColor);
        } else if (variant == HeadwearVariants.SPARKLES) {
            return
                HeadwearSparkles.getSparkles(
                    isGold ? HeadwearSparkles.SparklesColors.GOLD : HeadwearSparkles.SparklesColors.NONE
                );
        } else if (variant == HeadwearVariants.CROWN) {
            HeadwearCrown.CrownColors crownColor = isGold
                ? HeadwearCrown.CrownColors.GOLD
                : HeadwearCrown.CrownColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) % uint8(type(HeadwearCrown.CrownColors).max)
                );
            return HeadwearCrown.getCrown(crownColor);
        } else if (variant == HeadwearVariants.FLORAL) {
            HeadwearFloral.FloralColors floralColor = isGold
                ? HeadwearFloral.FloralColors.GOLD
                : HeadwearFloral.FloralColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearFloral.FloralColors).max)
                );
            return HeadwearFloral.getFloral(floralColor);
        } else if (variant == HeadwearVariants.GLASSES) {
            HeadwearGlasses.GlassesColors glassesColor = isGold
                ? HeadwearGlasses.GlassesColors.GOLD
                : HeadwearGlasses.GlassesColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearGlasses.GlassesColors).max)
                );
            return HeadwearGlasses.getGlasses(glassesColor);
        } else if (variant == HeadwearVariants.MUSHROOM) {
            HeadwearMushroom.MushroomColors mushroomColor = isGold
                ? HeadwearMushroom.MushroomColors.GOLD
                : HeadwearMushroom.MushroomColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearMushroom.MushroomColors).max)
                );
            return HeadwearMushroom.getMushroom(mushroomColor);
        } else if (variant == HeadwearVariants.NIGHTCAP) {
            HeadwearNightcap.NightcapColors nightcapColor = isGold
                ? HeadwearNightcap.NightcapColors.GOLD
                : HeadwearNightcap.NightcapColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearNightcap.NightcapColors).max)
                );
            return HeadwearNightcap.getNightcap(nightcapColor);
        } else if (variant == HeadwearVariants.PARTYHAT) {
            HeadwearPartyhat.PartyhatColors partyhatColor = isGold
                ? HeadwearPartyhat.PartyhatColors.GOLD
                : HeadwearPartyhat.PartyhatColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearPartyhat.PartyhatColors).max)
                );
            return HeadwearPartyhat.getPartyhat(partyhatColor);
        } else if (variant == HeadwearVariants.BEAR) {
            HeadwearBear.BearColors bearColor = isGold
                ? HeadwearBear.BearColors.GOLD
                : HeadwearBear.BearColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) % uint8(type(HeadwearBear.BearColors).max)
                );
            return HeadwearBear.getBear(bearColor);
        } else if (variant == HeadwearVariants.BEE) {
            HeadwearBee.BeeColors beeColor = isGold
                ? HeadwearBee.BeeColors.GOLD
                : HeadwearBee.BeeColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) % uint8(type(HeadwearBee.BeeColors).max)
                );
            return HeadwearBee.getBee(beeColor);
        } else if (variant == HeadwearVariants.BIRDIE) {
            HeadwearBirdie.BirdieColors birdieColor = isGold
                ? HeadwearBirdie.BirdieColors.GOLD
                : HeadwearBirdie.BirdieColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearBirdie.BirdieColors).max)
                );
            return HeadwearBirdie.getBirdie(birdieColor);
        } else if (variant == HeadwearVariants.BRAINS) {
            HeadwearBrains.BrainsColors brainsColor = isGold
                ? HeadwearBrains.BrainsColors.GOLD
                : HeadwearBrains.BrainsColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearBrains.BrainsColors).max)
                );
            return HeadwearBrains.getBrains(brainsColor);
        } else if (variant == HeadwearVariants.BULL) {
            HeadwearBull.BullColors bullColor = isGold
                ? HeadwearBull.BullColors.GOLD
                : HeadwearBull.BullColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) % uint8(type(HeadwearBull.BullColors).max)
                );
            return HeadwearBull.getBull(bullColor);
        } else if (variant == HeadwearVariants.EARRINGS) {
            HeadwearEarrings.EarringsColors earringsColor = isGold
                ? HeadwearEarrings.EarringsColors.GOLD
                : HeadwearEarrings.EarringsColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearEarrings.EarringsColors).max)
                );
            return HeadwearEarrings.getEarrings(earringsColor);
        } else if (variant == HeadwearVariants.LOTUS) {
            HeadwearLotus.LotusColors lotusColor = isGold
                ? HeadwearLotus.LotusColors.GOLD
                : HeadwearLotus.LotusColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) % uint8(type(HeadwearLotus.LotusColors).max)
                );
            return HeadwearLotus.getLotus(lotusColor);
        } else if (variant == HeadwearVariants.MAJOR) {
            HeadwearMajor.MajorColors majorColor = isGold
                ? HeadwearMajor.MajorColors.GOLD
                : HeadwearMajor.MajorColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) % uint8(type(HeadwearMajor.MajorColors).max)
                );
            return HeadwearMajor.getMajor(majorColor);
        } else if (variant == HeadwearVariants.SCOUT) {
            HeadwearScout.ScoutColors scoutColor = isGold
                ? HeadwearScout.ScoutColors.GOLD
                : HeadwearScout.ScoutColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) % uint8(type(HeadwearScout.ScoutColors).max)
                );
            return HeadwearScout.getScout(scoutColor);
        } else if (variant == HeadwearVariants.SHAMAN) {
            HeadwearShaman.ShamanColors shamanColor = isGold
                ? HeadwearShaman.ShamanColors.GOLD
                : HeadwearShaman.ShamanColors(
                    Helpers.getColor(seed, Helpers.ComponentBytes.HEADWEAR) %
                        uint8(type(HeadwearShaman.ShamanColors).max)
                );
            return HeadwearShaman.getShaman(shamanColor);
        } else {
            revert(); // Avoid warnings.
        }
    }
}
