// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {ImageTokenURILib} from 'contracts/libraries/token-uris/ImageTokenURILib.sol';
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
                            ImageTokenURILib.getSVGImageBase64Encoded(),
                            '","attributes":[{"display_type": "number", "trait_type":"ID","value":"',
                            profileIdAsString,
                            '"},{"trait_type":"HEX ID","value":"',
                            profileId.toHexString(),
                            '"},{"trait_type":"DIGITS","value":"',
                            bytes(profileIdAsString).length.toString(),
                            '"},{"trait_type":"MINTED AT","value":"',
                            StorageLib.getTokenData(profileId).mintTimestamp.toString(),
                            '"}]}'
                        )
                    )
                )
            );
    }
}
