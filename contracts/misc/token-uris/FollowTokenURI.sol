// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {FollowSVG} from '../../libraries/svgs/Follow/FollowSVG.sol';
import {IFollowTokenURI} from '../../interfaces/IFollowTokenURI.sol';

contract FollowTokenURI is IFollowTokenURI {
    using Strings for uint96;
    using Strings for uint256;

    function getTokenURI(
        uint256 followTokenId,
        uint256 followedProfileId,
        uint256 originalFollowTimestamp
    ) external pure override returns (string memory) {
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
                            Base64.encode(bytes(FollowSVG.getFollowSVG(followTokenId))),
                            '","attributes":[{"display_type":"number","trait_type":"ID","value":"',
                            followTokenIdAsString,
                            '"},{"trait_type":"DIGITS","value":"',
                            bytes(followTokenIdAsString).length.toString(),
                            '"},{"display_type":"date","trait_type":"MINTED AT","value":"',
                            originalFollowTimestamp.toString(),
                            '"}]}'
                        )
                    )
                )
            );
    }
}
