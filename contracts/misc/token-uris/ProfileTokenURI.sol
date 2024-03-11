// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {ProfileSVG} from '../../libraries/svgs/Profile/ProfileSVG.sol';
import {IProfileTokenURI} from '../../interfaces/IProfileTokenURI.sol';

contract ProfileTokenURI is IProfileTokenURI {
    using Strings for uint96;
    using Strings for uint256;

    bytes32 public immutable blockSeed;

    constructor() {
        blockSeed = blockhash(block.number - 1);
    }

    function getTokenURI(uint256 profileId, uint256 mintTimestamp) public view override returns (string memory) {
        string memory profileIdAsString = profileId.toString();
        (string memory profileSvg, string memory traits) = ProfileSVG.getProfileSVG(profileId, blockSeed);
        string memory json;
        {
            json = string.concat(
                '{"name":"Profile #',
                profileIdAsString,
                '","description":"Lens Protocol - Profile #',
                profileIdAsString,
                '","image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(profileSvg))
            );
        }
        return
            string.concat(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        string.concat(
                            json,
                            '","attributes":[{"display_type":"number","trait_type":"ID","value":"',
                            profileIdAsString,
                            '"},{"trait_type":"HEX ID","value":"',
                            profileId.toHexString(),
                            '"},{"trait_type":"DIGITS","value":"',
                            bytes(profileIdAsString).length.toString(),
                            '"},{"display_type":"date","trait_type":"MINTED AT","value":"',
                            mintTimestamp.toString(),
                            '"},',
                            traits,
                            ']}'
                        )
                    )
                )
            );
    }
}
