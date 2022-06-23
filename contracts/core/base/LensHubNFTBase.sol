// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {ILensNFTBase} from '../../interfaces/ILensNFTBase.sol';
import {DataTypes} from '../../libraries/DataTypes.sol';
import {Events} from '../../libraries/Events.sol';
import {ERC721Time} from './ERC721Time.sol';
import {ERC721Enumerable} from './ERC721Enumerable.sol';

/**
 * @title LensNFTBase
 * @author Lens Protocol
 *
 * @dev This is a trimmed down version of the LensNFTBase, mostly for contract size concerns.
 * Functions other than the initializer have been moved to the core LensHub.
 */
abstract contract LensHubNFTBase is ERC721Enumerable, ILensNFTBase {
    mapping(address => uint256) public sigNonces; // Slot 10

    /**
     * @notice Initializer sets the name and symbol.
     *
     * NOTE: Inheritor contracts *must* call this function to initialize the name & symbol in the
     * inherited ERC721 contract.
     *
     * @param name The name to set in the ERC721 contract.
     * @param symbol The symbol to set in the ERC721 contract.
     */
    function _initialize(string calldata name, string calldata symbol) internal {
        ERC721Time.__ERC721_Init(name, symbol);
        emit Events.BaseInitialized(name, symbol, block.timestamp);
    }
}
