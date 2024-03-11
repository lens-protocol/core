// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {HandleSVG} from '../../libraries/svgs/Handle/HandleSVG.sol';
import {IHandleTokenURI} from '../../interfaces/IHandleTokenURI.sol';

contract HandleTokenURI is IHandleTokenURI {
    using Strings for uint256;

    function getTokenURI(
        uint256 tokenId,
        string memory localName,
        string memory namespace
    ) external pure override returns (string memory) {
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
                            Base64.encode(bytes(HandleSVG.getHandleSVG(localName))),
                            '","attributes":[{"display_type":"number","trait_type":"ID","value":"',
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
