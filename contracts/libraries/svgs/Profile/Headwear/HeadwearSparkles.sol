// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from '../Headwear.sol';

library HeadwearSparkles {
    enum SparklesColors {
        LIGHT,
        GOLD
    }

    function getSparkles(
        SparklesColors sparklesColor
    ) external pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        // sparkle (2 colors: white, gold)
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="197" viewBox="0 0 210 197" fill="none">',
                _getSparklesStyle(sparklesColor),
                '<path class="hwcolor" d="M155.643 53.12c.107-.297.54-.286.642.012 1.901 5.575 6.049 9.99 11.277 11.917a.085.085 0 0 1-.002.16l-.545.198c-4.979 1.803-8.864 5.945-10.599 11.297l-.026.08a.254.254 0 0 1-.483.003c-1.886-5.683-6.035-10.183-11.315-12.137a.096.096 0 0 1 .004-.18l.241-.08c5.035-1.735 9.015-5.876 10.806-11.27ZM69.698 37.675c.063-.176.32-.17.381.008 1.13 3.312 3.594 5.936 6.7 7.08a.05.05 0 0 1-.001.095l-.324.118c-2.958 1.071-5.266 3.532-6.297 6.712l-.015.048a.151.151 0 0 1-.287.001c-1.121-3.376-3.586-6.05-6.724-7.21a.057.057 0 0 1 .003-.108l.143-.048c2.992-1.03 5.356-3.49 6.42-6.696ZM21.911 52.734c.063-.176.32-.17.381.008 1.13 3.312 3.594 5.936 6.7 7.08a.05.05 0 0 1 0 .095l-.324.118c-2.959 1.071-5.267 3.532-6.297 6.712l-.016.048a.151.151 0 0 1-.287.001c-1.12-3.376-3.586-6.05-6.723-7.21a.057.057 0 0 1 .002-.108l.144-.048c2.991-1.03 5.356-3.49 6.42-6.696Zm160.991-12.4c.063-.176.321-.17.381.008 1.13 3.312 3.594 5.936 6.7 7.08.043.018.043.079-.001.095l-.324.118c-2.958 1.07-5.266 3.532-6.297 6.712l-.015.048a.151.151 0 0 1-.287.001c-1.121-3.376-3.586-6.05-6.723-7.21a.057.057 0 0 1 .002-.108l.143-.048c2.992-1.03 5.356-3.49 6.421-6.696Z"/><path class="hwcolor" d="M135.213 29.984c.045-.126.229-.121.272.005.805 2.36 2.561 4.23 4.775 5.046a.036.036 0 0 1-.001.068l-.23.084c-2.108.763-3.754 2.517-4.488 4.784l-.011.034a.108.108 0 0 1-.205 0c-.799-2.406-2.555-4.311-4.791-5.139a.04.04 0 0 1 .001-.076l.102-.034c2.133-.734 3.818-2.488 4.576-4.772Z"/><path class="hwcolor" d="M52.283 63.067c.094-.262.476-.252.566.011 1.678 4.92 5.339 8.818 9.954 10.519a.075.075 0 0 1-.002.14l-.481.175c-4.394 1.591-7.823 5.247-9.355 9.971l-.023.071a.225.225 0 0 1-.426.002c-1.665-5.016-5.327-8.987-9.988-10.712a.085.085 0 0 1 .004-.159l.213-.071c4.444-1.53 7.956-5.186 9.538-9.947Z"/></svg>'
            ),
            Headwear.HeadwearVariants.SPARKLES,
            _getHeadwearColor(sparklesColor)
        );
    }

    function _getSparklesStyle(SparklesColors sparklesColor) internal pure returns (string memory) {
        return
            string.concat(
                '<style>.hwcolor{fill:#fff; stroke:',
                _getSparklesColor(sparklesColor),
                '; stroke-width: 3; stroke-linecap: square; stroke-linejoin: round}</style>'
            );
    }

    function _getSparklesColor(SparklesColors sparklesColor) internal pure returns (string memory) {
        if (sparklesColor == SparklesColors.LIGHT) {
            return '#000';
        } else if (sparklesColor == SparklesColors.GOLD) {
            return '#B96326';
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(SparklesColors sparklesColor) internal pure returns (Headwear.HeadwearColors) {
        if (sparklesColor == SparklesColors.LIGHT) {
            return Headwear.HeadwearColors.LIGHT;
        } else if (sparklesColor == SparklesColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
