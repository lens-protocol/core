// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract MockWrongReturnDataERC721Recipient is IERC721Receiver {
    function testMockWrongReturnDataERC721Recipient() public {
        // Prevents being counted in Foundry Coverage
    }

    bytes4 wrongReturnValue;

    constructor(bytes4 returnValue) {
        if (returnValue == IERC721Receiver.onERC721Received.selector) {
            revert('Only wrong values can be passed to this mock contract');
        }
        wrongReturnValue = returnValue;
    }

    function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
        return wrongReturnValue;
    }
}
