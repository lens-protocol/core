// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LensColors} from './LensColors.sol';
import {Face} from './Face.sol';

library Face2 {
    function getFaceVariant(Face.FaceVariants faceVariant) external pure returns (string memory) {
        if (faceVariant == Face.FaceVariants.BABY) {
            return '';
        } else if (faceVariant == Face.FaceVariants.KAWAII) {
            return '';
        } else if (faceVariant == Face.FaceVariants.PIXIE) {
            return '';
        } else if (faceVariant == Face.FaceVariants.TODDLER) {
            return '';
        } else if (faceVariant == Face.FaceVariants.VAMP) {
            return '';
        } else {
            revert(); // Avoid warnings.
        }
    }
}
