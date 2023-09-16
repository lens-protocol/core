// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {TokenURIMainFontLib} from 'contracts/libraries/token-uris/TokenURIMainFontLib.sol';
import {TokenURISecondaryFontLib} from 'contracts/libraries/token-uris/TokenURISecondaryFontLib.sol';

library HandleTokenURILib {
    using Strings for uint256;

    function getTokenURI(
        uint256 tokenId,
        string memory localName,
        string memory namespace
    ) external pure returns (string memory) {
        return
            string.concat(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        string.concat(
                            '{"name":"@',
                            localName,
                            '","description":"Lens Protocol - @',
                            localName,
                            '","image":"data:image/svg+xml;base64,',
                            _getSVGImageBase64Encoded(localName),
                            '","attributes":[{"display_type": "number", "trait_type":"ID","value":"',
                            tokenId.toString(),
                            '"},{"trait_type":"NAMESPACE","value":"',
                            namespace,
                            '"},{"trait_type":"LENGTH","value":"',
                            bytes(localName).length.toString(),
                            '"}]}'
                        )
                    )
                )
            );
    }

    function _getSVGImageBase64Encoded(string memory localName) private pure returns (string memory) {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg width="724" height="724" viewBox="0 0 724 724" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><style>',
                    TokenURIMainFontLib.getFontBase64Encoded(),
                    '</style></defs><defs><style>',
                    TokenURISecondaryFontLib.getFontBase64Encoded(),
                    '</style></defs><g clip-path="url(#clip0_2578_6956)"><rect width="724" height="724" fill="#DBCCF3"/><ellipse cx="362" cy="362" rx="322" ry="212" fill="#FFEBB8"/><text opacity="0.7" fill="#5A4E4C" text-anchor="middle" font-family="',
                    TokenURISecondaryFontLib.getFontName(),
                    '" font-size="26" letter-spacing="-0.2px"><tspan x="50%" y="469.016">Lens Handle</tspan></text><text fill="#5A4E4C" text-anchor="middle" font-family="',
                    TokenURIMainFontLib.getFontName(),
                    '" font-size="',
                    _localNameLengthToFontSize(bytes(localName).length).toString(),
                    '" letter-spacing="-2px"><tspan x="50%" y="430.562">@',
                    localName,
                    '</tspan></text><path d="M395.81 268.567C395.125 269.262 394.48 269.964 393.821 270.66C393.821 269.698 393.879 268.71 393.879 267.761C393.879 266.812 393.879 265.765 393.834 264.777C392.711 223.741 331.286 223.741 330.162 264.777C330.137 265.765 330.124 266.76 330.124 267.761C330.124 268.742 330.156 269.711 330.182 270.66C329.536 269.964 328.891 269.262 328.193 268.567C327.496 267.871 326.773 267.163 326.063 266.487C296.422 238.269 253.017 282.035 281.037 311.813C281.717 312.532 282.408 313.247 283.109 313.958C316.921 348 361.998 348 361.998 348C361.998 348 407.082 348 440.894 313.958C441.6 313.252 442.291 312.537 442.966 311.813C470.987 282.003 427.555 238.269 397.94 266.487C397.224 267.163 396.494 267.858 395.81 268.567Z" fill="#5A4E4C" fill-opacity="0.2"/><path d="M388.109 299.431C387.081 299.431 386.082 299.508 385.117 299.654C387.515 300.895 389.155 303.41 389.155 306.312C389.155 310.444 385.828 313.793 381.724 313.793C377.62 313.793 374.293 310.444 374.293 306.312C374.293 306.075 374.304 305.841 374.325 305.61C372.492 307.896 371.445 310.629 371.445 313.477H366.242C366.242 302.505 376.402 294.228 388.109 294.228C399.816 294.228 409.976 302.505 409.976 313.477H404.773C404.773 306.066 397.681 299.431 388.109 299.431ZM322.177 305.383C320.117 307.754 318.929 310.658 318.929 313.694H313.726C313.726 302.715 323.887 294.445 335.593 294.445C347.3 294.445 357.46 302.715 357.46 313.694H352.257C352.257 306.277 345.167 299.648 335.593 299.648C334.775 299.648 333.975 299.696 333.196 299.79C335.457 301.073 336.983 303.513 336.983 306.312C336.983 310.444 333.656 313.793 329.552 313.793C325.448 313.793 322.121 310.444 322.121 306.312C322.121 305.997 322.14 305.687 322.177 305.383ZM371.792 322.293C370.159 325.282 366.472 327.601 361.976 327.601C357.468 327.601 353.793 325.307 352.164 322.301L347.589 324.779C350.222 329.638 355.765 332.804 361.976 332.804C368.196 332.804 373.73 329.598 376.358 324.787L371.792 322.293Z" fill="#5A4E4C"/></g><defs><clipPath id="clip0_2578_6956"><rect width="724" height="724"/></clipPath></defs></svg>'
                )
            );
    }

    /**
     * @notice Maps the local name length to a font size.
     *
     * @dev Gives the font size as a function of the local name length. This dynamic font size mapping ensures all
     * handle token URIs will look nice when rendered as image.
     *
     * @param localNameLength The handle's local name length.
     *
     * @return uint256 The font size.
     */
    function _localNameLengthToFontSize(uint256 localNameLength) internal pure returns (uint256) {
        return (664301 * localNameLength * localNameLength + 790000000 - 41066900 * localNameLength) / 10000000;
    }
}
