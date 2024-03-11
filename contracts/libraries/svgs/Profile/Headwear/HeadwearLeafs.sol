// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Headwear} from '../Headwear.sol';

library HeadwearLeafs {
    enum LeafsColors {
        GREEN,
        BLUE,
        PURPLE,
        GOLD
    }

    // // we take the 15th byte from the left for hat color
    // uint8 color = uint8((seed >> 136) & 0xFF) % 3;
    function getLeafs(
        LeafsColors leafsColor
    ) internal pure returns (string memory, Headwear.HeadwearVariants, Headwear.HeadwearColors) {
        // leafs (4 colors: green, purple, blue, gold)
        return (
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="335" fill="none">',
                _getLeafsStyle(leafsColor),
                '<g clip-path="url(#a)"><path class="hwcolor" d="m40.4 87.2 1.7 3.3s3.3.3 5.4.7c2.3.5 5.8 1.9 5.8 1.9h.7l-2.1-4.6-4.5-3.9-6.8-.1-.2 2.7Z"/><path class="hwline35" d="M40.5 92c-1-2.8-1.4-5.8-1.1-8.8a19.2 19.2 0 0 1 18 14"/><path class="line25" d="m45.4 89.2 3.5 4"/><path class="hwcolor" d="M66.9 102.4s0-8.5 2.2-14c.1-.3.6-.7.6-.7l-.6-3.8-2.4-2.6-4.5-2.8-7.9-3.3L53 85.4s1.2 7.8 5 9.8l8.9 7.2Z"/><path class="hwline35" d="M57.6 97.2a28.7 28.7 0 0 1-3.6-23c3 2.3 6.8 3.5 10.2 5.4 3.4 1.9 6.5 4.8 6.8 8.4"/><path class="hwline3" d="M60 86.7c1.5 5.2 4.5 10 8.4 13.6"/><path class="hwcolor" d="M84.6 193.7c5.3 1 13.6 2 13.6 2l1.4 1-1.4 4.3-6 7.9-6.5 3.6-8.6 2.5-4-5.6-3.3-7.4-.3-8.8 2.3-2.6s7.8 2 12.8 3Z"/><path class="hwcolor" d="m69.7 189.9-4.6-1.5-1.8-.7-5 4.3-2.7 7.4 1 6h14l-1.8-5.5.9-10Z"/><path class="hwline35" d="M70.9 188.8c-3 3.8-2.6 9.3-.8 13.8 1.7 4.5 4.7 8.5 6.5 13A44.7 44.7 0 0 0 92 209a19 19 0 0 0 8.2-14"/><path class="hwline3" d="M85 192.4a71.4 71.4 0 0 1-4.7 13"/><path class="hwcolor" d="m41 185.9 9.9-3.2 4.7 2c2 .9 5.1 2 5.1 2l-2.7 5.4h-2l-7.2-.3-8-6Z"/><path class="hwline35" d="M70.6 206.1c-4.4 0-8.8-.2-13.3-.4a15.8 15.8 0 0 1 0-11c1.3-3.4 4-6.4 7.2-8.2"/><path class="hwline3" d="M68 194a21.8 21.8 0 0 0-5 4.4"/><path class="hwline35" d="M57.5 193.1c-7.2.7-14.6-2.6-18.5-8.3 3.9-.2 7.7-1.5 10.9-3.7"/><path class="line25" d="M52 186.6c2.3.2 4.7-.2 6.8-1.1"/></g><g clip-path="url(#b)"><path class="hwcolor" d="m169.4 87.2-1.7 3.3s-3.3.3-5.4.7c-2.3.5-5.7 1.9-5.7 1.9h-.7l2-4.6 4.6-3.9 6.8-.1.1 2.7Z"/><path class="hwline35" d="M169.3 92c1-2.8 1.4-5.8 1.2-8.8a19.2 19.2 0 0 0-18 14"/><path class="line25" d="m164.5 89.2-3.6 4"/><path class="hwcolor" d="M143 102.4s0-8.5-2.2-14l-.6-.7.6-3.8 2.4-2.6 4.4-2.8 8-3.3 1.3 10.2s-1.2 7.8-5 9.8c-.6.3-9 7.2-9 7.2Z"/><path class="hwline35" d="M152.2 97.2a28.7 28.7 0 0 0 3.7-23c-3 2.3-6.9 3.5-10.2 5.4-3.4 1.9-6.6 4.8-6.8 8.4"/><path class="hwline3" d="M149.8 86.7a29.5 29.5 0 0 1-8.4 13.6"/><path class="hwcolor" d="M125.2 193.7c-5.2 1-13.6 2-13.6 2l-1.4 1 1.4 4.3 6 7.9 6.5 3.6 8.7 2.5 4-5.6 3.2-7.4.3-8.8-2.3-2.6s-7.7 2-12.8 3Z"/><path class="hwcolor" d="m140.2 190 4.5-1.6 1.8-.7 5 4.3 2.8 7.4-1 6h-14.1l1.8-5.5-.8-9.8Z"/><path class="hwline35" d="M139 188.8c3 3.8 2.6 9.3.8 13.8s-4.7 8.5-6.6 13a44.7 44.7 0 0 1-15.4-6.5 19 19 0 0 1-8.2-14"/><path class="hwline3" d="M124.8 192.4c1.2 4.4 2.8 8.8 4.8 13"/><path class="hwcolor" d="m168.9 185.9-9.9-3.2-4.7 2c-2 1-5.1 2.1-5.1 2.1l2.7 5.3h1.8l7.2-.3 8-6Z"/><path class="hwline35" d="M139.3 206.1c4.4 0 8.8-.2 13.2-.4a15.8 15.8 0 0 0-7.2-19.2"/><path class="hwline3" d="M142 194c1.8 1.3 3.5 2.7 4.9 4.4"/><path class="hwline35" d="M152.4 193.1c7.2.7 14.6-2.6 18.5-8.3-4-.2-7.7-1.5-11-3.7"/><path class="line25" d="M157.8 186.6c-2.3.2-4.6-.2-6.8-1.1"/></g></svg>'
            ),
            Headwear.HeadwearVariants.LEAFS,
            _getHeadwearColor(leafsColor)
        );
    }

    function _getLeafsStyle(LeafsColors leafsColor) internal pure returns (string memory) {
        return
            string.concat(
                '<style>.hwcolor { fill: ',
                _getLeafsColor(leafsColor),
                ' }.hwline25 {stroke: black; stroke-linecap: round; stroke-linejoin: round; stroke-width: 2.5}.hwline3 {stroke: black; stroke-linecap: round; stroke-linejoin: round; stroke-width: 3}.hwline35 {stroke: black; stroke-linecap: round; stroke-linejoin: round; stroke-width: 3.5}</style>'
            );
    }

    function _getLeafsColor(LeafsColors leafsColor) internal pure returns (string memory) {
        if (leafsColor == LeafsColors.GREEN) {
            return '#A0D170';
        } else if (leafsColor == LeafsColors.PURPLE) {
            return '#EAD7FF';
        } else if (leafsColor == LeafsColors.BLUE) {
            return '#D9E0FF';
        } else if (leafsColor == LeafsColors.GOLD) {
            return '#FBD159';
        } else {
            revert(); // Avoid warnings.
        }
    }

    function _getHeadwearColor(LeafsColors leafsColor) internal pure returns (Headwear.HeadwearColors) {
        if (leafsColor == LeafsColors.GREEN) {
            return Headwear.HeadwearColors.GREEN;
        } else if (leafsColor == LeafsColors.PURPLE) {
            return Headwear.HeadwearColors.PURPLE;
        } else if (leafsColor == LeafsColors.BLUE) {
            return Headwear.HeadwearColors.BLUE;
        } else if (leafsColor == LeafsColors.GOLD) {
            return Headwear.HeadwearColors.GOLD;
        } else {
            revert(); // Avoid warnings.
        }
    }
}
