// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {TokenURIMainFontLib} from 'contracts/libraries/token-uris/TokenURIMainFontLib.sol';
import {TokenURISecondaryFontLib} from 'contracts/libraries/token-uris/TokenURISecondaryFontLib.sol';

library FollowTokenURILib {
    using Strings for uint96;
    using Strings for uint256;

    function getTokenURI(
        uint256 followTokenId,
        uint256 followedProfileId,
        uint256 originalFollowTimestamp
    ) external pure returns (string memory) {
        string memory followTokenIdAsString = followTokenId.toString();
        string memory followedProfileIdAsString = followedProfileId.toString();
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"Follower #',
                            followTokenIdAsString,
                            '","description":"Lens Protocol - Follower #',
                            followTokenIdAsString,
                            ' of Profile #',
                            followedProfileIdAsString,
                            '","image":"data:image/svg+xml;base64,',
                            _getSVGImageBase64Encoded(followTokenIdAsString, followedProfileIdAsString),
                            '","attributes":[{"display_type": "number", "trait_type":"ID","value":"',
                            followTokenIdAsString,
                            '"},{"trait_type":"DIGITS","value":"',
                            bytes(followTokenIdAsString).length.toString(),
                            '"},{"trait_type":"MINTED AT","value":"',
                            originalFollowTimestamp.toString(),
                            '"}]}'
                        )
                    )
                )
            );
    }

    function _getSVGImageBase64Encoded(string memory followTokenIdAsString, string memory followedProfileIdAsString)
        private
        pure
        returns (string memory)
    {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg width="724" height="724" viewBox="0 0 724 724" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><style>',
                    TokenURIMainFontLib.getFontBase64Encoded(),
                    '</style></defs><defs><style>',
                    TokenURISecondaryFontLib.getFontBase64Encoded(),
                    '</style></defs><g clip-path="url(#clip0_2600_6938)"><rect width="724" height="724" fill="#D0DBFF"/><rect x="91" y="290" width="543" height="144" rx="72" fill="#FFEBB8"/><text fill="#5A4E4C" font-family="',
                    TokenURIMainFontLib.getFontName(),
                    '" font-size="42" letter-spacing="-1.5px"><tspan x="278" y="393.182">#',
                    followTokenIdAsString,
                    '</tspan></text><text fill="#5A4E4C" fill-opacity="0.7" font-family="',
                    TokenURISecondaryFontLib.getFontName(),
                    '" font-size="26" letter-spacing="-0.2px"><tspan x="280" y="347.516">Following #',
                    followedProfileIdAsString,
                    '</tspan></text><path d="M215.667 344.257C215.188 344.745 214.736 345.238 214.275 345.726C214.275 345.051 214.316 344.358 214.316 343.692C214.316 343.026 214.316 342.291 214.284 341.598C213.498 312.801 170.5 312.801 169.714 341.598C169.696 342.291 169.687 342.989 169.687 343.692C169.687 344.381 169.709 345.06 169.727 345.726C169.275 345.238 168.823 344.745 168.335 344.257C167.847 343.769 167.341 343.272 166.844 342.798C146.095 322.996 115.712 353.709 135.326 374.606C135.802 375.11 136.285 375.612 136.776 376.111C160.444 400 191.999 400 191.999 400C191.999 400 223.558 400 247.226 376.111C247.72 375.615 248.203 375.113 248.676 374.606C268.291 353.686 237.889 322.996 217.158 342.798C216.657 343.272 216.146 343.76 215.667 344.257Z" fill="#5A4E4C" fill-opacity="0.25"/><path d="M210.278 365.9C209.551 365.9 208.843 365.955 208.16 366.059C209.851 366.926 211.01 368.698 211.01 370.744C211.01 373.644 208.682 375.994 205.809 375.994C202.936 375.994 200.607 373.644 200.607 370.744C200.607 370.57 200.615 370.397 200.632 370.227C199.34 371.836 198.602 373.763 198.602 375.773H194.984C194.984 368.089 202.084 362.282 210.278 362.282C218.473 362.282 225.573 368.089 225.573 375.773H221.955C221.955 370.557 216.98 365.9 210.278 365.9ZM164.129 370.069C162.678 371.738 161.841 373.784 161.841 375.925H158.223C158.223 368.236 165.324 362.434 173.518 362.434C181.712 362.434 188.813 368.236 188.813 375.925H185.195C185.195 370.705 180.22 366.052 173.518 366.052C172.937 366.052 172.369 366.087 171.816 366.154C173.411 367.051 174.49 368.77 174.49 370.744C174.49 373.644 172.161 375.994 169.288 375.994C166.415 375.994 164.086 373.644 164.086 370.744C164.086 370.515 164.101 370.29 164.129 370.069ZM198.866 381.969C197.72 384.073 195.135 385.701 191.985 385.701C188.829 385.701 186.251 384.09 185.107 381.974L181.924 383.694C183.764 387.098 187.64 389.319 191.985 389.319C196.338 389.319 200.207 387.07 202.043 383.7L198.866 381.969Z" fill="#5A4E4C"/></g><defs><clipPath id="clip0_2600_6938"><rect width="724" height="724" fill="white"/></clipPath></defs></svg>'
                )
            );
    }
}
