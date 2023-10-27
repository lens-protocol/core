// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {ImageTokenURILib} from 'contracts/libraries/token-uris/ImageTokenURILib.sol';

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
                            '","description":"Lens Protocol - Handle @',
                            localName,
                            '","image":"data:image/svg+xml;base64,',
                            ImageTokenURILib.getSVGImageBase64Encoded(),
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
}
