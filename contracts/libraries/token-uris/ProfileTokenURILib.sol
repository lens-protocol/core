// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {TokenURIMainFontLib} from 'contracts/libraries/token-uris/TokenURIMainFontLib.sol';
import {TokenURISecondaryFontLib} from 'contracts/libraries/token-uris/TokenURISecondaryFontLib.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';

library ProfileTokenURILib {
    using Strings for uint96;
    using Strings for uint256;

    function getTokenURI(uint256 profileId) external view returns (string memory) {
        string memory profileIdAsString = profileId.toString();
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"Profile #',
                            profileIdAsString,
                            '","description":"Lens Protocol - Profile #',
                            profileIdAsString,
                            '","image":"data:image/svg+xml;base64,',
                            _getSVGImageBase64Encoded(profileIdAsString),
                            '","attributes":[{"display_type": "number", "trait_type":"ID","value":"',
                            profileIdAsString,
                            '"},{"trait_type":"HEX ID","value":"',
                            profileId.toHexString(),
                            '"},{"trait_type":"DIGITS","value":"',
                            bytes(profileIdAsString).length,
                            '"},{"trait_type":"MINTED AT","value":"',
                            StorageLib.getTokenData(profileId).mintTimestamp.toString(),
                            '"}]}'
                        )
                    )
                )
            );
    }

    function _getSVGImageBase64Encoded(string memory profileIdAsString) private pure returns (string memory) {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg width="724" height="724" viewBox="0 0 724 724" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><style>',
                    TokenURIMainFontLib.getFontBase64Encoded(),
                    '</style></defs><defs><style>',
                    TokenURISecondaryFontLib.getFontBase64Encoded(),
                    '</style></defs><g clip-path="url(#clip0_2578_6938)"><rect width="724" height="724" fill="#C3E4CD"/><rect x="164" y="165" width="396" height="396" rx="20.5645" fill="#FFEBB8"/><text opacity="0.7" fill="#5A4E4C" font-family="',
                    TokenURISecondaryFontLib.getFontName(),
                    '" text-anchor="middle" font-size="26" letter-spacing="-0.2px"><tspan x="50%" y="504.748">Lens Profile</tspan></text><text fill="#5A4E4C" text-anchor="middle" font-family="',
                    TokenURIMainFontLib.getFontName(),
                    '" font-size="42" letter-spacing="-1.5px"><tspan x="50%" y="468.182">#',
                    profileIdAsString,
                    '</tspan></text><path d="M404.047 281.45C403.207 282.305 402.414 283.167 401.605 284.021C401.605 282.839 401.676 281.626 401.676 280.461C401.676 279.295 401.676 278.01 401.621 276.796C400.241 226.401 324.807 226.401 323.428 276.796C323.396 278.01 323.38 279.231 323.38 280.461C323.38 281.666 323.42 282.855 323.451 284.021C322.659 283.167 321.866 282.305 321.009 281.45C320.153 280.596 319.265 279.726 318.393 278.896C281.992 244.243 228.687 297.991 263.098 334.56C263.933 335.443 264.781 336.321 265.643 337.194C307.166 379 362.524 379 362.524 379C362.524 379 417.891 379 459.414 337.194C460.28 336.327 461.129 335.449 461.959 334.56C496.369 297.951 443.033 244.243 406.664 278.896C405.784 279.726 404.888 280.58 404.047 281.45Z" fill="black" fill-opacity="0.15"/><path d="M394.596 319.304C393.306 319.304 392.053 319.402 390.844 319.589C393.83 321.099 395.878 324.21 395.878 327.804C395.878 332.878 391.792 336.992 386.752 336.992C381.712 336.992 377.626 332.878 377.626 327.804C377.626 327.483 377.643 327.166 377.675 326.853C375.389 329.68 374.081 333.069 374.081 336.604H367.792C367.792 323.164 380.239 313.015 394.596 313.015C408.953 313.015 421.4 323.164 421.4 336.604H415.111C415.111 327.468 406.372 319.304 394.596 319.304ZM313.637 326.572C311.068 329.503 309.585 333.103 309.585 336.87H303.296C303.296 323.422 315.744 313.282 330.1 313.282C344.456 313.282 356.904 323.422 356.904 336.87H350.615C350.615 327.727 341.877 319.571 330.1 319.571C329.07 319.571 328.063 319.633 327.084 319.753C329.9 321.318 331.808 324.336 331.808 327.804C331.808 332.878 327.722 336.992 322.682 336.992C317.641 336.992 313.556 332.878 313.556 327.804C313.556 327.386 313.583 326.975 313.637 326.572ZM374.599 347.454C372.584 351.143 368.039 353.999 362.5 353.999C356.949 353.999 352.416 351.174 350.407 347.464L344.877 350.459C348.1 356.409 354.89 360.288 362.5 360.288C370.123 360.288 376.9 356.36 380.118 350.469L374.599 347.454Z" fill="#5A4E4C"/></g><defs><clipPath id="clip0_2578_6938"><rect width="724" height="724" fill="white"/></clipPath></defs></svg>'
                )
            );
    }
}
