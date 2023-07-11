// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract MockERC721RecipientWithRevertFlag is IERC721Receiver {
    error MockERC721RecipientReverted();

    function testMockERC721RecipientWithRevertFlag() public {
        // Prevents being counted in Foundry Coverage
    }

    bool revertFlag;

    function revertOnNextCall() public {
        revertFlag = true;
    }

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* id */,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        if (revertFlag || (data.length > 0 && abi.decode(data, (bool)))) {
            revert MockERC721RecipientReverted();
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
