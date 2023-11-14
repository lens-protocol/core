// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {ProfileSVG} from 'contracts/libraries/svgs/Profile/ProfileSVG.sol';
import {IProfileTokenURI} from 'contracts/interfaces/IProfileTokenURI.sol';

contract ProfileTokenURI is IProfileTokenURI {
    using Strings for uint96;
    using Strings for uint256;

    function getTokenURI(uint256 profileId, uint256 mintTimestamp) external pure override returns (string memory) {
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
                            Base64.encode(bytes(ProfileSVG.getProfileSVG(profileId))),
                            '","attributes":[{"display_type": "number", "trait_type":"ID","value":"',
                            profileIdAsString,
                            '"},{"trait_type":"HEX ID","value":"',
                            profileId.toHexString(),
                            '"},{"trait_type":"DIGITS","value":"',
                            bytes(profileIdAsString).length.toString(),
                            '"},{"trait_type":"MINTED AT","value":"',
                            mintTimestamp.toString(),
                            '"}]}'
                        )
                    )
                )
            );
    }
}
